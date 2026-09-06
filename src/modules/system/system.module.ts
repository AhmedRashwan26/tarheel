import { Module } from '@nestjs/common';
import { ServerWatchdogService } from './server-watchdog.service';

@Module({
  providers: [ServerWatchdogService],
  exports: [ServerWatchdogService],
})
export class SystemModule {}
