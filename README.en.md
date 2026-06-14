# kylinos-desktop-v11-skill

[中文](README.md)

A reusable skill and knowledge base for diagnosing, fixing, verifying, and recording KylinOS Desktop V11 system issues. It covers UKUI, KARE/Kaiming, TUN, autostart, maintenance mode, system services, partitions, mounts, overlay views, and the PanShi system architecture.

## Installation

This repository is not a directly executable program. It is a reusable system troubleshooting skill for AI coding tools. The recommended workflow is: clone it under your home directory, then configure your AI tool's user-level global prompt to read `SKILL.md` whenever you are working on KylinOS Desktop V11 system issues.

### Option 1: Ask An AI Tool To Install It

You can also paste the following prompt into Codex, Claude Code, opencode, or another AI coding tool and let it install the skill for you:

```text
Please install this KylinOS Desktop V11 system troubleshooting skill:

https://github.com/Swordup-Z/kylinos-desktop-v11-skill

Requirements:
1. Clone the repository to $HOME/kylinos-desktop-v11-skill.
2. Depending on the current tool, update the user-level global prompt file:
   - Codex: $HOME/.codex/AGENTS.md
   - Claude Code: $HOME/.claude/CLAUDE.md
   - opencode: $HOME/.config/opencode/AGENTS.md
3. Add a global rule: when handling KylinOS Desktop V11, UKUI, KARE, Kaiming, Clash Verge, system services, autostart, TUN, maintenance mode, PanShi architecture, system protection, partitions, mounts, overlay, or AI subsystem issues, first read $HOME/kylinos-desktop-v11-skill/SKILL.md, then selectively read the relevant references/*.md files listed there; if no specific reference matches, read references/system-maintenance.md at minimum; if the current task is not a desktop-system issue, do not load this skill.
4. Before any system-level repair, run mm-cli -s to check maintenance mode. If not in maintenance mode, only perform diagnostics and do not modify /usr, /etc, /opt, system packages, services, device nodes, partitions, or KSaf policy.
5. After a fix is confirmed, record reusable findings in this skill's SKILL.md or references/*.md; if the issue was not previously covered by this skill, add an appropriate reference file and link it from SKILL.md.
6. When running any git commit, do not include AI-related author, co-author, generator, or assistant attribution in the commit author, commit body, or commit trailers.
7. For future system repairs, use a dedicated session name such as os-fix; if the current AI tool supports session resume commands, continue later with <tool> resume os-fix to restore the same troubleshooting context.
8. After installation, verify by reading $HOME/kylinos-desktop-v11-skill/SKILL.md and tell me which skill entry point you will use first for future KylinOS Desktop V11 system issues.
```

### Option 2: Manual Installation

#### 1. Clone To Your Home Directory

```bash
cd "$HOME"
git clone https://github.com/Swordup-Z/kylinos-desktop-v11-skill.git
```

After cloning, the entry point should be:

```bash
$HOME/kylinos-desktop-v11-skill/SKILL.md
```

#### 2. Configure Your AI Tool's Global Prompt

Add the following instruction to your tool's user-level global prompt file:

