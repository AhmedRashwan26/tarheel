import { Injectable, BadRequestException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { SendChatMessageDto } from './dto/send-message.dto';
import { MessageType, NotificationType } from '@prisma/client';
import { NotificationsGateway } from '../notifications/notifications.gateway';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class ChatService {
  constructor(
    private prisma: PrismaService,
    private gateway: NotificationsGateway,
    private notificationsService: NotificationsService,
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
      },
      include: {
        sender: { select: { id: true, fullName: true, avatarUrl: true, role: true } },
      },
    });

    // Real-time broadcast via WebSockets to receiver room
    if (this.gateway.server) {
      this.gateway.server.to(`user_${dto.receiverId}`).emit('new_chat_message', {
        event: 'NEW_CHAT_MESSAGE',
        message,
      });
    }

    // Push notification preview
    let messagePreview = dto.content || 'رسالة جديدة';
    if (dto.messageType === MessageType.VOICE_NOTE) {
      messagePreview = '🎤 رسالة صوتية جديدة';
    } else if (dto.messageType === MessageType.LOCATION) {
      messagePreview = `📍 تم مشاركة الموقع الجغرافي: ${dto.locationAddress || 'موقع مباشر'}`;
    } else if (dto.messageType === MessageType.IMAGE) {
      messagePreview = '📷 صورة جديدة';
    }

    await this.notificationsService.createNotification(
      dto.receiverId,
      `رسالة جديدة من ${message.sender.fullName}`,
      messagePreview,
      NotificationType.CHAT_MESSAGE_RECEIVED,
      {
        messageId: message.id,
        contractId: dto.contractId,
        tripRequestId: dto.tripRequestId,
        senderId,
        messageType: dto.messageType,
        latitude: dto.latitude,
        longitude: dto.longitude,
      },
    );

    return {
      message: 'تم إرسال وتوثيق الرسالة بنجاح داخل محادثة ترحيل الآمنة',
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

    return this.prisma.chatMessage.findMany({
      where: { contractId },
      include: {
        sender: { select: { id: true, fullName: true, avatarUrl: true, role: true } },
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  async getTripMessages(tripRequestId: string, userId: string) {
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
}
