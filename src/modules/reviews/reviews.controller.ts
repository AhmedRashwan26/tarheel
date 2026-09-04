import { Controller, Post, Get, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { ReviewsService } from './reviews.service';
import { CreateReviewDto } from './dto/create-review.dto';
import { Roles, Public } from '../../common/decorators/roles.decorator';
import { Role } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('التقييمات والآراء (Reviews & Ratings)')
@Controller('reviews')
export class ReviewsController {
  constructor(private readonly reviewsService: ReviewsService) {}

  @Post()
  @ApiBearerAuth()
  @Roles(Role.CLIENT)
  @ApiOperation({
    summary: 'تقييم السائق بعد اكتمال مدة التوصيل (التقييم العام، دقة المواعيد، نظافة وتكييف السيارة)',
  })
  @ApiResponse({ status: 201, description: 'تم حفظ التقييم بنجاح وتحديث معدل السائق' })
  createReview(@CurrentUser('id') clientId: string, @Body() dto: CreateReviewDto) {
    return this.reviewsService.createReview(clientId, dto);
  }

  @Public()
  @Get('driver/:driverProfileId')
  @ApiOperation({ summary: 'استعراض تقييمات سائق معين' })
  getDriverReviews(@Param('driverProfileId') driverProfileId: string) {
    return this.reviewsService.getDriverReviews(driverProfileId);
  }
}
