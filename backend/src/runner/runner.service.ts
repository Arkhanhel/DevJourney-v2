import { Injectable, Logger } from '@nestjs/common';
import * as Dockerode from 'dockerode';
import * as path from 'path';
import * as fs from 'fs/promises';

export interface ExecutionResult {
  success: boolean;
  output?: string;
  error?: string;
  executionTime: number;
  memoryUsed?: number;
}

@Injectable()
export class RunnerService {
  private docker: Dockerode;
  private logger = new Logger(RunnerService.name);

  constructor() {
    this.docker = new Dockerode();
  }

  async executeCode(
    code: string,
    language: string,
    testInput: string,
    timeLimit = 5000,
    memoryLimit = 256,
  ): Promise<ExecutionResult> {
    const startTime = Date.now();

    try {
      const { image, fileName, runCommand } = this.getLanguageConfig(language);

      // Create container
      const container = await this.docker.createContainer({
        Image: image,
        Cmd: runCommand,
        AttachStdout: true,
        AttachStderr: true,
        Tty: false,
        HostConfig: {
          Memory: memoryLimit * 1024 * 1024, // Convert MB to bytes
          NanoCpus: 1000000000, // 1 CPU
          NetworkMode: 'none',
        },
        WorkingDir: '/workspace',
      });

      // Start container
      await container.start();

      // Wait for execution with timeout
      const execResult = await Promise.race([
        this.waitForExecution(container, testInput),
        this.timeout(timeLimit),
      ]);

      const executionTime = Date.now() - startTime;

      // Cleanup
      await container.remove({ force: true });

      if (execResult === 'TIMEOUT') {
        return {
          success: false,
          error: 'Time limit exceeded',
          executionTime,
        };
      }

      return {
        success: !execResult.error,
        output: execResult.output,
        error: execResult.error,
        executionTime,
      };
    } catch (error) {
      this.logger.error(`Execution error: ${error.message}`);
      return {
        success: false,
        error: error.message,
        executionTime: Date.now() - startTime,
      };
    }
  }

  private async waitForExecution(
    container: Dockerode.Container,
    input: string,
  ): Promise<{ output?: string; error?: string }> {
    const stream = await container.attach({
      stream: true,
      stdout: true,
      stderr: true,
      stdin: true,
    });

    let output = '';
    let error = '';

    stream.on('data', (chunk) => {
      const data = chunk.toString();
      output += data;
    });

    // Send input
    if (input) {
      stream.write(input);
    }
    stream.end();

    // Wait for container to finish
    await container.wait();

    return { output, error };
  }

  private timeout(ms: number): Promise<'TIMEOUT'> {
    return new Promise((resolve) => setTimeout(() => resolve('TIMEOUT'), ms));
  }

  private getLanguageConfig(language: string) {
    const configs = {
      javascript: {
        image: 'node:18-alpine',
        fileName: 'solution.js',
        runCommand: ['node', 'solution.js'],
      },
      python: {
        image: 'python:3.11-alpine',
        fileName: 'solution.py',
        runCommand: ['python', 'solution.py'],
      },
      java: {
        image: 'openjdk:17-alpine',
        fileName: 'Solution.java',
        runCommand: ['sh', '-c', 'javac Solution.java && java Solution'],
      },
      cpp: {
        image: 'gcc:12-alpine',
        fileName: 'solution.cpp',
        runCommand: ['sh', '-c', 'g++ solution.cpp -o solution && ./solution'],
      },
    };

    return configs[language] || configs.javascript;
  }
}
