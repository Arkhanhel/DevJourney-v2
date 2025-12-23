import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { ConfigService } from '@nestjs/config';
import { RunnerService as NewRunnerService } from './runner-new.service';
import { ExecutionProcessor } from './execution-new.processor';
import { PrismaModule } from '../prisma/prisma.module';
import { EventsModule } from '../events/events.module';

@Module({
  imports: [
    PrismaModule,
    EventsModule,
    BullModule.registerQueue({
      name: 'code-execution',
    }),
  ],
  providers: [NewRunnerService, ExecutionProcessor],
  exports: [NewRunnerService],
})
export class RunnerModule {}
