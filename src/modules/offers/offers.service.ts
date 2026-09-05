import { Injectable, BadRequestException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateOfferDto } from './dto/create-offer.dto';
import { OfferStatus, TripStatus, VerificationStatus, NotificationType } from '@prisma/client';
import { NotificationsGateway } from '../notifications/notifications.gateway';
import { NotificationsService } from '../notifications/notifications.service';
import { PLATFORM_CONSTANTS } from '../../common/constants';

@Injectable()
export class OffersService {
  constructor(
    private prisma: PrismaService,
    private gateway: NotificationsGateway,
    private notificationsService: NotificationsService,
  ) {}

  async createOffer(driverUserId: string, dto: CreateOfferDto) {
    const driverProfile = await this.prisma.driverProfile.findUnique({
      where: { userId: driverUserId },
      include: { vehicle: true, user: true },
    });

    if (!driverProfile) {
      throw new ForbiddenException('لم يتم العثور على ملف السائق');
    }

    if (driverProfile.verificationStatus !== VerificationStatus.APPROVED) {
      throw new ForbiddenException(
        'حساب السائق الخاص بك قيد المراجعة أو غير معتمد حالياً. لا يمكنك تقديم عروض حتى يتم الاعتماد من الإدارة.',
      );
    }

    const trip = await this.prisma.tripRequest.findUnique({
      where: { id: dto.tripRequestId },
    });

    if (!trip) {
      throw new NotFoundException('طلب المشوار غير موجود');
    }

    if (trip.status !== TripStatus.OPEN_FOR_BIDS) {
      throw new BadRequestException('طلب المشوار لم يعد متاحاً لاستقبال عروض أسعار');
    }

    if (driverProfile.vehicle && driverProfile.vehicle.capacity < trip.passengersCount) {
      throw new BadRequestException(
        `سعة سيارتك (${driverProfile.vehicle.capacity} ركاب) أقل من عدد الركاب المطلوب في المشوار (${trip.passengersCount} ركاب)`,
      );
    }

    // Check duplicate pending offer
    const existingOffer = await this.prisma.tripOffer.findFirst({
      where: {
        tripRequestId: dto.tripRequestId,
        driverProfileId: driverProfile.id,
        status: OfferStatus.PENDING,
      },
    });

    if (existingOffer) {
      throw new BadRequestException('لقد قمت بتقديم عرض سعر مسبقاً لهذا المشوار وما زال قيد الانتظار');
    }

    const offer = await this.prisma.tripOffer.create({
      data: {
        tripRequestId: dto.tripRequestId,
        driverProfileId: driverProfile.id,
        offerPrice: dto.offerPrice,
        driverNotes: dto.driverNotes,
        status: OfferStatus.PENDING,
      },
      include: {
        driverProfile: {
          include: {
            user: { select: { fullName: true, phoneNumber: true } },
            vehicle: true,
          },
        },
      },
    });

    // Notify client via websocket & database record
    this.gateway.notifyClientNewBid(trip.clientId, offer);
    await this.notificationsService.createNotification(
      trip.clientId,
      'عرض سعر جديد لمشوارك',
      `قدم السائق ${driverProfile.user.fullName} عرضاً بقيمة ${dto.offerPrice} ر.س لمشوارك`,
      NotificationType.BID_RECEIVED,
      { tripId: trip.id, offerId: offer.id, price: dto.offerPrice },
    );

    const platformFee = (dto.offerPrice * PLATFORM_CONSTANTS.COMMISSION_PERCENTAGE) / 100;
    const netEarnings = dto.offerPrice - platformFee;

    return {
      message: 'تم إرسال عرض السعر إلى العميل بنجاح!',
      offer,
      financialBreakdown: {
        offerPrice: dto.offerPrice,
        platformCommissionRate: '13.50%',
        platformCommission: platformFee,
        driverEstimatedNetEarnings: netEarnings,
        antiCashNotice: PLATFORM_CONSTANTS.DRIVER_TERMS_WARNING_AR,
      },
    };
  }

  async getOffersForTrip(tripId: string) {
    return this.prisma.tripOffer.findMany({
      where: { tripRequestId: tripId },
      include: {
        driverProfile: {
          include: {
            user: { select: { fullName: true, phoneNumber: true } },
            vehicle: true,
          },
        },
      },
      orderBy: { offerPrice: 'asc' },
    });
  }

  async getMyDriverOffers(driverUserId: string) {
    const driverProfile = await this.prisma.driverProfile.findUnique({
      where: { userId: driverUserId },
    });

    if (!driverProfile) {
      throw new NotFoundException('ملف السائق غير موجود');
    }

    return this.prisma.tripOffer.findMany({
      where: { driverProfileId: driverProfile.id },
      include: {
        tripRequest: {
          include: { client: { select: { fullName: true } } },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }
}
