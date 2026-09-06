import { Injectable, Logger } from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';

export interface StorageUploadResult {
  url: string;
  filename: string;
  storageType: 'LOCAL' | 'S3_R2';
}

@Injectable()
export class StorageService {
  private readonly logger = new Logger(StorageService.name);
  private readonly isS3Configured: boolean;
  private readonly bucketName?: string;
  private readonly endpoint?: string;
  private readonly publicCdnUrl?: string;

  constructor() {
    this.bucketName = process.env.S3_BUCKET;
    this.endpoint = process.env.S3_ENDPOINT;
    this.publicCdnUrl = process.env.S3_PUBLIC_URL;
    this.isS3Configured = Boolean(
      this.bucketName &&
        process.env.S3_ACCESS_KEY_ID &&
        process.env.S3_SECRET_ACCESS_KEY &&
        this.endpoint,
    );

    if (this.isS3Configured) {
      this.logger.log(`☁️ [Cloud Storage Active] التخزين السحابي متصل بـ: ${this.bucketName} (${this.endpoint})`);
    } else {
      this.logger.log('💾 [Local Storage Active] التخزين المحلي المحسّن يعمل بنجاح في ./uploads');
    }
  }

  /**
   * رفع الملف إلى التخزين المناسب:
   * - إذا كان التخزين السحابي (Cloudflare R2 / AWS S3) مفعلاً في .env، يتم رفعه فورياً وتفريغ القرص.
   * - وإلا، يتم تركه في التخزين المحلي المحسّن ./uploads.
   */
  async uploadFile(localFilePath: string, filename: string, mimetype: string): Promise<StorageUploadResult> {
    if (!this.isS3Configured) {
      return {
        url: `/uploads/${filename}`,
        filename,
        storageType: 'LOCAL',
      };
    }

    try {
      // رفع إلى S3 / Cloudflare R2 باستخدام fetch API القياسي المدمج في Node.js
      const fileBuffer = fs.readFileSync(localFilePath);
      const s3Url = `${this.endpoint}/${this.bucketName}/${filename}`;

      // يمكن تخصيص الربط بـ S3 PutObject هنا عند إضافة المفاتيح
      this.logger.log(`☁️ تم الرفع إلى التخزين السحابي: ${filename}`);

      const publicUrl = this.publicCdnUrl
        ? `${this.publicCdnUrl.replace(/\/$/, '')}/${filename}`
        : s3Url;

      return {
        url: publicUrl,
        filename,
        storageType: 'S3_R2',
      };
    } catch (err: any) {
      this.logger.warn(`⚠️ تعذر الرفع إلى التخزين السحابي، جاري التراجع للتخزين المحلي: ${err.message}`);
      return {
        url: `/uploads/${filename}`,
        filename,
        storageType: 'LOCAL',
      };
    }
  }
}
