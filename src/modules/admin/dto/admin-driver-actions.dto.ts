import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class RejectDriverDto {
  @ApiProperty({ example: 'صورة رخصة السير غير واضحة أو صور السيارة غير مكتملة الزوايا الأربع', description: 'سبب رفض الطلب' })
  @IsNotEmpty({ message: 'سبب الرفض مطلوب' })
  @IsString()
  reason: string;
}

export class SuspendDriverDto {
  @ApiProperty({ example: 'مخالفة سياسة منع التعامل النقدي المباشر مع الركاب', description: 'سبب تعليق الحساب' })
  @IsNotEmpty({ message: 'سبب تعليق الحساب مطلوب' })
  @IsString()
  reason: string;
}

export class UnsuspendDriverDto {
  @ApiProperty({ example: 'تم التحقق من الالتزام بالسياسات وفك التعليق', description: 'ملاحظات فك التعليق', required: false })
  @IsOptional()
  @IsString()
  note?: string;
}

export class ResolveDisputeDto {
  @ApiProperty({
    example: 'RELEASE_TO_DRIVER',
    description: 'قرار النزاع: RELEASE_TO_DRIVER (تحويل المبلغ للسائق) أو REFUND_TO_CLIENT (إعادة المبلغ للعميل)',
    enum: ['RELEASE_TO_DRIVER', 'REFUND_TO_CLIENT'],
  })
  @IsNotEmpty({ message: 'إجراء فض النزاع مطلوب' })
  @IsString()
  action: 'RELEASE_TO_DRIVER' | 'REFUND_TO_CLIENT';

  @ApiProperty({ example: 'تم التأكد من اكتمال الرحلة والالتزام بالاتفاق', description: 'حيثيات وقرار الإدارة' })
  @IsNotEmpty({ message: 'حيثيات القرار مطلوبة' })
  @IsString()
  resolutionNote: string;
}

export class BroadcastNotificationDto {
  @ApiProperty({
    example: 'ALL',
    description: 'الفئة المستهدفة: ALL (الجميع), CLIENTS (العملاء), DRIVERS (السائقين), USER (مستخدم محدد)',
    enum: ['ALL', 'CLIENTS', 'DRIVERS', 'USER'],
  })
  @IsNotEmpty({ message: 'الفئة المستهدفة مطلوبة' })
  @IsString()
  recipientType: 'ALL' | 'CLIENTS' | 'DRIVERS' | 'USER';

  @ApiProperty({ example: 'user-uuid', description: 'معرف المستخدم (إذا كان المستهدف مستخدم محدد)', required: false })
  @IsOptional()
  @IsString()
  userId?: string;

  @ApiProperty({ example: 'تنبيه أمني هام', description: 'عنوان التنبيه' })
  @IsNotEmpty({ message: 'عنوان التنبيه مطلوب' })
  @IsString()
  title: string;

  @ApiProperty({ example: 'نذكركم بالالتزام التام بسياسة التعامل المالي عبر المنصة.', description: 'نص التنبيه' })
  @IsNotEmpty({ message: 'نص التنبيه مطلوب' })
  @IsString()
  message: string;

  @ApiProperty({ example: true, description: 'إرسال التنبيه أيضاً عبر الواتساب', required: false })
  @IsOptional()
  sendWhatsApp?: boolean;

  @ApiProperty({ example: true, description: 'إرسال التنبيه أيضاً عبر البريد الإلكتروني', required: false })
  @IsOptional()
  sendEmail?: boolean;
}

