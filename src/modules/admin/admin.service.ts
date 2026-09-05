import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { VerificationStatus, NotificationType, EscrowStatus, ContractStatus, Role } from '@prisma/client';
import {
  RejectDriverDto,
  SuspendDriverDto,
  UnsuspendDriverDto,
  ResolveDisputeDto,
  BroadcastNotificationDto,
} from './dto/admin-driver-actions.dto';
import { NotificationsService } from '../notifications/notifications.service';
import { OtpSenderService } from '../notifications/otp-sender.service';

@Injectable()
export class AdminService {
  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
    private otpSender: OtpSenderService,
  ) {}

  async getPendingDrivers() {
    return this.prisma.driverProfile.findMany({
      where: { verificationStatus: VerificationStatus.PENDING },
      include: {
        user: { select: { id: true, fullName: true, phoneNumber: true, email: true, createdAt: true } },
        vehicle: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getAllDrivers(status?: VerificationStatus) {
    return this.prisma.driverProfile.findMany({
      where: status ? { verificationStatus: status } : {},
      include: {
        user: { select: { id: true, fullName: true, phoneNumber: true, email: true, createdAt: true } },
        vehicle: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getDriverDetails(driverProfileId: string) {
    const driver = await this.prisma.driverProfile.findUnique({
      where: { id: driverProfileId },
      include: {
        user: true,
        vehicle: true,
        contracts: {
          take: 10,
          orderBy: { createdAt: 'desc' },
          include: { tripRequest: true },
        },
        reviewsReceived: {
          take: 10,
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    if (!driver) {
      throw new NotFoundException('السائق غير موجود');
    }

    return driver;
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

    if (driver.user.phoneNumber) {
      this.otpSender.sendWhatsAppMessage(
        driver.user.phoneNumber,
        `🚗 *منصة تـرحـيـل (Tarheel)*\n\nأهلاً بك كابتن ${driver.user.fullName}،\nتم اعتماد وتفعيل حسابك الرسمي بنجاح! يمكنك الآن الدخول للتطبيق وتقديم عروضك على مشاوير الركاب.\n\nنتمنى لك عملاً موفقاً وأرباحاً وفيرة!`,
      ).catch(() => {});
    }

    return {
      message: 'تم اعتماد وتفعيل حساب السائق وحسابه البنكي بنجاح',
      driver: updated,
    };
  }

  async rejectDriver(driverProfileId: string, dto: RejectDriverDto) {
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
        verificationStatus: VerificationStatus.REJECTED,
        rejectionReason: dto.reason,
      },
    });

    await this.notificationsService.createNotification(
      driver.userId,
      'ملاحظات على طلب الانضمام كسائق',
      `تمت مراجعة طلبك وتوجد ملاحظات تتطلب التعديل: ${dto.reason}. يرجى تحديث الوثائق المطلوبة لإعادة التفعيل.`,
      NotificationType.KYC_UPDATE,
    );

    if (driver.user.phoneNumber) {
      this.otpSender.sendWhatsAppMessage(
        driver.user.phoneNumber,
        `🚗 *منصة تـرحـيـل (Tarheel)*\n\nأهلاً بك كابتن ${driver.user.fullName}،\nتمت مراجعة وثائقك وتوجد ملاحظات:\n${dto.reason}\n\nيرجى فتح التطبيق وتعديل الوثائق المطلوبة لإعادة المراجعة.`,
      ).catch(() => {});
    }

    return {
      message: 'تم رفض طلب السائق وتوثيق السبب بنجاح',
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

    await this.prisma.driverProfile.update({
      where: { id: driverProfileId },
      data: {
        verificationStatus: VerificationStatus.SUSPENDED,
        rejectionReason: dto.reason,
      },
    });

    await this.prisma.user.update({
      where: { id: driver.userId },
      data: { isBlocked: true },
    });

    await this.notificationsService.createNotification(
      driver.userId,
      'تنبيه إداري: تم تعليق حسابك',
      `تم تعليق حسابك في ترحيل للسبب التالي: ${dto.reason}`,
      NotificationType.SYSTEM_WARNING,
    );

    if (driver.user.phoneNumber) {
      this.otpSender.sendWhatsAppMessage(
        driver.user.phoneNumber,
        `⚠️ *تنبيه من إدارة منصة تـرحـيـل*\n\nكابتن ${driver.user.fullName}،\nتم تعليق حسابك مؤقتاً لمخالفة سياسات المنصة:\n${dto.reason}\n\nيرجى مراجعة خدمة العملاء عبر التطبيق.`,
      ).catch(() => {});
    }

    return {
      message: 'تم تعليق حساب السائق وحظره من المنصة بنجاح',
    };
  }

  async unsuspendDriver(driverProfileId: string, dto?: UnsuspendDriverDto) {
    const driver = await this.prisma.driverProfile.findUnique({
      where: { id: driverProfileId },
      include: { user: true },
    });

    if (!driver) {
      throw new NotFoundException('السائق غير موجود');
    }

    await this.prisma.driverProfile.update({
      where: { id: driverProfileId },
      data: {
        verificationStatus: VerificationStatus.APPROVED,
        rejectionReason: null,
      },
    });

    await this.prisma.user.update({
      where: { id: driver.userId },
      data: { isBlocked: false },
    });

    await this.notificationsService.createNotification(
      driver.userId,
      'تم فك تعليق حسابك في ترحيل!',
      'يسرنا إبلاغك بأنه قد تم فك تعليق حسابك وإعادة تفعيله، يمكنك الآن استقبال الرحلات وممارسة عملك كالمعتاد.',
      NotificationType.KYC_UPDATE,
    );

    return {
      message: 'تم فك تعليق الحساب وإعادة تفعيل السائق بنجاح',
    };
  }

  // ==================== DISPUTES & ESCROW ====================

  async getDisputes() {
    return this.prisma.tripContract.findMany({
      where: {
        OR: [
          { escrowStatus: EscrowStatus.DISPUTED },
          { escrowStatus: EscrowStatus.HELD_IN_ESCROW },
          { escrowStatus: EscrowStatus.PENDING_PAYMENT },
        ],
      },
      include: {
        tripRequest: true,
        client: { select: { id: true, fullName: true, phoneNumber: true, email: true } },
        driverProfile: {
          include: {
            user: { select: { id: true, fullName: true, phoneNumber: true, email: true } },
            vehicle: true,
          },
        },
      },
      orderBy: { updatedAt: 'desc' },
    });
  }

  async resolveDispute(contractId: string, dto: ResolveDisputeDto) {
    const contract = await this.prisma.tripContract.findUnique({
      where: { id: contractId },
      include: {
        client: true,
        driverProfile: { include: { user: true } },
        tripRequest: true,
      },
    });

    if (!contract) {
      throw new NotFoundException('العقد غير موجود');
    }

    if (dto.action === 'RELEASE_TO_DRIVER') {
      await this.prisma.$transaction([
        this.prisma.tripContract.update({
          where: { id: contractId },
          data: {
            escrowStatus: EscrowStatus.RELEASED_TO_DRIVER_BANK,
            contractStatus: ContractStatus.COMPLETED,
            completedAt: new Date(),
          },
        }),
        this.prisma.driverProfile.update({
          where: { id: contract.driverProfileId },
          data: {
            walletBalance: { increment: contract.driverEarnings },
            pendingEscrowBalance: { decrement: contract.driverEarnings },
          },
        }),
      ]);

      await this.notificationsService.createNotification(
        contract.driverProfile.userId,
        'تم فض النزاع وتحويل مستحقاتك المالية!',
        `أصدرت إدارة ترحيل قرارها بفض النزاع لمشوار (${contract.tripRequest.pickupAddress}) لصالحك. تم تحويل مبلغ (${contract.driverEarnings} ر.س) لرصيدك. قرار الإدارة: ${dto.resolutionNote}`,
        NotificationType.PAYMENT_CONFIRMED,
      );

      await this.notificationsService.createNotification(
        contract.clientId,
        'إشعار بقرار إدارة ترحيل في النزاع',
        `تمت مراجعة النزاع لمشوارك من قبل الإدارة وتقرر تسوية المستحقات للسائق بناءً على المعطيات: ${dto.resolutionNote}`,
        NotificationType.SYSTEM_WARNING,
      );

      return {
        message: 'تم فض النزاع لصالح السائق وتحويل المستحقات المالية بنجاح',
        action: dto.action,
      };
    } else {
      await this.prisma.$transaction([
        this.prisma.tripContract.update({
          where: { id: contractId },
          data: {
            escrowStatus: EscrowStatus.REFUNDED_TO_CLIENT,
            contractStatus: ContractStatus.CANCELLED,
          },
        }),
        this.prisma.driverProfile.update({
          where: { id: contract.driverProfileId },
          data: {
            pendingEscrowBalance: { decrement: contract.driverEarnings },
          },
        }),
      ]);

      await this.notificationsService.createNotification(
        contract.clientId,
        'تم استرجاع مبلغ المشوار بالكامل لحسابك!',
        `أصدرت إدارة ترحيل قرارها بفض النزاع لمشوارك لصالحك، وتم استرجاع مبلغ الضمان (${contract.totalPaidByClient} ر.س) لحسابك. حيثيات القرار: ${dto.resolutionNote}`,
        NotificationType.PAYMENT_CONFIRMED,
      );

      await this.notificationsService.createNotification(
        contract.driverProfile.userId,
        'إشعار بقرار فض النزاع وإلغاء العقد',
        `تم فض النزاع لصالح العميل وإلغاء مستحقات العقد المعلقة بناءً على تحقيق الإدارة: ${dto.resolutionNote}`,
        NotificationType.SYSTEM_WARNING,
      );

      return {
        message: 'تم فض النزاع لصالح العميل واسترداد مبلغ الضمان المالي بنجاح',
        action: dto.action,
      };
    }
  }

  // ==================== CHAT MONITORING ====================

  async getAllChats() {
    const contractsWithMessages = await this.prisma.tripContract.findMany({
      where: {
        chatMessages: { some: {} },
      },
      include: {
        client: { select: { id: true, fullName: true, phoneNumber: true } },
        driverProfile: {
          include: {
            user: { select: { id: true, fullName: true, phoneNumber: true } },
            vehicle: true,
          },
        },
        tripRequest: { select: { id: true, pickupAddress: true, dropoffAddress: true } },
        chatMessages: {
          take: 1,
          orderBy: { createdAt: 'desc' },
        },
      },
      orderBy: { updatedAt: 'desc' },
    });

    return contractsWithMessages;
  }

  async getChatMessages(contractId: string) {
    return this.prisma.chatMessage.findMany({
      where: { contractId },
      include: {
        sender: { select: { id: true, fullName: true, role: true } },
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  // ==================== BROADCAST NOTIFICATIONS ====================

  async broadcastNotification(dto: BroadcastNotificationDto) {
    let users: { id: string; fullName: string; phoneNumber: string | null; email: string | null }[] = [];

    if (dto.recipientType === 'USER') {
      if (!dto.userId) {
        throw new BadRequestException('معرف المستخدم مطلوب عند اختيار إرسال لمستخدم محدد');
      }
      const user = await this.prisma.user.findUnique({
        where: { id: dto.userId },
        select: { id: true, fullName: true, phoneNumber: true, email: true },
      });
      if (user) users = [user];
    } else if (dto.recipientType === 'CLIENTS') {
      users = await this.prisma.user.findMany({
        where: { role: Role.CLIENT, isBlocked: false },
        select: { id: true, fullName: true, phoneNumber: true, email: true },
      });
    } else if (dto.recipientType === 'DRIVERS') {
      users = await this.prisma.user.findMany({
        where: { role: Role.DRIVER, isBlocked: false },
        select: { id: true, fullName: true, phoneNumber: true, email: true },
      });
    } else {
      users = await this.prisma.user.findMany({
        where: { isBlocked: false },
        select: { id: true, fullName: true, phoneNumber: true, email: true },
      });
    }

    for (const u of users) {
      this.notificationsService.createNotification(
        u.id,
        dto.title,
        dto.message,
        NotificationType.SYSTEM_WARNING,
      ).catch(() => {});

      if (dto.sendWhatsApp && u.phoneNumber) {
        const waText = `🚗 *منصة تـرحـيـل (Tarheel)*\n\nأهلاً بك أستاذ/ة ${u.fullName}،\n*${dto.title}*\n\n${dto.message}`;
        this.otpSender.sendWhatsAppMessage(u.phoneNumber, waText).catch(() => {});
      }

      if (dto.sendEmail && u.email) {
        const emailHtml = `
          <div dir="rtl" style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f1f5f9; padding: 25px; text-align: right; color: #0f172a;">
            <div style="max-width: 540px; margin: 0 auto; background-color: #ffffff; border-radius: 14px; padding: 24px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);">
              <div style="text-align: center; margin-bottom: 20px;">
                <h2 style="color: #153364; margin: 0;">🚗 منصة تـرحـيـل</h2>
                <p style="color: #64748b; font-size: 13px; margin-top: 4px;">إشعار إداري رسمي</p>
              </div>
              <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 16px 0;" />
              <h3 style="color: #0f172a; margin-top: 0;">${dto.title}</h3>
              <p style="font-size: 14px; color: #334155; line-height: 1.7; white-space: pre-line;">${dto.message}</p>
              <div style="background-color: #f8fafc; padding: 12px; text-align: center; font-size: 11px; color: #94a3b8; border-top: 1px solid #e2e8f0; margin-top: 24px;">
                منصة ترحيل © 2026 - خدمة المشاوير المجدولة الآمنة
              </div>
            </div>
          </div>
        `;
        this.otpSender.sendEmailNotification(u.email, dto.title, emailHtml).catch(() => {});
      }
    }

    return {
      message: `تم إرسال التنبيه بنجاح إلى (${users.length}) مستخدم`,
      recipientCount: users.length,
      recipientType: dto.recipientType,
    };
  }

  // ==================== FINANCIAL OVERVIEW ====================

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
    const pendingDrivers = await this.prisma.driverProfile.count({
      where: { verificationStatus: VerificationStatus.PENDING },
    });
    const disputedContractsCount = await this.prisma.tripContract.count({
      where: { escrowStatus: EscrowStatus.DISPUTED },
    });
    const openTicketsCount = await this.prisma.supportTicket.count({
      where: { status: 'OPEN' },
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
        pendingDrivers,
        disputedContractsCount,
        openTicketsCount,
        activeEscrowContractsCount: heldEscrowContracts.length,
      },
    };
  }

  // ==================== FINANCIAL PERFORMANCE & USER AUDIT ====================

  async getUsersFinancialPerformance(role?: Role, search?: string) {
    const where: any = {};
    if (role) {
      where.role = role;
    } else {
      where.role = { in: [Role.CLIENT, Role.DRIVER] };
    }

    if (search) {
      where.OR = [
        { fullName: { contains: search, mode: 'insensitive' } },
        { phoneNumber: { contains: search } },
        { email: { contains: search, mode: 'insensitive' } },
      ];
    }

    const users = await this.prisma.user.findMany({
      where,
      include: {
        driverProfile: {
          include: {
            vehicle: true,
          },
        },
        contractsAsClient: {
          select: {
            id: true,
            totalPaidByClient: true,
            platformCommissionAmount: true,
            escrowStatus: true,
            contractStatus: true,
            createdAt: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });

    return users.map((u) => {
      if (u.role === Role.DRIVER && u.driverProfile) {
        return {
          userId: u.id,
          driverProfileId: u.driverProfile.id,
          fullName: u.fullName,
          phoneNumber: u.phoneNumber,
          email: u.email,
          role: u.role,
          isBlocked: u.isBlocked,
          verificationStatus: u.driverProfile.verificationStatus,
          ratingAverage: u.driverProfile.ratingAverage,
          totalTripsCount: u.driverProfile.totalTripsCount,
          walletBalance: u.driverProfile.walletBalance,
          pendingEscrowBalance: u.driverProfile.pendingEscrowBalance,
          vehicle: u.driverProfile.vehicle,
          createdAt: u.createdAt,
        };
      } else {
        const totalSpent = u.contractsAsClient.reduce((acc, c) => acc + c.totalPaidByClient, 0);
        const completedTrips = u.contractsAsClient.filter(
          (c) => c.contractStatus === ContractStatus.COMPLETED,
        ).length;
        const activeEscrows = u.contractsAsClient
          .filter((c) => c.escrowStatus === EscrowStatus.HELD_IN_ESCROW)
          .reduce((acc, c) => acc + c.totalPaidByClient, 0);

        return {
          userId: u.id,
          fullName: u.fullName,
          phoneNumber: u.phoneNumber,
          email: u.email,
          role: u.role,
          isBlocked: u.isBlocked,
          totalSpentSAR: totalSpent,
          completedTripsCount: completedTrips,
          activeEscrowHeldSAR: activeEscrows,
          totalContractsCount: u.contractsAsClient.length,
          createdAt: u.createdAt,
        };
      }
    });
  }

  async getUserActivityHistory(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        driverProfile: {
          include: {
            vehicle: true,
            contracts: {
              include: {
                tripRequest: true,
                client: { select: { id: true, fullName: true, phoneNumber: true } },
                escrowPayment: true,
                review: true,
              },
              orderBy: { createdAt: 'desc' },
            },
            reviewsReceived: {
              include: {
                reviewer: { select: { id: true, fullName: true } },
              },
              orderBy: { createdAt: 'desc' },
            },
          },
        },
        contractsAsClient: {
          include: {
            tripRequest: true,
            driverProfile: {
              include: {
                user: { select: { id: true, fullName: true, phoneNumber: true } },
                vehicle: true,
              },
            },
            escrowPayment: true,
            review: true,
          },
          orderBy: { createdAt: 'desc' },
        },
        tripRequests: {
          include: {
            offers: {
              include: {
                driverProfile: {
                  include: {
                    user: { select: { id: true, fullName: true } },
                    vehicle: true,
                  },
                },
              },
            },
          },
          orderBy: { createdAt: 'desc' },
          take: 20,
        },
        walletTransactions: {
          orderBy: { createdAt: 'desc' },
          take: 30,
        },
        supportTickets: {
          include: { replies: true },
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('المستخدم غير موجود');
    }

    return user;
  }
}
