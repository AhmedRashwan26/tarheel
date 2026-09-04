import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString, IsEmail, ValidateIf } from 'class-validator';

export class RegisterClientDto {
  @ApiProperty({ example: '+966501234567', required: false, description: 'رقم جوال العميل (اختياري إذا تم التسجيل بالبريد الإلكتروني)' })
  @ValidateIf((o) => !o.email)
  @IsNotEmpty({ message: 'يجب إدخال رقم الجوال أو البريد الإلكتروني' })
  @IsString()
  phoneNumber?: string;

  @ApiProperty({ example: 'ahmed@example.com', required: false, description: 'البريد الإلكتروني للعميل (اختياري إذا تم التسجيل برقم الجوال)' })
  @ValidateIf((o) => !o.phoneNumber)
  @IsNotEmpty({ message: 'يجب إدخال البريد الإلكتروني أو رقم الجوال' })
  @IsEmail({}, { message: 'صيغة البريد الإلكتروني غير صحيحة' })
  email?: string;

  @ApiProperty({ example: 'أحمد بن عبدالله التميمي', description: 'الاسم الكامل للعميل' })
  @IsNotEmpty({ message: 'الاسم الكامل مطلوب' })
  @IsString()
  fullName: string;
}
