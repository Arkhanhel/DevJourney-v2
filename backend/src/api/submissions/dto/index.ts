import { IsNotEmpty, IsString, IsUUID } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateSubmissionDto {
  @ApiProperty({ example: 'uuid-challenge-id' })
  @IsUUID()
  challengeId: string;

  @ApiProperty({ example: 'console.log("Hello World");' })
  @IsNotEmpty()
  @IsString()
  code: string;

  @ApiProperty({ example: 'javascript', enum: ['javascript', 'python', 'java', 'cpp'] })
  @IsNotEmpty()
  @IsString()
  language: string;
}
