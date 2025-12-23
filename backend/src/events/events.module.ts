import { Module } from '@nestjs/common';
import { SubmissionsGateway } from './submissions.gateway';

@Module({
  providers: [SubmissionsGateway],
  exports: [SubmissionsGateway],
})
export class EventsModule {}
