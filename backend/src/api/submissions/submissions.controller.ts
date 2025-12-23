import { Controller, Post, Get, Param, Body, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { SubmissionsService } from './submissions.service';
import { CreateSubmissionDto } from './dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('submissions')
@Controller('submissions')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class SubmissionsController {
  constructor(private submissionsService: SubmissionsService) {}

  @Post()
  @ApiOperation({ summary: 'Submit code for a challenge' })
  async create(@Req() req, @Body() dto: CreateSubmissionDto) {
    return this.submissionsService.create(req.user.id, dto);
  }

  @Get('my')
  @ApiOperation({ summary: 'Get current user submissions' })
  async findMy(@Req() req) {
    return this.submissionsService.findByUserId(req.user.id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get submission by ID' })
  async findById(@Param('id') id: string) {
    return this.submissionsService.findById(id);
  }

  @Get(':id/status')
  @ApiOperation({ summary: 'Get submission status' })
  async getStatus(@Param('id') id: string) {
    const submission = await this.submissionsService.findById(id);
    return {
      id: submission.id,
      status: submission.status,
      score: submission.score,
      executionTime: submission.executionTime,
      memoryUsed: submission.memoryUsed,
      errorMessage: submission.errorMessage,
      testResults: submission.testResults,
    };
  }
}
