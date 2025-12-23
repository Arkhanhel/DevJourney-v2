import { Module } from '@nestjs/common';
import { AuthModule } from './auth/auth.module';
import { ChallengesModule } from './challenges/challenges.module';
import { SubmissionsModule } from './submissions/submissions.module';
import { UsersModule } from './users/users.module';
import { TracksModule } from './tracks/tracks.module';
import { CoursesModule } from './courses/courses.module';
import { LessonsModule } from './lessons/lessons.module';
import { ProgressModule } from './progress/progress.module';

@Module({
  imports: [
    AuthModule,
    ChallengesModule,
    SubmissionsModule,
    UsersModule,
    TracksModule,
    CoursesModule,
    LessonsModule,
    ProgressModule,
  ],
})
export class ApiModule {}
