import { Controller, Post, Get, Body, Param, Query, Patch, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { TripsService } from './trips.service';
import { CreateTripRequestDto } from './dto/create-trip-request.dto';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('طلبات المشاوير والتوصيل (Trip Requests)')
@Controller('trips')
export class TripsController {
  constructor(private readonly tripsService: TripsService) {}

  @Post()
  @ApiBearerAuth()
  @Roles(Role.CLIENT)
  @ApiOperation({
    summary: 'نشر طلب مشوار جديد (تحديد نقطة الانطلاق والوصول، الموعد، تفعيل العودة وموعدها، وتكرار المشوار أسبوعي/شهري)',
  })
  @ApiResponse({ status: 201, description: 'تم نشر المشوار بنجاح وإتاحته للسائقين' })
  createTripRequest(@CurrentUser('id') clientId: string, @Body() dto: CreateTripRequestDto) {
    return this.tripsService.createTripRequest(clientId, dto);
  }

  @Get('feed')
  @ApiBearerAuth()
  @Roles(Role.DRIVER)
  @ApiOperation({ summary: 'تصفح طلبات المشاوير المفتوحة والمتاحة للسائقين مع إمكانية البحث والفرز بحسب المنطقة أو الحي' })
  @ApiQuery({ name: 'capacity', required: false, type: Number, description: 'فلترة بعدد المقاعد' })
  @ApiQuery({ name: 'search', required: false, type: String, description: 'البحث باسم المنطقة أو الحي أو الشارع' })
  getOpenTripsForDrivers(
    @Query('capacity') capacity?: number,
    @Query('search') search?: string,
  ) {
    return this.tripsService.getOpenTripsForDrivers({ capacity, search });
  }

  @Get('my-requests')
  @ApiBearerAuth()
  @Roles(Role.CLIENT)
  @ApiOperation({ summary: 'استرجاع مشاوير العميل الحالية والسابقة مع العروض المستلمة' })
  getMyTripRequests(@CurrentUser('id') clientId: string) {
    return this.tripsService.getMyTripRequests(clientId);
  }

  @Get(':id')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'استرجاع تفاصيل طلب مشوار معين مع قائمة العروض المقدمة' })
  getTripById(@Param('id') id: string) {
    return this.tripsService.getTripById(id);
  }

  @Patch(':id/cancel')
  @ApiBearerAuth()
  @Roles(Role.CLIENT)
  @ApiOperation({ summary: 'إلغاء طلب مشوار مفتوح' })
  cancelTripRequest(@CurrentUser('id') clientId: string, @Param('id') id: string) {
    return this.tripsService.cancelTripRequest(clientId, id);
  }
}
