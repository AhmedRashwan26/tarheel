import { ApiProperty } from '@nestjs/swagger';
import { IsInt, IsNotEmpty, IsOptional, IsString, Max, Min } from 'class-validator';

export class CreateReviewDto {
  @ApiProperty({ example: 'cf27a909-1a73-42eb-be60-d29b80b2a319', description: 'معرف عقد المشوار المكتمل' })
  @IsNotEmpty({ message: 'معرف العقد مطلوب' })
  @IsString()
  contractId: string;

  @ApiProperty({ example: 5, description: 'التقييم العام للخدمة من 1 إلى 5 نجوم' })
  @IsNotEmpty({ message: 'التقييم العام مطلوب' })
  @IsInt()
  @Min(1, { message: 'أقل تقييم هو 1' })
  @Max(5, { message: 'أعلى تقييم هو 5' })
  rating: number;

  @ApiProperty({ example: 5, description: 'تقييم الالتزام بالمواعيد والحضور من 1 إلى 5' })
  @IsNotEmpty({ message: 'تقييم المواعيد مطلوب' })
  @IsInt()
  @Min(1)
  @Max(5)
  punctualityRating: number;

  @ApiProperty({ example: 5, description: 'تقييم نظافة وتكييف السيارة من 1 إلى 5' })
  @IsNotEmpty({ message: 'تقييم نظافة السيارة والتكييف مطلوب' })
  @IsInt()
  @Min(1)
  @Max(5)
  cleanlinessRating: number;

  @ApiProperty({
    example: 'سائق محترم جداً، ملتزم بالوقت في الصباح والمساء، والسيارة نظيفة ومكيفة طوال مدة الشهر.',
    required: false,
    description: 'تعليق وملاحظات العميل',
  })
  @IsOptional()
  @IsString()
  comment?: string;
}
