import {
  Controller,
  Post,
  UploadedFile,
  UploadedFiles,
  UseInterceptors,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor, FileFieldsInterceptor } from '@nestjs/platform-express';
import { ApiTags, ApiOperation, ApiConsumes, ApiBody } from '@nestjs/swagger';
import { diskStorage } from 'multer';
import { extname } from 'path';
import * as path from 'path';
import { existsSync, mkdirSync } from 'fs';
import { Public } from '../../common/decorators/roles.decorator';
import { UploadsOptimizerService } from './uploads-optimizer.service';
import { StorageService } from './storage.service';

const uploadDirectory = './uploads';
if (!existsSync(uploadDirectory)) {
  mkdirSync(uploadDirectory, { recursive: true });
}

const storage = diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDirectory);
  },
  filename: (req, file, cb) => {
    const randomName = Array(32)
      .fill(null)
      .map(() => Math.round(Math.random() * 16).toString(16))
      .join('');
    return cb(null, `${randomName}${extname(file.originalname)}`);
  },
});

const mediaFileFilter = (req: any, file: any, cb: any) => {
  if (
    !file.mimetype.match(
      /\/(jpg|jpeg|png|webp|pdf|mp3|m4a|aac|wav|ogg|webm|octet-stream|audio\/.*)$/,
    ) &&
    !file.originalname.match(/\.(jpg|jpeg|png|webp|pdf|mp3|m4a|aac|wav|ogg|webm)$/i)
  ) {
    return cb(
      new BadRequestException(
        'صيغة الملف غير مدعومة. الصيغ المسموحة: PDF, JPG, PNG, MP3, M4A, AAC, WAV, OGG, WEBM',
      ),
      false,
    );
  }
  cb(null, true);
};

@ApiTags('رفع الملفات والتسجيلات الصوتية (Uploads & Voice Notes)')
@Controller('uploads')
export class UploadsController {
  constructor(
    private readonly optimizerService: UploadsOptimizerService,
    private readonly storageService: StorageService,
  ) {}

  @Public()
  @Post('single')
  @ApiOperation({
    summary: 'رفع ملف فردي مع الضغط التلقائي للصور بصيغة WebP وتوفير 85% من المساحة',
  })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: { type: 'string', format: 'binary' },
      },
    },
  })
  @UseInterceptors(
    FileInterceptor('file', {
      storage,
      fileFilter: mediaFileFilter,
      limits: { fileSize: 25 * 1024 * 1024 }, // 25MB
    }),
  )
  async uploadSingle(@UploadedFile() file: Express.Multer.File) {
    if (!file) {
      throw new BadRequestException('لم يتم إرسال أي ملف');
    }

    // 1. الضغط والتحسين التلقائي (تحويل الصور إلى WebP فائقة الخفة)
    const optimized = await this.optimizerService.optimizeFile(file);

    // 2. إيداع الملف في التخزين المناسب (محلي أو سحابي)
    const storageRes = await this.storageService.uploadFile(
      path.join(uploadDirectory, optimized.filename),
      optimized.filename,
      optimized.mimetype,
    );

    return {
      message: 'تم رفع الملف ومعالجته وضغطه تلقائياً بنجاح',
      fileName: optimized.filename,
      originalName: optimized.originalName,
      url: storageRes.url,
      size: optimized.size,
      mimeType: optimized.mimetype,
      isCompressed: optimized.isCompressed,
      storageType: storageRes.storageType,
    };
  }

  @Public()
  @Post('vehicle-photos')
  @ApiOperation({
    summary: 'رفع صور السيارة الأربعة مع رخصة السير والهوية وشهادة الحساب البنكي PDF دفعة واحدة مع الضغط التلقائي',
  })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(
    FileFieldsInterceptor(
      [
        { name: 'photoFront', maxCount: 1 },
        { name: 'photoBack', maxCount: 1 },
        { name: 'photoRight', maxCount: 1 },
        { name: 'photoLeft', maxCount: 1 },
        { name: 'photoInterior', maxCount: 1 },
        { name: 'vehicleRegistration', maxCount: 1 },
        { name: 'driverLicense', maxCount: 1 },
        { name: 'idCardPhoto', maxCount: 1 },
        { name: 'bankCertificate', maxCount: 1 },
      ],
      {
        storage,
        fileFilter: mediaFileFilter,
        limits: { fileSize: 15 * 1024 * 1024 },
      },
    ),
  )
  async uploadVehiclePhotos(
    @UploadedFiles()
    files: {
      photoFront?: Express.Multer.File[];
      photoBack?: Express.Multer.File[];
      photoRight?: Express.Multer.File[];
      photoLeft?: Express.Multer.File[];
      photoInterior?: Express.Multer.File[];
      vehicleRegistration?: Express.Multer.File[];
      driverLicense?: Express.Multer.File[];
      idCardPhoto?: Express.Multer.File[];
      bankCertificate?: Express.Multer.File[];
    },
  ) {
    const response: Record<string, string> = {};

    const processField = async (fieldFiles?: Express.Multer.File[]) => {
      if (fieldFiles?.[0]) {
        const optimized = await this.optimizerService.optimizeFile(fieldFiles[0]);
        const storageRes = await this.storageService.uploadFile(
          path.join(uploadDirectory, optimized.filename),
          optimized.filename,
          optimized.mimetype,
        );
        return storageRes.url;
      }
      return undefined;
    };

    if (files.photoFront?.[0]) response.photoFrontUrl = (await processField(files.photoFront))!;
    if (files.photoBack?.[0]) response.photoBackUrl = (await processField(files.photoBack))!;
    if (files.photoRight?.[0]) response.photoRightUrl = (await processField(files.photoRight))!;
    if (files.photoLeft?.[0]) response.photoLeftUrl = (await processField(files.photoLeft))!;
    if (files.photoInterior?.[0]) response.photoInteriorUrl = (await processField(files.photoInterior))!;
    if (files.vehicleRegistration?.[0]) response.vehicleRegistrationUrl = (await processField(files.vehicleRegistration))!;
    if (files.driverLicense?.[0]) response.driverLicenseUrl = (await processField(files.driverLicense))!;
    if (files.idCardPhoto?.[0]) response.idCardPhotoUrl = (await processField(files.idCardPhoto))!;
    if (files.bankCertificate?.[0]) response.bankCertificatePdfUrl = (await processField(files.bankCertificate))!;

    return {
      message: 'تم رفع مستندات وصور السائق وضغطها تلقائياً بنجاح',
      uploadedUrls: response,
    };
  }
}
