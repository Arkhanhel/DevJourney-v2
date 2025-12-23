import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { PrismaService } from '../prisma/prisma.service';
import { RunnerService } from './runner.service';
import { SubmissionStatus } from '@prisma/client';

@Processor('code-execution')
export class ExecutionProcessor extends WorkerHost {
  private logger = new Logger(ExecutionProcessor.name);

  constructor(
    private prisma: PrismaService,
    private runnerService: RunnerService,
  ) {
    super();
  }

  async process(job: Job): Promise<any> {
    const { submissionId, challengeId, code, language } = job.data;

    this.logger.log(`Processing submission ${submissionId}`);

    try {
      // Update status to RUNNING
      await this.prisma.submission.update({
        where: { id: submissionId },
        data: { status: SubmissionStatus.RUNNING },
      });

      // Get test cases
      const testCases = await this.prisma.testCase.findMany({
        where: { challengeId },
        orderBy: { weight: 'asc' },
      });

      const challenge = await this.prisma.challenge.findUnique({
        where: { id: challengeId },
      });

      const results = [];
      let totalScore = 0;
      let totalExecutionTime = 0;

      // Execute code for each test case
      for (const testCase of testCases) {
        const result = await this.runnerService.executeCode(
          code,
          language,
          testCase.input,
          challenge.timeLimit,
          challenge.memoryLimit,
        );

        const passed = result.success && result.output?.trim() === testCase.expected.trim();
        
        if (passed) {
          totalScore += testCase.weight;
        }

        totalExecutionTime += result.executionTime;

        results.push({
          testCaseId: testCase.id,
          passed,
          output: result.output,
          error: result.error,
          executionTime: result.executionTime,
        });

        // Stop if test failed and it's not public
        if (!passed && !testCase.isPublic) {
          break;
        }
      }

      const maxScore = testCases.reduce((sum, tc) => sum + tc.weight, 0);
      const finalScore = Math.round((totalScore / maxScore) * 100);
      const allPassed = results.every((r) => r.passed);

      // Update submission with results
      await this.prisma.submission.update({
        where: { id: submissionId },
        data: {
          status: allPassed ? SubmissionStatus.SUCCESS : SubmissionStatus.FAILED,
          score: finalScore,
          executionTime: totalExecutionTime,
          testResults: results,
        },
      });

      this.logger.log(`Submission ${submissionId} completed with score ${finalScore}`);

      return { success: true, score: finalScore };
    } catch (error) {
      this.logger.error(`Execution failed for submission ${submissionId}:`, error);

      await this.prisma.submission.update({
        where: { id: submissionId },
        data: {
          status: SubmissionStatus.ERROR,
          errorMessage: error.message,
        },
      });

      throw error;
    }
  }
}
