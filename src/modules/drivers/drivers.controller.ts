import { Controller, Post, Get, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { DriversService } from './drivers.service';
import { RegisterDriverDto } from './dto/register-driver.dto';
import { Public, Roles } from '../../common/decorators/roles.decorator';
import { Role } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('إدارة السائقين (Drivers)')
@Controller('drivers')
export class DriversController {
  constructor(private readonly driversService: DriversService) {}

  @Public()
  @Post('register')
  @ApiOperation({
    summary: 'تسجيل سائق جديد مع رفع الوثائق وصور السيارة الـ 4 والموافقة على العمولة 13.50% وسياسة منع النقد',
  })
  @ApiResponse({ status: 201, description: 'تم تسجيل السائق بنجاح وهو بانتظار اعتماد الإدارة' })
  registerDriver(@Body() dto: RegisterDriverDto) {
    return this.driversService.registerDriver(dto);
  }

  @Get('me')
  @ApiBearerAuth()
  @Roles(Role.DRIVER)
  @ApiOperation({ summary: 'استرجاع الملف الشخصي للسائق المسجل حالياً وبيانات مركبته ومحفظته' })
  getMyProfile(@CurrentUser('id') userId: string) {
    return this.driversService.getMyProfile(userId);
  }

  @Public()
  @Get(':id')
  @ApiOperation({ summary: 'استعراض بيانات السائق العامة وتقييماته وصور سيارته ومواصفاتها' })
  getDriverById(@Param('id') id: string) {
    return this.driversService.getDriverById(id);
  }
}
