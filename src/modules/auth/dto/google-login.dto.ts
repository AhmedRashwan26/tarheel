import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class GoogleLoginDto {
  @ApiProperty({ example: 'user@gmail.com', description: 'البريد الإلكتروني لحساب Google' })
  @IsNotEmpty({ message: 'البريد الإلكتروني لحساب Google مطلوب' })
  @IsEmail({}, { message: 'صيغة البريد الإلكتروني غير صحيحة' })
  email: string;

  @ApiProperty({ example: 'أحمد رشوان', description: 'الاسم الكامل الظاهر في حساب Google' })
  @IsNotEmpty({ message: 'الاسم الكامل مطلوب' })
  @IsString()
  fullName: string;

  @ApiProperty({ example: '109823472918374', required: false, description: 'معرف Google الفريد' })
  @IsOptional()
  @IsString()
  googleId?: string;

  @ApiProperty({ example: 'https://lh3.googleusercontent.com/...', required: false, description: 'رابط صورة الملف الشخصي' })
  @IsOptional()
  @IsString()
  avatarUrl?: string;

  @ApiProperty({
    enum: ['CLIENT', 'DRIVER'],
    example: 'CLIENT',
    required: false,
    description: 'الدور المستهدف: CLIENT أو DRIVER',
  })
  @IsOptional()
  @IsString()
  role?: string;
}
