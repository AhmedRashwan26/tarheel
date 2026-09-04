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
