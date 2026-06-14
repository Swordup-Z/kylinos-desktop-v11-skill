# kylinos-desktop-v11-skill

[中文](README.md)

A reusable skill and knowledge base for diagnosing, fixing, verifying, and recording KylinOS Desktop V11 system issues. It covers application installation and package management, UKUI, KARE/Kaiming, Clash Verge TUN, autostart, maintenance mode, system services, graphics/frequency issues, tray behavior, global search, source-rebuild assessment for system-component fixes, AI subsystem cleanup, partitions, mounts, overlay views, system-noise cleanup, global prompts for AI tools, and the PanShi system architecture.

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
- If an issue requires rebuilding a system source package, replacing a system shared library, or assessing ABI/SONAME/dependency/RPATH risk, read the specific scenario reference first, then [`knowledge/source-rebuild/README.md`](knowledge/source-rebuild/README.md).
- Do not load this skill for ordinary coding, documentation, Git operations, or unrelated tasks.
- Follow the loop: diagnosis -> repair -> verification -> record reusable findings.
- Treat persistent repair as the default goal for system issues; after any runtime workaround, verify whether the fix survives reboot, relogin, service restart, or app restart.
- Before system-level repairs, run `mm-cli -s` to check maintenance mode; outside maintenance mode, only perform non-destructive diagnostics such as reading state or simulating installs/removals.
- If the system is not in maintenance mode, enter maintenance mode and ask the user to reboot; after the fix is complete, exit maintenance mode and ask the user to reboot again to return to normal mode.
- Do not delete, move, or overwrite existing executables, configs, subscription files, proxy cores, systemd units, or user data unless the user explicitly asks and the impact has been verified.
- After a fix is confirmed, record reusable diagnosis steps, repair steps, risks, or system traits in `SKILL.md` or the relevant `references/*.md` file.
- If the resolved KylinOS Desktop V11 system issue was not previously covered by this skill, add an appropriate `references/*.md` file or extend an existing reference, then link it from `SKILL.md`.
- Before running `git commit` in this repository, check whether `README.md` and `README.en.md` need to be updated. If the change affects installation, core requirements, supported issue coverage, reference entry points, safety boundaries, global prompts, or the public usage workflow, update the READMEs in the same commit.
- When running any `git commit`, do not include AI-related author, co-author, generator, or assistant attribution in the commit author, commit body, or commit trailers.

## Supported Issues

The skill currently covers the issue types below. Each item links to its reference file; AI tools should load only the relevant references instead of preloading the whole repository.

### System Maintenance And Safety Boundaries

- Maintenance-mode checks, entering/exiting maintenance mode, and `mm-cli -s` / `mm-cli -o` / `mm-cli -c -a` boundaries: [`references/system-maintenance.md`](references/system-maintenance.md)
- Safe flow before command-line installs or writes to `/usr`, `/etc`, `/opt`, systemd units, device nodes, or system packages under the PanShi architecture: [`references/system-maintenance.md`](references/system-maintenance.md)
- The minimal loop for uncovered issues: diagnosis -> repair -> verification -> reusable finding capture: [`references/system-maintenance.md`](references/system-maintenance.md)

### System Health Checks And Noise Cleanup

- System-noise cleanup after full health checks, including `motd-news.service`, missing `pam_gnome_keyring.so`, and legacy rsyslog `$IMJournalStateFile` directives: [`references/system-health-noise.md`](references/system-health-noise.md)

### Application Installation And Package Management

- Host-side command-line installs, KARE mis-install detection, and whether an application entry comes from KARE or the host: [`references/application-installation.md`](references/application-installation.md)
- User-level AppImage installs, ARM64/x86-64 architecture checks, desktop entries, user icon-theme caches, and UKUI start-menu icon issues: [`references/application-installation.md`](references/application-installation.md)
- AppImage `libfuse.so.2` failures, `libfuse2` installation, and verification: [`references/application-installation.md`](references/application-installation.md)
- Stale third-party apt sources, missing signing keys, `NO_PUBKEY`, and source cleanup after the user chooses to remove an application: [`references/application-installation.md`](references/application-installation.md)

### KARE And Host Boundaries

