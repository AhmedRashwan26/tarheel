import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async getMyProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        driverProfile: { include: { vehicle: true } },
      },
    });

    if (!user) {
      throw new NotFoundException('المستخدم غير موجود');
    }

    return user;
  }

  async getMyWalletTransactions(userId: string) {
    return this.prisma.walletTransaction.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }

  async getMyNotifications(userId: string) {
    return this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }

  async updateProfile(userId: string, data: { avatarUrl?: string; fullName?: string }) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('المستخدم غير موجود');
    }

    return this.prisma.user.update({
      where: { id: userId },
      data: {
        ...(data.avatarUrl !== undefined && { avatarUrl: data.avatarUrl }),
        ...(data.fullName !== undefined && { fullName: data.fullName }),
      },
      include: {
        driverProfile: { include: { vehicle: true } },
      },
    });
  }
}
