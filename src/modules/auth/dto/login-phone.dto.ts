import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

export class LoginPhoneDto {
  @ApiProperty({
    example: '+966501234567',
    description: 'رقم الجوال (إجباري للسائق، ومتاح للعميل) أو البريد الإلكتروني (متاح للعميل)',
  })
  @IsNotEmpty({ message: 'رقم الجوال أو البريد الإلكتروني مطلوب' })
  @IsString()
  identifier: string; // Accepts phone number (e.g. +966501234567) or email (e.g. ahmed@gmail.com)
}

export class VerifyOtpDto {
  @ApiProperty({
    example: '+966501234567',
    description: 'رقم الجوال أو البريد الإلكتروني الذي تم إرسال الرمز إليه',
  })
  @IsNotEmpty({ message: 'رقم الجوال أو البريد الإلكتروني مطلوب' })
  @IsString()
  identifier: string;

  @ApiProperty({ example: '123456', description: 'رمز التحقق OTP (الرمز التجريبي: 123456)' })
  @IsNotEmpty({ message: 'رمز التحقق مطلوب' })
  @IsString()
  code: string;
}
