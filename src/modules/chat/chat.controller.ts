import { Controller, Post, Get, Patch, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { ChatService } from './chat.service';
import { SendChatMessageDto } from './dto/send-message.dto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('المحادثات والتواصل الداخلي (In-App Chat & Voice Notes)')
@ApiBearerAuth()
@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Post('send')
  @ApiOperation({
    summary: 'إرسال رسالة نصية أو رسالة صوتية (Voice Note) بين العميل والسائق حصراً داخل التطبيق لحفظ الحقوق مع إشعار بالواتساب والإيميل',
  })
  @ApiResponse({ status: 201, description: 'تم إرسال وتوثيق الرسالة بنجاح' })
  sendMessage(@CurrentUser('id') senderId: string, @Body() dto: SendChatMessageDto) {
    return this.chatService.sendMessage(senderId, dto);
  }

  @Get('contract/:contractId')
  @ApiOperation({ summary: 'استرجاع سجل محادثة عقد التوصيل بالكامل وتحديث حالة القراءة تلقائياً' })
  getContractMessages(
    @Param('contractId') contractId: string,
    @CurrentUser('id') userId: string,
  ) {
    return this.chatService.getContractMessages(contractId, userId);
  }

  @Get('trip/:tripRequestId')
  @ApiOperation({ summary: 'استرجاع سجل المحادثة المرتبطة بطلب مشوار مفتوح وتحديث حالة القراءة تلقائياً' })
  getTripMessages(
    @Param('tripRequestId') tripRequestId: string,
    @CurrentUser('id') userId: string,
  ) {
    return this.chatService.getTripMessages(tripRequestId, userId);
  }

  @Patch('mark-read')
  @ApiOperation({ summary: 'تحديث رسائل المحادثة غير المقروءة كمقروءة وإشعار الطرف الآخر' })
  @ApiQuery({ name: 'contractId', required: false })
  @ApiQuery({ name: 'tripRequestId', required: false })
  markAsRead(
    @CurrentUser('id') userId: string,
    @Query('contractId') contractId?: string,
    @Query('tripRequestId') tripRequestId?: string,
  ) {
    return this.chatService.markAsRead(userId, contractId, tripRequestId);
  }

  @Get('unread-count')
  @ApiOperation({ summary: 'استرجاع عدد الرسائل الجديدة غير المقروءة للمستخدم لتنبيهه وإظهار الشارة' })
  getUnreadCount(@CurrentUser('id') userId: string) {
    return this.chatService.getUnreadCount(userId);
  }
}
