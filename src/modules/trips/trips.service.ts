import { Injectable, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateTripRequestDto } from './dto/create-trip-request.dto';
import { TripStatus } from '@prisma/client';
import { NotificationsGateway } from '../notifications/notifications.gateway';

@Injectable()
export class TripsService {
  constructor(
    private prisma: PrismaService,
    private notificationsGateway: NotificationsGateway,
  ) {}

  async createTripRequest(clientId: string, dto: CreateTripRequestDto) {
    const client = await this.prisma.user.findUnique({ where: { id: clientId } });
    if (!client || !client.phoneNumber) {
      throw new BadRequestException('يجب ربط وتأكيد رقم الجوال أولاً لتتمكن من نشر طلب مشوار في ترحيل');
    }

    if (dto.hasReturn && !dto.returnTime) {
      throw new BadRequestException('يجب تحديد وقت العودة بدقة');
    }

    const trip = await this.prisma.tripRequest.create({
      data: {
        clientId,
        pickupAddress: dto.pickupAddress,
        pickupLatitude: dto.pickupLatitude,
        pickupLongitude: dto.pickupLongitude,
        dropoffAddress: dto.dropoffAddress,
        dropoffLatitude: dto.dropoffLatitude,
        dropoffLongitude: dto.dropoffLongitude,
        startDate: new Date(dto.startDate),
        preferredTime: dto.preferredTime,
        hasReturn: dto.hasReturn,
        returnTime: dto.hasReturn ? dto.returnTime : null,
        frequency: dto.frequency,
        recurringDays: dto.recurringDays,
        passengersCount: dto.passengersCount,
        notes: dto.notes,
        status: TripStatus.OPEN_FOR_BIDS,
      },
      include: {
        client: {
          select: { id: true, fullName: true, phoneNumber: true, avatarUrl: true },
        },
      },
    });

    // Broadcast new open trip request to all online drivers
    this.notificationsGateway.broadcastNewTripRequest(trip);

    return {
      message: 'تم نشر طلب المشوار بنجاح! يمكن للسائقين الآن رؤية طلبك وتقديم عروض الأسعار.',
      trip,
    };
  }

  async getOpenTripsForDrivers(query?: { capacity?: number; city?: string; search?: string; region?: string }) {
    const where: any = {
      status: TripStatus.OPEN_FOR_BIDS,
    };

    if (query?.capacity) {
      where.passengersCount = { lte: Number(query.capacity) };
    }

    const search = (query?.search || query?.region || query?.city)?.trim();
    if (search) {
      where.OR = [
        { pickupAddress: { contains: search, mode: 'insensitive' } },
        { dropoffAddress: { contains: search, mode: 'insensitive' } },
        { title: { contains: search, mode: 'insensitive' } },
        { notes: { contains: search, mode: 'insensitive' } },
      ];
    }

    return this.prisma.tripRequest.findMany({
      where,
      include: {
        client: {
          select: { id: true, fullName: true, avatarUrl: true },
        },
        _count: {
          select: { offers: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getTripById(id: string) {
    const trip = await this.prisma.tripRequest.findUnique({
      where: { id },
      include: {
        client: { select: { id: true, fullName: true, phoneNumber: true, avatarUrl: true } },
        offers: {
          include: {
            driverProfile: {
              include: {
                user: { select: { fullName: true, phoneNumber: true } },
                vehicle: true,
              },
            },
          },
          orderBy: { createdAt: 'desc' },
        },
        contract: {
          include: {
            escrowPayment: true,
            driverProfile: { include: { user: true, vehicle: true } },
          },
        },
      },
    });

    if (!trip) {
      throw new NotFoundException('طلب المشوار غير موجود');
    }

    return trip;
  }

  async getMyTripRequests(clientId: string) {
    return this.prisma.tripRequest.findMany({
      where: { clientId },
      include: {
        _count: { select: { offers: true } },
        contract: {
          select: {
            id: true,
            contractStatus: true,
            baseAmount: true,
            vatAmount: true,
            totalPaidByClient: true,
            driverProfile: {
              select: {
                user: { select: { fullName: true, phoneNumber: true } },
                vehicle: true,
                ratingAverage: true,
              },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async cancelTripRequest(clientId: string, tripId: string) {
    const trip = await this.prisma.tripRequest.findUnique({
      where: { id: tripId },
    });

    if (!trip) {
      throw new NotFoundException('طلب المشوار غير موجود');
    }

    if (trip.clientId !== clientId) {
      throw new ForbiddenException('لا يمكنك إلغاء طلب مشوار لا يخصك');
    }

    if (trip.status !== TripStatus.OPEN_FOR_BIDS) {
      throw new BadRequestException('لا يمكن إلغاء المشوار بعد قبول عرض أو بدء التعاقد');
    }

    return this.prisma.tripRequest.update({
      where: { id: tripId },
      data: { status: TripStatus.CANCELLED },
    });
  }
}
