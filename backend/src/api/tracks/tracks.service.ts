import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class TracksService {
  constructor(private prisma: PrismaService) {}

  async findAll() {
    return this.prisma.track.findMany({
      where: { isActive: true },
      orderBy: { order: 'asc' },
      select: {
        id: true,
        slug: true,
        title: true,
        description: true,
        icon: true,
        level: true,
        order: true,
        _count: {
          select: { courses: true },
        },
      },
    });
  }

  async findBySlug(slug: string) {
    return this.prisma.track.findUnique({
      where: { slug },
      include: {
        courses: {
          where: { isActive: true },
          orderBy: { order: 'asc' },
          select: {
            id: true,
            slug: true,
            title: true,
            description: true,
            duration: true,
            xpReward: true,
            _count: {
              select: { modules: true },
            },
          },
        },
      },
    });
  }
}
