import { PrismaClient, SkillLevel, Difficulty, LessonType } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting seed...');

  // Clear existing data in development
  if (process.env.NODE_ENV === 'development') {
    await prisma.aiHintEvent.deleteMany();
    await prisma.xpEvent.deleteMany();
    await prisma.examAttempt.deleteMany();
    await prisma.examQuestion.deleteMany();
    await prisma.exam.deleteMany();
    await prisma.certificate.deleteMany();
    await prisma.courseProgress.deleteMany();
    await prisma.userProgress.deleteMany();
    await prisma.submission.deleteMany();
    await prisma.testCase.deleteMany();
    await prisma.challenge.deleteMany();
    await prisma.lesson.deleteMany();
    await prisma.module.deleteMany();
    await prisma.course.deleteMany();
    await prisma.track.deleteMany();
    await prisma.userProfile.deleteMany();
    await prisma.user.deleteMany();
    console.log('✅ Cleared existing data');
  }

  // Create demo users
  const hashedPassword = await bcrypt.hash('password123', 10);

  const demoUser = await prisma.user.create({
    data: {
      email: 'demo@devjourney.com',
      username: 'demo_user',
      password: hashedPassword,
      role: 'USER',
      totalXp: 0,
      profile: {
        create: {
          age: 16,
          interests: ['web', 'mobile'],
          preferredLanguage: 'uk',
          skillLevel: 'BEGINNER',
          learningGoals: 'Стати фулстек розробником',
        },
      },
    },
  });

  const adminUser = await prisma.user.create({
    data: {
      email: 'admin@devjourney.com',
      username: 'admin',
      password: hashedPassword,
      role: 'ADMIN',
      totalXp: 5000,
    },
  });

  console.log('✅ Created users');

  // Create Track: Web Development
  const webTrack = await prisma.track.create({
    data: {
      slug: 'web-development',
      title: {
        uk: 'Веб-розробка',
        ru: 'Веб-разработка',
        en: 'Web Development',
      },
      description: {
        uk: 'Навчись створювати сучасні веб-сайти та додатки',
        ru: 'Научись создавать современные веб-сайты и приложения',
        en: 'Learn to build modern websites and applications',
      },
      icon: '🌐',
      level: 'BEGINNER',
      order: 1,
      isActive: true,
    },
  });

  // Create Track: Python Programming
  const pythonTrack = await prisma.track.create({
    data: {
      slug: 'python-basics',
      title: {
        uk: 'Основи Python',
        ru: 'Основы Python',
        en: 'Python Basics',
      },
      description: {
        uk: 'Почни свій шлях у програмуванні з Python',
        ru: 'Начни свой путь в программировании с Python',
        en: 'Start your programming journey with Python',
      },
      icon: '🐍',
      level: 'BEGINNER',
      order: 2,
      isActive: true,
    },
  });

  console.log('✅ Created tracks');

  // Create Course: HTML & CSS Basics
  const htmlCourse = await prisma.course.create({
    data: {
      trackId: webTrack.id,
      slug: 'html-css-basics',
      title: {
        uk: 'Основи HTML та CSS',
        ru: 'Основы HTML и CSS',
        en: 'HTML & CSS Basics',
      },
      description: {
        uk: 'Вивчи основи створення веб-сторінок',
        ru: 'Изучи основы создания веб-страниц',
        en: 'Learn the fundamentals of web page creation',
      },
      duration: 180,
      order: 1,
      prerequisites: [],
      xpReward: 100,
      isActive: true,
    },
  });

  // Create Course: Python for Beginners
  const pythonCourse = await prisma.course.create({
    data: {
      trackId: pythonTrack.id,
      slug: 'python-for-beginners',
      title: {
        uk: 'Python для початківців',
        ru: 'Python для начинающих',
        en: 'Python for Beginners',
      },
      description: {
        uk: 'Вивчи основи програмування на Python',
        ru: 'Изучи основы программирования на Python',
        en: 'Learn Python programming fundamentals',
      },
      duration: 240,
      order: 1,
      prerequisites: [],
      xpReward: 150,
      isActive: true,
    },
  });

  console.log('✅ Created courses');

  // Create Module: Python Variables
  const pythonVariablesModule = await prisma.module.create({
    data: {
      courseId: pythonCourse.id,
      slug: 'variables-and-types',
      title: {
        uk: 'Змінні та типи даних',
        ru: 'Переменные и типы данных',
        en: 'Variables and Data Types',
      },
      description: {
        uk: 'Познайомся зі змінними та основними типами даних у Python',
        ru: 'Познакомься с переменными и основными типами данных в Python',
        en: 'Get familiar with variables and basic data types in Python',
      },
      order: 1,
    },
  });

  console.log('✅ Created modules');

  // Create Lesson: Introduction to Variables
  const variablesLesson = await prisma.lesson.create({
    data: {
      moduleId: pythonVariablesModule.id,
      slug: 'intro-to-variables',
      title: {
        uk: 'Що таке змінні?',
        ru: 'Что такое переменные?',
        en: 'What are Variables?',
      },
      content: {
        uk: `# Що таке змінні?

Змінна - це контейнер для зберігання даних. Уяви, що це коробка з наклейкою (назвою).

## Створення змінних

В Python ти просто пишеш назву і присвоюєш значення:

\`\`\`python
name = "Олександр"
age = 16
is_student = True
\`\`\`

## Типи даних

- **Рядки (str)**: текст у лапках
- **Числа (int)**: цілі числа
- **Дробові (float)**: числа з комою
- **Булеві (bool)**: True або False

## Приклад

\`\`\`python
greeting = "Привіт"
score = 100
pi = 3.14
is_learning = True

print(greeting, "твій рахунок:", score)
\`\`\``,
        ru: `# Что такое переменные?

Переменная - это контейнер для хранения данных...`,
        en: `# What are Variables?

A variable is a container for storing data...`,
      },
      type: 'THEORY',
      duration: 15,
      order: 1,
    },
  });

  console.log('✅ Created lessons');

  // Create Challenge: First Variable
  const firstVariableChallenge = await prisma.challenge.create({
    data: {
      lessonId: variablesLesson.id,
      title: 'Створи свою першу змінну',
      description: `Давай створимо твою першу змінну!

Завдання:
1. Створи змінну з назвою "my_name" і збережи в неї своє ім'я
2. Виведи її на екран за допомогою print()

Приклад виводу:
Іван`,
      difficulty: 'EASY',
      tags: ['variables', 'basics', 'print'],
      language: 'python',
      ageRange: '8-12',
      timeLimit: 3000,
      memoryLimit: 128,
      xpReward: 25,
      starterCode: `# Створи змінну my_name тут


# Виведи її на екран
`,
      solution: `my_name = "Іван"
print(my_name)`,
      hints: {
        uk: [
          'Згадай: змінна створюється так: name = "значення"',
          'Використай функцію print() для виведення',
          'Переконайся, що ім\'я в лапках',
        ],
        en: [
          'Remember: variables are created like: name = "value"',
          'Use the print() function to display',
          'Make sure the name is in quotes',
        ],
      },
    },
  });

  // Create test cases
  await prisma.testCase.createMany({
    data: [
      {
        challengeId: firstVariableChallenge.id,
        input: '',
        expected: 'Іван',
        isPublic: true,
        weight: 1,
      },
      {
        challengeId: firstVariableChallenge.id,
        input: '',
        expected: 'Марія',
        isPublic: false,
        weight: 1,
      },
    ],
  });

  // Create Challenge: Sum Two Numbers
  const sumChallenge = await prisma.challenge.create({
    data: {
      lessonId: variablesLesson.id,
      title: 'Додай два числа',
      description: `Напиши програму, яка додає два числа і виводить результат.

Вхідні дані: два числа a і b
Вихідні дані: їх сума

Приклад:
Вхід: a = 5, b = 3
Вихід: 8`,
      difficulty: 'EASY',
      tags: ['variables', 'math', 'addition'],
      language: 'python',
      ageRange: '13-17',
      timeLimit: 5000,
      memoryLimit: 128,
      xpReward: 30,
      starterCode: `# Прочитай два числа
a = int(input())
b = int(input())

# Додай їх і виведи результат
`,
      solution: `a = int(input())
b = int(input())
result = a + b
print(result)`,
    },
  });

  await prisma.testCase.createMany({
    data: [
      {
        challengeId: sumChallenge.id,
        input: '5\n3',
        expected: '8',
        isPublic: true,
        weight: 1,
      },
      {
        challengeId: sumChallenge.id,
        input: '10\n20',
        expected: '30',
        isPublic: true,
        weight: 1,
      },
      {
        challengeId: sumChallenge.id,
        input: '100\n-50',
        expected: '50',
        isPublic: false,
        weight: 1,
      },
    ],
  });

  console.log('✅ Created challenges and test cases');

  // Create demo progress
  await prisma.courseProgress.create({
    data: {
      userId: demoUser.id,
      courseId: pythonCourse.id,
      completed: false,
      progress: 15,
      startedAt: new Date(),
    },
  });

  await prisma.userProgress.create({
    data: {
      userId: demoUser.id,
      challengeId: firstVariableChallenge.id,
      completed: true,
      bestScore: 100,
      attempts: 2,
      lastAttempt: new Date(),
    },
  });

  // Create XP events
  await prisma.xpEvent.create({
    data: {
      userId: demoUser.id,
      amount: 25,
      reason: 'challenge_completed',
      metadata: {
        challengeId: firstVariableChallenge.id,
        challengeTitle: firstVariableChallenge.title,
      },
    },
  });

  // Update user XP
  await prisma.user.update({
    where: { id: demoUser.id },
    data: { totalXp: 25 },
  });

  console.log('✅ Created progress and XP events');

  // Create Exam
  const pythonBasicsExam = await prisma.exam.create({
    data: {
      courseId: pythonCourse.id,
      title: {
        uk: 'Підсумковий тест: Основи Python',
        ru: 'Итоговый тест: Основы Python',
        en: 'Final Test: Python Basics',
      },
      description: {
        uk: 'Перевір свої знання основ Python',
        ru: 'Проверь свои знания основ Python',
        en: 'Test your knowledge of Python basics',
      },
      duration: 30,
      passingScore: 70,
      order: 1,
      isActive: true,
    },
  });

  await prisma.examQuestion.createMany({
    data: [
      {
        examId: pythonBasicsExam.id,
        question: {
          uk: 'Що виведе цей код?\n\nx = 5\ny = 10\nprint(x + y)',
          ru: 'Что выведет этот код?\n\nx = 5\ny = 10\nprint(x + y)',
          en: 'What will this code output?\n\nx = 5\ny = 10\nprint(x + y)',
        },
        options: {
          uk: ['5', '10', '15', '510'],
          ru: ['5', '10', '15', '510'],
          en: ['5', '10', '15', '510'],
        },
        correctAnswer: '15',
        explanation: {
          uk: 'Оператор + додає числа: 5 + 10 = 15',
          ru: 'Оператор + складывает числа: 5 + 10 = 15',
          en: 'The + operator adds numbers: 5 + 10 = 15',
        },
        points: 10,
        order: 1,
      },
      {
        examId: pythonBasicsExam.id,
        question: {
          uk: 'Який тип даних у змінної: name = "Python"?',
          ru: 'Какой тип данных у переменной: name = "Python"?',
          en: 'What is the data type of: name = "Python"?',
        },
        options: {
          uk: ['int', 'float', 'str', 'bool'],
          ru: ['int', 'float', 'str', 'bool'],
          en: ['int', 'float', 'str', 'bool'],
        },
        correctAnswer: 'str',
        explanation: {
          uk: 'Текст у лапках - це рядок (string, str)',
          ru: 'Текст в кавычках - это строка (string, str)',
          en: 'Text in quotes is a string (str)',
        },
        points: 10,
        order: 2,
      },
    ],
  });

  console.log('✅ Created exams and questions');

  console.log('🎉 Seed completed successfully!');
  console.log('\n📊 Summary:');
  console.log(`- Users: ${await prisma.user.count()}`);
  console.log(`- Tracks: ${await prisma.track.count()}`);
  console.log(`- Courses: ${await prisma.course.count()}`);
  console.log(`- Modules: ${await prisma.module.count()}`);
  console.log(`- Lessons: ${await prisma.lesson.count()}`);
  console.log(`- Challenges: ${await prisma.challenge.count()}`);
  console.log(`- Test Cases: ${await prisma.testCase.count()}`);
  console.log(`- Exams: ${await prisma.exam.count()}`);
  console.log('\n🔐 Demo credentials:');
  console.log('Email: demo@devjourney.com');
  console.log('Password: password123');
}

main()
  .catch((e) => {
    console.error('❌ Error during seed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
