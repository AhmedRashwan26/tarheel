import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe, Logger } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import * as compression from 'compression';
import { NestExpressApplication } from '@nestjs/platform-express';
import { join } from 'path';
import { existsSync, mkdirSync } from 'fs';

async function bootstrap() {
  const logger = new Logger('TarheelBootstrap');
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // Ensure uploads directory exists
  const uploadDir = join(process.cwd(), 'uploads');
  if (!existsSync(uploadDir)) {
    mkdirSync(uploadDir, { recursive: true });
  }

  // Serve static uploaded assets
  app.useStaticAssets(uploadDir, {
    prefix: '/uploads/',
  });

  // Global Middlewares & Security
  app.use(helmet({
    crossOriginResourcePolicy: false, // Allow image loading in mobile apps
  }));
  app.use(compression());

  app.enableCors({
    origin: '*',
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true,
  });

  // Global Prefix
  app.setGlobalPrefix('api/v1');

  // Global Validation Pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // Swagger Documentation Setup
  const swaggerConfig = new DocumentBuilder()
    .setTitle('منصة ترحيل - التوثيق البرمجي للباك اند (Tarheel API Documentation)')
    .setDescription(
      `توثيق شامل ومفصل للواجهات البرمجية (RESTful APIs) لتطبيق ومنصة ترحيل للنقل والتوصيل المجدول.
      
      الميزات الأساسية:
      1. تسجيل العملاء ونشر طلبات المشاوير (تحديد وقت الذهاب والعودة والتكرار أسبوعي أو شهري).
      2. تسجيل السائقين ورفع الوثائق وصور السيارة الأربعة وبيان التكييف والسعة.
      3. نظام المزايدة الفورية لتقديم عروض الأسعار مع خصم عمولة التطبيق (10%).
      4. نظام الضمان المالي (Escrow) والتحذير الأمني الصارم من التعامل النقدي لحفظ حقوق الأطراف.
      5. نظام التقييم وتحرير مستحقات السائقين فور اكتمال الخدمة.`,
    )
    .setVersion('1.0.0')
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        name: 'JWT Authorization',
        description: 'أدخل توكن الـ JWT مسبوقاً بكلمة Bearer',
        in: 'header',
      },
      'JWT-auth',
    )
    .build();

  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('api/docs', app, document, {
    customSiteTitle: 'توثيق واجهات ترحيل (Tarheel API Docs)',
    swaggerOptions: {
      persistAuthorization: true,
      docExpansion: 'list',
      filter: true,
    },
  });

  const port = process.env.PORT || 3000;
  await app.listen(port);
  logger.log(`🚀 تطبيق ترحيل يعمل بنجاح على المنفذ: http://localhost:${port}`);
  logger.log(`📚 رابط واجهة توثيق Swagger التفاعلية: http://localhost:${port}/api/docs`);
}

bootstrap();
