import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';
import { PrismaService } from '../prisma/prisma.service';
import {
  SYSTEM_PROMPTS,
  AGE_ADAPTATIONS,
  getAgeGroup,
} from './prompts/system-prompts';
import { GenerateHintDto, HintResponseDto } from './dto/hint.dto';

@Injectable()
export class AiService {
  private logger = new Logger(AiService.name);
  private apiKey: string;
  private model: string;
  private apiUrl = 'https://api.openai.com/v1/chat/completions';

  constructor(
    private config: ConfigService,
    private prisma: PrismaService,
  ) {
    this.apiKey = this.config.get<string>('AI_API_KEY');
    this.model = this.config.get<string>('AI_MODEL', 'gpt-4-turbo-preview');
  }

  async generateProgressiveHint(
    userId: string,
    dto: GenerateHintDto,
  ): Promise<HintResponseDto> {
    try {
      const { challengeId, userCode, attempts, failingOutput, locale = 'uk' } = dto;

      // Get user profile
      const userProfile = await this.prisma.userProfile.findUnique({
        where: { userId },
        include: { user: true },
      });

      // Get challenge details
      const challenge = await this.prisma.challenge.findUnique({
        where: { id: challengeId },
        include: { lesson: true },
      });

      if (!challenge) {
        throw new Error('Challenge not found');
      }

      // Calculate hint level
      const hintLevel = this.calculateHintLevel(attempts);

      // Get previous hints
      const previousHints = await this.prisma.aiHintEvent.findMany({
        where: { userId, challengeId },
        orderBy: { createdAt: 'desc' },
        take: 3,
      });

      // Build personalized prompt
      const systemPrompt = this.buildSystemPrompt(userProfile, locale);
      const userPrompt = this.buildUserPrompt({
        challenge,
        userCode,
        hintLevel,
        previousHints,
        failingOutput,
        userAge: userProfile?.age,
        skillLevel: userProfile?.skillLevel,
        locale,
      });

      // Call OpenAI
      const response = await this.callOpenAI(systemPrompt, userPrompt);

      // Parse response
      const hintResponse = this.parseHintResponse(response, hintLevel, locale);

      // Save hint event
      await this.prisma.aiHintEvent.create({
        data: {
          userId,
          challengeId,
          hintLevel,
          hintText: hintResponse.hintText,
          locale,
        },
      });

      return hintResponse;
    } catch (error) {
      this.logger.error(`AI hint generation failed: ${error.message}`);
      throw new Error('Failed to generate hint. Please try again later.');
    }
  }

  private calculateHintLevel(attempts: number): number {
    if (attempts <= 2) return 1; // General direction
    if (attempts === 3) return 2; // Specific advice
    if (attempts === 4) return 3; // Code example
    if (attempts === 5) return 4; // Step-by-step
    return 5; // Full solution
  }

  private buildSystemPrompt(userProfile: any, locale: string): string {
    const basePrompt = SYSTEM_PROMPTS[locale]?.tutor || SYSTEM_PROMPTS['uk'].tutor;
    
    if (!userProfile) {
      return basePrompt;
    }

    const ageGroup = getAgeGroup(userProfile.age);
    const adaptation = AGE_ADAPTATIONS[ageGroup];

    return `${basePrompt}

КОНТЕКСТ УЧНЯ:
- Вік: ${userProfile.age || 'не вказано'}
- Рівень: ${userProfile.skillLevel || 'BEGINNER'}
- Інтереси: ${userProfile.interests?.join(', ') || 'загальне програмування'}
- Цілі: ${userProfile.learningGoals || 'вивчити програмування'}

АДАПТАЦІЯ СТИЛЮ:
- Стиль: ${adaptation.style}
- Приклади: ${adaptation.examples}
- Тон: ${adaptation.tone}
- Складність: ${adaptation.complexity}`;
  }

