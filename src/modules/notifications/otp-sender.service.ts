import { Injectable, Logger } from '@nestjs/common';
import * as nodemailer from 'nodemailer';

export type OtpChannel = 'SMS' | 'WHATSAPP' | 'EMAIL';

@Injectable()
export class OtpSenderService {
  private readonly logger = new Logger(OtpSenderService.name);
  private mailTransporter: nodemailer.Transporter | null = null;

  constructor() {
    this.initMailTransporter();
  }

  private initMailTransporter() {
    const host = process.env.SMTP_HOST;
    const port = Number(process.env.SMTP_PORT) || 587;
    const user = process.env.SMTP_USER;
    const pass = process.env.SMTP_PASS;

    if (host && user && pass) {
      this.mailTransporter = nodemailer.createTransport({
        host,
        port,
        secure: port === 465,
        auth: { user, pass },
      });
      this.logger.log(`SMTP Mail Transporter initialized with sender: ${process.env.EMAIL_FROM || user}`);
    } else {
      this.logger.warn('SMTP credentials not provided in .env. Email OTP will run in logging/dev mode.');
    }
  }

  /**
   * إرسال رمز التحقق عبر الواتساب (WhatsApp OTP)
   * يدعم Meta WhatsApp Cloud API أو بوابات التراسل (Taqnyat/Twilio/Unifonic)
   */
  async sendWhatsAppOtp(phoneNumber: string, otpCode: string): Promise<boolean> {
    const gatewayUrl = process.env.WHATSAPP_GATEWAY_URL;
    const whatsappApiUrl = process.env.WHATSAPP_API_URL;
    const whatsappToken = process.env.WHATSAPP_API_TOKEN;
    const whatsappPhoneNumberId = process.env.WHATSAPP_PHONE_NUMBER_ID;

    this.logger.log(`[WHATSAPP OTP] Sending code [${otpCode}] to [${phoneNumber}]`);

    // 1. Try Self-Hosted WhatsApp Gateway if configured
    if (gatewayUrl) {
      try {
        const response = await fetch(`${gatewayUrl}/send`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            to: phoneNumber,
            message: `🚗 منصة تـرحـيـل (Tarheel)\n\nرمز التحقق الخاص بك هو:\n*${otpCode}*\n\nصالح لمدة 10 دقائق. لا تشارك هذا الرمز مع أحد.`,
          }),
        });

