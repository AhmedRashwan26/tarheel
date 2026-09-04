import { Injectable, BadRequestException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../../prisma/prisma.service';
import { RegisterClientDto } from './dto/register-client.dto';
import { LoginPhoneDto, VerifyOtpDto } from './dto/login-phone.dto';
import { Role } from '@prisma/client';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

  async sendOtp(dto: LoginPhoneDto) {
    const isEmail = dto.identifier.includes('@');

    const user = await this.prisma.user.findFirst({
      where: isEmail
        ? { email: dto.identifier.toLowerCase().trim() }
        : { phoneNumber: dto.identifier.trim() },
    });

    return {
      message: isEmail
        ? 'تم إرسال رمز التحقق بنجاح إلى بريدك الإلكتروني'
        : 'تم إرسال رمز التحقق بنجاح إلى رقم الجوال',
      identifier: dto.identifier,
      channel: isEmail ? 'EMAIL' : 'SMS',
      isRegistered: !!user,
      role: user?.role || null,
      devOtpHint: '123456',
    };
  }

  async verifyOtp(dto: VerifyOtpDto) {
    if (dto.code !== '123456' && dto.code !== '000000') {
      throw new BadRequestException('رمز التحقق غير صحيح أو منتهي الصلاحية');
    }

    const isEmail = dto.identifier.includes('@');
    const user = await this.prisma.user.findFirst({
      where: isEmail
        ? { email: dto.identifier.toLowerCase().trim() }
        : { phoneNumber: dto.identifier.trim() },
      include: { driverProfile: { include: { vehicle: true } } },
    });

    if (!user) {
      throw new BadRequestException('الحساب غير مسجل. يرجى إنشاء حساب جديد أولاً.');
    }

    if (user.isBlocked) {
      throw new UnauthorizedException('تم حظر هذا الحساب لمخالفة سياسات ترحيل');
    }

    const tokens = await this.generateTokens(user);
    return {
      message: 'تم تسجيل الدخول بنجاح',
      user,
      ...tokens,
    };
  }

  async registerClient(dto: RegisterClientDto) {
    if (!dto.phoneNumber && !dto.email) {
      throw new BadRequestException('يجب إدخال رقم الجوال أو البريد الإلكتروني على الأقل لإنشاء الحساب');
    }

    if (dto.phoneNumber) {
      const existingPhone = await this.prisma.user.findUnique({
        where: { phoneNumber: dto.phoneNumber.trim() },
      });
      if (existingPhone) {
        throw new BadRequestException('رقم الهاتف مسجل بالفعل مسبقاً');
      }
    }

    if (dto.email) {
      const existingEmail = await this.prisma.user.findUnique({
        where: { email: dto.email.toLowerCase().trim() },
      });
      if (existingEmail) {
        throw new BadRequestException('البريد الإلكتروني مسجل بالفعل مسبقاً');
      }
    }

    const user = await this.prisma.user.create({
      data: {
        phoneNumber: dto.phoneNumber ? dto.phoneNumber.trim() : null,
        email: dto.email ? dto.email.toLowerCase().trim() : null,
        fullName: dto.fullName,
        role: Role.CLIENT,
      },
    });

    const tokens = await this.generateTokens(user);
    return {
      message: 'تم إنشاء حساب العميل بنجاح في ترحيل',
      user,
      ...tokens,
    };
  }

  async generateTokens(user: { id: string; role: Role; phoneNumber?: string; email?: string }) {
    const payload = {
      sub: user.id,
      role: user.role,
      phoneNumber: user.phoneNumber || null,
      email: user.email || null,
    };
    const accessToken = await this.jwtService.signAsync(payload);

    return {
      accessToken,
      tokenType: 'Bearer',
      expiresIn: '7d',
    };
  }
}
