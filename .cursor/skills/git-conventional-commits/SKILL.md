---
name: git-conventional-commits
description: Stages changes, writes Conventional Commits messages (type, optional scope, subject, body, footers), runs git commit and push. Use when the user asks to commit, push, save work to git, or follow conventional commits; use before or after completing a feature or fix.
---

# Git: Conventional Commits and Push

## Workflow

1. **Inspect**: Run `git status` and review `git diff` (staged and unstaged). Understand what changed before writing the message.
2. **Stage**: Stage only what belongs in this commit (`git add <paths>` or `git add -p`). One logical change per commit when possible.
3. **Commit message**: Use the format below. Subject line max ~72 characters; use imperative mood ("add", "fix", not "added", "fixes").
4. **Commit**: `git commit -m "type(scope): subject"` or use multiple `-m` for body/footers, or open editor for multi-paragraph body.
5. **Push**: `git push` (or `git push -u origin <branch>` on first push). Resolve conflicts if push is rejected; never force-push unless the user explicitly asks.

## Commit format (Conventional Commits 1.0.0)

```
<type>(<optional scope>): <subject>

[optional body]

[optional footer(s)]
```

- **type** (common): `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`
- **scope**: optional noun describing the area (e.g. `compass`, `auth`, `api`)
- **subject**: short summary, no trailing period, imperative
- **body**: what/why, wrap ~72 chars
- **footer**: `BREAKING CHANGE: description` or `Closes #123`

## Rules

- Match **type** to the dominant change; split unrelated changes into separate commits.
- If the user specifies a message, still validate it matches conventional format unless they override.
- Do not commit secrets, `.env` with credentials, or large generated artifacts the repo ignores.
- If nothing is staged and the user asked to commit, stage appropriate files after confirming scope—or ask which paths to include.

## Push safety

- Prefer normal `git push`. Use `--force-with-lease` only when the user requests a safe force after explaining risk.
- If pre-commit hooks fail, read hook output and fix issues or report them; do not bypass hooks unless the user asks.

## Examples

See [examples.md](examples.md) for message and command examples.
