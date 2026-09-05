import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { VerificationStatus, NotificationType, EscrowStatus } from '@prisma/client';
import { RejectDriverDto, SuspendDriverDto } from './dto/admin-driver-actions.dto';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class AdminService {
  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
  ) {}

  async getPendingDrivers() {
    return this.prisma.driverProfile.findMany({
      where: { verificationStatus: VerificationStatus.PENDING },
      include: {
        user: { select: { id: true, fullName: true, phoneNumber: true, email: true } },
        vehicle: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getAllDrivers(status?: VerificationStatus) {
    return this.prisma.driverProfile.findMany({
      where: status ? { verificationStatus: status } : {},
      include: {
        user: { select: { id: true, fullName: true, phoneNumber: true } },
        vehicle: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async approveDriver(driverProfileId: string) {
    const driver = await this.prisma.driverProfile.findUnique({
      where: { id: driverProfileId },
      include: { user: true },
    });

    if (!driver) {
      throw new NotFoundException('السائق غير موجود');
    }

    const updated = await this.prisma.driverProfile.update({
      where: { id: driverProfileId },
      data: {
        verificationStatus: VerificationStatus.APPROVED,
        approvedAt: new Date(),
        rejectionReason: null,
      },
    });

    await this.notificationsService.createNotification(
      driver.userId,
      'تم اعتماد حسابك وبياناتك البنكية كسائق في ترحيل!',
      'تهانينا! تم التحقق من وثائقك وسيارتك وحسابك البنكي بنجاح، يمكنك الآن تصفح طلبات المشاوير وتقديم عروض الأسعار للركاب.',
      NotificationType.KYC_UPDATE,
    );

    return {
      message: 'تم اعتماد وتفعيل حساب السائق وحسابه البنكي بنجاح',
      driver: updated,
    };
  }

  async rejectDriver(driverProfileId: string, dto: RejectDriverDto) {
    const driver = await this.prisma.driverProfile.findUnique({
      where: { id: driverProfileId },
    });

    if (!driver) {
      throw new NotFoundException('السائق غير موجود');
    }

    const updated = await this.prisma.driverProfile.update({
      where: { id: driverProfileId },
      data: {
        verificationStatus: VerificationStatus.REJECTED,
        rejectionReason: dto.reason,
      },
    });

    await this.notificationsService.createNotification(
      driver.userId,
      'تم رفض طلب التسجيل كسائق',
      `نأسف لإبلاغك بأنه تعذر قبول طلبك للسبب التالي: ${dto.reason}. يمكنك مراجعة وثائقك أو شهادة الآيبان وإعادة التقديم.`,
      NotificationType.KYC_UPDATE,
    );

    return {
      message: 'تم تسجيل رفض الطلب وإشعار السائق بالسبب',
      driver: updated,
    };
  }

  async suspendDriver(driverProfileId: string, dto: SuspendDriverDto) {
    const driver = await this.prisma.driverProfile.findUnique({
      where: { id: driverProfileId },
      include: { user: true },
    });

    if (!driver) {
      throw new NotFoundException('السائق غير موجود');
    }

    await this.prisma.$transaction([
      this.prisma.driverProfile.update({
        where: { id: driverProfileId },
        data: { verificationStatus: VerificationStatus.SUSPENDED },
      }),
      this.prisma.user.update({
        where: { id: driver.userId },
        data: { isBlocked: true },
      }),
    ]);

    await this.notificationsService.createNotification(
      driver.userId,
      'تنبيه إداري: تم تعليق حسابك',
      `تم تعليق حسابك في ترحيل للسبب التالي: ${dto.reason}`,
      NotificationType.SYSTEM_WARNING,
    );

    return {
      message: 'تم تعليق حساب السائق وحظره من المنصة بنجاح',
    };
  }

  async getPlatformFinancialOverview() {
    const totalContracts = await this.prisma.tripContract.count();
    const completedContracts = await this.prisma.tripContract.findMany({
      where: { escrowStatus: EscrowStatus.RELEASED_TO_DRIVER_BANK },
    });

    const heldEscrowContracts = await this.prisma.tripContract.findMany({
      where: { escrowStatus: EscrowStatus.HELD_IN_ESCROW },
    });

    const totalVolume = completedContracts.reduce((acc, c) => acc + c.totalPaidByClient, 0);
    const totalBaseVolume = completedContracts.reduce((acc, c) => acc + c.baseAmount, 0);
    const totalVatCollected = completedContracts.reduce((acc, c) => acc + c.vatAmount, 0);
    const totalPlatformCommissionEarned = completedContracts.reduce(
      (acc, c) => acc + c.platformCommissionAmount,
      0,
    );
    const totalDriverBankPayouts = completedContracts.reduce(
      (acc, c) => acc + c.driverEarnings,
      0,
    );
    const totalEscrowCurrentlyHeld = heldEscrowContracts.reduce(
      (acc, c) => acc + c.totalPaidByClient,
      0,
    );

    const totalClients = await this.prisma.user.count({ where: { role: 'CLIENT' } });
    const totalDrivers = await this.prisma.driverProfile.count();
    const approvedDrivers = await this.prisma.driverProfile.count({
      where: { verificationStatus: VerificationStatus.APPROVED },
    });

    return {
      financials: {
        vatRate: '15%',
        platformCommissionRate: '13.50%',
        totalVolumePaidByClientsSAR: totalVolume,
        totalBaseTripVolumeSAR: totalBaseVolume,
        totalVat15PercentCollectedSAR: totalVatCollected,
        totalPlatformCommissionEarnedSAR: totalPlatformCommissionEarned,
        totalDriverEarningsTransferredToBankSAR: totalDriverBankPayouts,
        totalEscrowCurrentlyHeldSAR: totalEscrowCurrentlyHeld,
      },
      stats: {
        totalContracts,
        totalClients,
        totalDrivers,
        approvedDrivers,
        activeEscrowContractsCount: heldEscrowContracts.length,
      },
    };
  }
}
