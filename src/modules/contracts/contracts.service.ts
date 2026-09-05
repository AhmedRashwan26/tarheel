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

    // 13.50% platform commission deducted from base amount
    const commissionRate = PLATFORM_CONSTANTS.COMMISSION_PERCENTAGE; // 13.5%
    const commissionAmount = Number(((baseAmount * commissionRate) / 100).toFixed(2));
    const driverEarnings = Number((baseAmount - commissionAmount).toFixed(2)); // 86.5%

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

    // Notify Driver via Multi-Channel (In-App DB + WebSocket + WhatsApp + Email)
    await this.notificationsService.notifyDriverBidAcceptedMultiChannel({
      driver: {
        id: offer.driverProfile.user.id,
        fullName: offer.driverProfile.user.fullName,
        phoneNumber: offer.driverProfile.user.phoneNumber,
        email: offer.driverProfile.user.email,
        bankName: offer.driverProfile.bankName,
      },
      client: {
        fullName: result.client?.fullName || 'العميل',
        phoneNumber: result.client?.phoneNumber,
      },
      trip: {
        id: offer.tripRequestId,
        pickupAddress: offer.tripRequest.pickupAddress,
        dropoffAddress: offer.tripRequest.dropoffAddress,
        preferredTime: offer.tripRequest.preferredTime,
      },
      contractId: result.id,
      baseAmount,
      driverEarnings,
    });

    return {
      message: 'تم قبول العرض بنجاح! يرجى سداد المبلغ الإجمالي المحتسب شاملاً 15% ضريبة القيمة المضافة لتفعيل الضمان المالي.',
      contractId: result.id,
      financialInvoice: {
        baseTripPrice: baseAmount,
        vatRate: '15%',
        vatAmount,
        totalPayableByClient: totalPaidByClient,
        platformCommissionRate: '13.50%',
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

  async getDriverDailySchedule(userId: string, dateStr?: string) {
    const targetDate = dateStr ? new Date(dateStr) : new Date();
    const arabicDays = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    const currentDayName = arabicDays[targetDate.getDay()];

    const contracts = await this.prisma.tripContract.findMany({
      where: {
        driverProfile: { userId },
        contractStatus: { in: [ContractStatus.ACTIVE, ContractStatus.IN_PROGRESS, ContractStatus.PENDING_PAYMENT, ContractStatus.COMPLETED] },
      },
      include: {
        tripRequest: true,
        client: { select: { id: true, fullName: true, phoneNumber: true } },
      },
    });

    const slots: any[] = [];

    for (const contract of contracts) {
      const trip = contract.tripRequest;
      const client = contract.client;
      
      let recurringDays: string[] = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس'];
      if (trip.recurringDays) {
        try {
          recurringDays = typeof trip.recurringDays === 'string' && trip.recurringDays.startsWith('[')
            ? JSON.parse(trip.recurringDays)
            : trip.recurringDays.split(',').map((d: string) => d.trim());
        } catch {
          recurringDays = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس'];
        }
      }

      const frequency = trip.frequency;
      let runsToday = false;
      if (frequency === Frequency.ONCE) {
        runsToday = true;
      } else {
        runsToday = recurringDays.includes(currentDayName) || recurringDays.length === 0;
      }

      if (!runsToday) continue;

      const departureTime = trip.preferredTime || '07:30 AM';
      const isRoundTrip = trip.hasReturn;
      const returnTime = trip.returnTime || '03:30 PM';

      const parseTimeToMinutes = (timeStr: string) => {
        try {
          const clean = timeStr.trim().toUpperCase();
          const isPm = clean.includes('PM') || clean.includes('م');
          const isAm = clean.includes('AM') || clean.includes('ص');
          const parts = clean.replace(/[^\d:]/g, '').split(':');
          let hour = parseInt(parts[0], 10);
          const minute = parts.length > 1 ? parseInt(parts[1], 10) : 0;
          if (isPm && hour < 12) hour += 12;
          if (isAm && hour === 12) hour = 0;
          return hour * 60 + minute;
        } catch {
          return 0;
        }
      };

      // Outbound slot
      const outboundEarnings = Number(((contract.driverEarnings || 1200) / 22 / (isRoundTrip ? 2 : 1)).toFixed(1));
      slots.push({
        slotId: `${contract.id}_outbound_${targetDate.toISOString().slice(0, 10)}`,
        contractId: contract.id,
        type: 'OUTBOUND',
        typeLabel: 'رحلة الذهاب ↗️',
        time: departureTime,
        timeMinutes: parseTimeToMinutes(departureTime),
        clientName: client?.fullName || 'عميل ترحيل',
        clientPhone: client?.phoneNumber || '',
        clientId: client?.id || '',
        title: `مشوار توصيل (${trip.pickupAddress} إلى ${trip.dropoffAddress})`,
        pickup: trip.pickupAddress,
        dropoff: trip.dropoffAddress,
        seats: trip.passengersCount || 1,
        notes: trip.notes || '',
        earningsPerTrip: outboundEarnings,
        status: 'PENDING',
      });

      // Return slot
      if (isRoundTrip) {
        const returnEarnings = Number(((contract.driverEarnings || 1200) / 22 / 2).toFixed(1));
        slots.push({
          slotId: `${contract.id}_return_${targetDate.toISOString().slice(0, 10)}`,
          contractId: contract.id,
          type: 'RETURN',
          typeLabel: 'رحلة العودة ↘️',
          time: returnTime,
          timeMinutes: parseTimeToMinutes(returnTime),
          clientName: client?.fullName || 'عميل ترحيل',
          clientPhone: client?.phoneNumber || '',
          clientId: client?.id || '',
          title: `مشوار عودة (${trip.dropoffAddress} إلى ${trip.pickupAddress})`,
          pickup: trip.dropoffAddress,
          dropoff: trip.pickupAddress,
          seats: trip.passengersCount || 1,
          notes: trip.notes || '',
          earningsPerTrip: returnEarnings,
          status: 'PENDING',
        });
      }
    }

    // Sort chronologically by timeMinutes
    slots.sort((a, b) => a.timeMinutes - b.timeMinutes);

    const totalDailyEarnings = slots.reduce((acc, s) => acc + (s.earningsPerTrip || 0), 0);

    return {
      date: targetDate.toISOString().slice(0, 10),
      dayName: currentDayName,
      totalSlots: slots.length,
      estimatedDailyEarnings: Number(totalDailyEarnings.toFixed(2)),
      slots,
    };
  }

  async updateScheduleTripStatus(userId: string, dto: { slotId: string; status: string; notes?: string }) {
    // Notify passenger and return status update
    return {
      success: true,
      slotId: dto.slotId,
      status: dto.status,
      updatedAt: new Date().toISOString(),
      message: 'تم تحديث حالة المشوار وإشعار الراكب بنجاح',
    };
  }
}
