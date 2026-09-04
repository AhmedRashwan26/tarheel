import { PrismaClient, Role, VerificationStatus, Frequency, TripStatus, OfferStatus } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting Tarheel database seeding with VAT 15% and Driver Bank details...');

  // 1. Create Admin
  const admin = await prisma.user.upsert({
    where: { phoneNumber: '+966500000001' },
    update: {},
    create: {
      phoneNumber: '+966500000001',
      fullName: 'إدارة منصة ترحيل (Admin)',
      email: 'admin@tarheel.app',
      role: Role.ADMIN,
    },
  });
  console.log(`✅ Admin user seeded: ${admin.fullName} (${admin.phoneNumber})`);

  // 2. Create Approved Driver with Vehicle and Bank Account
  const driverUser1 = await prisma.user.upsert({
    where: { phoneNumber: '+966551112233' },
    update: {},
    create: {
      phoneNumber: '+966551112233',
      fullName: 'سالم بن فهد الدوسري',
      email: 'salem@tarheel.app',
      role: Role.DRIVER,
    },
  });

  const driverProfile1 = await prisma.driverProfile.upsert({
    where: { userId: driverUser1.id },
    update: {},
    create: {
      userId: driverUser1.id,
      nationalId: '1089345612',
      idCardPhotoUrl: '/uploads/demo_id_card.jpg',
      driverLicenseUrl: '/uploads/demo_license.jpg',
      vehicleRegistrationUrl: '/uploads/demo_registration.jpg',
      bankName: 'مصرف الراجحي',
      iban: 'SA0380000000608010167519',
      bankAccountHolderName: 'سالم فهد الدوسري',
      bankCertificatePdfUrl: '/uploads/demo_iban_certificate.pdf',
      verificationStatus: VerificationStatus.APPROVED,
      approvedAt: new Date(),
      ratingAverage: 4.95,
      totalRatingsCount: 28,
      totalTripsCount: 30,
      walletBalance: 4500.0,
      pendingEscrowBalance: 0.0,
      agreedToAntiCashPolicyAt: new Date(),
    },
  });

  const vehicle1 = await prisma.vehicle.upsert({
    where: { driverProfileId: driverProfile1.id },
    update: {},
    create: {
      driverProfileId: driverProfile1.id,
      brand: 'تويوتا',
      model: 'كامري GLE',
      year: 2023,
      plateNumber: 'ط ر ح 2026',
      capacity: 4,
      isAirConditioned: true,
      photoFrontUrl: '/uploads/demo_camry_front.jpg',
      photoBackUrl: '/uploads/demo_camry_back.jpg',
      photoRightUrl: '/uploads/demo_camry_right.jpg',
      photoLeftUrl: '/uploads/demo_camry_left.jpg',
      photoInteriorUrl: '/uploads/demo_camry_interior.jpg',
    },
  });
  console.log(`✅ Approved Driver seeded: ${driverUser1.fullName} with Bank (${driverProfile1.bankName} - ${driverProfile1.iban})`);

  // 3. Create Pending Driver
  const driverUser2 = await prisma.user.upsert({
    where: { phoneNumber: '+966559998877' },
    update: {},
    create: {
      phoneNumber: '+966559998877',
      fullName: 'خالد بن محمد الشمري',
      email: 'khaled@tarheel.app',
      role: Role.DRIVER,
    },
  });

  const driverProfile2 = await prisma.driverProfile.upsert({
    where: { userId: driverUser2.id },
    update: {},
    create: {
      userId: driverUser2.id,
      nationalId: '1044789123',
      idCardPhotoUrl: '/uploads/demo_id2.jpg',
      driverLicenseUrl: '/uploads/demo_license2.jpg',
      vehicleRegistrationUrl: '/uploads/demo_registration2.jpg',
      bankName: 'البنك الأهلي السعودي',
      iban: 'SA1210000001234567890123',
      bankAccountHolderName: 'خالد محمد الشمري',
      bankCertificatePdfUrl: '/uploads/demo_iban_certificate2.pdf',
      verificationStatus: VerificationStatus.PENDING,
      ratingAverage: 5.0,
      totalRatingsCount: 0,
      totalTripsCount: 0,
      walletBalance: 0.0,
      pendingEscrowBalance: 0.0,
      agreedToAntiCashPolicyAt: new Date(),
    },
  });

  await prisma.vehicle.upsert({
    where: { driverProfileId: driverProfile2.id },
    update: {},
    create: {
      driverProfileId: driverProfile2.id,
      brand: 'هيونداي',
      model: 'النترا سمارت',
      year: 2024,
      plateNumber: 'س ع د 7788',
      capacity: 4,
      isAirConditioned: true,
      photoFrontUrl: '/uploads/demo_elantra_front.jpg',
      photoBackUrl: '/uploads/demo_elantra_back.jpg',
      photoRightUrl: '/uploads/demo_elantra_right.jpg',
      photoLeftUrl: '/uploads/demo_elantra_left.jpg',
      photoInteriorUrl: '/uploads/demo_elantra_interior.jpg',
    },
  });
  console.log(`✅ Pending Driver seeded: ${driverUser2.fullName}`);

  // 4. Create Client User
  const client = await prisma.user.upsert({
    where: { phoneNumber: '+966501234567' },
    update: {},
    create: {
      phoneNumber: '+966501234567',
      fullName: 'أحمد بن عبدالله التميمي',
      email: 'ahmed@client.com',
      role: Role.CLIENT,
    },
  });
  console.log(`✅ Client user seeded: ${client.fullName} (${client.phoneNumber})`);

  // 5. Create Sample Trip Request
  const trip = await prisma.tripRequest.create({
    data: {
      clientId: client.id,
      pickupAddress: 'حي النرجس، شمال الرياض',
      pickupLatitude: 24.82345,
      pickupLongitude: 46.68345,
      dropoffAddress: 'جامعة الملك سعود، مبنى كلية الهندسة',
      dropoffLatitude: 24.71612,
      dropoffLongitude: 46.61891,
      startDate: new Date('2026-09-10T07:30:00Z'),
      preferredTime: '07:30',
      hasReturn: true,
      returnTime: '15:30',
      frequency: Frequency.MONTHLY,
      recurringDays: 'الأحد,الاثنين,الثلاثاء,الأربعاء,الخميس',
      passengersCount: 1,
      notes: 'مشوار جامعي شهري مستمر من الأحد للخميس، يرجى الالتزام الصارم بمواعيد الذهاب والعودة.',
      status: TripStatus.OPEN_FOR_BIDS,
    },
  });
  console.log(`✅ Trip Request seeded: ID ${trip.id}`);

  // 6. Create Initial Offer from Driver 1
  const offer = await prisma.tripOffer.create({
    data: {
      tripRequestId: trip.id,
      driverProfileId: driverProfile1.id,
      offerPrice: 1200.0,
      driverNotes: 'سيارة تويوتا كامري 2023 حديثة ومكيفة، جاهز للالتزام بالمواعيد 7:30 صباحاً و 3:30 عصراً طوال الشهر.',
      status: OfferStatus.PENDING,
    },
  });
  console.log(`✅ Driver Offer seeded: ID ${offer.id} (Base Price: ${offer.offerPrice} SAR -> With 15% VAT: 1380 SAR)`);

  console.log('🎉 Tarheel Database Seed Completed Successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Error during database seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
