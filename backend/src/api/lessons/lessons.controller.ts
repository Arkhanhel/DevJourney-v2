import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
  Request,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { IsIn } from 'class-validator';
import { LessonsService } from './lessons.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

class UpdateLessonProgressDto {
  @IsIn(['STARTED', 'COMPLETED'])
  status!: 'STARTED' | 'COMPLETED';
}

@ApiTags('lessons')
@Controller('lessons')
export class LessonsController {
  constructor(private readonly lessonsService: LessonsService) {}

  @Get(':moduleId/:slug')
  @ApiOperation({ summary: 'Get lesson by module ID and slug' })
  findOne(
    @Param('moduleId') moduleId: string,
    @Param('slug') slug: string,
    @Query('locale') locale: string = 'uk',
  ) {
    return this.lessonsService.findBySlug(moduleId, slug, locale);
  }

  @Post(':lessonId/progress')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update lesson progress for current user' })
  updateProgress(
    @Param('lessonId') lessonId: string,
    @Body() body: UpdateLessonProgressDto,
    @Request() req: any,
  ) {
    return this.lessonsService.updateProgress(req.user.id, lessonId, body.status);
  }

  @Get(':lessonId/next')
  @ApiOperation({ summary: 'Get next lesson in course' })
  getNext(@Param('lessonId') lessonId: string) {
    return this.lessonsService.getNextLesson(lessonId);
  }
}