- KARE namespaces, applications showing hostname as `kare`, host hostname validation, and KARE base-environment risks: [`references/kare-namespace.md`](references/kare-namespace.md)
- KARE desktop-entry overrides, pinned menu entries still pointing to KARE, and host-native entry validation: [`references/kare-namespace.md`](references/kare-namespace.md)
- Recovery after accidentally starting the UKUI panel from a KARE environment, including namespace validation: [`references/kare-namespace.md`](references/kare-namespace.md)

### Network Proxy And Clash Verge

- Clash Verge Rev TUN installation failures, missing `/dev/net/tun`, and persistent TUN device handling: [`references/clash-verge-tun.md`](references/clash-verge-tun.md)
- `clash-verge-service` installation, startup, status validation, and permission issues: [`references/clash-verge-tun.md`](references/clash-verge-tun.md)
- Missing or misplaced `verge-mihomo`, KARE shadow/upper path recovery, and proxy group disappearance after core-path problems: [`references/clash-verge-tun.md`](references/clash-verge-tun.md)

### UKUI Desktop And System Services

- UKUI autostart failures, missing Settings entries, original `.desktop` repair, icon resolution, and `sort-app-list` / `statusMap` issues: [`references/ukui-autostart.md`](references/ukui-autostart.md)
- UKUI global shortcut conflicts, Settings reporting that a shortcut is occupied by the system, global search shortcuts, and `Alt+Space` conflicts with the window menu: [`references/ukui-keybindings.md`](references/ukui-keybindings.md)
- UKUI global-search result sources, Software Center results for uninstalled apps, and disabling or rolling back the Software Center search D-Bus provider: [`references/ukui-search.md`](references/ukui-search.md)
- Source matching, building, and ABI-risk checks for adding Bing/Google or other hard-coded default web search engines to UKUI global search: [`knowledge/source-rebuild/ukui-search-web-engine.md`](knowledge/source-rebuild/ukui-search-web-engine.md)
- UKUI right-side system tray icon order and folded/hidden area persistence, `systemTray.json`, `orderedItems`, and `separateIndex`: [`references/ukui-system-tray.md`](references/ukui-system-tray.md)
- `ukui-system-service-manager.service` repeated timeouts, `QDBusError("", "")`, `org.ukui.serviceManager` owned by an orphan process, and persistent D-Bus activation repair: [`references/ukui-system-service-manager.md`](references/ukui-system-service-manager.md)
- Taskbar/tray AI assistant, AI subsystem cleanup, Kaiming AI assistant removal boundaries, and residue cleanup: [`references/kylin-ai-subsystem.md`](references/kylin-ai-subsystem.md)

### Fingerprint And Biometrics

- `GW_Fingerprint_PA` fingerprint driver recovery, Pixelauth T350P package installation, `biometric-authentication.service` validation, and diagnostics for registered drivers whose devices are not detected: [`references/biometric-fingerprint.md`](references/biometric-fingerprint.md)

### Graphics, Frequency, And Hardware-Specific Stability

- Graphics drivers, GPU/display frequency, `devfreq` DVFS failures, and `failed to set <driver> frequency`: [`references/graphics-frequency.md`](references/graphics-frequency.md)
- Hardware-specific graphics stability diagnosis, such as Phytium FTG / `PHYT0048:00`, and UKUI power-management policy handling: [`references/graphics-frequency.md`](references/graphics-frequency.md)
- NVIDIA probing on systems without NVIDIA hardware, `NVRM: No NVIDIA GPU found`, and NVIDIA suspend/resume hook boundaries: [`references/graphics-frequency.md`](references/graphics-frequency.md)

### Storage, Partitions, And Overlay Views

- Root partition, DATA partition, actual `/home` mount location, and disk-usage interpretation: [`references/storage-layout.md`](references/storage-layout.md)
- PanShi, ostree, overlay, and KARE merged-view interpretation: [`references/storage-layout.md`](references/storage-layout.md)
- Diagnosis boundaries and risk checks before root expansion or DATA partition changes: [`references/storage-layout.md`](references/storage-layout.md)

### AI Tool Configuration And Reuse

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
