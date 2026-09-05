import { Controller, Post, Get, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { OffersService } from './offers.service';
import { CreateOfferDto } from './dto/create-offer.dto';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('عروض الأسعار والمزايدة (Trip Offers & Bids)')
@Controller('offers')
export class OffersController {
  constructor(private readonly offersService: OffersService) {}

  @Post()
  @ApiBearerAuth()
  @Roles(Role.DRIVER)
  @ApiOperation({
    summary: 'تقديم عرض سعر من السائق لطلب مشوار (مع احتساب خصم عمولة 13.50% والتحذير من النقد)',
  })
  @ApiResponse({ status: 201, description: 'تم تقديم العرض بنجاح وإشعار العميل' })
  createOffer(@CurrentUser('id') driverUserId: string, @Body() dto: CreateOfferDto) {
    return this.offersService.createOffer(driverUserId, dto);
  }

  @Get('my-offers')
  @ApiBearerAuth()
  @Roles(Role.DRIVER)
  @ApiOperation({ summary: 'استرجاع العروض السعرية التي قدمها السائق وحالتها' })
  getMyOffers(@CurrentUser('id') driverUserId: string) {
    return this.offersService.getMyDriverOffers(driverUserId);
  }

  @Get('trip/:tripId')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'استعراض جميع عروض الأسعار المقدمة لمشوار معين' })
  getOffersForTrip(@Param('tripId') tripId: string) {
    return this.offersService.getOffersForTrip(tripId);
  }
}
