import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationType } from '@prisma/client';
import { NotificationsGateway } from './notifications.gateway';
import { OtpSenderService } from './otp-sender.service';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private prisma: PrismaService,
    private gateway: NotificationsGateway,
    private otpSender: OtpSenderService,
  ) {}

  async createNotification(
    userId: string,
    title: string,
    message: string,
    type: NotificationType,
    metadata?: any,
  ) {
    const notification = await this.prisma.notification.create({
      data: {
        userId,
        title,
        message,
        type,
        metadata: metadata ? JSON.stringify(metadata) : null,
      },
    });

    return notification;
  }

  async getUserNotifications(userId: string) {
    return this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }

  async markAsRead(id: string, userId: string) {
    return this.prisma.notification.updateMany({
      where: { id, userId },
      data: { isRead: true },
    });
  }

  /**
   * إشعار متعدد القنوات للعميل عند استلام عرض جديد (In-App + WhatsApp + Email)
   */
  async notifyClientNewBidMultiChannel(params: {
    client: { id: string; fullName: string; phoneNumber?: string | null; email?: string | null };
    trip: { id: string; pickupAddress: string; dropoffAddress: string };
    driver: { fullName: string; ratingAverage?: number; totalTrips?: number };
    vehicle: {
      fullName: string;
      brand?: string;
      model?: string;
      year?: string | number;
      plateNumber?: string;
      photoFrontUrl?: string | null;
      photoInteriorUrl?: string | null;
      isAirConditioned?: boolean;
      capacity?: number;
    };
    offerPrice: number;
    offerId: string;
  }) {
    const { client, trip, driver, vehicle, offerPrice, offerId } = params;
    const appBaseUrl = process.env.FRONTEND_APP_URL || 'http://localhost:8085';
    const appOfferUrl = `${appBaseUrl}/#/offers?tripId=${trip.id}`;
    const baseDomain = process.env.API_BASE_URL || 'http://localhost:3000';
    const interiorPhoto = vehicle.photoInteriorUrl || vehicle.photoFrontUrl;
    const fullPhotoInteriorUrl = interiorPhoto
      ? (interiorPhoto.startsWith('http') ? interiorPhoto : `${baseDomain}${interiorPhoto}`)
      : null;

    const notifTitle = `🚗 تلقيت عرض سعر جديد بقيمة ${offerPrice} ر.س!`;
    const notifMessage = `قدم الكابتن ${driver.fullName} عرضاً بقيمة ${offerPrice} ر.س بسيارة (${vehicle.fullName}) لمشوارك من ${trip.pickupAddress} إلى ${trip.dropoffAddress}. اضغط لمعاينة مقصورة السيارة من الداخل وتفاصيل العرض.`;

    const metadata = {
      tripId: trip.id,
      offerId,
      offerPrice,
      driverName: driver.fullName,
      driverRating: driver.ratingAverage || 5.0,
      totalTrips: driver.totalTrips || 0,
      carFullName: vehicle.fullName,
      carBrand: vehicle.brand || '',
      carModel: vehicle.model || '',
      carYear: vehicle.year || '',
      carPlateNumber: vehicle.plateNumber || '',
      carPhotoInteriorUrl: vehicle.photoInteriorUrl || '',
      carPhotoFrontUrl: '', // محجوبة لحماية خصوصية فحص جوانب السيارة
      isAirConditioned: vehicle.isAirConditioned ?? true,
      carCapacity: vehicle.capacity || 4,
      pickupAddress: trip.pickupAddress,
      dropoffAddress: trip.dropoffAddress,
    };

    // 1. In-App Notification (Database)
    await this.createNotification(
      client.id,
      notifTitle,
      notifMessage,
      NotificationType.BID_RECEIVED,
      metadata,
    );

    // 2. Real-Time WebSocket Notification
    this.gateway.notifyClientNewBid(client.id, metadata);

    // 3. WhatsApp Notification
    if (client.phoneNumber) {
      const waMessage =
        `🚗 *منصة تـرحـيـل (Tarheel)*\n` +
        `السلام عليكم أستاذ/ة ${client.fullName}،\n\n` +
        `وصلك عرض سعر جديد لمشوارك! 🔔\n` +
        `💰 *قيمة العرض:* ${offerPrice} ر.س\n` +
        `👤 *الكابتن:* ${driver.fullName} (⭐ ${driver.ratingAverage || 5.0})\n` +
        `🚘 *المركبة:* ${vehicle.fullName}${vehicle.plateNumber ? ` (${vehicle.plateNumber})` : ''}\n` +
        `📍 *المسار:* من ${trip.pickupAddress} إلى ${trip.dropoffAddress}\n\n` +
        `📸 *معاينة صورة السيارة الأمامية:*\n` +
        `قام الكابتن برفع صورة حية لمركبته للتأكد من نظافتها وجاهزيتها، يمكنك معاينتها وفحص العرض عبر التطبيق:\n` +
        `${appOfferUrl}\n\n` +
        `نتمنى لك رحلة مريحة وآمنة مع ترحيل!`;

      this.otpSender.sendWhatsAppMessage(client.phoneNumber, waMessage).catch((err) => {
        this.logger.warn(`Failed to send WhatsApp offer notice to client ${client.phoneNumber}: ${err.message}`);
      });
    }

    // 4. Email Notification (HTML)
    if (client.email) {
      const emailHtml = `
        <div dir="rtl" style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f1f5f9; padding: 25px; text-align: right; color: #0f172a;">
          <div style="max-width: 580px; margin: 0 auto; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);">
            <div style="background: linear-gradient(135deg, #153364 0%, #1E468A 100%); padding: 24px; text-align: center; color: #ffffff;">
              <h2 style="margin: 0; font-size: 22px;">🚗 منصة تـرحـيـل</h2>
              <p style="margin: 6px 0 0 0; font-size: 14px; opacity: 0.85;">إشعار استلام عرض سعر جديد لمشوارك</p>
            </div>
            <div style="padding: 24px;">
              <p style="font-size: 16px; margin: 0 0 12px 0;">مرحباً <strong>${client.fullName}</strong>،</p>
              <p style="font-size: 14px; color: #475569; line-height: 1.6; margin: 0 0 16px 0;">
                يسعدنا إبلاغك بأن الكابتن <strong>${driver.fullName}</strong> قد قدّم عرض سعر لمشوارك.
              </p>

              <!-- Price Box -->
              <div style="background-color: #eff6ff; border: 1.5px solid #bfdbfe; border-radius: 12px; padding: 16px; text-align: center; margin-bottom: 20px;">
                <span style="font-size: 13px; color: #1e40af; font-weight: bold; display: block; margin-bottom: 4px;">قيمة العرض المقدم</span>
                <span style="font-size: 30px; font-weight: 900; color: #153364;">${offerPrice} <span style="font-size: 18px;">ر.س</span></span>
              </div>

              <!-- Vehicle & Driver Card -->
              <div style="background-color: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding: 16px; margin-bottom: 20px;">
                <h4 style="margin: 0 0 12px 0; color: #153364; font-size: 15px;">🚘 بيانات الكابتن والمركبة:</h4>
                <p style="margin: 6px 0; font-size: 13px;"><strong>الكابتن:</strong> ${driver.fullName} (⭐ ${driver.ratingAverage || 5.0})</p>
                <p style="margin: 6px 0; font-size: 13px;"><strong>نوع السيارة:</strong> ${vehicle.fullName}</p>
                ${vehicle.plateNumber ? `<p style="margin: 6px 0; font-size: 13px;"><strong>رقم اللوحة:</strong> ${vehicle.plateNumber}</p>` : ''}
                <p style="margin: 6px 0; font-size: 13px;"><strong>المسار:</strong> من ${trip.pickupAddress} إلى ${trip.dropoffAddress}</p>
              </div>

              ${
                fullPhotoInteriorUrl
                  ? `
              <!-- Car Interior Photo Preview -->
              <div style="margin-bottom: 24px; text-align: center;">
                <p style="font-size: 13px; font-weight: bold; color: #334155; margin-bottom: 8px;">💺 معاينة مقصورة السيارة والفرش الداخلي:</p>
                <img src="${fullPhotoInteriorUrl}" alt="صورة مقصورة السيارة من الداخل" style="max-width: 100%; height: 200px; object-fit: cover; border-radius: 10px; border: 1px solid #cbd5e1;" />
              </div>
              `
                  : ''
              }

              <!-- CTA Button -->
              <div style="text-align: center; margin: 25px 0 10px 0;">
                <a href="${appOfferUrl}" style="background-color: #F15A24; color: #ffffff; text-decoration: none; padding: 14px 28px; border-radius: 10px; font-weight: bold; font-size: 15px; display: inline-block;">
                  معاينة العرض ومقصورة السيارة في التطبيق ⬅️
                </a>
              </div>
            </div>
            <div style="background-color: #f8fafc; padding: 14px; text-align: center; font-size: 11px; color: #94a3b8; border-top: 1px solid #e2e8f0;">
              منصة ترحيل © 2026 - جميع الحقوق محفوظة | مشاويرك مؤمنة بالكامل بالضمان المالي
            </div>
          </div>
        </div>
      `;

      this.otpSender
        .sendEmailNotification(client.email, notifTitle, emailHtml)
        .catch((err) => {
          this.logger.warn(`Failed to send email offer notice to client ${client.email}: ${err.message}`);
        });
    }
  }

  /**
   * إشعار متعدد القنوات للسائق عند قبول العرض (In-App + WhatsApp + Email)
   */
  async notifyDriverBidAcceptedMultiChannel(params: {
    driver: { id: string; fullName: string; phoneNumber?: string | null; email?: string | null; bankName?: string };
    client: { fullName: string; phoneNumber?: string | null };
    trip: { id: string; pickupAddress: string; dropoffAddress: string; preferredTime?: string };
    contractId: string;
    baseAmount: number;
    driverEarnings: number;
  }) {
    const { driver, client, trip, contractId, baseAmount, driverEarnings } = params;
    const appBaseUrl = process.env.FRONTEND_APP_URL || 'http://localhost:8085';
    const appScheduleUrl = `${appBaseUrl}/#/driver/schedule`;

    const preferredTime = trip.preferredTime || 'في الموعد المحدد';
    const notifTitle = `🎉 مبارك! وافق العميل على عرضك السعري (${baseAmount} ر.س)`;
    const notifMessage =
      `تهانينا كابتن! لقد وافق العميل ${client.fullName} على عرضك لمشوار من (${trip.pickupAddress}) إلى (${trip.dropoffAddress}) بقيمة (${baseAmount} ر.س).\n\n` +
      `📌 توجيهات مهمة لرحلة مميزة:\n` +
      `1️⃣ احترام مواعيد العمل: يرجى التواجد في الموعد المحدد بدقة (${preferredTime}) والالتزام التام بوقت العميل.\n` +
      `2️⃣ نظافة السيارة: تأكد من نظافة المركبة داخلياً وخارجياً وتوفير بيئة مريحة ومكيفة للراكب.\n` +
      `3️⃣ التعامل الأخلاقي والراقي: عامل العميل بأخلاق فاضلة ولباقة، فالتعامل الحسن يرفع تقييمك (5 نجوم) ويضمن لك الأولوية في استقبال عروض ومشاريع جديدة مستقبلاً.\n` +
      `4️⃣ جدول العمل اليومي: تم إضافة هذا المشوار رسمياً إلى جدول عملك اليومي على منصة ترحيل.\n\n` +
      `💰 مستحقاتك الصافية: ${driverEarnings} ر.س (بعد خصم 13.50% عمولة ترحيل) سيتم إيداعها بحسابك (${driver.bankName || 'البنكي'}) بعد إتمام الرحلة.`;

    const metadata = {
      contractId,
      tripId: trip.id,
      pickup: trip.pickupAddress,
      dropoff: trip.dropoffAddress,
      baseAmount,
      driverEarnings,
      preferredTime,
    };

    // 1. In-App Notification (Database)
    await this.createNotification(
      driver.id,
      notifTitle,
      notifMessage,
      NotificationType.BID_ACCEPTED,
      metadata,
    );

    // 2. Real-Time WebSocket Notification
    this.gateway.notifyDriverBidAccepted(driver.id, {
      title: notifTitle,
      message: notifMessage,
      ...metadata,
    });

    // 3. WhatsApp Notification to Driver
    if (driver.phoneNumber) {
      const waMessage =
        `🎉 *مبارك يا كابتن ${driver.fullName}!*\n` +
        `وافق العميل ${client.fullName} على عرضك السعري لمشوار ترحيل.\n\n` +
        `📍 *نقطة الانطلاق:* ${trip.pickupAddress}\n` +
        `📍 *نقطة الوصول:* ${trip.dropoffAddress}\n` +
        `⏰ *الموعد المحدد:* ${preferredTime}\n\n` +
        `💰 *تفاصيل المستحقات المالية:*\n` +
        `- قيمة المشوار الأساسية: ${baseAmount} ر.س\n` +
        `- عمولة ترحيل: 13.50%\n` +
        `- *صافي أرباحك المقدرة:* ${driverEarnings} ر.س (تودع في حسابك ${driver.bankName || 'البنكي'})\n\n` +
        `📌 *توجيهات منصة ترحيل لنجاح الرحلة ورفع تقييمك:*\n` +
        `1️⃣ *احترام مواعيد العمل:* الالتزام الصارم بموعد المشوار وموقع الانطلاق بدقة.\n` +
        `2️⃣ *نظافة السيارة:* التأكد من نظافة المركبة داخلياً وخارجياً وكفاءة التكييف.\n` +
        `3️⃣ *التعامل الراقي بالأخلاق الحسنة:* حسن الخلق يرفع تقييمك (5 نجوم) ويمنحك الأولوية في استقبال مشاريع جديدة.\n` +
        `4️⃣ *جدول عملك اليومي:* تمت إضافة المشوار تلقائياً إلى جدول عملك اليومي على المنصة.\n\n` +
        `للإطلاع على تفاصيل المشوار في جدولك والتواصل مع العميل:\n` +
        `${appScheduleUrl}\n\n` +
        `تمنياتنا لك برحلة موفقة وآمنة!`;

      this.otpSender.sendWhatsAppMessage(driver.phoneNumber, waMessage).catch((err) => {
        this.logger.warn(`Failed to send WhatsApp acceptance notice to driver ${driver.phoneNumber}: ${err.message}`);
      });
    }

    // 4. Email Notification to Driver (HTML)
    if (driver.email) {
      const emailHtml = `
        <div dir="rtl" style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f1f5f9; padding: 25px; text-align: right; color: #0f172a;">
          <div style="max-width: 580px; margin: 0 auto; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);">
            <div style="background: linear-gradient(135deg, #065F46 0%, #059669 100%); padding: 24px; text-align: center; color: #ffffff;">
              <h2 style="margin: 0; font-size: 22px;">🎉 مبارك يا كابتن!</h2>
              <p style="margin: 6px 0 0 0; font-size: 14px; opacity: 0.9;">وافق العميل على عرضك السعري لمشواره</p>
            </div>
            <div style="padding: 24px;">
              <p style="font-size: 16px; margin: 0 0 12px 0;">أهلاً بك كابتن <strong>${driver.fullName}</strong>،</p>
              <p style="font-size: 14px; color: #475569; line-height: 1.6; margin: 0 0 16px 0;">
                يسرنا إبلاغك بأن العميل <strong>${client.fullName}</strong> قد وافق رسمياً على عرضك السعري لمشواره.
              </p>

              <!-- Financial Box -->
              <div style="background-color: #ecfdf5; border: 1.5px solid #a7f3d0; border-radius: 12px; padding: 16px; margin-bottom: 20px;">
                <div style="display: flex; justify-content: space-between; margin-bottom: 6px; font-size: 13px; color: #065f46;">
                  <span>قيمة المشوار الأساسية:</span>
                  <strong>${baseAmount} ر.س</strong>
                </div>
                <div style="display: flex; justify-content: space-between; margin-bottom: 8px; font-size: 13px; color: #065f46;">
                  <span>عمولة منصة ترحيل (13.50%):</span>
                  <span>-${(baseAmount - driverEarnings).toFixed(2)} ر.س</span>
                </div>
                <hr style="border: none; border-top: 1px dashed #6ee7b7; margin: 8px 0;" />
                <div style="display: flex; justify-content: space-between; font-size: 16px; color: #064e3b; font-weight: bold;">
                  <span>صافي مستحقاتك المحولة:</span>
                  <span style="font-size: 20px; color: #059669;">${driverEarnings} ر.س</span>
                </div>
              </div>

              <!-- Guidelines Box -->
              <div style="background-color: #fffbeb; border: 1px solid #fde68a; border-radius: 12px; padding: 18px; margin-bottom: 20px;">
                <h4 style="margin: 0 0 10px 0; color: #92400e; font-size: 14px;">📌 توجيهات هامة لرحلة ممتازة ورفع تقييمك:</h4>
                <ul style="margin: 0; padding-right: 20px; font-size: 13px; color: #78350f; line-height: 1.8;">
                  <li><strong>احترام مواعيد العمل:</strong> الالتزام الصارم بالموعد المحدد (${preferredTime}) والتواجد في موقع الانطلاق بدقة.</li>
                  <li><strong>نظافة السيارة:</strong> التأكد التام من نظافة المركبة داخلياً وخارجياً وتجهيز التكييف لراحة الراكب.</li>
                  <li><strong>معاملة العميل بأخلاق حسنة:</strong> اللباقة وحسن المعاملة تضمن لك تقييم 5 نجوم وأولوية استقبال مشاريع جديدة.</li>
                  <li><strong>جدول عملك اليومي:</strong> تم إضافة هذا المشوار رسمياً في جدول عملك اليومي على المنصة.</li>
                </ul>
              </div>

              <!-- CTA Button -->
              <div style="text-align: center; margin: 25px 0 10px 0;">
                <a href="${appScheduleUrl}" style="background-color: #153364; color: #ffffff; text-decoration: none; padding: 14px 28px; border-radius: 10px; font-weight: bold; font-size: 15px; display: inline-block;">
                  عرض تفاصيل الرحلة في جدول عملي اليومي ⬅️
                </a>
              </div>
            </div>
            <div style="background-color: #f8fafc; padding: 14px; text-align: center; font-size: 11px; color: #94a3b8; border-top: 1px solid #e2e8f0;">
              منصة ترحيل © 2026 - تمنياتنا لك برحلة موفقة وآمنة
            </div>
          </div>
        </div>
      `;

      this.otpSender
        .sendEmailNotification(driver.email, notifTitle, emailHtml)
        .catch((err) => {
          this.logger.warn(`Failed to send email acceptance notice to driver ${driver.email}: ${err.message}`);
        });
    }
  }
}
