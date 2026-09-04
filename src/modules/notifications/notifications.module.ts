import { Global, Module } from '@nestjs/common';
import { NotificationsGateway } from './notifications.gateway';
import { NotificationsService } from './notifications.service';
import { OtpSenderService } from './otp-sender.service';

@Global()
@Module({
  providers: [NotificationsGateway, NotificationsService, OtpSenderService],
  exports: [NotificationsGateway, NotificationsService, OtpSenderService],
})
export class NotificationsModule {}
