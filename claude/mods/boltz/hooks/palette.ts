import type { Theme, ThemeChoice } from "../types";

export type Palette = {
  ink: string;
  grey: string;
  dim: string;
  rule: string;
  orange: string;
  blue: string;
  green: string;
  white: string;
  red: string;
  onChip: string;
  highlight: string;
  codeBg: string;
};

export const PALETTES: Record<Theme, Palette> = {
  dark: {
    ink: "#f0f0ec",
    grey: "#8a8a85",
    dim: "#3a3a37",
    rule: "#5a5a55",
    orange: "#ff5a1f",
    blue: "#3d7bff",
    green: "#1fc77a",
    white: "#f0f0ec",
    red: "#ff3b30",
    onChip: "#0d0d0d",
    highlight: "#3b1d12",
    codeBg: "#171716",
  },
  light: {
    ink: "#161616",
    grey: "#65655e",
    dim: "#b0b0a9",
    rule: "#9a9a93",
    orange: "#cc3d00",
    blue: "#0047ff",
    green: "#007d4b",
    white: "#161616",
    red: "#cc1a16",
    onChip: "#ffffff",
    highlight: "#ffd3bf",
    codeBg: "#f4f4f0",
  },
};

export const THEMES = Object.keys(PALETTES) as Theme[];

export const THEME_CHOICES: ThemeChoice[] = ["auto", ...THEMES];

export function themeFromName(name: unknown): Theme | null {
  if (typeof name !== "string") return null;
  const lower = name.toLowerCase();
  if (lower.startsWith("light")) return "light";
  if (lower.startsWith("dark")) return "dark";
  return null;
}

export function themeFromCustom(name: string, definition: string): Theme | null {
  try {
    const fromBase = themeFromName(
      (JSON.parse(definition) as { base?: unknown }).base,
    );
    if (fromBase !== null) return fromBase;
  } catch {}
  if (/light/i.test(name)) return "light";
  if (/dark/i.test(name)) return "dark";
  return null;
}

export type Category = "read" | "write" | "shell" | "agent" | "other";

const CATEGORIES: Record<string, Category> = {
  Read: "read",
  Grep: "read",
  Glob: "read",
  LSP: "read",
  WebFetch: "read",
  WebSearch: "read",
  Edit: "write",
  MultiEdit: "write",
  Write: "write",
  NotebookEdit: "write",
  Bash: "shell",
  Agent: "agent",
  Task: "agent",
  Skill: "agent",
};

export function categoryOf(tool: string): Category {
  return CATEGORIES[tool] ?? "other";
}

export function categoryColor(palette: Palette, category: Category): string {
  switch (category) {
    case "read":
      return palette.blue;
    case "write":
      return palette.green;
    case "shell":
      return palette.orange;
    case "agent":
      return palette.white;
    case "other":
      return palette.grey;
  }
}

export function toolLabel(tool: string): string {
  const parts = tool.split("__");
  const name = parts.length >= 3 ? parts[1]! : tool;
  return name.toUpperCase();
}
