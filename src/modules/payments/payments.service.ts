import { Injectable, BadRequestException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { ProcessEscrowPaymentDto } from './dto/process-payment.dto';
import {
  BankPayoutStatus,
  ContractStatus,
  EscrowStatus,
  NotificationType,
  PaymentStatus,
  TransactionType,
  TripStatus,
} from '@prisma/client';
import { NotificationsGateway } from '../notifications/notifications.gateway';
import { NotificationsService } from '../notifications/notifications.service';
import { PLATFORM_CONSTANTS } from '../../common/constants';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class PaymentsService {
  constructor(
    private prisma: PrismaService,
    private gateway: NotificationsGateway,
    private notificationsService: NotificationsService,
  ) {}

  async processEscrowPayment(clientId: string, dto: ProcessEscrowPaymentDto) {
    const contract = await this.prisma.tripContract.findUnique({
      where: { id: dto.contractId },
      include: {
        tripRequest: true,
        driverProfile: { include: { user: true } },
      },
    });

    if (!contract) {
      throw new NotFoundException('عقد التوصيل غير موجود');
    }

    if (contract.clientId !== clientId) {
      throw new ForbiddenException('لا يمكنك دفع قيمة عقد لا يخصك');
    }

    if (contract.contractStatus !== ContractStatus.PENDING_PAYMENT) {
      throw new BadRequestException('تم سداد قيمة هذا العقد مسبقاً أو أن العقد ليس في حالة انتظار الدفع');
    }

    const transactionReference = `TRH-PAY-${Date.now()}-${uuidv4().substring(0, 8).toUpperCase()}`;

    // Execute atomic transaction for escrow lock (including 15% VAT)
    const result = await this.prisma.$transaction(async (tx) => {
      // 1. Create or update Escrow Payment record
      const payment = await tx.escrowPayment.create({
        data: {
          contractId: contract.id,
          baseAmount: contract.baseAmount,
          vatAmount: contract.vatAmount,
          totalAmount: contract.totalPaidByClient,
          paymentMethod: dto.paymentMethod,
          transactionReference,
          status: PaymentStatus.CAPTURED,
          antiCashWarningDisplayed: true,
          paidAt: new Date(),
        },
      });

      // 2. Update Contract status
      const updatedContract = await tx.tripContract.update({
        where: { id: contract.id },
        data: {
          contractStatus: ContractStatus.ACTIVE,
          escrowStatus: EscrowStatus.HELD_IN_ESCROW,
        },
      });

      // 3. Update Driver pending escrow balance
      await tx.driverProfile.update({
        where: { id: contract.driverProfileId },
        data: {
          pendingEscrowBalance: { increment: contract.driverEarnings },
        },
      });

      // 4. Update Trip Request status
      await tx.tripRequest.update({
        where: { id: contract.tripRequestId },
        data: { status: TripStatus.IN_PROGRESS },
      });

      // 5. Log Wallet Transaction for Client escrow deposit
      await tx.walletTransaction.create({
        data: {
          userId: clientId,
          amount: -contract.totalPaidByClient,
          type: TransactionType.ESCROW_PAYMENT,
          balanceAfter: 0.0,
          description: `سداد وحجز قيمة عقد التوصيل (#${contract.id.substring(0, 8)}) تحت ضمان ترحيل شاملة 15% ضريبة القيمة المضافة (${contract.vatAmount} ر.س)`,
          contractId: contract.id,
        },
      });

      return { payment, contract: updatedContract };
    });

    // Notify Driver of successful payment & guarantee activation
    const driverMessage = `تم تأكيد سداد العميل لمبلغ التعاقد (${contract.totalPaidByClient} ر.س شاملاً 15% ضريبة). تم تعليق مستحقاتك (${contract.driverEarnings} ر.س) في الضمان لحين انتهاء مدة التوصيل وتقييم العميل. يرجى الالتزام بالمواعيد وموقع الانطلاق.`;
    await this.notificationsService.createNotification(
      contract.driverProfile.user.id,
      'تم تأكيد سداد العقد وتعليق المستحقات في الضمان!',
      driverMessage,
      NotificationType.PAYMENT_CONFIRMED,
      { contractId: contract.id },
    );

    return {
      message: 'تم إتمام عملية الدفع بنجاح وحجز المبلغ شاملاً 15% ضريبة القيمة المضافة في ضمان ترحيل. العقد سارٍ الآن ومحمي 100%.',
      paymentReference: transactionReference,
      invoiceBreakdown: {
        baseAmount: contract.baseAmount,
        vatRate: '15%',
        vatAmount: contract.vatAmount,
        totalPaidByClient: contract.totalPaidByClient,
        amountHeldInEscrow: contract.totalPaidByClient,
      },
      antiCashWarningNotice: PLATFORM_CONSTANTS.ANTI_CASH_WARNING_AR,
      contractStatus: ContractStatus.ACTIVE,
      escrowStatus: EscrowStatus.HELD_IN_ESCROW,
    };
  }

  async completeContractAndReleaseFunds(contractId: string, actorUserId: string) {
    const contract = await this.prisma.tripContract.findUnique({
      where: { id: contractId },
      include: {
        driverProfile: { include: { user: true } },
        client: true,
        tripRequest: true,
        escrowPayment: true,
      },
    });

    if (!contract) {
      throw new NotFoundException('العقد غير موجود');
    }

    // Must be either client or admin
    if (contract.clientId !== actorUserId && contract.client.id !== actorUserId) {
      const user = await this.prisma.user.findUnique({ where: { id: actorUserId } });
      if (user?.role !== 'ADMIN') {
        throw new ForbiddenException('فقط العميل أو إدارة ترحيل يمكنهم تأكيد اكتمال التوصيل وتحرير المبلغ');
      }
    }

    if (contract.escrowStatus !== EscrowStatus.HELD_IN_ESCROW) {
      throw new BadRequestException('المبلغ ليس محتجزاً في الضمان المالي أو تم تحريره مسبقاً');
    }

    const netDriverEarnings = contract.driverEarnings; // 90% of base amount
    const platformCommission = contract.platformCommissionAmount; // 10% of base amount
    const bankPayoutRef = `TRH-BNK-${Date.now()}-${uuidv4().substring(0, 6).toUpperCase()}`;
    const driverIban = contract.driverProfile.iban || contract.driverBankIban || 'الحساب البنكي المسجل';
    const driverBank = contract.driverProfile.bankName || contract.driverBankName || 'البنك المسجل';

    // Atomic execution for fund release, commission ledger, and bank transfer payout
    const result = await this.prisma.$transaction(async (tx) => {
      // 1. Update Driver wallet & decrement pending escrow balance
      const updatedDriver = await tx.driverProfile.update({
        where: { id: contract.driverProfileId },
        data: {
          walletBalance: { increment: netDriverEarnings },
          pendingEscrowBalance: { decrement: netDriverEarnings },
          totalTripsCount: { increment: 1 },
        },
      });

      // 2. Log Driver Bank Payout Transaction
      await tx.walletTransaction.create({
        data: {
          userId: contract.driverProfile.userId,
          amount: netDriverEarnings,
          type: TransactionType.BANK_PAYOUT,
          balanceAfter: updatedDriver.walletBalance,
          description: `تحويل بنكي مباشر لمستحقات مشوار التوصيل (#${contract.id.substring(0, 8)}) إلى ${driverBank} - آيبان: ${driverIban} (بعد خصم 10% عمولة ترحيل)`,
          contractId: contract.id,
          iban: driverIban,
          bankName: driverBank,
        },
      });

      // 3. Update Contract & Escrow statuses with bank transfer details
      const updatedContract = await tx.tripContract.update({
        where: { id: contract.id },
        data: {
          contractStatus: ContractStatus.COMPLETED,
          escrowStatus: EscrowStatus.RELEASED_TO_DRIVER_BANK,
          bankPayoutStatus: BankPayoutStatus.TRANSFERRED_TO_BANK,
          bankPayoutReference: bankPayoutRef,
          bankPayoutTransferredAt: new Date(),
          completedAt: new Date(),
        },
      });

      // 4. Update Trip Request status
      await tx.tripRequest.update({
        where: { id: contract.tripRequestId },
        data: { status: TripStatus.COMPLETED },
      });

      // 5. Update Escrow payment record
      if (contract.escrowPayment) {
        await tx.escrowPayment.update({
          where: { id: contract.escrowPayment.id },
          data: {
            status: PaymentStatus.RELEASED,
            releasedAt: new Date(),
          },
        });
      }

      return { updatedContract, updatedDriver };
    });

    // Notify Driver of bank transfer
    await this.notificationsService.createNotification(
      contract.driverProfile.user.id,
      'تم تحويل أرباحك إلى حسابك البنكي!',
      `تم تحويل مبلغ ${netDriverEarnings} ر.س إلى حسابك البنكي (${driverBank} - ${driverIban}) بمرجع (${bankPayoutRef}) بعد خصم عمولة ترحيل (${platformCommission} ر.س - 10%). شكراً لالتزامك وجودة خدمتك.`,
      NotificationType.BANK_PAYOUT_SENT,
      {
        contractId: contract.id,
        earnings: netDriverEarnings,
        commission: platformCommission,
        bankPayoutReference: bankPayoutRef,
        iban: driverIban,
      },
    );

    // Prompt Client for review
    this.gateway.notifyContractCompleted(contract.clientId, contract.id);
    await this.notificationsService.createNotification(
      contract.clientId,
      'اكتملت مدة التوصيل! يرجى تقييم السائق',
      'يسرنا تقييمك للسائق لإبداء رأيك في دقة المواعيد ونظافة وتكييف السيارة والمساعدة في تحسين جودة خدمة ترحيل.',
      NotificationType.REVIEW_REQUESTED,
      { contractId: contract.id, driverId: contract.driverProfileId },
    );

    return {
      message: 'تم إنهاء مدة التوصيل بنجاح وتحويل المستحقات لحساب السائق البنكي المعتمد بعد خصم عمولة ترحيل (10%). يرجى تقييم السائق.',
      financialSummary: {
        baseTripPrice: contract.baseAmount,
        vat15PercentCollected: contract.vatAmount,
        totalPaidByClient: contract.totalPaidByClient,
        platformCommission10Percent: platformCommission,
        driverTransferredEarnings90Percent: netDriverEarnings,
        destinationBankAccount: {
          bankName: driverBank,
          iban: driverIban,
          payoutReference: bankPayoutRef,
          transferStatus: 'TRANSFERRED_TO_BANK',
        },
      },
      contractStatus: ContractStatus.COMPLETED,
      escrowStatus: EscrowStatus.RELEASED_TO_DRIVER_BANK,
      reviewPromptRequired: true,
    };
  }
}
