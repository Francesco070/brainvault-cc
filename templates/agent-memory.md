---
name: agent-{topic}
description: {one sentence — what kind of task this agent/prompt is good for}
metadata:
  type: agent
  agent_type: {built-in role name, or "custom" for a one-off prompt}
  project: {project-name, or "cross-project"}
  tags: []
  date: YYYY-MM-DD
  template_version: 1
---

## Aufgabe
{What was the task? What made it a good fit for delegating to an agent rather than doing it inline?}

## Agent / Prompt
{The subagent_type used, and the prompt (trimmed of task-specific facts that don't
generalise — keep names/dates/paths that matter, drop ones that don't). Kept verbatim
enough to copy-paste and adapt for a similar case.}

## Ergebnis
{How did it go? Quality of the output, anything that needed correcting afterwards.}

## Wiederverwendbar für
{What class of future problem should reach for this agent/prompt? What would need to
change to adapt it?}

Related memories: [[proj-{project-name}]]
