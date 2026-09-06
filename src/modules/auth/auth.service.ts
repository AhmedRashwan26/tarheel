import { Injectable, BadRequestException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../../prisma/prisma.service';
import { RegisterClientDto } from './dto/register-client.dto';
import { LoginPhoneDto, VerifyOtpDto, OtpDeliveryChannel } from './dto/login-phone.dto';
import { Role, VerificationStatus } from '@prisma/client';
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

  private normalizeIdentifier(raw: string): string {
    const trimmed = raw.trim();
    if (trimmed.includes('@')) {
      return trimmed.toLowerCase();
    }
    let clean = trimmed.replace(/[^0-9]/g, '');
    if (clean.startsWith('00')) {
      clean = clean.substring(2);
    }
    // Saudi Arabia: 05XXXXXXXX (10 digits) -> 9665XXXXXXXX
    if (clean.startsWith('05') && clean.length === 10) {
      return '966' + clean.substring(1);
    }
    // Saudi Arabia: 5XXXXXXXX (9 digits) -> 9665XXXXXXXX
    if (clean.startsWith('5') && clean.length === 9) {
      return '966' + clean;
    }
    // Egypt: 01XXXXXXXXX (11 digits) -> 201XXXXXXXXX
    if (clean.startsWith('01') && clean.length === 11) {
      return '20' + clean.substring(1);
    }
    return clean || trimmed;
  }

  async sendOtp(dto: LoginPhoneDto) {
    const isEmail = dto.identifier.includes('@');
    const normalizedIdentifier = this.normalizeIdentifier(dto.identifier);
    
    // Generate real random 6-digit OTP
    const otpCode = Math.floor(100000 + Math.random() * 900000).toString();

    const otpData = {
      code: otpCode,
      expiresAt: Date.now() + 10 * 60 * 1000,
    };

    // Store under both normalized and raw identifier
    AuthService.otpStore.set(normalizedIdentifier, otpData);
    if (normalizedIdentifier !== dto.identifier.trim().toLowerCase()) {
      AuthService.otpStore.set(dto.identifier.trim().toLowerCase(), otpData);
    }

    const user = await this.prisma.user.findFirst({
      where: isEmail
        ? { email: normalizedIdentifier }
        : {
            OR: [
              { phoneNumber: normalizedIdentifier },
              { phoneNumber: dto.identifier.trim() },
              { phoneNumber: '0' + normalizedIdentifier.replace(/^966/, '') },
            ],
          },
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
    } else {
      // Always use WhatsApp for phone numbers (SMS disabled)
      const sent = await this.otpSender.sendWhatsAppOtp(normalizedIdentifier, otpCode);
      if (!sent) {
        throw new BadRequestException('تعذر إرسال الرمز عبر الواتساب. يرجى التأكد من الرقم أو تجربة البريد الإلكتروني');
      }
    }

    const channelNamesAr = {
      EMAIL: 'البريد الإلكتروني',
      WHATSAPP: 'الواتساب',
      SMS: 'الواتساب',
    };

    return {
      message: `تم إرسال رمز التحقق بنجاح عبر (${channelNamesAr[selectedChannel] || 'الواتساب'})`,
      identifier: dto.identifier,
      normalizedIdentifier,
      channel: selectedChannel === OtpDeliveryChannel.EMAIL ? OtpDeliveryChannel.EMAIL : OtpDeliveryChannel.WHATSAPP,
      isRegistered: !!user,
      role: user?.role || null,
    };
  }

  async verifyOtp(dto: VerifyOtpDto) {
    const normalizedIdentifier = this.normalizeIdentifier(dto.identifier);
    const storedOtp = AuthService.otpStore.get(normalizedIdentifier) || AuthService.otpStore.get(dto.identifier.trim().toLowerCase());

    // Normalize Arabic/Persian digits to standard ASCII digits
    const cleanCode = dto.code
      .replace(/[٠-٩]/g, d => '٠١٢٣٤٥٦٧٨٩'.indexOf(d).toString())
      .replace(/[۰-۹]/g, d => '۰۱۲۳۴۵۶۷۸۹'.indexOf(d).toString())
      .replace(/[^0-9]/g, '')
      .trim();

    const isAdminEmail = normalizedIdentifier === 'tarheel.platform@gmail.com';
    let isValidStored = false;

    if (isAdminEmail) {
      // للأدمن حصراً: يجب أن يطابق الرمز العشوائي الحقيقي المرسل على البريد الرسمي فقط (يُمنع رمز التطوير 123456)
      isValidStored = Boolean(storedOtp && storedOtp.code === cleanCode && Date.now() <= storedOtp.expiresAt);
    } else {
      const isDevTesting = cleanCode === '123456';
      isValidStored = isDevTesting || Boolean(storedOtp && storedOtp.code === cleanCode && Date.now() <= storedOtp.expiresAt);
    }

    if (!isValidStored) {
      throw new BadRequestException('رمز التحقق غير صحيح أو منتهي الصلاحية');
    }

    // Consume OTP once verified
    AuthService.otpStore.delete(normalizedIdentifier);
    AuthService.otpStore.delete(dto.identifier.trim().toLowerCase());

    const isEmail = dto.identifier.includes('@');
    let user: any = null;

    if (isAdminEmail) {
      // ضمان وجود حساب الأدمن وترقيته حصراً لدور ADMIN
      user = await this.prisma.user.upsert({
        where: { email: 'tarheel.platform@gmail.com' },
        update: {
          role: Role.ADMIN,
          isBlocked: false,
        },
        create: {
          email: 'tarheel.platform@gmail.com',
          fullName: 'إدارة منصة ترحيل (Admin)',
          role: Role.ADMIN,
        },
        include: { driverProfile: { include: { vehicle: true } } },
      });
    } else {
      user = await this.prisma.user.findFirst({
        where: isEmail
          ? { email: normalizedIdentifier }
          : {
              OR: [
                { phoneNumber: normalizedIdentifier },
                { phoneNumber: dto.identifier.trim() },
                { phoneNumber: '0' + normalizedIdentifier.replace(/^966/, '') },
              ],
            },
        include: { driverProfile: { include: { vehicle: true } } },
      });

      const targetRole = dto.role === 'DRIVER' ? Role.DRIVER : Role.CLIENT;

      // If account does not exist yet, auto-register with targetRole seamlessly
      if (!user) {
        const assignedRole = targetRole || Role.CLIENT;
        user = await this.prisma.user.create({
          data: {
            email: isEmail ? normalizedIdentifier : undefined,
            phoneNumber: !isEmail ? normalizedIdentifier : undefined,
            fullName: isEmail ? normalizedIdentifier.split('@')[0] : (assignedRole === Role.DRIVER ? 'كابتن ترحيل' : 'عميل ترحيل'),
            role: assignedRole,
            driverProfile: assignedRole === Role.DRIVER ? {
              create: {
                nationalId: '10' + Math.floor(10000000 + Math.random() * 90000000),
                verificationStatus: VerificationStatus.PENDING,
              }
            } : undefined,
          },
          include: { driverProfile: { include: { vehicle: true } } },
        });
      } else if (targetRole === Role.DRIVER && user.role !== Role.ADMIN) {
        // If user logs in through Driver portal, ensure role is DRIVER and driverProfile exists
        user = await this.prisma.user.update({
          where: { id: user.id },
          data: {
            role: Role.DRIVER,
            driverProfile: !user.driverProfile ? {
              create: {
                nationalId: '10' + Math.floor(10000000 + Math.random() * 90000000),
                verificationStatus: VerificationStatus.PENDING,
              }
            } : undefined,
          },
          include: { driverProfile: { include: { vehicle: true } } },
        });
      }
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
