# Portable AI for Ventoy / WinPE

[Download the latest Lite bundle](https://github.com/XYLOHEAT/portable-ai-ventoy-winpe/releases/tag/multi-2026.08.12) · [Third-party notices](THIRD-PARTY-NOTICES.md) · [Security policy](SECURITY.md)

Unofficial portable launchers for running native Windows AI coding agents from a Ventoy USB drive in a 64-bit Windows PE environment. The menu supports OpenAI Codex CLI, Anthropic Claude Code, OpenCode, Crush, and Goose, with portable MinGit for Git operations.

This public repository is intentionally **binary-free**. The updater retrieves each CLI from its official release server, verifies SHA-256 against official release metadata, and installs it under `apps/`.

> [!WARNING]
> Windows PE is a recovery/deployment environment, not a general-purpose operating system. Compatibility is best-effort. Agents may have direct access to every mounted disk. Claude Code has no native Windows OS sandbox, Codex EDIT disables its OS sandbox, and the community agents rely mainly on permission prompts. Review every command before approving it.

## Download

The public [Multi-agent Lite release](https://github.com/XYLOHEAT/portable-ai-ventoy-winpe/releases/tag/multi-2026.08.12) contains the launchers, verified updater, documentation, and empty portable directory structure. It does not contain third-party executables.

- File: `PortableAI-Ventoy-WinPE-LITE-MULTI.zip`
- Size: 22,682 bytes
- SHA-256: `9b3de275a9118e4b92bb19e9b945922686d3a27748114d7b7654f0dd6c27db2f`

READY packages that embed downloaded executables are intentionally not published in this public repository. Build one locally by running the updater on full Windows.

## Included launch modes

| Tool | Menu modes | Intended use |
| --- | --- | --- |
| Codex CLI | SAFE / EDIT | Start sandboxed where supported, or use the WinPE compatibility fallback |
| Claude Code | PLAN / MANUAL | Plan without edits, or approve changes manually |
| OpenCode | PLAN / BUILD | Read-only planning or implementation mode |
| Crush | ASK | Multi-provider TUI with permission prompts |
| Goose CLI | SESSION | Configurable multi-provider agent session |
| MinGit | Runtime | Portable Git available to agents and workspaces |

## Install

1. Download and extract the Lite release, or clone this repository, on a normal Windows 10/11 x64 or ARM64 computer.
2. Run `Update-PortableAI.cmd` while connected to the internet.
3. Copy the complete `PortableAI-Ventoy` folder to the large data partition of the Ventoy USB drive.
4. Boot a recent 64-bit WinPE build and connect to the network.
5. Open the USB folder and run `PortableAI.cmd`.
6. Start with **Codex SAFE**, **Claude PLAN**, or **OpenCode PLAN**.

The updater installs all components by default. A single component can be selected from Command Prompt:

```bat
Update-PortableAI.cmd -Component OpenCode
Update-PortableAI.cmd -Component Codex
Update-PortableAI.cmd -Component All
```

Supported component names are `All`, `Codex`, `Claude`, `OpenCode`, `Crush`, `Goose`, and `MinGit`. Claude uses its stable channel by default; use `-ClaudeChannel latest` only when you explicitly want the latest channel.

The updater uses these official endpoints:

- Codex: <https://releases.openai.com/codex/>
- Claude Code: <https://downloads.claude.ai/claude-code-releases/>
- OpenCode: <https://github.com/anomalyco/opencode/releases>
- Crush: <https://github.com/charmbracelet/crush/releases>
- Goose CLI: <https://github.com/aaif-goose/goose/releases>
- MinGit: <https://github.com/git-for-windows/git/releases>

## Portable folders

| Path | Purpose | Safe to publish? |
| --- | --- | --- |
| `apps/` | Downloaded executables and runtimes | No; excluded from this repository |
| `data/` | Logins, provider configuration, caches, and sessions | **Never**; may contain secrets |
| `workspaces/` | Projects opened by the agents | Only after reviewing their contents |
| `licenses/` | Third-party license copies | Yes |

The launcher redirects `HOME`, `USERPROFILE`, `APPDATA`, and tool-specific configuration paths into `data/`, so profiles remain on the USB instead of being written to the WinPE RAM disk.

## Authentication

- Choose **Codex login** to use the device-code flow.
- Choose **Claude login** to use Anthropic's browser flow. If WinPE cannot open the browser, log in once from full Windows using the same portable folder.
- Choose **OpenCode provider login** to configure a supported model provider.
- Choose **Goose configure provider** before starting the first Goose session.
- Crush prompts for a provider/API key on first launch.

Ventoy data partitions commonly use exFAT, which does not provide Windows per-user ACL protection. Anyone holding the USB may be able to read credentials or session transcripts. Log out before lending the drive, revoke tokens if it is lost, and remove `data/` after logout if prior sessions are not required.

Never put API keys in `.cmd` files. For temporary API-key use, set variables such as `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, or `OPENROUTER_API_KEY` only in the current terminal session.

## Compatibility notes

- Requires 64-bit Windows/WinPE and at least 4 GB RAM.
- WinPE is not officially supported by these agents; native Windows compatibility is best-effort.
- Goose currently has no native Windows ARM64 CLI release, so the updater skips Goose on ARM64.
- MinGit supplies Git but not a full Bash runtime. Shell-heavy prompts may require Windows command syntax.
- If Codex SAFE cannot initialize its Windows sandbox, Codex EDIT is the compatibility fallback. EDIT can access mounted disks directly.
- If a binary reports a missing DLL/API or cannot render its TUI, use a newer WinPE build. A Linux live ISO on the same Ventoy drive is a more reliable fallback.

## What is not included

- Agent or MinGit binaries
- Ventoy
- Sergei Strelec or any other WinPE/ISO distribution
- Account credentials, API keys, or user sessions

## ภาษาไทย

โปรเจกต์นี้เป็นเมนู portable สำหรับเปิด Codex CLI, Claude Code, OpenCode, Crush และ Goose จากแฟลชไดรฟ์ Ventoy ภายใน WinPE 64-bit โดย Public repository และไฟล์ Lite **ไม่มี binary ของโปรแกรมเหล่านี้**

วิธีใช้แบบสั้น:

1. ดาวน์โหลด [Lite release ล่าสุด](https://github.com/XYLOHEAT/portable-ai-ventoy-winpe/releases/tag/multi-2026.08.12) แล้วแตกไฟล์บน Windows 10/11 ตัวเต็ม
2. เปิด `Update-PortableAI.cmd` เพื่อดาวน์โหลด binary ทางการและตรวจ SHA-256
3. คัดลอกทั้งโฟลเดอร์ลงพาร์ทิชันข้อมูลของ Ventoy
4. บูต WinPE 64-bit ต่ออินเทอร์เน็ต แล้วเปิด `PortableAI.cmd`
5. เริ่มด้วย `Codex SAFE`, `Claude PLAN` หรือ `OpenCode PLAN`

ข้อมูลบัญชีและ session จะอยู่ใน `data/` บนแฟลช ห้าม commit หรือเผยแพร่โฟลเดอร์นี้ และควรตรวจทุกคำสั่งก่อนอนุมัติเพราะ WinPE มองเห็นดิสก์ที่ mount อยู่ทั้งหมด

## Legal

This community project is not affiliated with or endorsed by OpenAI, Anthropic, Anomaly, Charmbracelet, AAIF, Git for Windows, Ventoy, or Sergei Strelec. Product names are used only to describe compatibility. The scripts in this repository are MIT licensed. Third-party software downloaded by the updater remains subject to its vendor's terms and licenses; see [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).
