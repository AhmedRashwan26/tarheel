import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';
import { PLATFORM_CONSTANTS } from '../src/common/constants';

describe('Tarheel Application E2E Tests', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('api/v1');
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        transform: true,
      }),
    );
    await app.init();
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  it('1. Platform Constants Verification', () => {
    expect(PLATFORM_CONSTANTS.COMMISSION_PERCENTAGE).toBe(10);
    expect(PLATFORM_CONSTANTS.ANTI_CASH_WARNING_AR).toContain('يمنع منعاً باتاً دفع أي مبالغ نقدية');
    expect(PLATFORM_CONSTANTS.DRIVER_TERMS_WARNING_AR).toContain('10%');
  });

  it('2. POST /api/v1/auth/send-otp - should send OTP for phone authentication', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/send-otp')
      .send({ phoneNumber: '+966509991122' })
      .expect(200);

    expect(response.body.success).toBe(true);
    expect(response.body.data.message).toContain('تم إرسال رمز التحقق');
  });

  it('3. POST /api/v1/drivers/register - should validate 4-angle car photos and A/C status', async () => {
    const invalidDriverPayload = {
      phoneNumber: '+966550001122',
      fullName: 'سائق تجريبي',
      nationalId: '1099998888',
      vehicleBrand: 'تويوتا',
      vehicleModel: 'كامري',
      vehicleYear: 2023,
      plateNumber: 'ر ق م 1234',
      capacity: 4,
      isAirConditioned: true,
      // Missing 4 angle photos and missing anti-cash agreement
      agreeToAntiCashPolicy: false,
    };

    const response = await request(app.getHttpServer())
      .post('/api/v1/drivers/register')
      .send(invalidDriverPayload)
      .expect(400);

    expect(response.body.success).toBe(false);
  });
});
