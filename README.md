# Portable AI for Ventoy / WinPE

Unofficial portable launchers for running native Windows AI coding agents from a Ventoy USB drive in a 64-bit Windows PE environment. Supported agents are OpenAI Codex CLI, Anthropic Claude Code, OpenCode, Crush, and Goose. A portable MinGit runtime is included by the updater for Git operations.

This repository is intentionally **binary-free**. The updater downloads each CLI directly from its official vendor release server and verifies its SHA-256 checksum against official release metadata.

> [!WARNING]
> Windows PE is a recovery/deployment environment, not a general-purpose operating system. Compatibility is best-effort. Native Windows agents may have direct access to every mounted disk. Claude Code has no native Windows OS sandbox, Codex EDIT disables its OS sandbox, and the community agents rely mainly on permission prompts. Review every command before approving it.

## Features

- Drive-letter independent: launchers resolve paths relative to the USB folder.
- Persistent USB profiles for configuration, login state, and sessions.
- Codex SAFE/EDIT, Claude PLAN/MANUAL, and OpenCode PLAN/BUILD launch modes.
- Crush and Goose multi-provider sessions.
- Portable MinGit available to agents and the workspace.
- Device-code login for Codex.
- Official downloads with SHA-256 verification.
- No modification of Ventoy, ISO, WIM, or WinPE images.

## Install

1. Download or clone this repository onto a normal Windows 10/11 x64 or ARM64 computer.
2. Run `Update-PortableAI.cmd` while connected to the internet.
3. Copy the whole folder to the large data partition of your Ventoy USB drive.
4. Boot a recent 64-bit WinPE build and connect to the network.
5. Run `PortableAI.cmd` from the USB drive.
6. Start with **Codex SAFE**, **Claude PLAN**, or **OpenCode PLAN**.

The updater uses these official endpoints:

- Codex: <https://releases.openai.com/codex/>
- Claude Code: <https://downloads.claude.ai/claude-code-releases/>
- OpenCode: <https://github.com/anomalyco/opencode/releases>
- Crush: <https://github.com/charmbracelet/crush/releases>
- Goose CLI: <https://github.com/aaif-goose/goose/releases>
- MinGit: <https://github.com/git-for-windows/git/releases>

## Authentication

- Choose **Codex login** to use the device-code flow.
- Choose **Claude login** to use Anthropic's browser flow. If WinPE cannot open the browser, run the portable folder and log in once from full Windows before booting WinPE.
- Choose **OpenCode provider login** to configure any supported model provider.
- Choose **Goose configure provider** before starting the first Goose session.
- Crush prompts for a provider/API key on first launch. Temporary provider keys can also be supplied through environment variables.
- Credentials and session history are stored under `data/` on the USB drive.

Ventoy data partitions commonly use exFAT, which does not provide Windows per-user ACL protection. Anyone holding the USB may be able to read credentials or session transcripts. Log out before lending the drive, revoke tokens if the drive is lost, and delete `data/` after logout if you do not need prior sessions.

Never place API keys in the `.cmd` files. For temporary API-key use, set variables such as `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, or `OPENROUTER_API_KEY` only in the current terminal session.

## Compatibility notes

- Requires 64-bit Windows/WinPE and at least 4 GB RAM.
- Claude Code supports native Windows but native Windows sandboxing is not available.
- Codex publishes native Windows binaries, but WinPE is not an officially supported Codex environment.
- OpenCode, Crush, and Goose publish native Windows binaries, but none officially list WinPE as a supported environment.
- Goose currently has no native Windows ARM64 CLI release; the updater skips it on ARM64.
- OpenCode falls back to `cmd.exe` when Git Bash is unavailable. MinGit supplies Git but not a full Bash runtime, so shell-heavy prompts may require Windows command syntax.
- If Codex SAFE cannot initialize its Windows sandbox, Codex EDIT is the compatibility fallback. EDIT has direct access to mounted disks; approve commands carefully.
- If a binary reports a missing DLL/API or cannot render its TUI, use a newer WinPE build. A Linux live ISO on the same Ventoy drive is the more reliable fallback.

## What is not included

- Codex, Claude Code, OpenCode, Crush, Goose, or MinGit binaries
- Ventoy
- Sergei Strelec or any other WinPE/ISO distribution
- Account credentials, API keys, or user sessions

## ภาษาไทย

โปรเจกต์นี้เป็น launcher แบบ portable สำหรับเปิด Codex CLI, Claude Code, OpenCode, Crush และ Goose จากแฟลชไดรฟ์ Ventoy ภายใน WinPE x64 โดยไม่ฝัง binary ไว้ใน repository

วิธีใช้สั้น ๆ:

1. ดาวน์โหลด repository บน Windows 10/11 ตัวเต็ม
2. เปิด `Update-PortableAI.cmd` เพื่อดาวน์โหลด binary ทางการและตรวจ SHA-256
3. คัดลอกทั้งโฟลเดอร์ลงพาร์ทิชันข้อมูลของ Ventoy
4. บูต WinPE x64 ต่ออินเทอร์เน็ต แล้วเปิด `PortableAI.cmd`
5. เริ่มด้วย `Codex SAFE`, `Claude PLAN` หรือ `OpenCode PLAN`

WinPE เข้าถึงดิสก์ที่ mount ได้ทั้งหมด ตรวจทุกคำสั่งก่อนอนุมัติ และอย่า commit โฟลเดอร์ `data` เพราะอาจมี token และประวัติ session

## Legal

This community project is not affiliated with or endorsed by OpenAI, Anthropic, Anomaly, Charmbracelet, AAIF, Git for Windows, Ventoy, or Sergei Strelec. Product names are used only to describe compatibility. The scripts in this repository are MIT licensed. Third-party software downloaded by the updater remains subject to its vendor's terms and licenses; see [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).
