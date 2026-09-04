import { Body, Controller, Post, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { RegisterClientDto } from './dto/register-client.dto';
import { LoginPhoneDto, VerifyOtpDto } from './dto/login-phone.dto';
import { Public } from '../../common/decorators/roles.decorator';

@ApiTags('المصادقة وتوثيق الحسابات (Auth)')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Public()
  @Post('send-otp')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'إرسال رمز تحقق OTP إلى رقم الجوال أو الإيميل' })
  @ApiResponse({ status: 200, description: 'تم إرسال رمز التحقق بنجاح' })
  sendOtp(@Body() dto: LoginPhoneDto) {
    return this.authService.sendOtp(dto);
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
}
