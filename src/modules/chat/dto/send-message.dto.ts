import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsInt, IsNotEmpty, IsNumber, IsOptional, IsString, ValidateIf } from 'class-validator';
import { MessageType } from '@prisma/client';

export class SendChatMessageDto {
  @ApiProperty({ example: 'cf27a909-1a73-42eb-be60-d29b80b2a319', required: false, description: 'معرف عقد التوصيل إن وجد' })
  @IsOptional()
  @IsString()
  contractId?: string;

  @ApiProperty({ example: 'b9d5ec58-b11c-469b-818c-30b127ff4791', required: false, description: 'معرف طلب المشوار إن وجد' })
  @IsOptional()
  @IsString()
  tripRequestId?: string;

  @ApiProperty({ example: 'usr-driver-uuid-456', description: 'معرف المستخدم المستلم (السائق أو العميل)' })
  @IsNotEmpty({ message: 'معرف المستلم مطلوب' })
  @IsString()
  receiverId: string;

  @ApiProperty({
    enum: MessageType,
    example: MessageType.LOCATION,
    description: 'نوع الرسالة: TEXT (نصية), VOICE_NOTE (رسالة صوتية), IMAGE (صورة), LOCATION (موقع جغرافي مباشر)',
  })
  @IsNotEmpty({ message: 'نوع الرسالة مطلوب' })
  @IsEnum(MessageType, { message: 'نوع الرسالة غير مدعوم' })
  messageType: MessageType;

  @ApiProperty({ example: 'أنا متواجد هنا عند نقطة الانتظار', required: false, description: 'نص الرسالة المكتوبة' })
  @IsOptional()
  @IsString()
  content?: string;

  @ApiProperty({ example: '/uploads/voice_note_123.m4a', required: false, description: 'رابط التسجيل الصوتي أو الصورة داخل التطبيق' })
  @IsOptional()
  @IsString()
  mediaUrl?: string;

  @ApiProperty({ example: 12, required: false, description: 'مدة التسجيل الصوتي بالثواني' })
  @IsOptional()
  @IsInt()
  durationSeconds?: number;

  // حقول مشاركة الموقع الجغرافي (LOCATION)
  @ApiProperty({ example: 24.7136, required: false, description: 'خط العرض لموقع السائق أو الراكب (إلزامي عند اختيار LOCATION)' })
  @ValidateIf((o) => o.messageType === MessageType.LOCATION)
  @IsNotEmpty({ message: 'إحداثي خط العرض مطلوب عند مشاركة الموقع' })
  @IsNumber({}, { message: 'خط العرض يجب أن يكون رقماً' })
  latitude?: number;

  @ApiProperty({ example: 46.6753, required: false, description: 'خط الطول لموقع السائق أو الراكب (إلزامي عند اختيار LOCATION)' })
  @ValidateIf((o) => o.messageType === MessageType.LOCATION)
  @IsNotEmpty({ message: 'إحداثي خط الطول مطلوب عند مشاركة الموقع' })
  @IsNumber({}, { message: 'خط الطول يجب أن يكون رقماً' })
  longitude?: number;

  @ApiProperty({ example: 'بوابة رقم 3 - جامعة الملك سعود', required: false, description: 'اسم أو وصف الموقع الجغرافي' })
  @IsOptional()
  @IsString()
  locationAddress?: string;
}
