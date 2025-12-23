import { Controller, Get, Param } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { TracksService } from './tracks.service';

@ApiTags('tracks')
@Controller('tracks')
export class TracksController {
  constructor(private readonly tracksService: TracksService) {}

  @Get()
  @ApiOperation({ summary: 'Get all active tracks' })
  findAll() {
    return this.tracksService.findAll();
  }

  @Get(':slug')
  @ApiOperation({ summary: 'Get track by slug with courses' })
  findOne(@Param('slug') slug: string) {
    return this.tracksService.findBySlug(slug);
  }
}
