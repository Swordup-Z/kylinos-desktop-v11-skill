# kylinos-desktop-v11-skill

[中文](README.md)

A reusable skill and knowledge base for diagnosing, fixing, verifying, and recording KylinOS Desktop V11 system issues. It covers UKUI, KARE/Kaiming, TUN, autostart, maintenance mode, system services, partitions, mounts, overlay views, and the PanShi system architecture.

## Usage

This repository is not a directly executable program. It is a reusable system troubleshooting skill for AI coding tools. The recommended workflow is: clone it under your home directory, then configure your AI tool's user-level global prompt to read `SKILL.md` whenever you are working on KylinOS Desktop V11 system issues.

### 1. Clone To Your Home Directory

```bash
cd "$HOME"
git clone https://github.com/Swordup-Z/kylinos-desktop-v11-skill.git
```

After cloning, the entry point should be:

```bash
$HOME/kylinos-desktop-v11-skill/SKILL.md
```

### 2. Configure Your AI Tool's Global Prompt

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

### 3. Verify The Setup

Ask your AI tool:

```text
I need to handle a KylinOS Desktop V11 TUN/autostart/maintenance-mode issue. Which skill entry point will you read first?
```

The expected answer should point to:

```text
$HOME/kylinos-desktop-v11-skill/SKILL.md
```

### 4. Use It

After setup, describe the system issue directly, for example:

```text
Clash Verge cannot install TUN mode. Please diagnose it.
```

The AI tool should read `SKILL.md`, selectively load the relevant `references/*.md`, and follow the flow: diagnosis -> repair -> verification -> record reusable findings.

## Safety

System-level repairs on KylinOS Desktop V11 may require maintenance mode. Before modifying `/usr`, `/etc`, `/opt`, system packages, services, device nodes, partitions, or KSaf policy, check:

```bash
mm-cli -s
```

Only proceed with system-level changes after confirming maintenance mode.

## License

MIT
