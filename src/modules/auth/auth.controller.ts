import { Body, Controller, Post, HttpCode, HttpStatus, Req } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { RegisterClientDto } from './dto/register-client.dto';
import { LoginPhoneDto, VerifyOtpDto } from './dto/login-phone.dto';
import { GoogleLoginDto } from './dto/google-login.dto';
import { SendBindPhoneOtpDto, VerifyBindPhoneDto } from './dto/bind-phone.dto';
import { Public } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('المصادقة وتوثيق الحسابات (Auth)')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Public()
  @Post('send-otp')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'إرسال رمز تحقق OTP إلى رقم الجوال أو الإيميل مع تقييد الطلبات' })
  @ApiResponse({ status: 200, description: 'تم إرسال رمز التحقق بنجاح' })
  sendOtp(@Body() dto: LoginPhoneDto, @Req() req: any) {
    const clientIp = (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() || req.socket?.remoteAddress || req.ip || '127.0.0.1';
    return this.authService.sendOtp(dto, clientIp);
  }

  @Public()
  @Post('test-email')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'فحص إرسال الإيميل المباشر' })
  testEmail(@Body('to') to?: string) {
    return this.authService.testEmailDirect(to || 'pharmahmedrashwan@gmail.com');
  }

  @Public()
  @Post('verify-otp')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'التحقق من رمز OTP وتسجيل الدخول' })
  @ApiResponse({ status: 200, description: 'تم تسجيل الدخول وإرجاع التوكن' })
  verifyOtp(@Body() dto: VerifyOtpDto) {
    return this.authService.verifyOtp(dto);
  }

  @Public()
  @Post('register/client')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'تسجيل حساب عميل جديد في ترحيل برقم الهاتف' })
  @ApiResponse({ status: 201, description: 'تم إنشاء حساب العميل بنجاح' })
  registerClient(@Body() dto: RegisterClientDto) {
    return this.authService.registerClient(dto);
  }

  @Public()
  @Post('google')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'تسجيل الدخول أو إنشاء حساب عبر حساب Google' })
  @ApiResponse({ status: 200, description: 'تمت المصادقة بحساب Google وإرجاع التوكن' })
  googleLogin(@Body() dto: GoogleLoginDto) {
    return this.authService.googleLogin(dto);
  }

  @Post('bind-phone/send-otp')
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'إرسال رمز OTP لتأكيد وربط رقم الجوال بالحساب مع تقييد الطلبات' })
  @ApiResponse({ status: 200, description: 'تم إرسال رمز التحقق إلى رقم الجوال' })
  sendBindPhoneOtp(
    @CurrentUser('id') userId: string,
    @Body() dto: SendBindPhoneOtpDto,
    @Req() req: any,
  ) {
    const clientIp = (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() || req.socket?.remoteAddress || req.ip || '127.0.0.1';
    return this.authService.sendBindPhoneOtp(userId, dto, clientIp);
  }

  @Post('bind-phone/verify')
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'التحقق من رمز OTP وتأكيد ربط رقم الجوال' })
  @ApiResponse({ status: 200, description: 'تم ربط وتوثيق رقم الجوال بنجاح' })
  verifyAndBindPhone(@CurrentUser('id') userId: string, @Body() dto: VerifyBindPhoneDto) {
    return this.authService.verifyAndBindPhone(userId, dto);
  }
}
