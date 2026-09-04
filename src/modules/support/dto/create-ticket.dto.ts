import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { TicketDepartment, TicketPriority } from '@prisma/client';

export class CreateSupportTicketDto {
  @ApiProperty({
    enum: TicketDepartment,
    example: TicketDepartment.CUSTOMER_SERVICE,
    description: 'القسم المطلوب: CUSTOMER_SERVICE (خدمة العملاء), TECHNICAL_SUPPORT (الدعم الفني)',
  })
  @IsNotEmpty({ message: 'تحديد القسم مطلوب' })
  @IsEnum(TicketDepartment, { message: 'القسم المحدد غير صحيح' })
  department: TicketDepartment;

  @ApiProperty({ example: 'استفسار عن تمديد مدة التعاقد الشهري', description: 'عنوان التذكرة' })
  @IsNotEmpty({ message: 'عنوان التذكرة مطلوب' })
  @IsString()
  subject: string;

  @ApiProperty({ example: 'أرغب في الاستفسار عن إمكانية تمديد العقد لمدة شهر إضافي بنفس السائق وشروط الضمان.', description: 'تفاصيل الطلب أو المشكلة' })
  @IsNotEmpty({ message: 'تفاصيل المشكلة أو الاستفسار مطلوبة' })
  @IsString()
  description: string;

  @ApiProperty({ example: 'تمديد عقود', description: 'تصنيف التذكرة (فواتير، مشاوير، أخطاء تطبيق، إلخ)' })
  @IsNotEmpty({ message: 'تصنيف التذكرة مطلوب' })
  @IsString()
  category: string;

  @ApiProperty({ example: 'cf27a909-1a73-42eb-be60-d29b80b2a319', required: false, description: 'معرف العقد المرتبط إن وجد' })
  @IsOptional()
  @IsString()
  contractId?: string;

  @ApiProperty({
    enum: TicketPriority,
    example: TicketPriority.MEDIUM,
    required: false,
    description: 'أولوية التذكرة: LOW, MEDIUM, HIGH, URGENT',
  })
  @IsOptional()
  @IsEnum(TicketPriority)
  priority?: TicketPriority;

  // Technical support specifics
  @ApiProperty({ example: '1.2.0', required: false, description: 'إصدار التطبيق (خاص بالدعم الفني)' })
  @IsOptional()
  @IsString()
  appVersion?: string;

  @ApiProperty({ example: 'iPhone 15 Pro, iOS 18.2', required: false, description: 'معلومات الجهاز ونظام التشغيل (خاص بالدعم الفني)' })
  @IsOptional()
  @IsString()
  deviceInfo?: string;

  @ApiProperty({ example: '/uploads/screenshot_error.jpg', required: false, description: 'روابط صور أو لقطات شاشة للمشكلة' })
  @IsOptional()
  @IsString()
  attachments?: string;
}

export class ReplyTicketDto {
  @ApiProperty({ example: 'شكراً لتواصلك مع ترحيل. تم التنسيق وتفعيل خيار التمديد عبر التطبيق.', description: 'نص الرد' })
  @IsNotEmpty({ message: 'نص الرد مطلوب' })
  @IsString()
  message: string;

  @ApiProperty({ example: '/uploads/response_doc.pdf', required: false, description: 'مرفق إضافي مع الرد' })
  @IsOptional()
  @IsString()
  attachmentUrl?: string;
}
