import { IsString, IsInt, IsOptional, IsEnum, Min } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class GenerateHintDto {
  @ApiProperty()
  @IsString()
  challengeId: string;

  @ApiProperty()
  @IsString()
  userCode: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  failingOutput?: string;

  @ApiProperty()
  @IsInt()
  @Min(1)
  attempts: number;

  @ApiProperty({ required: false, enum: ['uk', 'ru', 'en'] })
  @IsOptional()
  @IsEnum(['uk', 'ru', 'en'])
  locale?: 'uk' | 'ru' | 'en';
}

export class HintResponseDto {
  @ApiProperty()
  level: number;

  @ApiProperty()
  hintText: string;

  @ApiProperty({ required: false })
  partialCode?: string;

  @ApiProperty()
  explanation: string;

  @ApiProperty()
  encouragement: string;
}
