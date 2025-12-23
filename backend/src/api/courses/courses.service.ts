import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class CoursesService {
  constructor(private prisma: PrismaService) {}

  async findAll(trackId?: string) {
    const where: any = { isActive: true };
    if (trackId) {
      where.trackId = trackId;
    }

    return this.prisma.course.findMany({
      where,
      orderBy: { order: 'asc' },
      include: {
        track: {
          select: {
            id: true,
            slug: true,
            title: true,
            icon: true,
          },
        },
        _count: {
          select: { modules: true },
        },
      },
    });
  }

  async findBySlug(slug: string, userId?: string) {
    const course = await this.prisma.course.findUnique({
      where: { slug },
      include: {
        track: {
          select: {
            id: true,
            slug: true,
            title: true,
          },
        },
        modules: {
          orderBy: { order: 'asc' },
          include: {
            lessons: {
              orderBy: { order: 'asc' },
              select: {
                id: true,
                slug: true,
                title: true,
                type: true,
                duration: true,
                order: true,
                _count: {
                  select: { challenges: true },
                },
              },
            },
          },
        },
      },
    });

    if (!course) {
      throw new NotFoundException('Course not found');
    }

    // If userId provided, get user progress
    let progress = null;
    if (userId) {
      progress = await this.prisma.courseProgress.findUnique({
        where: {
          userId_courseId: { userId, courseId: course.id },
        },
      });
    }

    return { ...course, userProgress: progress };
  }

  async startCourse(userId: string, courseId: string) {
    const existing = await this.prisma.courseProgress.findUnique({
      where: {
        userId_courseId: { userId, courseId },
      },
    });

    if (existing) {
      return existing;
    }

    return this.prisma.courseProgress.create({
      data: {
        userId,
        courseId,
        progress: 0,
        completed: false,
      },
    });
  }
}
