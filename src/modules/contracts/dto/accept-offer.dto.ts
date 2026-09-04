import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { PaymentType } from '@prisma/client';

export class AcceptOfferDto {
  @ApiProperty({ example: '7d34199c-e35b-43be-a238-765f041ff231', description: 'معرف العرض السعري المختار' })
  @IsNotEmpty({ message: 'معرف العرض مطلوب' })
  @IsString()
  offerId: string;

  @ApiProperty({
    enum: PaymentType,
    example: PaymentType.MONTHLY,
    required: false,
    description: 'نظام الدفع (شهري / أسبوعي / دفعة كاملة مقدمة)',
  })
  @IsOptional()
  @IsEnum(PaymentType, { message: 'نوع الدفع غير صحيح' })
  paymentType?: PaymentType;
}
