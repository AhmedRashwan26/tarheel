import { Controller, Get, Patch, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { AdminService } from './admin.service';
import { RejectDriverDto, SuspendDriverDto } from './dto/admin-driver-actions.dto';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role, VerificationStatus } from '@prisma/client';

@ApiTags('لوحة تحكم الإدارة (Admin Dashboard & KYC)')
@ApiBearerAuth()
@Roles(Role.ADMIN)
@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('drivers/pending')
  @ApiOperation({
    summary: 'استعراض قائمة السائقين الجدد قيد المراجعة للتحقق من الوثائق وصور السيارة الأربعة والتكييف',
  })
  getPendingDrivers() {
    return this.adminService.getPendingDrivers();
  }

  @Get('drivers')
  @ApiOperation({ summary: 'استعراض كافة السائقين مع إمكانية الفلترة بحالة الحساب' })
  @ApiQuery({ name: 'status', enum: VerificationStatus, required: false })
  getAllDrivers(@Query('status') status?: VerificationStatus) {
    return this.adminService.getAllDrivers(status);
  }

  @Patch('drivers/:id/approve')
  @ApiOperation({ summary: 'اعتماد حساب السائق وتفعيله لبدء تقديم العروض' })
  @ApiResponse({ status: 200, description: 'تم اعتماد السائق بنجاح' })
  approveDriver(@Param('id') driverProfileId: string) {
    return this.adminService.approveDriver(driverProfileId);
  }

  @Patch('drivers/:id/reject')
  @ApiOperation({ summary: 'رفض طلب السائق مع ذكر سبب الرفض' })
  rejectDriver(@Param('id') driverProfileId: string, @Body() dto: RejectDriverDto) {
    return this.adminService.rejectDriver(driverProfileId, dto);
  }

  @Patch('drivers/:id/suspend')
  @ApiOperation({ summary: 'تعليق حساب السائق وحظره لمخالفة سياسة التعامل النقدي أو الشروط' })
  suspendDriver(@Param('id') driverProfileId: string, @Body() dto: SuspendDriverDto) {
    return this.adminService.suspendDriver(driverProfileId, dto);
  }

  @Get('financial-overview')
  @ApiOperation({
    summary: 'تقرير مالي شامل للمنصة (إجمالي حجم التداول، أرباح المنصة من عمولة 10%، مبالغ الضمان المحتجزة، ومستحقات السائقين)',
  })
  getPlatformFinancialOverview() {
    return this.adminService.getPlatformFinancialOverview();
  }
}