```markdown
When handling KylinOS Desktop V11, UKUI, KARE, Kaiming, Clash Verge, system services, autostart, TUN, maintenance mode, PanShi architecture, system protection, partitions, mounts, overlay, or AI subsystem issues, first read `$HOME/kylinos-desktop-v11-skill/SKILL.md`, then selectively read the relevant `references/*.md` files listed there. If no specific reference matches, read `references/system-maintenance.md` at minimum. If the current task is not a desktop-system issue, do not load this skill. Do not preload every reference file.

Before any system-level repair, run `mm-cli -s` to check maintenance mode. Only modify `/usr`, `/etc`, `/opt`, system packages, services, device nodes, partitions, or KSaf policy after confirming maintain mode.

After a fix is confirmed, record reusable diagnosis steps, repair steps, risks, or system traits in `$HOME/kylinos-desktop-v11-skill/SKILL.md` or the relevant `references/*.md` file.

If the resolved KylinOS Desktop V11 system issue was not previously covered by this skill, add an appropriate `references/*.md` file or extend an existing reference, then link it from `SKILL.md`.
```

Common user-level global prompt files:

```text
Codex:       $HOME/.codex/AGENTS.md
Claude Code: $HOME/.claude/CLAUDE.md
opencode:    $HOME/.config/opencode/AGENTS.md
```

For a fuller multi-tool template, see:

```text
references/agent-global-prompts.md
```

#### 3. Verify The Setup

Ask your AI tool:

```text
I need to handle a KylinOS Desktop V11 TUN/autostart/maintenance-mode issue. Which skill entry point will you read first?
```

The expected answer should point to:

```text
$HOME/kylinos-desktop-v11-skill/SKILL.md
```

#### 4. Use It

For system troubleshooting, it is recommended to use a dedicated session such as `os-fix`. This keeps system state, previous diagnostics, maintenance-mode transitions, completed repairs, and recorded findings in one recoverable context.

If your AI tool supports named sessions or session resume commands, continue the same troubleshooting session with a command like:

```bash
<tool> resume os-fix
```

Examples:

```bash
codex resume os-fix
claude resume os-fix
opencode resume os-fix
```

After setup, describe the system issue directly, for example:

```text
Clash Verge cannot install TUN mode. Please diagnose it.
```

The AI tool should read `SKILL.md`, selectively load the relevant `references/*.md`, and follow the flow: diagnosis -> repair -> verification -> record reusable findings.

## Core Requirements

When using this skill for system troubleshooting, the AI tool must follow these baseline rules:

- For any KylinOS Desktop V11 desktop-system maintenance task, read [`SKILL.md`](SKILL.md) first, then selectively read the relevant `references/*.md` files listed there; do not preload every reference file.
- If no specific reference matches, read the general maintenance reference [`references/system-maintenance.md`](references/system-maintenance.md) at minimum.
- Do not load this skill for ordinary coding, documentation, Git operations, or unrelated tasks.
- Follow the loop: diagnosis -> repair -> verification -> record reusable findings.
- Treat persistent repair as the default goal for system issues; after any runtime workaround, verify whether the fix survives reboot, relogin, service restart, or app restart.
- Before system-level repairs, run `mm-cli -s` to check maintenance mode; outside maintenance mode, only perform non-destructive diagnostics such as reading state or simulating installs/removals.
- If the system is not in maintenance mode, enter maintenance mode and ask the user to reboot; after the fix is complete, exit maintenance mode and ask the user to reboot again to return to normal mode.
- Do not delete, move, or overwrite existing executables, configs, subscription files, proxy cores, systemd units, or user data unless the user explicitly asks and the impact has been verified.
- After a fix is confirmed, record reusable diagnosis steps, repair steps, risks, or system traits in `SKILL.md` or the relevant `references/*.md` file.
- If the resolved KylinOS Desktop V11 system issue was not previously covered by this skill, add an appropriate `references/*.md` file or extend an existing reference, then link it from `SKILL.md`.
- When running any `git commit`, do not include AI-related author, co-author, generator, or assistant attribution in the commit author, commit body, or commit trailers.

## Supported Issues

- General system maintenance, maintenance mode, system-level repair boundaries, and the minimal loop for uncovered issues: [`references/system-maintenance.md`](references/system-maintenance.md)
- UKUI right-side system tray icons, StatusNotifier icon order or folded/hidden area not persisting after app or system restart, `systemTray.json`, `orderedItems`, and `separateIndex`: [`references/ukui-system-tray.md`](references/ukui-system-tray.md)
- Graphics drivers, GPU/display frequency, `devfreq` DVFS failures, `failed to set <driver> frequency`, and hardware-specific graphics stability issues such as NVIDIA probing on systems without NVIDIA hardware: [`references/graphics-frequency.md`](references/graphics-frequency.md)
- `ukui-system-service-manager.service` repeated timeouts, `QDBusError("", "")`, `org.ukui.serviceManager` owned by an orphan process, and UKUI system service manager failures: [`references/ukui-system-service-manager.md`](references/ukui-system-service-manager.md)
- Clash Verge Rev TUN mode, `clash-verge-service`, `/dev/net/tun`, and missing or misplaced `verge-mihomo`: [`references/clash-verge-tun.md`](references/clash-verge-tun.md)
- UKUI autostart failures, missing entries in Settings, `sort-app-list` / `statusMap` issues: [`references/ukui-autostart.md`](references/ukui-autostart.md)
- Taskbar/tray AI assistant, AI subsystem cleanup, Kaiming AI assistant, and `kylin-ai-memorymap` box residue: [`references/kylin-ai-subsystem.md`](references/kylin-ai-subsystem.md)
- Root partition, DATA partition, `/home` mounts, PanShi/ostree/overlay/KARE merged views, and disk usage interpretation: [`references/storage-layout.md`](references/storage-layout.md)
- Codex user-level config, default full access, permission display, and maintenance-mode/root permission boundaries: [`references/codex-config.md`](references/codex-config.md)
- Multi-tool global prompt entry points for Codex, Claude Code, opencode, AI-install prompt, and progressive loading template: [`references/agent-global-prompts.md`](references/agent-global-prompts.md)

## Safety

System-level repairs on KylinOS Desktop V11 usually require maintenance mode. Before modifying `/usr`, `/etc`, `/opt`, system packages, services, device nodes, partitions, or KSaf policy, always check the current mode:

```bash
mm-cli -s
```

Only proceed with system-level changes after confirming maintenance mode.

If the system is not in maintenance mode, do not continue with system modifications. First enter maintenance mode:

```bash
sudo mm-cli -o
```

Or, in a graphical/Polkit environment:

```bash
pkexec mm-cli -o
```

After that, reboot the system and reopen the AI tool to continue the repair. Before entering maintenance mode and rebooting, only perform non-destructive diagnostics such as reading state, checking logs, or simulating installs/removals.

After the issue is fixed and verified, save changes and exit maintenance mode:

```bash
sudo mm-cli -c -a
```

Or:

```bash
pkexec mm-cli -c -a
```

Exiting maintenance mode usually also requires another reboot. The system returns to normal mode only after that reboot. Do not leave the system in maintenance mode long-term.

## License

MIT
