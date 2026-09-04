import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export enum OtpDeliveryChannel {
  SMS = 'SMS',
  WHATSAPP = 'WHATSAPP',
  EMAIL = 'EMAIL',
}

export class LoginPhoneDto {
  @ApiProperty({
    example: '+966501234567',
    description: 'رقم الجوال (إجباري للسائق، ومتاح للعميل) أو البريد الإلكتروني (متاح للعميل)',
  })
  @IsNotEmpty({ message: 'رقم الجوال أو البريد الإلكتروني مطلوب' })
  @IsString()
  identifier: string;

  @ApiProperty({
    enum: OtpDeliveryChannel,
    example: OtpDeliveryChannel.WHATSAPP,
    required: false,
    description: 'القناة المفضلة لاستلام الرمز: WHATSAPP (واتساب), SMS (رسالة نصية), EMAIL (بريد إلكتروني)',
  })
  @IsOptional()
  @IsEnum(OtpDeliveryChannel)
  channel?: OtpDeliveryChannel;
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
