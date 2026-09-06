import { Injectable, Logger } from '@nestjs/common';
import * as path from 'path';
import * as fs from 'fs';
const sharp = require('sharp');

export interface OptimizedFileResult {
  filename: string;
  originalName: string;
  url: string;
  mimetype: string;
  size: number;
  isCompressed: boolean;
}

@Injectable()
export class UploadsOptimizerService {
  private readonly logger = new Logger(UploadsOptimizerService.name);
  private readonly uploadDirectory = './uploads';

  constructor() {
    if (!fs.existsSync(this.uploadDirectory)) {
      fs.mkdirSync(this.uploadDirectory, { recursive: true });
    }
  }

  /**
   * ضغط وتحسين أي ملف مرفوع تلقائياً:
   * - إذا كان صورة (JPG, PNG, WebP): يتم تصغير أبعادها إلى 1280px كحد أقصى، وتحويلها إلى WebP بنقاء 80%، وحذف الملف الأصلي الضخم.
   * - إذا كان مستنداً أو صوتاً (PDF, MP3, M4A): يُترك كما هو دون المساس به.
   */
  async optimizeFile(file: Express.Multer.File): Promise<OptimizedFileResult> {
    const isImage = file.mimetype.startsWith('image/') || /\.(jpe?g|png|webp|bmp|tiff)$/i.test(file.originalname);

    if (!isImage) {
      return {
        filename: file.filename,
        originalName: file.originalname,
        url: `/uploads/${file.filename}`,
        mimetype: file.mimetype,
        size: file.size,
        isCompressed: false,
      };
    }

    try {
      const originalPath = file.path;
      const parsed = path.parse(file.filename);
      const webpFilename = `${parsed.name}.webp`;
      const webpPath = path.join(this.uploadDirectory, webpFilename);

      const beforeSize = fs.existsSync(originalPath) ? fs.statSync(originalPath).size : file.size;

      // ضغط وتحويل الصورة إلى WebP
      await sharp(originalPath)
        .rotate() // تصحيح اتجاه الصورة تلقائياً حسب حساس الكاميرا
        .resize({
          width: 1280,
          height: 1280,
          fit: 'inside',
          withoutEnlargement: true,
        })
        .webp({ quality: 80, effort: 4 })
        .toFile(webpPath);

      const afterSize = fs.statSync(webpPath).size;
      const savedRatio = Math.round(((beforeSize - afterSize) / beforeSize) * 100);

      this.logger.log(
        `⚡ [Image Auto-Compressed] ${file.originalname}: ${(beforeSize / 1024).toFixed(1)} KB ➔ ${(afterSize / 1024).toFixed(1)} KB (وفرت مساحة: ${savedRatio}%)`,
      );

      // حذف الملف الأصلي غير المضغوط إذا كان مختلفاً عن ملف webp
      if (originalPath !== webpPath && fs.existsSync(originalPath)) {
        fs.unlinkSync(originalPath);
      }

      return {
        filename: webpFilename,
        originalName: file.originalname,
        url: `/uploads/${webpFilename}`,
        mimetype: 'image/webp',
        size: afterSize,
        isCompressed: true,
      };
    } catch (err: any) {
      this.logger.warn(`⚠️ تعذر ضغط الصورة ${file.originalname}، سيتم الاحتفاظ بالملف الأصلي: ${err.message}`);
      return {
        filename: file.filename,
        originalName: file.originalname,
        url: `/uploads/${file.filename}`,
        mimetype: file.mimetype,
        size: file.size,
        isCompressed: false,
      };
    }
  }

  /**
   * معالجة مجموعة صور زوايا المركبة دفعة واحدة
   */
  async optimizeFiles(files: Express.Multer.File[]): Promise<OptimizedFileResult[]> {
    return Promise.all(files.map((f) => this.optimizeFile(f)));
  }
}
