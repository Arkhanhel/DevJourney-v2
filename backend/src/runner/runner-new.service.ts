import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as Dockerode from 'dockerode';
import * as path from 'path';
import * as fs from 'fs/promises';
import * as os from 'os';
import { getLanguageConfig } from './language-configs';
import { HmacUtils } from './utils/hmac.utils';

export interface ExecutionResult {
  success: boolean;
  output?: string;
  error?: string;
  executionTime: number;
  memoryUsed?: number;
  exitCode?: number;
}

export interface TestResult {
  passed: boolean;
  input: string;
  expected: string;
  actual: string;
  executionTime: number;
  error?: string;
}

@Injectable()
export class RunnerService {
  private docker: Dockerode;
  private logger = new Logger(RunnerService.name);
  private runnerSecret: string;

  constructor(private config: ConfigService) {
    this.docker = new Dockerode();
    this.runnerSecret = this.config.get<string>('RUNNER_SECRET', 'default-secret');
  }

  /**
   * Execute user code with multiple test cases
   */
  async executeWithTests(
    code: string,
    language: string,
    testCases: Array<{ input: string; expected: string }>,
    timeLimit = 5000,
    memoryLimit = 256,
  ): Promise<{
    results: TestResult[];
    allPassed: boolean;
    totalTime: number;
  }> {
    const results: TestResult[] = [];
    let totalTime = 0;

    for (const testCase of testCases) {
      const result = await this.executeCode(
        code,
        language,
        testCase.input,
        timeLimit,
        memoryLimit,
      );

      const passed =
        result.success &&
        result.output?.trim() === testCase.expected.trim();

      results.push({
        passed,
        input: testCase.input,
        expected: testCase.expected,
        actual: result.output?.trim() || '',
        executionTime: result.executionTime,
        error: result.error,
      });

      totalTime += result.executionTime;

      // Stop on first failure for faster feedback (optional)
      // if (!passed) break;
    }

    return {
      results,
      allPassed: results.every((r) => r.passed),
      totalTime,
    };
  }

