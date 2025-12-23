import {
  Controller,
  Get,
  Param,
  Post,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { CoursesService } from './courses.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('courses')
@Controller('courses')
export class CoursesController {
  constructor(private readonly coursesService: CoursesService) {}

  @Get()
  @ApiOperation({ summary: 'Get all active courses' })
  findAll(@Query('trackId') trackId?: string) {
    return this.coursesService.findAll(trackId);
  }

  @Get(':slug')
  @ApiOperation({ summary: 'Get course by slug with modules and lessons' })
  findOne(@Param('slug') slug: string, @Query('userId') userId?: string) {
    return this.coursesService.findBySlug(slug, userId);
  }

  @Post(':courseId/start')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Start a course' })
  startCourse(@Param('courseId') courseId: string, @Request() req: any) {
    return this.coursesService.startCourse(req.user.id, courseId);
  }
}
