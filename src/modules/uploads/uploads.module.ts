import { Module } from '@nestjs/common';
import { UploadsController } from './uploads.controller';
import { UploadsOptimizerService } from './uploads-optimizer.service';
import { StorageService } from './storage.service';

@Module({
  controllers: [UploadsController],
  providers: [UploadsOptimizerService, StorageService],
  exports: [UploadsOptimizerService, StorageService],
})
export class UploadsModule {}
