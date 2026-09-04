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
import { existsSync, mkdirSync } from 'fs';
import { Public } from '../../common/decorators/roles.decorator';

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
  @Public()
  @Post('single')
  @ApiOperation({
    summary: 'رفع ملف فردي (رسالة صوتية Voice note، شهادة آيبان PDF، رخصة، هوية، صورة سيارة)',
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
  uploadSingle(@UploadedFile() file: Express.Multer.File) {
    if (!file) {
      throw new BadRequestException('لم يتم إرسال أي ملف');
    }
    const fileUrl = `/uploads/${file.filename}`;
    return {
      message: 'تم رفع الملف بنجاح',
      fileName: file.filename,
      originalName: file.originalname,
      url: fileUrl,
      size: file.size,
      mimeType: file.mimetype,
    };
  }

  @Public()
  @Post('vehicle-photos')
  @ApiOperation({
    summary: 'رفع صور السيارة الأربعة مع رخصة السير والهوية وشهادة الحساب البنكي PDF دفعة واحدة',
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
  uploadVehiclePhotos(
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
    if (files.photoFront?.[0]) response.photoFrontUrl = `/uploads/${files.photoFront[0].filename}`;
    if (files.photoBack?.[0]) response.photoBackUrl = `/uploads/${files.photoBack[0].filename}`;
    if (files.photoRight?.[0]) response.photoRightUrl = `/uploads/${files.photoRight[0].filename}`;
    if (files.photoLeft?.[0]) response.photoLeftUrl = `/uploads/${files.photoLeft[0].filename}`;
    if (files.photoInterior?.[0]) response.photoInteriorUrl = `/uploads/${files.photoInterior[0].filename}`;
    if (files.vehicleRegistration?.[0]) response.vehicleRegistrationUrl = `/uploads/${files.vehicleRegistration[0].filename}`;
    if (files.driverLicense?.[0]) response.driverLicenseUrl = `/uploads/${files.driverLicense[0].filename}`;
    if (files.idCardPhoto?.[0]) response.idCardPhotoUrl = `/uploads/${files.idCardPhoto[0].filename}`;
    if (files.bankCertificate?.[0]) response.bankCertificatePdfUrl = `/uploads/${files.bankCertificate[0].filename}`;

    return {
      message: 'تم رفع مستندات وصور السائق وشهادة الحساب البنكي بنجاح',
      uploadedUrls: response,
    };
  }
}