  /**
   * Execute single code execution
   */
  async executeCode(
    code: string,
    language: string,
    testInput: string,
    timeLimit = 5000,
    memoryLimit = 256,
  ): Promise<ExecutionResult> {
    const startTime = Date.now();

    try {
      const config = getLanguageConfig(language);
      const workDir = await this.createWorkspace(code, language, config.extension);

      // Adjust timeout for compiled languages
      const adjustedTimeout =
        timeLimit * (config.timeoutMultiplier || 1);

      // Compile if needed
      if (config.compileCommand) {
        const compileResult = await this.compileCode(
          workDir,
          config.image,
          config.compileCommand,
          timeLimit,
        );
        if (!compileResult.success) {
          await this.cleanup(workDir);
          return {
            ...compileResult,
            executionTime: Date.now() - startTime,
          };
        }
      }

      // Execute
      const execResult = await this.runCode(
        workDir,
        config.image,
        config.runCommand,
        testInput,
        adjustedTimeout,
        memoryLimit,
      );

      await this.cleanup(workDir);

      return {
        ...execResult,
        executionTime: Date.now() - startTime,
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

  /**
   * Create workspace directory with code file
   */
  private async createWorkspace(
    code: string,
    language: string,
    extension: string,
  ): Promise<string> {
    const workDir = path.join(
      os.tmpdir(),
      `devjourney-${Date.now()}-${Math.random().toString(36).substring(7)}`,
    );

    await fs.mkdir(workDir, { recursive: true });

    const fileName =
      language === 'java' ? 'Solution' + extension : 'solution' + extension;
    await fs.writeFile(path.join(workDir, fileName), code, 'utf8');

    return workDir;
  }

  /**
   * Compile code (for compiled languages)
   */
  private async compileCode(
    workDir: string,
    image: string,
    compileCommand: string[],
    timeLimit: number,
  ): Promise<ExecutionResult> {
    try {
      const container = await this.docker.createContainer({
        Image: image,
        Cmd: compileCommand,
        WorkingDir: '/workspace',
        HostConfig: {
          Binds: [`${workDir}:/workspace`],
          Memory: 512 * 1024 * 1024, // 512 MB for compilation
          NetworkMode: 'none',
          ReadonlyRootfs: false,
        },
        Tty: false,
      });

      await container.start();

      const execResult = await Promise.race([
        this.captureOutput(container),
        this.timeout(timeLimit * 2), // More time for compilation
      ]);

      await container.remove({ force: true });

      if (execResult === 'TIMEOUT') {
        return {
          success: false,
          error: 'Compilation timeout',
          executionTime: timeLimit * 2,
        };
      }

      if (execResult.exitCode !== 0) {
        return {
          success: false,
          error: execResult.stderr || 'Compilation failed',
          executionTime: 0,
        };
      }

      return {
        success: true,
        output: execResult.stdout,
        executionTime: 0,
      };
    } catch (error) {
      return {
        success: false,
        error: `Compilation error: ${error.message}`,
        executionTime: 0,
      };
    }
  }

  /**
   * Run code in Docker container
   */
  private async runCode(
    workDir: string,
    image: string,
    runCommand: string[],
    input: string,
    timeLimit: number,
    memoryLimit: number,
  ): Promise<ExecutionResult> {
    try {
      const container = await this.docker.createContainer({
        Image: image,
        Cmd: runCommand,
        WorkingDir: '/workspace',
        HostConfig: {
          Binds: [`${workDir}:/workspace:ro`], // Read-only for security
          Memory: memoryLimit * 1024 * 1024,
          MemorySwap: memoryLimit * 1024 * 1024, // No swap
          NanoCpus: 1000000000, // 1 CPU
          NetworkMode: 'none', // No network access
          ReadonlyRootfs: true, // Read-only filesystem
          PidsLimit: 50, // Limit processes
        },
        OpenStdin: true,
        StdinOnce: true,
        Tty: false,
      });

      await container.start();

      // Send input if provided
      if (input) {
        const stream = await container.attach({
          stream: true,
          stdin: true,
          stdout: false,
          stderr: false,
        });
        stream.write(input);
        stream.end();
      }

      const execResult = await Promise.race([
        this.captureOutput(container),
        this.timeout(timeLimit),
      ]);

      await container.remove({ force: true });

      if (execResult === 'TIMEOUT') {
        return {
          success: false,
          error: 'Time limit exceeded',
          executionTime: timeLimit,
        };
      }

      return {
        success: execResult.exitCode === 0,
        output: execResult.stdout,
        error: execResult.exitCode !== 0 ? execResult.stderr : undefined,
        executionTime: 0,
        exitCode: execResult.exitCode,
      };
    } catch (error) {
      return {
        success: false,
        error: `Runtime error: ${error.message}`,
        executionTime: 0,
      };
    }
  }

  /**
   * Capture container output
   */
  private async captureOutput(
    container: Dockerode.Container,
  ): Promise<{ stdout: string; stderr: string; exitCode: number }> {
    const stream = await container.attach({
      stream: true,
      stdout: true,
      stderr: true,
    });

    let stdout = '';
    let stderr = '';

    return new Promise((resolve) => {
      stream.on('data', (chunk: Buffer) => {
        // Docker multiplexes stdout/stderr
        // First byte indicates stream type: 1=stdout, 2=stderr
        const streamType = chunk[0];
        const data = chunk.slice(8).toString(); // Skip 8-byte header

        if (streamType === 1) {
          stdout += data;
        } else if (streamType === 2) {
          stderr += data;
        }
      });

      container.wait().then((result) => {
        resolve({
          stdout: stdout.trim(),
          stderr: stderr.trim(),
          exitCode: result.StatusCode,
        });
      });
    });
  }

  /**
   * Timeout promise
   */
  private timeout(ms: number): Promise<'TIMEOUT'> {
    return new Promise((resolve) => setTimeout(() => resolve('TIMEOUT'), ms));
  }

  /**
   * Cleanup workspace
   */
  private async cleanup(workDir: string): Promise<void> {
    try {
      await fs.rm(workDir, { recursive: true, force: true });
    } catch (error) {
      this.logger.warn(`Cleanup failed for ${workDir}: ${error.message}`);
    }
  }

  /**
   * Generate HMAC signature for callback
   */
  generateCallbackSignature(payload: any): string {
    return HmacUtils.generateSignature(payload, this.runnerSecret);
  }

  /**
   * Verify callback signature
   */
  verifyCallbackSignature(payload: any, signature: string): boolean {
    return HmacUtils.verifySignature(payload, signature, this.runnerSecret);
  }
}
