# Security

## Sensitive local data

The launchers deliberately store CLI state under `data/` so it persists across WinPE reboots. Depending on the CLI and authentication method, this directory can contain credentials, account tokens, command history, source excerpts, and complete session transcripts.

The repository's `.gitignore` excludes `data/`. Never force-add it, attach it to an issue, or include it in a release archive.

If a USB drive is lost:

1. Revoke the affected OpenAI and Anthropic sessions or tokens immediately.
2. Rotate any API keys used from that environment.
3. Review account activity.

## Reporting a problem

Open a GitHub issue for launcher or updater bugs, but remove usernames, drive contents, tokens, API keys, and session transcripts first. Report vulnerabilities in Codex or Claude Code directly to their respective vendors.
