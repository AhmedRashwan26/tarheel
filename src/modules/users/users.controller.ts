import { Controller, Get, UseGuards } from '@nestjs/common';
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
}
