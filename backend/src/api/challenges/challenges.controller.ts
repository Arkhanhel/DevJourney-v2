import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { ChallengesService } from './challenges.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { Difficulty } from '@prisma/client';

@ApiTags('challenges')
@Controller('challenges')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class ChallengesController {
  constructor(private challengesService: ChallengesService) {}

  @Get()
  @ApiOperation({ summary: 'Get all challenges' })
  @ApiQuery({ name: 'difficulty', required: false, enum: Difficulty })
  @ApiQuery({ name: 'tags', required: false, type: [String] })
  async findAll(
    @Query('difficulty') difficulty?: Difficulty,
    @Query('tags') tags?: string | string[],
  ) {
    const tagsArray = tags 
      ? Array.isArray(tags) 
        ? tags 
        : tags.split(',')
      : undefined;

    return this.challengesService.findAll(difficulty, tagsArray);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get challenge by ID' })
  async findById(@Param('id') id: string) {
    return this.challengesService.findById(id);
  }

  @Get(':id/next')
  @ApiOperation({ summary: 'Get next challenge in the same lesson' })
  async getNext(@Param('id') id: string) {
    return this.challengesService.getNextChallenge(id);
  }
}
