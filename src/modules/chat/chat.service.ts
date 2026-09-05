import { Injectable, BadRequestException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { SendChatMessageDto } from './dto/send-message.dto';
import { MessageType, NotificationType, Role } from '@prisma/client';
import { NotificationsGateway } from '../notifications/notifications.gateway';
import { NotificationsService } from '../notifications/notifications.service';
import { OtpSenderService } from '../notifications/otp-sender.service';

@Injectable()
export class ChatService {
  constructor(
    private prisma: PrismaService,
    private gateway: NotificationsGateway,
    private notificationsService: NotificationsService,
    private otpSender: OtpSenderService,
  ) {}

  async sendMessage(senderId: string, dto: SendChatMessageDto) {
    if (dto.messageType === MessageType.LOCATION) {
      if (dto.latitude === undefined || dto.longitude === undefined) {
        throw new BadRequestException('إحداثيات الموقع (خط العرض وخط الطول) مطلوبة عند مشاركة الموقع');
      }
    } else if (!dto.content && !dto.mediaUrl) {
      throw new BadRequestException('يجب إرسال نص أو رسالة صوتية أو موقع أو صورة');
    }

    if (dto.messageType === MessageType.VOICE_NOTE && !dto.mediaUrl) {
      throw new BadRequestException('رابط الرسالة الصوتية مطلوب');
    }

    const receiver = await this.prisma.user.findUnique({
      where: { id: dto.receiverId },
    });

    if (!receiver) {
      throw new NotFoundException('المستخدم المستلم غير موجود');
    }

    const message = await this.prisma.chatMessage.create({
      data: {
        senderId,
        receiverId: dto.receiverId,
        contractId: dto.contractId,
        tripRequestId: dto.tripRequestId,
        messageType: dto.messageType,
        content: dto.content,
        mediaUrl: dto.mediaUrl,
        durationSeconds: dto.durationSeconds,
        latitude: dto.latitude,
        longitude: dto.longitude,
        locationAddress: dto.locationAddress,
        isRead: false,
      },
      include: {
        sender: { select: { id: true, fullName: true, avatarUrl: true, role: true } },
      },
    });

    // 1. Real-time broadcast via WebSockets to receiver room
    if (this.gateway.server) {
      this.gateway.server.to(`user_${dto.receiverId}`).emit('new_chat_message', {
        event: 'NEW_CHAT_MESSAGE',
        message,
      });
    }

    // 2. Format message preview
    let messagePreview = dto.content || 'رسالة جديدة';
    if (dto.messageType === MessageType.VOICE_NOTE) {
      messagePreview = '🎤 رسالة صوتية موثقة';
    } else if (dto.messageType === MessageType.LOCATION) {
      messagePreview = `📍 الموقع الجغرافي المشترك: ${dto.locationAddress || 'موقع مباشر'}`;
    } else if (dto.messageType === MessageType.IMAGE) {
      messagePreview = '📷 صورة جديدة';
    }

    const senderRoleAr = message.sender.role === Role.DRIVER ? 'الكابتن' : 'العميل';

    // 3. In-App Notification
    await this.notificationsService.createNotification(
      dto.receiverId,
      `رسالة جديدة من ${senderRoleAr} ${message.sender.fullName}`,
      messagePreview,
      NotificationType.CHAT_MESSAGE_RECEIVED,
      {
        messageId: message.id,
        contractId: dto.contractId,
        tripRequestId: dto.tripRequestId,
        senderId,
        senderName: message.sender.fullName,
        senderRole: message.sender.role,
        messageType: dto.messageType,
        latitude: dto.latitude,
        longitude: dto.longitude,
      },
    );

    // 4. WhatsApp Multi-Channel Notification for unread messages
    if (receiver.phoneNumber) {
      const waText = `💬 *رسالة جديدة في منصة تـرحـيـل*\n\nأهلاً بك أستاذ/ة ${receiver.fullName}،\nأرسل لك ${senderRoleAr} *${message.sender.fullName}* رسالة بخصوص مشوارك:\n"${messagePreview}"\n\nيرجى فتح التطبيق للرد ومتابعة المشوار: https://tarheel.app`;
      this.otpSender.sendWhatsAppMessage(receiver.phoneNumber, waText).catch(() => {});
    }

    // 5. Email Notification for unread messages
    if (receiver.email) {
      const emailHtml = `
        <div dir="rtl" style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f8fafc; padding: 25px; text-align: right; color: #0f172a;">
          <div style="max-width: 520px; margin: 0 auto; background-color: #ffffff; border-radius: 14px; padding: 24px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);">
            <div style="text-align: center; margin-bottom: 20px;">
              <h2 style="color: #153364; margin: 0;">🚗 منصة تـرحـيـل</h2>
              <p style="color: #64748b; font-size: 13px; margin-top: 4px;">إشعار رسالة جديدة غير مقروءة</p>
            </div>
            <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 16px 0;" />
            <p style="font-size: 15px; color: #1e293b;">أهلاً بك <strong>${receiver.fullName}</strong>،</p>
            <p style="font-size: 14px; color: #475569; line-height: 1.6;">
              أرسل لك ${senderRoleAr} <strong>${message.sender.fullName}</strong> رسالة جديدة بخصوص مشوارك المجدول:
            </p>
            <div style="background-color: #f1f5f9; padding: 14px; border-radius: 8px; border-right: 4px solid #F15A24; margin: 18px 0; font-size: 15px; color: #0f172a; font-weight: 500;">
              ${messagePreview}
            </div>
            <div style="text-align: center; margin-top: 24px;">
              <a href="https://tarheel.app" style="background-color: #153364; color: #ffffff; padding: 12px 28px; text-decoration: none; border-radius: 8px; font-weight: bold; font-size: 14px; display: inline-block;">
                فتح المحادثة والرد الآن
              </a>
            </div>
            <div style="background-color: #f8fafc; padding: 12px; text-align: center; font-size: 11px; color: #94a3b8; border-top: 1px solid #e2e8f0; margin-top: 24px;">
              منصة ترحيل © 2026 - تواصل موثق وآمن لحفظ حقوق الطرفين
            </div>
          </div>
        </div>
      `;
      this.otpSender.sendEmailNotification(receiver.email, `رسالة جديدة من ${message.sender.fullName}`, emailHtml).catch(() => {});
    }

    return {
      message: 'تم إرسال وتوثيق الرسالة بنجاح وإشعار الطرف الآخر',
      data: message,
    };
  }

  async getContractMessages(contractId: string, userId: string) {
    const contract = await this.prisma.tripContract.findUnique({
      where: { id: contractId },
      include: { driverProfile: true },
    });

    if (!contract) {
      throw new NotFoundException('العقد غير موجود');
    }

    if (contract.clientId !== userId && contract.driverProfile.userId !== userId) {
      throw new ForbiddenException('غير مصرح لك بقراءة هذه المحادثة');
    }

    // Mark incoming messages as read automatically
    await this.markAsRead(userId, contractId);

    return this.prisma.chatMessage.findMany({
      where: { contractId },
      include: {
        sender: { select: { id: true, fullName: true, avatarUrl: true, role: true } },
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  async getTripMessages(tripRequestId: string, userId: string) {
    // Mark incoming messages as read automatically
    await this.markAsRead(userId, undefined, tripRequestId);

    return this.prisma.chatMessage.findMany({
      where: {
        tripRequestId,
        OR: [{ senderId: userId }, { receiverId: userId }],
      },
      include: {
        sender: { select: { id: true, fullName: true, avatarUrl: true, role: true } },
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  async markAsRead(userId: string, contractId?: string, tripRequestId?: string) {
    const where: any = {
      receiverId: userId,
      isRead: false,
    };
    if (contractId) where.contractId = contractId;
    if (tripRequestId) where.tripRequestId = tripRequestId;

    const updated = await this.prisma.chatMessage.updateMany({
      where,
      data: { isRead: true },
    });

    if (this.gateway.server && updated.count > 0) {
      this.gateway.server.emit('messages_marked_read', {
        readerId: userId,
        contractId,
        tripRequestId,
      });
    }

    return {
      message: 'تم تحديث حالة قراءة الرسائل بنجاح',
      markedCount: updated.count,
    };
  }

  async getUnreadCount(userId: string) {
    const totalUnread = await this.prisma.chatMessage.count({
      where: {
        receiverId: userId,
        isRead: false,
      },
    });

    const unreadByContract = await this.prisma.chatMessage.groupBy({
      by: ['contractId'],
      where: {
        receiverId: userId,
        isRead: false,
        contractId: { not: null },
      },
      _count: {
        id: true,
      },
    });

    return {
      totalUnread,
      byContract: unreadByContract.map((c) => ({
        contractId: c.contractId,
        unreadCount: c._count.id,
      })),
    };
  }
}
