export interface LanguageConfig {
  image: string;
  extension: string;
  compileCommand?: string[];
  runCommand: string[];
  timeoutMultiplier?: number; // For compiled languages
}

export const LANGUAGE_CONFIGS: Record<string, LanguageConfig> = {
  python: {
    image: 'python:3.11-slim',
    extension: '.py',
    runCommand: ['python', 'solution.py'],
  },
  javascript: {
    image: 'node:20-alpine',
    extension: '.js',
    runCommand: ['node', 'solution.js'],
  },
  typescript: {
    image: 'node:20-alpine',
    extension: '.ts',
    runCommand: ['npx', 'ts-node', 'solution.ts'],
    timeoutMultiplier: 1.5, // TS needs more time
  },
  java: {
    image: 'openjdk:17-slim',
    extension: '.java',
    compileCommand: ['javac', 'Solution.java'],
    runCommand: ['java', 'Solution'],
    timeoutMultiplier: 2, // Compilation + execution
  },
  cpp: {
    image: 'gcc:13',
    extension: '.cpp',
    compileCommand: ['g++', '-o', 'solution', 'solution.cpp', '-std=c++17'],
    runCommand: ['./solution'],
    timeoutMultiplier: 1.5,
  },
  c: {
    image: 'gcc:13',
    extension: '.c',
    compileCommand: ['gcc', '-o', 'solution', 'solution.c'],
    runCommand: ['./solution'],
    timeoutMultiplier: 1.5,
  },
  go: {
    image: 'golang:1.21-alpine',
    extension: '.go',
    runCommand: ['go', 'run', 'solution.go'],
  },
  rust: {
    image: 'rust:1.74-slim',
    extension: '.rs',
    compileCommand: ['rustc', 'solution.rs'],
    runCommand: ['./solution'],
    timeoutMultiplier: 2,
  },
};

export function getLanguageConfig(language: string): LanguageConfig {
  const config = LANGUAGE_CONFIGS[language.toLowerCase()];
  if (!config) {
    throw new Error(`Unsupported language: ${language}`);
  }
  return config;
}
