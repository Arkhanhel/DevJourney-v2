import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { Difficulty } from '@prisma/client';

@Injectable()
export class ChallengesService {
  constructor(private prisma: PrismaService) {}

  async findAll(difficulty?: Difficulty, tags?: string[]) {
    const where: any = {};

    if (difficulty) {
      where.difficulty = difficulty;
    }

    if (tags && tags.length > 0) {
      where.tags = {
        hasSome: tags,
      };
    }

    return this.prisma.challenge.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        title: true,
        description: true,
        difficulty: true,
        tags: true,
        totalTests: true,
        createdAt: true,
      },
    });
  }

  async findById(id: string) {
    const challenge = await this.prisma.challenge.findUnique({
      where: { id },
      include: {
        testCases: {
          where: { isPublic: true },
          select: {
            id: true,
            input: true,
            expected: true,
          },
        },
      },
    });

    if (!challenge) {
      throw new NotFoundException('Challenge not found');
    }

    return challenge;
  }

  async getTestCases(challengeId: string) {
    return this.prisma.testCase.findMany({
      where: { challengeId },
      orderBy: { weight: 'asc' },
    });
  }

  async getNextChallenge(challengeId: string) {
    const current = await this.prisma.challenge.findUnique({
      where: { id: challengeId },
      select: {
        id: true,
        lessonId: true,
        createdAt: true,
      },
    });

    if (!current) {
      throw new NotFoundException('Challenge not found');
    }

    if (!current.lessonId) {
      return null;
    }

    return this.prisma.challenge.findFirst({
      where: {
        lessonId: current.lessonId,
        createdAt: { gt: current.createdAt },
      },
      orderBy: { createdAt: 'asc' },
      select: {
        id: true,
        lessonId: true,
        title: true,
        difficulty: true,
        tags: true,
        language: true,
        xpReward: true,
        createdAt: true,
      },
    });
  }
}
