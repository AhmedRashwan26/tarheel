import { PrismaClient, Role } from '@prisma/client';
import * as fs from 'fs';
import * as path from 'path';

const prisma = new PrismaClient();

async function main() {
  console.log('\n==================================================================');
  console.log('🧹 [TARHEEL PRODUCTION PURGE] بدء تنظيف وتصفير قاعدة البيانات للإنتاج');
  console.log('==================================================================\n');

  // 1. أخذ نسخة احتياطية آمنة (Safety JSON Backup) قبل التصفير
  const backupDir = path.join(process.cwd(), 'backups');
  if (!fs.existsSync(backupDir)) {
    fs.mkdirSync(backupDir, { recursive: true });
  }

  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const backupFile = path.join(backupDir, `backup_before_purge_${timestamp}.json`);

  console.log('📦 [1/4] جاري إنشاء نسخة احتياطية آمنة من البيانات الحالية...');
  try {
    const existingData = {
      timestamp: new Date().toISOString(),
      usersCount: await prisma.user.count(),
      tripsCount: await prisma.tripRequest.count(),
      contractsCount: await prisma.tripContract.count(),
      users: await prisma.user.findMany(),
      tripRequests: await prisma.tripRequest.findMany(),
      tripOffers: await prisma.tripOffer.findMany(),
      tripContracts: await prisma.tripContract.findMany(),
    };
    fs.writeFileSync(backupFile, JSON.stringify(existingData, null, 2), 'utf-8');
    console.log(`✅ تم حفظ النسخة الاحتياطية بنجاح في: ${backupFile}`);
  } catch (backupErr) {
    console.warn(`⚠️ تعذر إتمام النسخ الاحتياطي: ${backupErr.message} - جاري المتابعة بحذر.`);
  }

  console.log('\n🗑️ [2/4] جاري حذف كافة السجلات والبيانات التجريبية...');

  // الحذف بالترتيب العكسي للعلاقات لضمان سلامة المفاتيح الخارجية (Foreign Keys)
  const deletedSupportReplies = await prisma.supportReply.deleteMany({});
  console.log(`   - تم حذف ردود الدعم الفني: ${deletedSupportReplies.count}`);

  const deletedSupportTickets = await prisma.supportTicket.deleteMany({});
  console.log(`   - تم حذف تذاكر الدعم الفني: ${deletedSupportTickets.count}`);

  const deletedChatMessages = await prisma.chatMessage.deleteMany({});
  console.log(`   - تم حذف رسائل المحادثات: ${deletedChatMessages.count}`);

  const deletedReviews = await prisma.review.deleteMany({});
  console.log(`   - تم حذف التقييمات: ${deletedReviews.count}`);

  const deletedWalletTx = await prisma.walletTransaction.deleteMany({});
  console.log(`   - تم حذف معاملات المحافظ المالية: ${deletedWalletTx.count}`);

  const deletedNotifications = await prisma.notification.deleteMany({});
  console.log(`   - تم حذف الإشعارات: ${deletedNotifications.count}`);

  const deletedEscrow = await prisma.escrowPayment.deleteMany({});
  console.log(`   - تم حذف عمليات الدفع والضمان: ${deletedEscrow.count}`);

  const deletedContracts = await prisma.tripContract.deleteMany({});
  console.log(`   - تم حذف العقود: ${deletedContracts.count}`);

  const deletedOffers = await prisma.tripOffer.deleteMany({});
  console.log(`   - تم حذف عروض الأسعار: ${deletedOffers.count}`);

  const deletedTrips = await prisma.tripRequest.deleteMany({});
  console.log(`   - تم حذف طلبات الرحلات: ${deletedTrips.count}`);

  const deletedVehicles = await prisma.vehicle.deleteMany({});
  console.log(`   - تم حذف سيارات السائقين التجريبية: ${deletedVehicles.count}`);

  const deletedDriverProfiles = await prisma.driverProfile.deleteMany({});
  console.log(`   - تم حذف ملفات السائقين التجريبية: ${deletedDriverProfiles.count}`);

  // حذف جميع المستخدمين باستثناء حسابات الإدارة الرسمية (ADMIN)
  const deletedUsers = await prisma.user.deleteMany({
    where: {
      role: {
        not: Role.ADMIN,
      },
    },
  });
  console.log(`   - تم حذف المستخدمين التجريبيين (عملاء وسائقين): ${deletedUsers.count}`);

  // 3. التحقق من وجود حساب الإدارة الرسمي (Admin) أو إنشاؤه نظيفاً
  console.log('\n👑 [3/4] التحقق من حساب الإدارة الرسمي (Admin)...');
  const adminPhone = process.env.ADMIN_PHONE || '+966500000001';
  const adminEmail = process.env.ADMIN_EMAIL || 'admin@tarheel.app';

  const admin = await prisma.user.upsert({
    where: { email: adminEmail },
    update: {
      role: Role.ADMIN,
      fullName: 'إدارة منصة ترحيل (Admin)',
      phoneNumber: adminPhone,
      isBlocked: false,
    },
    create: {
      phoneNumber: adminPhone,
      fullName: 'إدارة منصة ترحيل (Admin)',
      email: adminEmail,
      role: Role.ADMIN,
    },
  });
  console.log(`✅ حساب الإدارة الرسمي نشط وجاهز: ${admin.fullName} (${admin.email} / ${admin.phoneNumber})`);

  // 4. إحصائية الجداول بعد التنظيف
  console.log('\n📊 [4/4] حالة قاعدة البيانات بعد التصفير:');
  console.log(`   - إجمالي المستخدمين: ${await prisma.user.count()} (حساب الإدارة فقط)`);
  console.log(`   - إجمالي الرحلات: ${await prisma.tripRequest.count()}`);
  console.log(`   - إجمالي العقود: ${await prisma.tripContract.count()}`);
  console.log(`   - إجمالي السائقين: ${await prisma.driverProfile.count()}`);
  console.log(`   - إجمالي المعاملات المالية: ${await prisma.walletTransaction.count()}`);

  console.log('\n==================================================================');
  console.log('🎉 تم تصفير وتنظيف قاعدة بيانات ترحيل بنجاح 100% وهي جاهزة للإنتاج!');
  console.log('==================================================================\n');
}

main()
  .catch((e) => {
    console.error('❌ حدث خطأ أثناء تصفير قاعدة البيانات:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
