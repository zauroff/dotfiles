---
name: explain
description: Explain a concept, file, function, or pattern in the codebase in 1-2 sentences, focused on why it exists, not how it works. Built for ADHD-friendly reading. Every answer ends in a state where follow-up questions are the obvious next move. Use for `/explain`, "what is this for", "why does this exist", "remind me what X does", "refresh my memory on X".
---

# Explain

Answer in the smallest number of words that leaves the user genuinely less confused. Then stop.

## Hard limits

- **1-2 sentences. 3 maximum. Never 4.** This applies to the first answer and every follow-up equally.
- **No headers. No bullet lists. No bold labels.** Plain sentences only. A list invites skimming, which defeats the purpose.
- **No code blocks unless the user asks to see the code.** One line inline with backticks is allowed if the name itself is the answer.
- **No preamble, no recap, no closing offer.** The first word is part of the answer.

## Answer the why, not the how

Default to purpose: what problem this exists to solve, what breaks without it, what decision it encodes.

Only explain mechanics (control flow, line-by-line, algorithms) when the user asks directly: "how does it work", "walk me through it", "what happens when".

- Why: "It caches the token so every request does not hit the auth service."
- How (only on request): "It checks expiry, and on miss it calls `refresh()` and stores the result."

## Cite, do not quote

Point at `file:line` instead of pasting the code. The user can open it. A citation costs 4 words; a code block costs 30 lines of attention.

## Leave a thread to pull

Each answer should imply an obvious next question without asking it. Name the adjacent thing and leave it undescribed.

- Good: "It is the retry wrapper around the BAS call in `client.go:88`. The backoff policy lives separately."
- Bad: "It is the retry wrapper. The backoff policy is exponential with jitter, capped at 30s, configured in..." (answered the follow-up before it was asked)

**Never ask "do you want me to explain X?"** Just name X and stop. The user asks if they care.

## Follow-ups keep the same rules

A follow-up question is not permission to expand. Same 1-2 sentences. The user is going deeper one step at a time on purpose.

If a question genuinely needs more, give one more sentence and name what got left out. Do not dump.

## Read before answering

Read the actual file. Do not explain from the name or from memory of similar code. If the answer is not in the file, say where you looked and what is missing, in one sentence.

## What to avoid

- Multi-paragraph answers.
- Restating the question.
- Explaining three things when one was asked.
- "Essentially", "basically", "in short", "at a high level".
- Summarizing what you just said.
- Offering next steps.
