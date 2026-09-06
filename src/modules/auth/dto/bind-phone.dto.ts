import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

export class SendBindPhoneOtpDto {
  @ApiProperty({ example: '+966501234567', description: 'رقم الجوال المراد ربطه وتأكيده' })
  @IsNotEmpty({ message: 'رقم الجوال مطلوب' })
  @IsString()
  phoneNumber: string;
}

export class VerifyBindPhoneDto {
  @ApiProperty({ example: '+966501234567', description: 'رقم الجوال المراد ربطه' })
  @IsNotEmpty({ message: 'رقم الجوال مطلوب' })
  @IsString()
  phoneNumber: string;

  @ApiProperty({ example: '123456', description: 'رمز التحقق المرسل عبر الواتساب/SMS' })
  @IsNotEmpty({ message: 'رمز التحقق مطلوب' })
  @IsString()
  code: string;
}
