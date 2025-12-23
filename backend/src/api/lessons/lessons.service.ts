import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class LessonsService {
  constructor(private prisma: PrismaService) {}

  async findBySlug(moduleId: string, slug: string, locale: string = 'uk') {
    const lesson = await this.prisma.lesson.findUnique({
      where: {
        moduleId_slug: { moduleId, slug },
      },
      include: {
        module: {
          include: {
            course: {
              select: {
                id: true,
                title: true,
                slug: true,
              },
            },
          },
        },
        challenges: {
          orderBy: { createdAt: 'asc' },
          select: {
            id: true,
            title: true,
            description: true,
            difficulty: true,
            tags: true,
            language: true,
            xpReward: true,
          },
        },
      },
    });

    if (!lesson) {
      throw new NotFoundException('Lesson not found');
    }

    // Extract content for specific locale
    const content =
      typeof lesson.content === 'object' && lesson.content
        ? (lesson.content as any)[locale] || (lesson.content as any)['uk']
        : lesson.content;

    const title =
      typeof lesson.title === 'object' && lesson.title
        ? (lesson.title as any)[locale] || (lesson.title as any)['uk']
        : lesson.title;

    return {
      ...lesson,
      title,
      content,
    };
  }

  async getNextLesson(currentLessonId: string) {
    const currentLesson = await this.prisma.lesson.findUnique({
      where: { id: currentLessonId },
    });

    if (!currentLesson) {
      return null;
    }

    // Find next lesson in same module
    const nextLesson = await this.prisma.lesson.findFirst({
      where: {
        moduleId: currentLesson.moduleId,
        order: { gt: currentLesson.order },
      },
      orderBy: { order: 'asc' },
    });

    if (nextLesson) {
      return nextLesson;
    }

    // Find first lesson in next module
    const currentModule = await this.prisma.module.findUnique({
      where: { id: currentLesson.moduleId },
    });

    if (!currentModule) {
      return null;
    }

    const nextModule = await this.prisma.module.findFirst({
      where: {
        courseId: currentModule.courseId,
        order: { gt: currentModule.order },
      },
      orderBy: { order: 'asc' },
      include: {
        lessons: {
          orderBy: { order: 'asc' },
          take: 1,
        },
      },
    });

    return nextModule?.lessons[0] || null;
  }

  async updateProgress(
    userId: string,
    lessonId: string,
    status: 'STARTED' | 'COMPLETED',
  ) {
    const lesson = await this.prisma.lesson.findUnique({
      where: { id: lessonId },
      select: { id: true },
    });

    if (!lesson) {
      throw new NotFoundException('Lesson not found');
    }

    const now = new Date();

    if (status === 'STARTED') {
      return this.prisma.lessonProgress.upsert({
        where: {
          userId_lessonId: { userId, lessonId },
        },
        create: {
          userId,
          lessonId,
          startedAt: now,
        },
        update: {
          completedAt: null,
        },
      });
    }

    return this.prisma.lessonProgress.upsert({
      where: {
        userId_lessonId: { userId, lessonId },
      },
      create: {
        userId,
        lessonId,
        startedAt: now,
        completedAt: now,
      },
      update: {
        completedAt: now,
      },
    });
  }
}
