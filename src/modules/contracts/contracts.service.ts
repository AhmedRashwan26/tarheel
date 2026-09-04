import { Injectable, BadRequestException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AcceptOfferDto } from './dto/accept-offer.dto';
import {
  BankPayoutStatus,
  ContractStatus,
  EscrowStatus,
  Frequency,
  OfferStatus,
  PaymentType,
  TripStatus,
  NotificationType,
} from '@prisma/client';
import { NotificationsGateway } from '../notifications/notifications.gateway';
import { NotificationsService } from '../notifications/notifications.service';
import { PLATFORM_CONSTANTS } from '../../common/constants';

@Injectable()
export class ContractsService {
  constructor(
    private prisma: PrismaService,
    private gateway: NotificationsGateway,
    private notificationsService: NotificationsService,
  ) {}

  async acceptOffer(clientId: string, dto: AcceptOfferDto) {
    const offer = await this.prisma.tripOffer.findUnique({
      where: { id: dto.offerId },
      include: {
        tripRequest: true,
        driverProfile: { include: { user: true } },
      },
    });

    if (!offer) {
      throw new NotFoundException('عرض السعر غير موجود');
    }

    if (offer.tripRequest.clientId !== clientId) {
      throw new ForbiddenException('لا يمكنك قبول عرض لمشوار لا يخصك');
    }

    if (offer.tripRequest.status !== TripStatus.OPEN_FOR_BIDS) {
      throw new BadRequestException('تم قبول عرض مسبقاً لهذا المشوار أو تم إلغاؤه');
    }

    // Financial calculations:
    // Base amount from driver offer
    const baseAmount = offer.offerPrice;
    
    // 15% VAT added to client's bill
    const vatRate = PLATFORM_CONSTANTS.VAT_PERCENTAGE; // 15%
    const vatAmount = Number(((baseAmount * vatRate) / 100).toFixed(2));
    const totalPaidByClient = Number((baseAmount + vatAmount).toFixed(2));

    // 10% platform commission deducted from base amount
    const commissionRate = PLATFORM_CONSTANTS.COMMISSION_PERCENTAGE; // 10%
    const commissionAmount = Number(((baseAmount * commissionRate) / 100).toFixed(2));
    const driverEarnings = Number((baseAmount - commissionAmount).toFixed(2)); // 90%

    let defaultPaymentType: PaymentType = PaymentType.FULL_UPFRONT;
    if (offer.tripRequest.frequency === Frequency.MONTHLY) defaultPaymentType = PaymentType.MONTHLY;
    if (offer.tripRequest.frequency === Frequency.WEEKLY) defaultPaymentType = PaymentType.WEEKLY;

    const paymentType = dto.paymentType || defaultPaymentType;

    // Transaction to update offer, tripRequest, reject others, and create contract
    const result = await this.prisma.$transaction(async (tx) => {
      // 1. Mark this offer as ACCEPTED
      await tx.tripOffer.update({
        where: { id: offer.id },
        data: { status: OfferStatus.ACCEPTED },
      });

      // 2. Reject other offers for this trip
      await tx.tripOffer.updateMany({
        where: {
          tripRequestId: offer.tripRequestId,
          id: { not: offer.id },
        },
        data: { status: OfferStatus.REJECTED },
      });

      // 3. Update trip request status
      await tx.tripRequest.update({
        where: { id: offer.tripRequestId },
        data: { status: TripStatus.ASSIGNED },
      });

      // 4. Create Trip Contract
      const contract = await tx.tripContract.create({
        data: {
          tripRequestId: offer.tripRequestId,
          clientId,
          driverProfileId: offer.driverProfileId,
          acceptedOfferId: offer.id,
          baseAmount,
          vatRate,
          vatAmount,
          totalPaidByClient,
          platformCommissionRate: commissionRate,
          platformCommissionAmount: commissionAmount,
          driverEarnings,
          paymentType,
          escrowStatus: EscrowStatus.PENDING_PAYMENT,
          contractStatus: ContractStatus.PENDING_PAYMENT,
          bankPayoutStatus: BankPayoutStatus.PENDING_REVIEW,
          driverBankIban: offer.driverProfile.iban,
          driverBankName: offer.driverProfile.bankName,
          startDate: offer.tripRequest.startDate,
          antiCashPolicyAcknowledged: true,
        },
        include: {
          tripRequest: true,
          driverProfile: { include: { user: true, vehicle: true } },
          client: { select: { fullName: true, phoneNumber: true } },
        },
      });

      return contract;
    });

    // Notify Driver via WebSocket and Database Notification
    const driverNoticeMessage = `تنبيه مهم للسائق: تم قبول عرضك لمشوار (${offer.tripRequest.pickupAddress} إلى ${offer.tripRequest.dropoffAddress})! يجب التواجد في الموعد المحدد (${offer.tripRequest.preferredTime}) وموقع الانطلاق بدقة. قيمة المشوار الأساسية (${baseAmount} ر.س) - مستحقاتك بعد خصم 10% عمولة ترحيل هي (${driverEarnings} ر.س) سيتم تحويلها لحسابك البنكي (${offer.driverProfile.bankName} - ${offer.driverProfile.iban}) بعد انتهاء مدة التوصيل وتقييم العميل.`;

    this.gateway.notifyDriverBidAccepted(offer.driverProfile.user.id, result);
    await this.notificationsService.createNotification(
      offer.driverProfile.user.id,
      'تم قبول عرضك السعري!',
      driverNoticeMessage,
      NotificationType.BID_ACCEPTED,
      { contractId: result.id, tripId: offer.tripRequestId },
    );

    return {
      message: 'تم قبول العرض بنجاح! يرجى سداد المبلغ الإجمالي المحتسب شاملاً 15% ضريبة القيمة المضافة لتفعيل الضمان المالي.',
      contractId: result.id,
      financialInvoice: {
        baseTripPrice: baseAmount,
        vatRate: '15%',
        vatAmount,
        totalPayableByClient: totalPaidByClient,
        platformCommissionRate: '10%',
        platformCommission: commissionAmount,
        driverNetEarnings: driverEarnings,
        driverTargetBank: `${offer.driverProfile.bankName || 'البنك المسجل'} (${offer.driverProfile.iban || ''})`,
      },
      contract: result,
      paymentInstructions: {
        paymentType,
        antiCashGuaranteeNotice: PLATFORM_CONSTANTS.ANTI_CASH_WARNING_AR,
        nextStep: 'يرجى إتمام عملية الدفع عبر مسار /payments/process-escrow لحجز المبلغ في الضمان وتأكيد الحجز.',
      },
    };
  }

  async getContractById(contractId: string, userId: string) {
    const contract = await this.prisma.tripContract.findUnique({
      where: { id: contractId },
      include: {
        tripRequest: true,
        driverProfile: {
          include: {
            user: { select: { fullName: true, phoneNumber: true } },
            vehicle: true,
          },
        },
        client: { select: { fullName: true, phoneNumber: true } },
        escrowPayment: true,
        review: true,
      },
    });

    if (!contract) {
      throw new NotFoundException('عقد المشوار غير موجود');
    }

    if (contract.clientId !== userId && contract.driverProfile.userId !== userId) {
      throw new ForbiddenException('غير مصرح لك بالاطلاع على هذا العقد');
    }

    return contract;
  }

  async getMyContracts(userId: string) {
    return this.prisma.tripContract.findMany({
      where: {
        OR: [{ clientId: userId }, { driverProfile: { userId } }],
      },
      include: {
        tripRequest: true,
        driverProfile: {
          include: {
            user: { select: { fullName: true, phoneNumber: true } },
            vehicle: true,
          },
        },
        client: { select: { fullName: true, phoneNumber: true } },
        escrowPayment: true,
        review: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }
}
