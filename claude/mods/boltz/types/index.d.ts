export type Theme = "dark" | "light";

export type ThemeChoice = "auto" | Theme;

export type BtwQuestion = {
  question: string;
  answer: string | null;
  error: string | null;
};

export type BtwThread = {
  turn: number;
  prompt: string;
  reply: string;
  questions: BtwQuestion[];
};

declare module "claude-code" {
  interface PluginState {
    boltz: {
      isOn: boolean;
      tocIsOpen: boolean;
      tocVersion: number;
      theme: Theme;
      themeChoice: ThemeChoice;
      phase: number;
      isWorking: boolean;
      liveTurn: number | null;
      replyNumbers: Record<string, number | null>;
      durations: Record<string, number>;
      btwThreads: Record<string, BtwThread>;
    };
  }
}
