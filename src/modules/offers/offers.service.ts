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

    if (!driverProfile.vehicle) {
      throw new ForbiddenException(
        'يرجى استكمال بيانات مركبتك ووثائقك الرسمية أولاً لتتمكن من تقديم العروض على هذا المشوار.',
      );
    }

    if (driverProfile.verificationStatus !== VerificationStatus.APPROVED) {
      throw new ForbiddenException(
        'حساب السائق الخاص بك قيد المراجعة أو غير معتمد حالياً. لا يمكنك تقديم عروض حتى يتم الاعتماد من الإدارة.',
      );
    }

    const trip = await this.prisma.tripRequest.findUnique({
      where: { id: dto.tripRequestId },
      include: { client: true },
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

    // Prepare enriched bid metadata with vehicle interior photo & specs
    // Note: Only vehicle interior photo is visible to client for privacy & comfort inspection.
    // Exterior angle photos are strictly reserved for platform admin inspection.
    const carPhotoInteriorUrl = driverProfile.vehicle?.photoInteriorUrl || null;
    const carBrand = driverProfile.vehicle?.brand || 'سيارة';
    const carModel = driverProfile.vehicle?.model || '';
    const carYear = driverProfile.vehicle?.year || '';
    const carFullName = `${carBrand} ${carModel} ${carYear}`.trim();

    const notificationPayload = {
      tripId: trip.id,
      offerId: offer.id,
      offerPrice: dto.offerPrice,
      driverName: driverProfile.user.fullName,
      driverRating: driverProfile.ratingAverage,
      totalTrips: driverProfile.totalTripsCount,
      carFullName,
      carBrand,
      carModel,
      carYear,
      carPlateNumber: driverProfile.vehicle?.plateNumber || '',
      carPhotoInteriorUrl,
      carPhotoFrontUrl: null, // لم يعد مسموحاً بمشاركة صور الجوانب الخارجية مع العميل
      isAirConditioned: driverProfile.vehicle?.isAirConditioned ?? true,
      carCapacity: driverProfile.vehicle?.capacity || 4,
      pickupAddress: trip.pickupAddress,
      dropoffAddress: trip.dropoffAddress,
    };

    // Notify client via Multi-Channel (In-App DB + WebSocket + WhatsApp + Email)
    await this.notificationsService.notifyClientNewBidMultiChannel({
      client: {
        id: trip.clientId,
        fullName: trip.client.fullName,
        phoneNumber: trip.client.phoneNumber,
        email: trip.client.email,
      },
      trip: {
        id: trip.id,
        pickupAddress: trip.pickupAddress,
        dropoffAddress: trip.dropoffAddress,
      },
      driver: {
        fullName: driverProfile.user.fullName,
        ratingAverage: driverProfile.ratingAverage,
        totalTrips: driverProfile.totalTripsCount,
      },
      vehicle: {
        fullName: carFullName,
        brand: carBrand,
        model: carModel,
        year: carYear,
        plateNumber: driverProfile.vehicle?.plateNumber || '',
        photoInteriorUrl: carPhotoInteriorUrl,
        isAirConditioned: driverProfile.vehicle?.isAirConditioned ?? true,
        capacity: driverProfile.vehicle?.capacity || 4,
      },
      offerPrice: dto.offerPrice,
      offerId: offer.id,
    });

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
