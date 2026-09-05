import { Controller, Get, Post, Patch, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { AdminService } from './admin.service';
import {
  RejectDriverDto,
  SuspendDriverDto,
  UnsuspendDriverDto,
  ResolveDisputeDto,
  BroadcastNotificationDto,
} from './dto/admin-driver-actions.dto';
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

  @Get('drivers/:id')
  @ApiOperation({ summary: 'استعراض الملف الكامل للسائق مع وثائقه، صور سيارته، رحلاته وتقييماته' })
  getDriverDetails(@Param('id') driverProfileId: string) {
    return this.adminService.getDriverDetails(driverProfileId);
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

  @Patch('drivers/:id/unsuspend')
  @ApiOperation({ summary: 'فك تعليق حساب السائق وإعادة تفعيله لممارسة عمله' })
  unsuspendDriver(@Param('id') driverProfileId: string, @Body() dto?: UnsuspendDriverDto) {
    return this.adminService.unsuspendDriver(driverProfileId, dto);
  }

  // ==================== DISPUTES & ESCROW ====================

  @Get('disputes')
  @ApiOperation({ summary: 'استعراض العقود المعلقة والنزاعات المالية للبت فيها' })
  getDisputes() {
    return this.adminService.getDisputes();
  }

  @Post('disputes/:contractId/resolve')
  @ApiOperation({ summary: 'البت الإداري في النزاع المالي (تحويل للسائق أو استرداد للعميل)' })
  resolveDispute(@Param('contractId') contractId: string, @Body() dto: ResolveDisputeDto) {
    return this.adminService.resolveDispute(contractId, dto);
  }

  // ==================== CHAT MONITORING ====================

  @Get('chats')
  @ApiOperation({ summary: 'مراقبة كافة محادثات العملاء والسائقين لمتابعة الالتزام وعدم التعامل النقدي' })
  getAllChats() {
    return this.adminService.getAllChats();
  }

  @Get('chats/:contractId')
  @ApiOperation({ summary: 'استعراض سجل الرسائل والملاحظات الصوتية لعقد معين' })
  getChatMessages(@Param('contractId') contractId: string) {
    return this.adminService.getChatMessages(contractId);
  }

  // ==================== BROADCAST NOTIFICATIONS ====================

  @Post('notifications/broadcast')
  @ApiOperation({ summary: 'إرسال تنبيهات مخصصة أو جماعية للعملاء أو السائقين (تطبيق / واتساب / إيميل)' })
  broadcastNotification(@Body() dto: BroadcastNotificationDto) {
    return this.adminService.broadcastNotification(dto);
  }

  // ==================== FINANCIAL OVERVIEW ====================

  @Get('financial-overview')
  @ApiOperation({
    summary: 'تقرير مالي شامل للمنصة (إجمالي حجم التداول، أرباح المنصة من عمولة 13.50%، مبالغ الضمان المحتجزة، ومستحقات السائقين)',
  })
  getPlatformFinancialOverview() {
    return this.adminService.getPlatformFinancialOverview();
  }

  // ==================== USERS PERFORMANCE & AUDIT ====================

  @Get('users/financial-performance')
  @ApiOperation({ summary: 'متابعة الأداء المالي للسائقين والعملاء (الأرباح، المصروفات، الرحلات المنفذة، والتقييمات)' })
  @ApiQuery({ name: 'role', enum: Role, required: false })
  @ApiQuery({ name: 'search', type: String, required: false })
  getUsersFinancialPerformance(
    @Query('role') role?: Role,
    @Query('search') search?: string,
  ) {
    return this.adminService.getUsersFinancialPerformance(role, search);
  }

  @Get('users/:id/activity-history')
  @ApiOperation({ summary: 'استعراض سجل النشاط الكامل والعمليات المالية لتاريخ أي سائق أو عميل' })
  getUserActivityHistory(@Param('id') userId: string) {
    return this.adminService.getUserActivityHistory(userId);
  }
}
