import { ApiProperty } from '@nestjs/swagger';
import {
  IsBoolean,
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  ValidateIf,
} from 'class-validator';
import { Frequency } from '@prisma/client';

export class CreateTripRequestDto {
  @ApiProperty({ example: 'حي النرجس، الرياض', description: 'عنوان ونقطة الانطلاق' })
  @IsNotEmpty({ message: 'عنوان الانطلاق مطلوب' })
  @IsString()
  pickupAddress: string;

  @ApiProperty({ example: 24.82345, description: 'إحداثيات خط العرض لنقطة الانطلاق' })
  @IsNotEmpty({ message: 'إحداثيات نقطة الانطلاق مطلوبة' })
  @IsNumber()
  pickupLatitude: number;

  @ApiProperty({ example: 46.68345, description: 'إحداثيات خط الطول لنقطة الانطلاق' })
  @IsNotEmpty({ message: 'إحداثيات نقطة الانطلاق مطلوبة' })
  @IsNumber()
  pickupLongitude: number;

  @ApiProperty({ example: 'جامعة الملك سعود، الدرعية', description: 'عنوان ونقطة الوصول' })
  @IsNotEmpty({ message: 'عنوان جهة الوصول مطلوب' })
  @IsString()
  dropoffAddress: string;

  @ApiProperty({ example: 24.71612, description: 'إحداثيات خط العرض لنقطة الوصول' })
  @IsNotEmpty({ message: 'إحداثيات نقطة الوصول مطلوبة' })
  @IsNumber()
  dropoffLatitude: number;

  @ApiProperty({ example: 46.61891, description: 'إحداثيات خط الطول لنقطة الوصول' })
  @IsNotEmpty({ message: 'إحداثيات نقطة الوصول مطلوبة' })
  @IsNumber()
  dropoffLongitude: number;

  @ApiProperty({ example: '2026-09-10', description: 'تاريخ بدء المشوار أو التعاقد (YYYY-MM-DD)' })
  @IsNotEmpty({ message: 'تاريخ بداية المشوار مطلوب' })
  @IsString()
  startDate: string;

  @ApiProperty({ example: '07:30', description: 'وقت الذهاب المفضل صباحاً أو مساءً (HH:mm)' })
  @IsNotEmpty({ message: 'وقت الذهاب مطلوب' })
  @IsString()
  preferredTime: string;

  @ApiProperty({ example: true, description: 'هل المشوار يشمل عودة؟ (نعم / لا)' })
  @IsNotEmpty({ message: 'تحديد وجود عودة مطلوب' })
  @IsBoolean()
  hasReturn: boolean;

  @ApiProperty({
    example: '14:30',
    required: false,
    description: 'وقت العودة (إلزامي إذا كان hasReturn = true) (HH:mm)',
  })
  @ValidateIf((o) => o.hasReturn === true)
  @IsNotEmpty({ message: 'يجب تحديد وقت العودة عند تفعيل خيار العودة' })
  @IsString()
  returnTime?: string;

  @ApiProperty({
    enum: Frequency,
    example: Frequency.MONTHLY,
    description: 'نوع التكرار: ONCE (مرة واحدة), WEEKLY (أسبوعي), MONTHLY (شهري), CUSTOM_DAYS (أيام محددة)',
  })
  @IsNotEmpty({ message: 'نوع تكرار المشوار مطلوب' })
  @IsEnum(Frequency, { message: 'نوع التكرار غير صحيح' })
  frequency: Frequency;

  @ApiProperty({
    example: 'الأحد,الاثنين,الثلاثاء,الأربعاء,الخميس',
    required: false,
    description: 'أيام التكرار الأسبوعية (مثل مشاوير الدوام أو المدارس والجامعات)',
  })
  @IsOptional()
  @IsString()
  recurringDays?: string;

  @ApiProperty({ example: 1, description: 'عدد الركاب' })
  @IsNotEmpty({ message: 'عدد الركاب مطلوب' })
  @IsInt()
  @Min(1, { message: 'يجب أن يكون عدد الركاب 1 على الأقل' })
  passengersCount: number;

  @ApiProperty({ example: 'مشوار يومي للجامعة، يفضل سيارة مكيفة وسائق ملتزم بالمواعيد', required: false, description: 'ملاحظات إضافية' })
  @IsOptional()
  @IsString()
  notes?: string;
}
