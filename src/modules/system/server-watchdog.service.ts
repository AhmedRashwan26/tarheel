import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import * as os from 'os';
import * as fs from 'fs';
import * as path from 'path';
import { OtpSenderService } from '../notifications/otp-sender.service';

export interface SystemMetrics {
  totalRamMb: number;
  freeRamMb: number;
  usedRamMb: number;
  ramUsagePercent: number;
  totalDiskGb: number;
  freeDiskGb: number;
  usedDiskGb: number;
  diskUsagePercent: number;
  uptimeHours: number;
  nodeVersion: string;
}

@Injectable()
export class ServerWatchdogService {
  private readonly logger = new Logger(ServerWatchdogService.name);
  private lastAlertTimestamp: number = 0;
  private readonly alertCooldownMs = 6 * 60 * 60 * 1000; // تنبيه كل 6 ساعات لتجنب الإزعاج
  private readonly uploadDirectory = './uploads';

  constructor(private readonly otpSenderService: OtpSenderService) {
    this.logger.log('🛡️ [Server Watchdog Active] حارس موارد السيرفر والتنظيف الذاتي يعمل بنجاح');
  }

  /**
   * حساب مقاييس النظام (الرامات والمساحة ووقت التشغيل)
   */
  getSystemMetrics(): SystemMetrics {
    const totalMemBytes = os.totalmem();
    const freeMemBytes = os.freemem();
    const usedMemBytes = totalMemBytes - freeMemBytes;

    const totalRamMb = Math.round(totalMemBytes / (1024 * 1024));
    const freeRamMb = Math.round(freeMemBytes / (1024 * 1024));
    const usedRamMb = Math.round(usedMemBytes / (1024 * 1024));
    const ramUsagePercent = Math.round((usedMemBytes / totalMemBytes) * 100);

    let totalDiskGb = 40;
    let freeDiskGb = 30;
    let usedDiskGb = 10;
    let diskUsagePercent = 25;

    try {
      if (typeof fs.statfsSync === 'function') {
        const stats = fs.statfsSync(process.cwd());
        const totalBytes = stats.bsize * stats.blocks;
        const freeBytes = stats.bsize * stats.bavail;
        const usedBytes = totalBytes - freeBytes;

        totalDiskGb = Number((totalBytes / (1024 ** 3)).toFixed(1));
        freeDiskGb = Number((freeBytes / (1024 ** 3)).toFixed(1));
        usedDiskGb = Number((usedBytes / (1024 ** 3)).toFixed(1));
        diskUsagePercent = Math.round((usedBytes / totalBytes) * 100);
      }
    } catch {
      // Fallback safe values if OS doesn't support statfs
    }

    return {
      totalRamMb,
      freeRamMb,
      usedRamMb,
      ramUsagePercent,
      totalDiskGb,
      freeDiskGb,
      usedDiskGb,
      diskUsagePercent,
      uptimeHours: Number((os.uptime() / 3600).toFixed(1)),
      nodeVersion: process.version,
    };
  }

  /**
   * فحص موارد السيرفر كل 30 دقيقة والتنبيه عبر الواتساب عند تجاوز 80%
   */
  @Cron(CronExpression.EVERY_30_MINUTES)
  async checkServerHealthAndAlert(): Promise<void> {
    const metrics = this.getSystemMetrics();

    this.logger.log(
      `📊 [Server Watchdog] استهلاك الرام: ${metrics.ramUsagePercent}% (${metrics.usedRamMb}/${metrics.totalRamMb} MB) | استهلاك القرص: ${metrics.diskUsagePercent}% (${metrics.usedDiskGb}/${metrics.totalDiskGb} GB)`,
    );

    const isHighRam = metrics.ramUsagePercent >= 80;
    const isHighDisk = metrics.diskUsagePercent >= 80;

    if (isHighRam || isHighDisk) {
      const now = Date.now();
      if (now - this.lastAlertTimestamp < this.alertCooldownMs) {
        this.logger.warn('⚠️ موارد السيرفر مرتفعة ولكن تم إرسال تنبيه مؤخراً (في فترة التهدئة)');
        return;
      }

      this.lastAlertTimestamp = now;
      const adminPhone = process.env.ADMIN_WHATSAPP_PHONE || process.env.WHATSAPP_TEST_PHONE || '966500000001';

      const alertMessage =
        `🚨 *تنبيه ذكي لموارد سيرفر منصة ترحيل*\n\n` +
        `⚠️ تجاوز السيرفر نسبة الاستهلاك الآمنة (80%):\n` +
        `• *الذاكرة العشوائية (RAM):* ${metrics.ramUsagePercent}% مستهلكة (${metrics.usedRamMb} MB من ${metrics.totalRamMb} MB)\n` +
        `• *مساحة القرص (Disk):* ${metrics.diskUsagePercent}% مستهلكة (${metrics.usedDiskGb} GB من ${metrics.totalDiskGb} GB)\n` +
        `• *المتبقي في القرص:* ${metrics.freeDiskGb} GB\n` +
        `• *مدة عمل السيرفر:* ${metrics.uptimeHours} ساعة\n\n` +
        `💡 *الإجراء المقترح:* مراجعة استهلاك العمليات أو الترقية لخطة أعلى عبر لوحة Hetzner بضغطة زر.`;

      this.logger.warn(`🚨 جاري إرسال تنبيه واتساب للمشرف على الرقم: ${adminPhone}`);
      await this.otpSenderService.sendWhatsAppMessage(adminPhone, alertMessage);
    }
  }

  /**
   * التنظيف الذاتي التلقائي فجر كل يوم الساعة 3:00 صباحاً
   * يحذف أي ملفات مؤقتة orphaned .tmp أو تالفة مر عليها أكثر من 24 ساعة
   */
  @Cron(CronExpression.EVERY_DAY_AT_3AM)
  async autoCleanOrphanedFiles(): Promise<void> {
    this.logger.log('🧹 [Auto-Cleanup] بدء مهمة التنظيف الذاتي للملفات المؤقتة القديمة...');

    if (!fs.existsSync(this.uploadDirectory)) return;

    try {
      const files = fs.readdirSync(this.uploadDirectory);
      const now = Date.now();
      const maxAgeMs = 24 * 60 * 60 * 1000; // 24 ساعة
      let deletedCount = 0;
      let freedBytes = 0;

      for (const file of files) {
        const filePath = path.join(this.uploadDirectory, file);
        try {
          const stats = fs.statSync(filePath);
          const isTmp = file.endsWith('.tmp') || file.endsWith('.temp') || stats.size === 0;
          const isOld = now - stats.mtimeMs > maxAgeMs;

          if (isTmp && isOld) {
            freedBytes += stats.size;
            fs.unlinkSync(filePath);
            deletedCount++;
          }
        } catch {
          // Ignore individual file error
        }
      }

      this.logger.log(
        `✅ [Auto-Cleanup Completed] تم تفريغ ${deletedCount} ملف مؤقت مهمل (مساحة محررة: ${(freedBytes / 1024).toFixed(1)} KB)`,
      );
    } catch (err: any) {
      this.logger.warn(`⚠️ حدث خطأ أثناء مهمة التنظيف التلقائي: ${err.message}`);
    }
  }
}
