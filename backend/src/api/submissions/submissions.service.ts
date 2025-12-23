import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { PrismaService } from '../../prisma/prisma.service';
import { SubmissionStatus } from '@prisma/client';
import { CreateSubmissionDto } from './dto';

@Injectable()
export class SubmissionsService {
  constructor(
    private prisma: PrismaService,
    @InjectQueue('code-execution') private executionQueue: Queue,
  ) {}

  async create(userId: string, dto: CreateSubmissionDto) {
    // Create submission record
    const submission = await this.prisma.submission.create({
      data: {
        userId,
        challengeId: dto.challengeId,
        code: dto.code,
        language: dto.language,
        status: SubmissionStatus.PENDING,
      },
    });

    // Add to execution queue with userId for XP rewards
    await this.executionQueue.add('execute', {
      submissionId: submission.id,
      challengeId: dto.challengeId,
      code: dto.code,
      language: dto.language,
      userId, // Add userId for XP system
    });

    return submission;
  }

  async findById(id: string) {
    const submission = await this.prisma.submission.findUnique({
      where: { id },
      include: {
        challenge: {
          select: {
            title: true,
            difficulty: true,
          },
        },
      },
    });

    if (!submission) {
      throw new NotFoundException('Submission not found');
    }

    return submission;
  }

  async findByUserId(userId: string) {
    return this.prisma.submission.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      include: {
        challenge: {
          select: {
            title: true,
            difficulty: true,
          },
        },
      },
    });
  }

  async updateStatus(
    id: string,
    status: SubmissionStatus,
    data?: {
      score?: number;
      executionTime?: number;
      memoryUsed?: number;
      errorMessage?: string;
      testResults?: any;
    },
  ) {
    return this.prisma.submission.update({
      where: { id },
      data: {
        status,
        ...data,
      },
    });
  }
}
