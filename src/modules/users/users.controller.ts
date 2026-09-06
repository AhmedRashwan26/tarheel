import { Controller, Get, Patch, Post, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('حساب المستخدم والمحفظة (User Profile & Wallet)')
@ApiBearerAuth()
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('profile')
  @ApiOperation({ summary: 'استرجاع الملف الشخصي للمستخدم الحالي' })
  getMyProfile(@CurrentUser('id') userId: string) {
    return this.usersService.getMyProfile(userId);
  }

  @Get('wallet/transactions')
  @ApiOperation({ summary: 'استعراض سجل المعاملات المالية والمحفظة للمستخدم' })
  getMyWalletTransactions(@CurrentUser('id') userId: string) {
    return this.usersService.getMyWalletTransactions(userId);
  }

  @Get('notifications')
  @ApiOperation({ summary: 'استعراض الإشعارات والتنبيهات للمستخدم' })
  getMyNotifications(@CurrentUser('id') userId: string) {
    return this.usersService.getMyNotifications(userId);
  }

  @Patch('profile')
  @ApiOperation({ summary: 'تحديث الملف الشخصي والصورة الرمزية (Avatar) والاسم والشروط' })
  updateProfile(
    @CurrentUser('id') userId: string,
    @Body() body: { avatarUrl?: string; fullName?: string; termsAccepted?: boolean },
  ) {
    return this.usersService.updateProfile(userId, body);
  }

  @Post('accept-terms')
  @ApiOperation({ summary: 'الموافقة الرسمية على الشروط والأحكام وسياسة منصة ترحيل' })
  acceptTerms(@CurrentUser('id') userId: string) {
    return this.usersService.acceptTerms(userId);
  }
}
