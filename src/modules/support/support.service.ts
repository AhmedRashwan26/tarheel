import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateSupportTicketDto, ReplyTicketDto } from './dto/create-ticket.dto';
import { TicketDepartment, TicketStatus, Role, NotificationType } from '@prisma/client';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class SupportService {
  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
  ) {}

  async createTicket(userId: string, dto: CreateSupportTicketDto) {
    const ticket = await this.prisma.supportTicket.create({
      data: {
        userId,
        department: dto.department,
        subject: dto.subject,
        description: dto.description,
        category: dto.category,
        contractId: dto.contractId,
        priority: dto.priority || 'MEDIUM',
        appVersion: dto.appVersion,
        deviceInfo: dto.deviceInfo,
        attachments: dto.attachments,
        status: TicketStatus.OPEN,
      },
      include: {
        user: { select: { id: true, fullName: true, phoneNumber: true, email: true, role: true } },
      },
    });

    const departmentNameAr =
      dto.department === TicketDepartment.CUSTOMER_SERVICE ? 'خدمة العملاء' : 'الدعم الفني';

    return {
      message: `تم فتح تذكرة جديدة بنجاح في قسم (${departmentNameAr}) برقم مرجعي: #${ticket.id.substring(0, 8)}`,
      ticket,
    };
  }

  async getMyTickets(userId: string, department?: TicketDepartment) {
    return this.prisma.supportTicket.findMany({
      where: {
        userId,
        ...(department ? { department } : {}),
      },
      include: {
        replies: {
          orderBy: { createdAt: 'asc' },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getTicketById(ticketId: string, userId: string, userRole: Role) {
    const ticket = await this.prisma.supportTicket.findUnique({
      where: { id: ticketId },
      include: {
        user: { select: { id: true, fullName: true, phoneNumber: true, email: true, role: true } },
        contract: true,
        replies: {
          orderBy: { createdAt: 'asc' },
        },
      },
    });

    if (!ticket) {
      throw new NotFoundException('التذكرة غير موجودة');
    }

    if (ticket.userId !== userId && userRole !== Role.ADMIN && userRole !== Role.SUPPORT_AGENT) {
      throw new ForbiddenException('غير مصرح لك بالاطلاع على هذه التذكرة');
    }

    return ticket;
  }

  async replyTicket(ticketId: string, senderId: string, senderRole: Role, dto: ReplyTicketDto) {
    const ticket = await this.prisma.supportTicket.findUnique({
      where: { id: ticketId },
      include: { user: true },
    });

    if (!ticket) {
      throw new NotFoundException('التذكرة غير موجودة');
    }

    const reply = await this.prisma.supportReply.create({
      data: {
        ticketId,
        senderId,
        senderRole,
        message: dto.message,
        attachmentUrl: dto.attachmentUrl,
      },
    });

    // Update ticket status to IN_PROGRESS if open
    if (ticket.status === TicketStatus.OPEN) {
      await this.prisma.supportTicket.update({
        where: { id: ticketId },
        data: { status: TicketStatus.IN_PROGRESS },
      });
    }

    // Notify ticket owner if reply is from admin/agent
    if (senderRole === Role.ADMIN || senderRole === Role.SUPPORT_AGENT) {
      await this.notificationsService.createNotification(
        ticket.userId,
        `رد جديد على تذكرتك (#${ticket.id.substring(0, 8)})`,
        dto.message.substring(0, 80) + '...',
        NotificationType.SUPPORT_TICKET_REPLIED,
        { ticketId: ticket.id },
      );
    }

    return {
      message: 'تم إضافة الرد بنجاح',
      reply,
    };
  }

  async getAllTicketsForAdmin(department?: TicketDepartment, status?: TicketStatus) {
    return this.prisma.supportTicket.findMany({
      where: {
        ...(department ? { department } : {}),
        ...(status ? { status } : {}),
      },
      include: {
        user: { select: { id: true, fullName: true, phoneNumber: true, email: true, role: true } },
        _count: { select: { replies: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async updateTicketStatus(ticketId: string, status: TicketStatus) {
    const ticket = await this.prisma.supportTicket.update({
      where: { id: ticketId },
      data: { status },
    });

    return {
      message: `تم تحديث حالة التذكرة إلى (${status}) بنجاح`,
      ticket,
    };
  }
}
