import { Controller, Post, Get, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
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
    summary: 'إرسال رسالة نصية أو رسالة صوتية (Voice Note) بين العميل والسائق حصراً داخل التطبيق لحفظ الحقوق',
  })
  @ApiResponse({ status: 201, description: 'تم إرسال وتوثيق الرسالة بنجاح' })
  sendMessage(@CurrentUser('id') senderId: string, @Body() dto: SendChatMessageDto) {
    return this.chatService.sendMessage(senderId, dto);
  }

  @Get('contract/:contractId')
  @ApiOperation({ summary: 'استرجاع سجل محادثة عقد التوصيل بالكامل (نصوص ورسائل صوتية)' })
  getContractMessages(
    @Param('contractId') contractId: string,
    @CurrentUser('id') userId: string,
  ) {
    return this.chatService.getContractMessages(contractId, userId);
  }

  @Get('trip/:tripRequestId')
  @ApiOperation({ summary: 'استرجاع سجل المحادثة المرتبطة بطلب مشوار مفتوح' })
  getTripMessages(
    @Param('tripRequestId') tripRequestId: string,
    @CurrentUser('id') userId: string,
  ) {
    return this.chatService.getTripMessages(tripRequestId, userId);
  }
}
