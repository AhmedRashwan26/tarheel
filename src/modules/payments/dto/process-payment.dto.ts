import { ApiProperty } from '@nestjs/swagger';
import { Equals, IsEnum, IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { PaymentMethod } from '@prisma/client';

export class ProcessEscrowPaymentDto {
  @ApiProperty({ example: 'cf27a909-1a73-42eb-be60-d29b80b2a319', description: 'معرف عقد التوصيل' })
  @IsNotEmpty({ message: 'معرف العقد مطلوب' })
  @IsString()
  contractId: string;

  @ApiProperty({
    enum: PaymentMethod,
    example: PaymentMethod.MADA,
    description: 'وسيلة الدفع الإلكتروني (MADA, CARD, APPLE_PAY, STC_PAY, WALLET)',
  })
  @IsNotEmpty({ message: 'وسيلة الدفع مطلوبة' })
  @IsEnum(PaymentMethod, { message: 'وسيلة الدفع غير مدعومة' })
  paymentMethod: PaymentMethod;

  @ApiProperty({
    example: 'tok_visa_mada_sandbox_123',
    required: false,
    description: 'توكن أو مرجع بوابة الدفع',
  })
  @IsOptional()
  @IsString()
  paymentToken?: string;

  @ApiProperty({
    example: true,
    description: 'الإقرار بالعلم: ليس مسموحاً دفع أية مبالغ نقدية أو تحويل بنكي للسائق وأن ذلك يخرجك من ضمان ترحيل',
  })
  @Equals(true, { message: 'يجب تأكيد الإقرار بعدم التعامل النقدي للحفاظ على ضمان ترحيل' })
  acknowledgeAntiCashPolicy: boolean;
}
