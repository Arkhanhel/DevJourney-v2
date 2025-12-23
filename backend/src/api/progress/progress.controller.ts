import {
  Controller,
  Get,
  Param,
  UseGuards,
  Request,
  Query,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PrismaService } from '../../prisma/prisma.service';

@Controller('progress')
@UseGuards(JwtAuthGuard)
export class ProgressController {
  constructor(private prisma: PrismaService) {}

  /**
   * Get user's overall progress
   */
  @Get()
  async getUserProgress(@Request() req) {
    const userId = req.user.userId;

    // Get total XP
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { totalXp: true },
    });

    // Get completed challenges count
    const completedChallenges = await this.prisma.userProgress.count({
      where: {
        userId,
        completed: true,
      },
    });

    // Get recent XP events
    const recentXp = await this.prisma.xpEvent.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 10,
    });

    // Get in-progress courses
    const courseProgress = await this.prisma.userProgress.findMany({
      where: {
        userId,
        challenge: {
          lesson: {
            isNot: null,
          },
        },
      },
      include: {
        challenge: {
          include: {
            lesson: {
              include: {
                module: {
                  include: {
                    course: {
                      select: {
                        id: true,
                        title: true,
                        slug: true,
                      },
                    },
                  },
                },
              },
            },
          },
        },
      },
    });

    // Group by course
    const courseStats = courseProgress.reduce((acc, progress) => {
      const course = progress.challenge.lesson?.module?.course;
      if (!course) return acc;

      if (!acc[course.id]) {
        acc[course.id] = {
          courseId: course.id,
          courseTitle: course.title,
          courseSlug: course.slug,
          totalChallenges: 0,
          completedChallenges: 0,
        };
      }

      acc[course.id].totalChallenges++;
      if (progress.completed) {
        acc[course.id].completedChallenges++;
      }

      return acc;
    }, {});

    return {
      totalXp: user?.totalXp || 0,
      completedChallenges,
      recentXp,
      courses: Object.values(courseStats),
    };
  }

  /**
   * Get progress for specific challenge
   */
  @Get('challenge/:challengeId')
  async getChallengeProgress(
    @Request() req,
    @Param('challengeId') challengeId: string,
  ) {
    const userId = req.user.userId;

    const progress = await this.prisma.userProgress.findUnique({
      where: {
        userId_challengeId: {
          userId,
          challengeId,
        },
      },
    });

    // Get recent submissions
    const submissions = await this.prisma.submission.findMany({
      where: {
        userId,
        challengeId,
      },
      orderBy: { createdAt: 'desc' },
      take: 5,
      select: {
        id: true,
        status: true,
        score: true,
        executionTime: true,
        createdAt: true,
      },
    });

    return {
      progress: progress || {
        completed: false,
        bestScore: 0,
        attempts: 0,
      },
      submissions,
    };
  }

  /**
   * Get XP leaderboard
   */
  @Get('leaderboard')
  async getLeaderboard(@Query('limit') limit?: string) {
    const limitNum = limit ? parseInt(limit) : 10;

    const topUsers = await this.prisma.user.findMany({
      orderBy: { totalXp: 'desc' },
      take: limitNum,
      select: {
        id: true,
        email: true,
        username: true,
        totalXp: true,
      },
    });

    return topUsers.map((user, index) => ({
      rank: index + 1,
      userId: user.id,
      displayName: user.username || user.email.split('@')[0],
      totalXp: user.totalXp,
    }));
  }
}
