import { Injectable, BadRequestException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateReviewDto } from './dto/create-review.dto';

@Injectable()
export class ReviewsService {
  constructor(private prisma: PrismaService) {}

  async createReview(clientId: string, dto: CreateReviewDto) {
    const contract = await this.prisma.tripContract.findUnique({
      where: { id: dto.contractId },
      include: { review: true, driverProfile: true },
    });

    if (!contract) {
      throw new NotFoundException('عقد التوصيل غير موجود');
    }

    if (contract.clientId !== clientId) {
      throw new ForbiddenException('لا يمكنك تقييم عقد لا يخصك');
    }

    if (contract.review) {
      throw new BadRequestException('لقد قمت بتقييم هذا السائق مسبقاً لهذا العقد');
    }

    // Save review and update driver's rating in atomic transaction
    const result = await this.prisma.$transaction(async (tx) => {
      const review = await tx.review.create({
        data: {
          contractId: contract.id,
          reviewerId: clientId,
          driverProfileId: contract.driverProfileId,
          rating: dto.rating,
          punctualityRating: dto.punctualityRating,
          cleanlinessRating: dto.cleanlinessRating,
          comment: dto.comment,
        },
      });

      // Calculate new average
      const allReviews = await tx.review.findMany({
        where: { driverProfileId: contract.driverProfileId },
      });

      const totalRatings = allReviews.length;
      const sumRatings = allReviews.reduce((acc, curr) => acc + curr.rating, 0);
      const newAverage = Number((sumRatings / totalRatings).toFixed(2));

      await tx.driverProfile.update({
        where: { id: contract.driverProfileId },
        data: {
          ratingAverage: newAverage,
          totalRatingsCount: totalRatings,
        },
      });

      return { review, newAverage, totalRatings };
    });

    return {
      message: 'شكراً لتقييمك! تم حفظ تقييمك للسائق والمساهمة في رفع جودة ترحيل.',
      review: result.review,
      driverNewRatingAverage: result.newAverage,
    };
  }

  async getDriverReviews(driverProfileId: string) {
    return this.prisma.review.findMany({
      where: { driverProfileId },
      include: {
        reviewer: { select: { fullName: true, avatarUrl: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }
}
