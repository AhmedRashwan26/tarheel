import { Controller, Post, Get, Patch, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { SupportService } from './support.service';
import { CreateSupportTicketDto, ReplyTicketDto } from './dto/create-ticket.dto';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role, TicketDepartment, TicketStatus } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('خدمة العملاء والدعم الفني (Customer Service & Technical Support)')
@ApiBearerAuth()
@Controller('support')
export class SupportController {
  constructor(private readonly supportService: SupportService) {}

  @Post('ticket')
  @ApiOperation({
    summary: 'فتح تذكرة جديدة (خدمة العملاء أو الدعم الفني) للعملاء أو السائقين',
  })
  @ApiResponse({ status: 201, description: 'تم إنشاء التذكرة بنجاح' })
  createTicket(
    @CurrentUser('id') userId: string,
    @Body() dto: CreateSupportTicketDto,
  ) {
    return this.supportService.createTicket(userId, dto);
  }

  @Get('my-tickets')
  @ApiOperation({ summary: 'استعراض تذاكر المستخدم الحالية مع إمكانية الفلترة بالقسم' })
  @ApiQuery({ name: 'department', enum: TicketDepartment, required: false, description: 'CUSTOMER_SERVICE أو TECHNICAL_SUPPORT' })
  getMyTickets(
    @CurrentUser('id') userId: string,
    @Query('department') department?: TicketDepartment,
  ) {
    return this.supportService.getMyTickets(userId, department);
  }

  @Get('tickets/:id')
  @ApiOperation({ summary: 'استرجاع تفاصيل تذكرة مع كافة الردود' })
  getTicketById(
    @Param('id') ticketId: string,
    @CurrentUser('id') userId: string,
    @CurrentUser('role') userRole: Role,
  ) {
    return this.supportService.getTicketById(ticketId, userId, userRole);
  }

  @Post('tickets/:id/reply')
  @ApiOperation({ summary: 'إضافة رد على التذكرة' })
  replyTicket(
    @Param('id') ticketId: string,
    @CurrentUser('id') senderId: string,
    @CurrentUser('role') senderRole: Role,
    @Body() dto: ReplyTicketDto,
  ) {
    return this.supportService.replyTicket(ticketId, senderId, senderRole, dto);
  }

  // Admin / Support Agent Endpoints
  @Get('admin/tickets')
  @Roles(Role.ADMIN, Role.SUPPORT_AGENT)
  @ApiOperation({ summary: 'استعراض كافة التذاكر للإدارة وقسم الدعم مع الفلترة' })
  @ApiQuery({ name: 'department', enum: TicketDepartment, required: false })
  @ApiQuery({ name: 'status', enum: TicketStatus, required: false })
  getAllTicketsForAdmin(
    @Query('department') department?: TicketDepartment,
    @Query('status') status?: TicketStatus,
  ) {
    return this.supportService.getAllTicketsForAdmin(department, status);
  }

  @Patch('admin/tickets/:id/status')
  @Roles(Role.ADMIN, Role.SUPPORT_AGENT)
  @ApiOperation({ summary: 'تحديث حالة التذكرة (OPEN, IN_PROGRESS, RESOLVED, CLOSED)' })
  updateTicketStatus(
    @Param('id') ticketId: string,
    @Body('status') status: TicketStatus,
  ) {
    return this.supportService.updateTicketStatus(ticketId, status);
  }
}
