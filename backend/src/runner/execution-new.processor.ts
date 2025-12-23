import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { PrismaService } from '../prisma/prisma.service';
import { RunnerService as NewRunnerService } from './runner-new.service';
import { SubmissionsGateway } from '../events/submissions.gateway';
import { SubmissionStatus } from '@prisma/client';

@Processor('code-execution')
export class ExecutionProcessor extends WorkerHost {
  private logger = new Logger(ExecutionProcessor.name);

  constructor(
    private prisma: PrismaService,
    private runnerService: NewRunnerService,
    private submissionsGateway: SubmissionsGateway,
  ) {
    super();
  }

  async process(job: Job): Promise<any> {
    const { submissionId, challengeId, code, language, userId } = job.data;

    this.logger.log(`Processing submission ${submissionId} for user ${userId}`);

    try {
      // Update status to RUNNING
      await this.prisma.submission.update({
        where: { id: submissionId },
        data: { status: SubmissionStatus.RUNNING },
      });

      // Emit WebSocket event
      this.submissionsGateway.emitSubmissionUpdate(submissionId, {
        status: 'RUNNING',
        message: 'Виконується код...',
      });

      // Get test cases and challenge
      const testCases = await this.prisma.testCase.findMany({
        where: { challengeId },
        orderBy: { weight: 'asc' },
      });

      const challenge = await this.prisma.challenge.findUnique({
        where: { id: challengeId },
        select: {
          timeLimit: true,
          memoryLimit: true,
          xpReward: true,
          id: true,
          title: true,
        },
      });

      if (!challenge || testCases.length === 0) {
        throw new Error('Challenge or test cases not found');
      }

      // Execute with new Runner (all tests at once)
      const executionResult = await this.runnerService.executeWithTests(
        code,
        language,
        testCases.map((tc) => ({
          input: tc.input,
          expected: tc.expected,
        })),
        challenge.timeLimit,
        challenge.memoryLimit,
      );

      // Emit test results progressively (optional - if needed)
      executionResult.results.forEach((result, index) => {
        this.submissionsGateway.emitTestResult(submissionId, index, {
          passed: result.passed,
          executionTime: result.executionTime,
        });
      });

      // Calculate score
      const passedCount = executionResult.results.filter((r) => r.passed).length;
      const finalScore = Math.round((passedCount / testCases.length) * 100);
      const allPassed = executionResult.allPassed;

      // Determine status
      const status = allPassed
        ? SubmissionStatus.SUCCESS
        : executionResult.results.some((r) => r.error)
        ? SubmissionStatus.ERROR
        : SubmissionStatus.FAILED;

      // Update submission with results
      await this.prisma.submission.update({
        where: { id: submissionId },
        data: {
          status,
          score: finalScore,
          executionTime: executionResult.totalTime,
          testResults: executionResult.results as any, // Convert to JSON
        },
      });

      // Emit final WebSocket event
      this.submissionsGateway.emitSubmissionUpdate(submissionId, {
        status,
        score: finalScore,
        totalTime: executionResult.totalTime,
        passed: passedCount,
        total: testCases.length,
        message: allPassed
          ? '✅ Всі тести пройдені!'
          : `⚠️ Пройдено ${passedCount} з ${testCases.length} тестів`,
      });

      // Award XP if successful
      if (allPassed) {
        await this.awardXp(userId, challenge, submissionId);
        
        // Update user progress
        await this.updateUserProgress(userId, challengeId, finalScore);
      }

      this.logger.log(
        `Submission ${submissionId} completed: ${status}, score: ${finalScore}`,
      );

      return { success: true, score: finalScore, allPassed };
    } catch (error) {
      this.logger.error(
        `Execution failed for submission ${submissionId}:`,
        error.stack,
      );

      await this.prisma.submission.update({
        where: { id: submissionId },
        data: {
          status: SubmissionStatus.ERROR,
          errorMessage: error.message,
        },
      });

      // Emit error via WebSocket
      this.submissionsGateway.emitSubmissionUpdate(submissionId, {
        status: 'ERROR',
        error: error.message,
        message: '❌ Помилка виконання',
      });

      throw error;
    }
  }

  /**
   * Award XP to user for completing challenge
   */
  private async awardXp(
    userId: string,
    challenge: { id: string; xpReward: number; title: string },
    submissionId: string,
  ) {
    try {
      // Check if already awarded XP for this challenge
      const existingProgress = await this.prisma.userProgress.findUnique({
        where: {
          userId_challengeId: {
            userId,
            challengeId: challenge.id,
          },
        },
      });

      // Only award XP on first completion
      if (!existingProgress || !existingProgress.completed) {
        await this.prisma.xpEvent.create({
          data: {
            userId,
            amount: challenge.xpReward,
            reason: 'challenge_completed',
            metadata: {
              challengeId: challenge.id,
              challengeTitle: challenge.title,
              submissionId,
            },
          },
        });

        // Update user's total XP
        await this.prisma.user.update({
          where: { id: userId },
          data: {
            totalXp: {
              increment: challenge.xpReward,
            },
          },
        });

        this.logger.log(
          `Awarded ${challenge.xpReward} XP to user ${userId} for challenge ${challenge.id}`,
        );
      }
    } catch (error) {
      this.logger.error(`Failed to award XP: ${error.message}`);
      // Don't throw - XP is not critical
    }
  }

  /**
   * Update user progress for challenge
   */
  private async updateUserProgress(
    userId: string,
    challengeId: string,
    score: number,
  ) {
    try {
      const existing = await this.prisma.userProgress.findUnique({
        where: {
          userId_challengeId: { userId, challengeId },
        },
      });

      if (existing) {
        // Update if better score
        await this.prisma.userProgress.update({
          where: {
            userId_challengeId: { userId, challengeId },
          },
          data: {
            completed: score === 100,
            bestScore: Math.max(existing.bestScore || 0, score),
            attempts: { increment: 1 },
            lastAttempt: new Date(),
          },
        });
      } else {
        // Create new progress
        await this.prisma.userProgress.create({
          data: {
            userId,
            challengeId,
            completed: score === 100,
            bestScore: score,
            attempts: 1,
            lastAttempt: new Date(),
          },
        });
      }
    } catch (error) {
      this.logger.error(`Failed to update user progress: ${error.message}`);
    }
  }
}
