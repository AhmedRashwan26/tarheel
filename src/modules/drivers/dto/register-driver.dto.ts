import { ApiProperty } from '@nestjs/swagger';
import {
  IsBoolean,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Min,
  Max,
  Equals,
  Matches,
} from 'class-validator';

export class RegisterDriverDto {
  @ApiProperty({ example: '+966551234567', description: 'رقم جوال السائق' })
  @IsNotEmpty({ message: 'رقم الجوال مطلوب' })
  @IsString()
  phoneNumber: string;

  @ApiProperty({ example: 'سالم بن فهد الدوسري', description: 'الاسم الكامل للسائق' })
  @IsNotEmpty({ message: 'الاسم الكامل مطلوب' })
  @IsString()
  fullName: string;

  @ApiProperty({ example: '1089345612', description: 'رقم الهوية الوطنية أو الإقامة' })
  @IsNotEmpty({ message: 'رقم الهوية الوطنية مطلوب' })
  @IsString()
  nationalId: string;

  @ApiProperty({ example: '/uploads/id_card.jpg', required: false, description: 'رابط صورة الهوية الوطنية' })
  @IsOptional()
  @IsString()
  idCardPhotoUrl?: string;

  @ApiProperty({ example: '/uploads/driver_license.jpg', required: false, description: 'رابط صورة رخصة القيادة' })
  @IsOptional()
  @IsString()
  driverLicenseUrl?: string;

  @ApiProperty({ example: '/uploads/vehicle_reg.jpg', required: false, description: 'رابط صورة رخصة سير السيارة (الاستمارة)' })
  @IsOptional()
  @IsString()
  vehicleRegistrationUrl?: string;

  // Vehicle Information
  @ApiProperty({ example: 'تويوتا', description: 'ماركة السيارة (تويوتا، هيونداي، نيسان، إلخ)' })
  @IsNotEmpty({ message: 'ماركة السيارة مطلوبة' })
  @IsString()
  vehicleBrand: string;

  @ApiProperty({ example: 'كامري', description: 'طراز السيارة' })
  @IsNotEmpty({ message: 'طراز السيارة مطلوب' })
  @IsString()
  vehicleModel: string;

  @ApiProperty({ example: 2023, description: 'سنة صنع السيارة' })
  @IsNotEmpty({ message: 'سنة الصنع مطلوبة' })
  @IsInt({ message: 'سنة الصنع يجب أن تكون رقماً صحيحاً' })
  @Min(2012, { message: 'يجب أن يكون موديل السيارة من 2012 فما فوق' })
  vehicleYear: number;

  @ApiProperty({ example: 'أ ب ج 1234', description: 'رقم لوحة السيارة' })
  @IsNotEmpty({ message: 'رقم اللوحة مطلوب' })
  @IsString()
  plateNumber: string;

  @ApiProperty({ example: 4, description: 'عدد الركاب المتاح في السيارة' })
  @IsNotEmpty({ message: 'عدد الركاب المتاح مطلوب' })
  @IsInt()
  @Min(1, { message: 'يجب أن تتسع السيارة لراكب واحد على الأقل' })
  @Max(30, { message: 'الحد الأقصى للمقاعد 30 راكباً' })
  capacity: number;

  @ApiProperty({ example: true, description: 'هل السيارة مكيفة؟ (نعم / لا)' })
  @IsNotEmpty({ message: 'حالة التكييف مطلوبة' })
  @IsBoolean({ message: 'حالة التكييف يجب أن تكون قيمة منطقية (true/false)' })
  isAirConditioned: boolean;

  // 4 Angle Photos
  @ApiProperty({ example: '/uploads/car_front.jpg', description: 'صورة السيارة من الأمام' })
  @IsNotEmpty({ message: 'صورة السيارة من الأمام مطلوبة' })
  @IsString()
  photoFrontUrl: string;

  @ApiProperty({ example: '/uploads/car_back.jpg', description: 'صورة السيارة من الخلف' })
  @IsNotEmpty({ message: 'صورة السيارة من الخلف مطلوبة' })
  @IsString()
  photoBackUrl: string;

  @ApiProperty({ example: '/uploads/car_right.jpg', description: 'صورة السيارة من اليمين' })
  @IsNotEmpty({ message: 'صورة السيارة من اليمين مطلوبة' })
  @IsString()
  photoRightUrl: string;

  @ApiProperty({ example: '/uploads/car_left.jpg', description: 'صورة السيارة من اليسار' })
  @IsNotEmpty({ message: 'صورة السيارة من اليسار مطلوبة' })
  @IsString()
  photoLeftUrl: string;

  @ApiProperty({ example: '/uploads/car_interior.jpg', required: false, description: 'صورة السيارة من الداخل' })
  @IsOptional()
  @IsString()
  photoInteriorUrl?: string;

  // Bank Account & PDF Proof
  @ApiProperty({ example: 'مصرف الراجحي', description: 'اسم البنك' })
  @IsNotEmpty({ message: 'اسم البنك مطلوب لتحويل المستحقات' })
  @IsString()
  bankName: string;

  @ApiProperty({ example: 'SA0380000000608010167519', description: 'رقم الآيبان البنكي (يبدأ بـ SA)' })
  @IsNotEmpty({ message: 'رقم الآيبان مطلوب' })
  @IsString()
  @Matches(/^SA[0-9]{22}$/, { message: 'صيغة الآيبان غير صحيحة، يجب أن يبدأ بـ SA متبوعاً بـ 22 رقماً' })
  iban: string;

  @ApiProperty({ example: 'سالم بن فهد الدوسري', description: 'اسم صاحب الحساب كما هو في شهادة الآيبان البنكية' })
  @IsNotEmpty({ message: 'اسم صاحب الحساب البنكي مطلوب' })
  @IsString()
  bankAccountHolderName: string;

  @ApiProperty({ example: '/uploads/iban_certificate.pdf', description: 'رابط ملف إثبات الحساب البنكي / شهادة الآيبان (PDF أو صورة)' })
  @IsNotEmpty({ message: 'ملف إثبات الحساب البنكي (شهادة الآيبان) مطلوب بصيغة PDF أو صورة' })
  @IsString()
  bankCertificatePdfUrl: string;

  // Strict Policy Agreement
  @ApiProperty({
    example: true,
    description: 'الموافقة على شروط ترحيل: عمولة 13.50% للتطبيق، وتحويل الأرباح للحساب البنكي المسجل بعد التقييم، ومنع استلام أي مبالغ نقدية',
  })
  @Equals(true, { message: 'يجب الإقرار والموافقة على سياسة منع التعامل النقدي وعمولة ترحيل 13.50%' })
  agreeToAntiCashPolicy: boolean;
}
