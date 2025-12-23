import { Controller, Post, Body, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AiService } from './ai.service';
import { JwtAuthGuard } from '../api/auth/guards/jwt-auth.guard';
import { GenerateHintDto } from './dto/hint.dto';

@ApiTags('ai')
@Controller('ai')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class AiController {
  constructor(private aiService: AiService) {}

  @Post('hint')
  @ApiOperation({ summary: 'Get personalized AI-powered progressive hint' })
  async getHint(@Body() dto: GenerateHintDto, @Request() req: any) {
    return this.aiService.generateProgressiveHint(req.user.id, dto);
  }

  @Post('analyze')
  @ApiOperation({ summary: 'Analyze code quality and get recommendations' })
  async analyzeCode(@Body() body: { code: string; language: string }) {
    const analysis = await this.aiService.analyzeCode(body.code, body.language);
    return analysis;
  }
}
