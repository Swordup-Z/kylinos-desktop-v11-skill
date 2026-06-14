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
3. Add a global rule: when handling KylinOS Desktop V11, UKUI, KARE, Kaiming, Clash Verge, system services, autostart, TUN, maintenance mode, PanShi architecture, system protection, partitions, mounts, overlay, or AI subsystem issues, first read $HOME/kylinos-desktop-v11-skill/SKILL.md, then selectively read the relevant references/*.md files listed there.
4. Before any system-level repair, run mm-cli -s to check maintenance mode. If not in maintenance mode, only perform diagnostics and do not modify /usr, /etc, /opt, system packages, services, device nodes, partitions, or KSaf policy.
5. After a fix is confirmed, record reusable findings in this skill's SKILL.md or references/*.md.
6. When running any git commit, do not include AI-related author, co-author, generator, or assistant attribution in the commit author, commit body, or commit trailers.
7. After installation, verify by reading $HOME/kylinos-desktop-v11-skill/SKILL.md and tell me which skill entry point you will use first for future KylinOS Desktop V11 system issues.
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
When handling KylinOS Desktop V11, UKUI, KARE, Kaiming, Clash Verge, system services, autostart, TUN, maintenance mode, PanShi architecture, system protection, partitions, mounts, overlay, or AI subsystem issues, first read `$HOME/kylinos-desktop-v11-skill/SKILL.md`, then selectively read the relevant `references/*.md` files listed there. Do not preload every reference file.

Before any system-level repair, run `mm-cli -s` to check maintenance mode. Only modify `/usr`, `/etc`, `/opt`, system packages, services, device nodes, partitions, or KSaf policy after confirming maintain mode.

After a fix is confirmed, record reusable diagnosis steps, repair steps, risks, or system traits in `$HOME/kylinos-desktop-v11-skill/SKILL.md` or the relevant `references/*.md` file.
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

After setup, describe the system issue directly, for example:

```text
Clash Verge cannot install TUN mode. Please diagnose it.
```

The AI tool should read `SKILL.md`, selectively load the relevant `references/*.md`, and follow the flow: diagnosis -> repair -> verification -> record reusable findings.

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
