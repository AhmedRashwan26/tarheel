import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsNumber, IsOptional, IsPositive, IsString } from 'class-validator';

export class CreateOfferDto {
  @ApiProperty({ example: 'b9d5ec58-b11c-469b-818c-30b127ff4791', description: 'معرف طلب المشوار' })
  @IsNotEmpty({ message: 'معرف المشوار مطلوب' })
  @IsString()
  tripRequestId: string;

  @ApiProperty({
    example: 1200,
    description: 'سعر العرض الإجمالي المقترح بالريال السعودي (شاملاً عمولة التطبيق 10%)',
  })
  @IsNotEmpty({ message: 'سعر العرض مطلوب' })
  @IsNumber({}, { message: 'يجب أن يكون السعر رقماً' })
  @IsPositive({ message: 'يجب أن يكون السعر أكبر من الصفر' })
  offerPrice: number;

  @ApiProperty({
    example: 'سيارة تويوتا كامري حديثة 2023 مكيفة، الالتزام التام بالمواعيد يومياً صباحاً ومساءً.',
    required: false,
    description: 'ملاحظات السائق وتفاصيل العرض',
  })
  @IsOptional()
  @IsString()
  driverNotes?: string;
}
