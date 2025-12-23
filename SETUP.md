# DevJourney v2 - Setup Guide

## Шаг 1: Настройка Backend

```powershell
# Перейдите в директорию backend
cd d:\DevJourney-v2\backend

# Скопируйте файл окружения
Copy-Item .env.example .env

# Откройте .env и настройте переменные:
# - DATABASE_URL (если не используете Docker)
# - JWT_SECRET (генерируйте случайную строку)
# - AI_API_KEY (получите на https://platform.openai.com/api-keys)
```

## Шаг 2: Установка зависимостей

```powershell
# Вернитесь в корень проекта
cd d:\DevJourney-v2

# Установите зависимости backend
cd backend
pnpm install
cd ..

# Установите зависимости Flutter
cd flutter_app
flutter pub get
cd ..
```

## Шаг 3: Запуск инфраструктуры (PostgreSQL + Redis)

```powershell
# Из корня проекта
docker-compose up -d postgres redis

# Проверьте статус
docker-compose ps
```

## Шаг 4: Настройка базы данных

```powershell
cd backend

# Генерация Prisma Client
pnpm prisma:generate

# Запуск миграций
pnpm prisma:migrate

# Опционально: Откройте Prisma Studio для просмотра БД
pnpm prisma:studio
```

## Шаг 5: Запуск приложения

### Вариант A: Запустить все одновременно
```powershell
# Из корня проекта
pnpm dev
```

### Вариант B: Запустить отдельно (2 терминала)

**Терминал 1 - Backend:**
```powershell
cd d:\DevJourney-v2
pnpm backend:dev
```

**Терминал 2 - Flutter Web:**
```powershell
cd d:\DevJourney-v2
pnpm flutter:run:web
```

## Шаг 6: Доступ к приложению

- 🌐 **Frontend (Flutter Web):** http://localhost:3000
- 🚀 **Backend API:** http://localhost:3001/api
- 📚 **API Documentation:** http://localhost:3001/api/docs
- 🗄️ **Prisma Studio:** http://localhost:5555 (если запущен)

## Дополнительные команды

### Backend
```powershell
cd backend

# Форматирование кода
pnpm format

# Проверка линтером
pnpm lint

# Тесты
pnpm test

# Production build
pnpm build
pnpm start:prod
```

### Flutter
```powershell
cd flutter_app

# Форматирование кода
flutter format .

# Анализ кода
flutter analyze

# Тесты
flutter test

# Сборка для production
flutter build web
flutter build apk
flutter build ios
```

### Docker
```powershell
# Остановить все сервисы
docker-compose down

# Остановить и удалить volumes (сброс данных)
docker-compose down -v

# Пересборка образов
docker-compose build

# Запуск всех сервисов (full stack)
docker-compose up -d

# Просмотр логов
docker-compose logs -f backend
```

## Troubleshooting

### Проблема: Порты заняты
```powershell
# Проверьте занятые порты
Get-NetTCPConnection | Where-Object {$_.LocalPort -eq 3001 -or $_.LocalPort -eq 5432 -or $_.LocalPort -eq 6379}

# Измените порты в docker-compose.yml если нужно
```

### Проблема: Docker не запускается
```powershell
# Убедитесь что Docker Desktop запущен
Get-Process "*docker*"

# Перезапустите Docker Desktop
```

### Проблема: Prisma ошибки
```powershell
cd backend

# Сброс базы данных
pnpm prisma:migrate:reset

# Регенерация клиента
pnpm prisma:generate
```

### Проблема: Flutter pub get ошибки
```powershell
cd flutter_app

# Очистка кэша
flutter clean
flutter pub cache repair
flutter pub get
```

## Создание первого пользователя

После запуска приложения:

1. Откройте http://localhost:3000
2. Нажмите "Register"
3. Введите данные:
   - Email: admin@devjourney.com
   - Username: admin
   - Password: admin123
4. После регистрации вы автоматически войдете в систему

## Следующие шаги

1. ✅ Запустите приложение
2. 📝 Создайте первые challenges через Prisma Studio или API
3. 💻 Протестируйте выполнение кода
4. 🤖 Настройте AI_API_KEY для использования подсказок
5. 🎨 Кастомизируйте UI под свои нужды

Успешной разработки! 🚀