  private buildUserPrompt(context: any): string {
    const {
      challenge,
      userCode,
      hintLevel,
      previousHints,
      failingOutput,
      locale,
    } = context;

    let prompt = `
ЗАДАЧА: ${challenge.title}
ОПИС: ${challenge.description}
МОВА ПРОГРАМУВАННЯ: ${challenge.language}
СКЛАДНІСТЬ: ${challenge.difficulty}

КОД СТУДЕНТА:
\`\`\`${challenge.language}
${userCode}
\`\`\`
`;

    if (failingOutput) {
      prompt += `\nПОМИЛКА АБО НЕВІРНИЙ ВИВІД:\n${failingOutput}\n`;
    }

    if (previousHints.length > 0) {
      prompt += `\nПОПЕРЕДНІ ПІДКАЗКИ:\n`;
      previousHints.forEach((hint, index) => {
        prompt += `${index + 1}. Рівень ${hint.hintLevel}: ${hint.hintText}\n`;
      });
      prompt += `\nНЕ ПОВТОРЮЙ попередні підказки. Надай нову інформацію.\n`;
    }

    prompt += `\nПОТРІБНИЙ РІВЕНЬ ПІДКАЗКИ: ${hintLevel}

Згідно з політикою прогресивних підказок, надай підказку рівня ${hintLevel}.

ФОРМАТ ВІДПОВІДІ (JSON):
{
  "hintText": "Основний текст підказки",
  "partialCode": "Якщо потрібно - приклад коду або фрагмент",
  "explanation": "Детальне пояснення концепції",
  "encouragement": "Мотивуюче повідомлення"
}`;

    return prompt;
  }

  private async callOpenAI(
    systemPrompt: string,
    userPrompt: string,
  ): Promise<string> {
    const response = await axios.post(
      this.apiUrl,
      {
        model: this.model,
        messages: [
          {
            role: 'system',
            content: systemPrompt,
          },
          {
            role: 'user',
            content: userPrompt,
          },
        ],
        temperature: 0.7,
        max_tokens: 800,
        response_format: { type: 'json_object' },
      },
      {
        headers: {
          Authorization: `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
        },
      },
    );

    return response.data.choices[0].message.content;
  }

  private parseHintResponse(
    response: string,
    hintLevel: number,
    locale: string,
  ): HintResponseDto {
    try {
      const parsed = JSON.parse(response);
      return {
        level: hintLevel,
        hintText: parsed.hintText || parsed.hint || 'Спробуй ще раз!',
        partialCode: parsed.partialCode,
        explanation: parsed.explanation || '',
        encouragement: parsed.encouragement || 'Ти впораєшся! 💪',
      };
    } catch (error) {
      this.logger.error(`Failed to parse AI response: ${error.message}`);
      // Fallback
      return {
        level: hintLevel,
        hintText: response,
        explanation: '',
        encouragement: 'Продовжуй пробувати!',
      };
    }
  }

  async analyzeCode(code: string, language: string): Promise<any> {
    try {
      const prompt = `
Проаналізуй наступний ${language} код та надай:
1. Оцінку якості коду (0-100)
2. Потенційні баги або проблеми
3. Міркування щодо продуктивності
4. Рекомендації best practices

**Код:**
\`\`\`${language}
${code}
\`\`\`

Відповідь у JSON форматі.
`;

      const response = await axios.post(
        this.apiUrl,
        {
          model: this.model,
          messages: [
            {
              role: 'system',
              content:
                'Ти - експерт з аналізу коду. Надавай конструктивні та корисні відгуки.',
            },
            {
              role: 'user',
              content: prompt,
            },
          ],
          temperature: 0.3,
          max_tokens: 600,
          response_format: { type: 'json_object' },
        },
        {
          headers: {
            Authorization: `Bearer ${this.apiKey}`,
            'Content-Type': 'application/json',
          },
        },
      );

      return JSON.parse(response.data.choices[0].message.content);
    } catch (error) {
      this.logger.error(`Code analysis failed: ${error.message}`);
      throw new Error('Failed to analyze code');
    }
  }
}
