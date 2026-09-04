import { Injectable, BadRequestException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../../prisma/prisma.service';
import { RegisterClientDto } from './dto/register-client.dto';
import { LoginPhoneDto, VerifyOtpDto, OtpDeliveryChannel } from './dto/login-phone.dto';
import { Role } from '@prisma/client';
import { OtpSenderService } from '../notifications/otp-sender.service';

@Injectable()
export class AuthService {
  // Key: identifier (phone or email), Value: { code: string, expiresAt: number }
  private static otpStore = new Map<string, { code: string; expiresAt: number }>();

  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private otpSender: OtpSenderService,
  ) {}

  async sendOtp(dto: LoginPhoneDto) {
    const isEmail = dto.identifier.includes('@');
    const normalizedIdentifier = dto.identifier.toLowerCase().trim();
    
    // Generate real random 6-digit OTP
    const otpCode = Math.floor(100000 + Math.random() * 900000).toString();

    // Store in OTP memory store for 10 minutes
    AuthService.otpStore.set(normalizedIdentifier, {
      code: otpCode,
      expiresAt: Date.now() + 10 * 60 * 1000,
    });

    const user = await this.prisma.user.findFirst({
      where: isEmail
        ? { email: normalizedIdentifier }
        : { phoneNumber: dto.identifier.trim() },
    });

    let selectedChannel = dto.channel;
    if (!selectedChannel) {
      selectedChannel = isEmail ? OtpDeliveryChannel.EMAIL : OtpDeliveryChannel.WHATSAPP;
    }

    if (isEmail && selectedChannel !== OtpDeliveryChannel.EMAIL) {
      selectedChannel = OtpDeliveryChannel.EMAIL;
    }

    // Send via the selected channel
    if (selectedChannel === OtpDeliveryChannel.EMAIL) {
      const sent = await this.otpSender.sendEmailOtp(normalizedIdentifier, otpCode, user?.fullName);
      if (!sent) {
        throw new BadRequestException('تعذر إرسال الرمز إلى البريد الإلكتروني. يرجى التأكد من صحة البريد أو تجربة الواتساب');
      }
    } else if (selectedChannel === OtpDeliveryChannel.WHATSAPP) {
      const sent = await this.otpSender.sendWhatsAppOtp(dto.identifier.trim(), otpCode);
      if (!sent) {
        throw new BadRequestException('تعذر إرسال الرمز عبر الواتساب. يرجى التأكد من الرقم أو تجربة البريد الإلكتروني');
      }
    } else {
      await this.otpSender.sendSmsOtp(dto.identifier.trim(), otpCode);
    }

    const channelNamesAr = {
      EMAIL: 'البريد الإلكتروني',
      WHATSAPP: 'الواتساب',
      SMS: 'الرسائل النصية SMS',
    };

    return {
      message: `تم إرسال رمز التحقق بنجاح عبر (${channelNamesAr[selectedChannel]})`,
      identifier: dto.identifier,
      channel: selectedChannel,
      isRegistered: !!user,
      role: user?.role || null,
    };
  }

  async verifyOtp(dto: VerifyOtpDto) {
    const normalizedIdentifier = dto.identifier.toLowerCase().trim();
    const storedOtp = AuthService.otpStore.get(normalizedIdentifier);

    const isValidStored = storedOtp && storedOtp.code === dto.code.trim() && Date.now() <= storedOtp.expiresAt;

    if (!isValidStored) {
      throw new BadRequestException('رمز التحقق غير صحيح أو منتهي الصلاحية');
    }

    // Consume OTP once verified
    if (storedOtp) {
      AuthService.otpStore.delete(normalizedIdentifier);
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

  async testEmailDirect(to: string) {
    return this.otpSender.testEmailDirect(to);
  }
}
