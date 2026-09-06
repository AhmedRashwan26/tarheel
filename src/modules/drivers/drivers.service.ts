import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AuthService } from '../auth/auth.service';
import { RegisterDriverDto } from './dto/register-driver.dto';
import { Role, VerificationStatus } from '@prisma/client';
import { PLATFORM_CONSTANTS } from '../../common/constants';

@Injectable()
export class DriversService {
  constructor(
    private prisma: PrismaService,
    private authService: AuthService,
  ) {}

  async registerDriver(dto: RegisterDriverDto) {
    const existingPhone = await this.prisma.user.findUnique({
      where: { phoneNumber: dto.phoneNumber },
    });

    if (existingPhone) {
      throw new BadRequestException('رقم الهاتف مسجل مسبقاً');
    }

    const existingId = await this.prisma.driverProfile.findUnique({
      where: { nationalId: dto.nationalId },
    });

    if (existingId) {
      throw new BadRequestException('رقم الهوية الوطنية مسجل مسبقاً لدى سائق آخر');
    }

    const existingPlate = await this.prisma.vehicle.findUnique({
      where: { plateNumber: dto.plateNumber },
    });

    if (existingPlate) {
      throw new BadRequestException('رقم لوحة السيارة مسجل مسبقاً');
    }

    // Execute in transaction
    const result = await this.prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          phoneNumber: dto.phoneNumber,
          fullName: dto.fullName,
          role: Role.DRIVER,
          avatarUrl: dto.profilePictureUrl || dto.avatarUrl || null,
        },
      });

      const driverProfile = await tx.driverProfile.create({
        data: {
          userId: user.id,
          nationalId: dto.nationalId,
          idCardPhotoUrl: dto.idCardPhotoUrl,
          driverLicenseUrl: dto.driverLicenseUrl,
          vehicleRegistrationUrl: dto.vehicleRegistrationUrl,
          bankName: dto.bankName,
          iban: dto.iban,
          bankAccountHolderName: dto.bankAccountHolderName,
          bankCertificatePdfUrl: dto.bankCertificatePdfUrl,
          verificationStatus: VerificationStatus.PENDING,
          agreedToAntiCashPolicyAt: new Date(),
        },
      });

      const vehicle = await tx.vehicle.create({
        data: {
          driverProfileId: driverProfile.id,
          brand: dto.vehicleBrand,
          model: dto.vehicleModel,
          year: dto.vehicleYear,
          plateNumber: dto.plateNumber,
          capacity: dto.capacity,
          isAirConditioned: dto.isAirConditioned,
          photoFrontUrl: dto.photoFrontUrl,
          photoBackUrl: dto.photoBackUrl,
          photoRightUrl: dto.photoRightUrl,
          photoLeftUrl: dto.photoLeftUrl,
          photoInteriorUrl: dto.photoInteriorUrl,
        },
      });

      return { user, driverProfile, vehicle };
    });

    const tokens = await this.authService.generateTokens(result.user);

    return {
      message: 'تم تسجيل بيانات السائق والحساب البنكي بنجاح! طلبك قيد المراجعة والاعتماد من قبل إدارة ترحيل.',
      policyNotice: PLATFORM_CONSTANTS.DRIVER_TERMS_WARNING_AR,
      commissionPercentage: PLATFORM_CONSTANTS.COMMISSION_PERCENTAGE,
      vatPercentage: PLATFORM_CONSTANTS.VAT_PERCENTAGE,
      driverProfile: {
        ...result.driverProfile,
        vehicle: result.vehicle,
      },
      ...tokens,
    };
  }

  async completeDriverProfile(userId: string, dto: RegisterDriverDto) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('المستخدم غير موجود');
    }

    if (!user.phoneNumber) {
      throw new BadRequestException('يجب ربط وتأكيد رقم الجوال أولاً قبل استكمال التسجيل');
    }

    const existingId = await this.prisma.driverProfile.findFirst({
      where: { nationalId: dto.nationalId, NOT: { userId } },
    });
    if (existingId) {
      throw new BadRequestException('رقم الهوية الوطنية مسجل مسبقاً لدى سائق آخر');
    }

    const existingPlate = await this.prisma.vehicle.findFirst({
      where: { plateNumber: dto.plateNumber, NOT: { driverProfile: { userId } } },
    });
    if (existingPlate) {
      throw new BadRequestException('رقم لوحة السيارة مسجل مسبقاً');
    }

    const result = await this.prisma.$transaction(async (tx) => {
      await tx.user.update({
        where: { id: userId },
        data: {
          fullName: dto.fullName || user.fullName,
          avatarUrl: dto.profilePictureUrl || dto.avatarUrl || user.avatarUrl,
          role: Role.DRIVER,
          termsAccepted: true,
          termsAcceptedAt: new Date(),
        },
      });

      const driverProfile = await tx.driverProfile.upsert({
        where: { userId },
        update: {
          nationalId: dto.nationalId,
          idCardPhotoUrl: dto.idCardPhotoUrl,
          driverLicenseUrl: dto.driverLicenseUrl,
          vehicleRegistrationUrl: dto.vehicleRegistrationUrl,
          bankName: dto.bankName,
          iban: dto.iban,
          bankAccountHolderName: dto.bankAccountHolderName,
          bankCertificatePdfUrl: dto.bankCertificatePdfUrl,
          verificationStatus: VerificationStatus.PENDING,
          agreedToAntiCashPolicyAt: new Date(),
        },
        create: {
          userId,
          nationalId: dto.nationalId,
          idCardPhotoUrl: dto.idCardPhotoUrl,
          driverLicenseUrl: dto.driverLicenseUrl,
          vehicleRegistrationUrl: dto.vehicleRegistrationUrl,
          bankName: dto.bankName,
          iban: dto.iban,
          bankAccountHolderName: dto.bankAccountHolderName,
          bankCertificatePdfUrl: dto.bankCertificatePdfUrl,
          verificationStatus: VerificationStatus.PENDING,
          agreedToAntiCashPolicyAt: new Date(),
        },
      });

      const vehicle = await tx.vehicle.upsert({
        where: { driverProfileId: driverProfile.id },
        update: {
          brand: dto.vehicleBrand,
          model: dto.vehicleModel,
          year: dto.vehicleYear,
          plateNumber: dto.plateNumber,
          capacity: dto.capacity,
          isAirConditioned: dto.isAirConditioned,
          photoFrontUrl: dto.photoFrontUrl,
          photoBackUrl: dto.photoBackUrl,
          photoRightUrl: dto.photoRightUrl,
          photoLeftUrl: dto.photoLeftUrl,
          photoInteriorUrl: dto.photoInteriorUrl,
        },
        create: {
          driverProfileId: driverProfile.id,
          brand: dto.vehicleBrand,
          model: dto.vehicleModel,
          year: dto.vehicleYear,
          plateNumber: dto.plateNumber,
          capacity: dto.capacity,
          isAirConditioned: dto.isAirConditioned,
          photoFrontUrl: dto.photoFrontUrl,
          photoBackUrl: dto.photoBackUrl,
          photoRightUrl: dto.photoRightUrl,
          photoLeftUrl: dto.photoLeftUrl,
          photoInteriorUrl: dto.photoInteriorUrl,
        },
      });

      return { driverProfile, vehicle };
    });

    return {
      message: 'تم استكمال بيانات السائق والمركبة والوثائق بنجاح والموافقة على الشروط والأحكام! طلبك قيد المراجعة من الإدارة.',
      policyNotice: PLATFORM_CONSTANTS.DRIVER_TERMS_WARNING_AR,
      driverProfile: {
        ...result.driverProfile,
        vehicle: result.vehicle,
      },
    };
  }

  async getMyProfile(userId: string) {
    const profile = await this.prisma.driverProfile.findUnique({
      where: { userId },
      include: {
        user: { select: { id: true, fullName: true, phoneNumber: true, role: true } },
        vehicle: true,
        contracts: {
          take: 10,
          orderBy: { createdAt: 'desc' },
          include: { tripRequest: true },
        },
      },
    });

    if (!profile) {
      throw new NotFoundException('لم يتم العثور على ملف السائق');
    }

    return profile;
  }

  async getDriverById(id: string) {
    const profile = await this.prisma.driverProfile.findUnique({
      where: { id },
      include: {
        user: { select: { fullName: true, phoneNumber: true } },
        vehicle: true,
        reviewsReceived: {
          take: 5,
          orderBy: { createdAt: 'desc' },
          include: { reviewer: { select: { fullName: true } } },
        },
      },
    });

    if (!profile) {
      throw new NotFoundException('السائق غير موجود');
    }

    // Hide confidential IBAN / Bank certificate from public view
    const { iban, bankCertificatePdfUrl, ...safeProfile } = profile;

    return safeProfile;
  }
}
