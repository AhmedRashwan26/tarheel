import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, IsEmail } from 'class-validator';

export class RegisterClientDto {
  @ApiProperty({ example: '+966501234567', description: 'رقم جوال العميل (مطلوب)' })
  @IsNotEmpty({ message: 'رقم الجوال مطلوب' })
  @IsString()
  phoneNumber: string;

  @ApiProperty({ example: 'ahmed@example.com', description: 'البريد الإلكتروني للعميل (مطلوب)' })
  @IsNotEmpty({ message: 'البريد الإلكتروني مطلوب' })
  @IsEmail({}, { message: 'صيغة البريد الإلكتروني غير صحيحة' })
  email: string;

  @ApiProperty({ example: 'أحمد بن عبدالله التميمي', description: 'الاسم الكامل للعميل' })
  @IsNotEmpty({ message: 'الاسم الكامل مطلوب' })
  @IsString()
  fullName: string;
}
