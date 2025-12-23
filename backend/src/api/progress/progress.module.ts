import { Module } from '@nestjs/common';
import { ProgressController } from './progress.controller';
import { PrismaModule } from '../../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [ProgressController],
})
export class ProgressModule {}