        const resData = await response.json();
        if (response.ok && resData.success) {
          this.logger.log(`✅ [Self-Hosted Gateway] WhatsApp OTP sent successfully to ${phoneNumber}`);
          return true;
        } else {
          this.logger.warn(`WhatsApp Gateway response: ${JSON.stringify(resData)}`);
        }
      } catch (err) {
        this.logger.warn(`Failed to send via Self-Hosted WhatsApp Gateway: ${err.message}`);
      }
    }

    // 2. Fallback to Meta Cloud API if available
    if (whatsappApiUrl && whatsappToken && whatsappPhoneNumberId) {
      try {
        const cleanPhone = phoneNumber.replace(/[^0-9]/g, '');
        const endpoint = `${whatsappApiUrl}/${whatsappPhoneNumberId}/messages`;

        const response = await fetch(endpoint, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${whatsappToken}`,
          },
          body: JSON.stringify({
            messaging_product: 'whatsapp',
            recipient_type: 'individual',
            to: cleanPhone,
            type: 'text',
            text: {
              preview_url: false,
              body: `🚗 منصة تـرحـيـل (Tarheel)\n\nرمز التحقق الخاص بك هو:\n*${otpCode}*\n\nصالح لمدة 10 دقائق. لا تشارك هذا الرمز مع أحد.`,
            },
          }),
        });

        const resData = await response.json();
        if (response.ok) {
          this.logger.log(`✅ [Meta Cloud API] WhatsApp OTP sent successfully to ${phoneNumber}`);
          return true;
        }
      } catch (error) {
        this.logger.error(`Failed to send WhatsApp OTP via Meta: ${error.message}`);
      }
    }

    this.logger.log(`[DEV MODE] WhatsApp message simulated. Code: ${otpCode} for ${phoneNumber}`);
    return true;
  }

  /**
   * إرسال رمز التحقق عبر البريد الإلكتروني (Email OTP)
   */
  async sendEmailOtp(toEmail: string, otpCode: string, userName?: string): Promise<boolean> {
    const fromEmail = process.env.EMAIL_FROM || 'no-reply@tarheel.app';
    const appName = 'منصة ترحيل (Tarheel)';

    this.logger.log(`[EMAIL OTP] Sending code [${otpCode}] to [${toEmail}]`);

    const htmlContent = `
      <div dir="rtl" style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f8fafc; padding: 30px; text-align: right; color: #1e293b;">
        <div style="max-width: 500px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; padding: 30px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);">
          <div style="text-align: center; margin-bottom: 20px;">
            <h2 style="color: #0f172a; margin: 0;">🚗 منصة ترحيل</h2>
            <p style="color: #64748b; font-size: 14px; margin-top: 5px;">لتوصيل الركاب والمشاوير المجدولة</p>
          </div>
          <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 20px 0;" />
          <p style="font-size: 16px; margin-bottom: 10px;">مرحباً ${userName || 'عزيزنا العميل'}،</p>
          <p style="font-size: 14px; color: #475569; line-height: 1.6;">
            استخدم رمز التحقق التالي لتسجيل الدخول إلى حسابك في ترحيل. هذا الرمز صالح لمدة 10 دقائق:
          </p>
          <div style="background-color: #f1f5f9; border-radius: 8px; text-align: center; padding: 15px; margin: 25px 0;">
            <span style="font-size: 32px; font-weight: bold; letter-spacing: 6px; color: #0284c7;">${otpCode}</span>
          </div>
          <p style="font-size: 12px; color: #94a3b8; text-align: center; margin-top: 20px;">
            ⚠️ تنبيه أمني: لا تشارك هذا الرمز مع أي شخص. فريق ترحيل لن يطلب منك هذا الرمز أبداً.
          </p>
        </div>
      </div>
    `;

    if (this.mailTransporter) {
      try {
        await this.mailTransporter.sendMail({
          from: `"${appName}" <${fromEmail}>`,
          to: toEmail,
          subject: `${otpCode} هو رمز التحقق الخاص بك في ترحيل`,
          html: htmlContent,
        });
        this.logger.log(`✅ Email OTP sent successfully to ${toEmail}`);
        return true;
      } catch (error) {
        this.logger.error(`Failed to send Email OTP: ${error.message}`);
        return false;
      }
    } else {
      this.logger.log(`[DEV MODE] Email OTP simulated. Code: ${otpCode} for ${toEmail}`);
      return true;
    }
  }

  /**
   * إرسال رمز التحقق عبر SMS (Taqnyat / Unifonic)
   */
  async sendSmsOtp(phoneNumber: string, otpCode: string): Promise<boolean> {
    const smsApiKey = process.env.TAQNYAT_API_KEY || process.env.SMS_API_KEY;
    const smsSender = process.env.SMS_SENDER_NAME || 'Tarheel';

    this.logger.log(`[SMS OTP] Sending code [${otpCode}] to [${phoneNumber}]`);

    if (smsApiKey) {
      try {
        // Taqnyat SMS Gateway Integration
        const response = await fetch('https://api.taqnyat.sa/v1/messages', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${smsApiKey}`,
          },
          body: JSON.stringify({
            recipients: [phoneNumber],
            sender: smsSender,
            body: `رمز التحقق الخاص بك في منصة ترحيل هو: ${otpCode}`,
          }),
        });

        if (response.ok) {
          this.logger.log(`✅ SMS OTP sent successfully to ${phoneNumber}`);
          return true;
        }
        return false;
      } catch (error) {
        this.logger.error(`Failed to send SMS OTP: ${error.message}`);
        return false;
      }
    } else {
      this.logger.log(`[DEV MODE] SMS OTP simulated. Code: ${otpCode} for ${phoneNumber}`);
      return true;
    }
  }
}
