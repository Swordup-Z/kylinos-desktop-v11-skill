# kylinos-desktop-v11-skill

[中文](README.md)

A reusable skill and knowledge base for diagnosing, fixing, verifying, and recording KylinOS Desktop V11 system issues. It covers application installation and package management, UKUI, application isolation environments, proxy/TUN, autostart, maintenance mode, system services, graphics/frequency issues, tray behavior, global search, source-rebuild assessment for system-component fixes, desktop AI component cleanup, partitions, mounts, overlay views, system-noise cleanup, global prompts for AI tools, and the PanShi system architecture.

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
3. Add a global rule: when handling KylinOS Desktop V11, UKUI, KARE, Kaiming, Clash Verge, system services, autostart, TUN, maintenance mode, PanShi architecture, system protection, partitions, mounts, overlay, or AI subsystem issues, first read $HOME/kylinos-desktop-v11-skill/SKILL.md, then selectively read the relevant references/*.md files listed there; if a reference points to a concrete knowledge/ chapter, read only that chapter as needed; if no specific reference matches, read references/system-maintenance.md at minimum; if the current task is not a desktop-system issue, do not load this skill.
4. If the local skill has been read but does not cover the current system issue, before exploring a repair from scratch, try syncing $HOME/kylinos-desktop-v11-skill with the GitHub repository: first confirm it is a git repository with a clean worktree, then use git fetch, git status -sb, and git pull --ff-only to check for new reusable knowledge. Do not use reset, rebase, or force-overwrite local changes. Sync failure does not block troubleshooting; continue with the current material, model capability, and general system-maintenance knowledge.
5. Before any system-level repair, run mm-cli -s to check maintenance mode. If not in maintenance mode, only perform diagnostics and do not modify /usr, /etc, /opt, system packages, services, device nodes, partitions, or KSaf policy.
6. After a fix is confirmed, record reusable findings in this skill's SKILL.md, the relevant references/*.md routing file, or a concrete knowledge/ chapter; if the issue was not previously covered by this skill, add an appropriate reference as the category entry and put the detailed experience under knowledge/.
7. When running any git commit, do not include AI-related author, co-author, generator, or assistant attribution in the commit author, commit body, or commit trailers.
8. For future system repairs, use a dedicated session name such as os-fix; if the current AI tool supports session resume commands, continue later with <tool> resume os-fix to restore the same troubleshooting context.
9. After installation, verify by reading $HOME/kylinos-desktop-v11-skill/SKILL.md and tell me which skill entry point you will use first for future KylinOS Desktop V11 system issues.
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
When handling KylinOS Desktop V11, UKUI, KARE, Kaiming, Clash Verge, system services, autostart, TUN, maintenance mode, PanShi architecture, system protection, partitions, mounts, overlay, or AI subsystem issues, first read `$HOME/kylinos-desktop-v11-skill/SKILL.md`, then selectively read the relevant `references/*.md` files listed there. If a reference points to a concrete `knowledge/` chapter, read only that chapter as needed. If no specific reference matches, read `references/system-maintenance.md` at minimum. If the current task is not a desktop-system issue, do not load this skill. Do not preload every reference or knowledge file.

If the local skill has been read but does not cover the current system issue, before exploring a repair from scratch, try syncing `$HOME/kylinos-desktop-v11-skill` with the GitHub repository to check for new reusable knowledge. First confirm the directory is a git repository and the worktree is clean; only use non-destructive commands such as `git fetch`, `git status -sb`, and `git pull --ff-only`. If there are local uncommitted changes, diverged branches, network failures, or fast-forward failures, do not force-overwrite. Sync failure does not block troubleshooting; continue with the current material, model capability, and general system-maintenance knowledge.

Before any system-level repair, run `mm-cli -s` to check maintenance mode. Only modify `/usr`, `/etc`, `/opt`, system packages, services, device nodes, partitions, or KSaf policy after confirming maintain mode.

After a fix is confirmed, record reusable diagnosis steps, repair steps, risks, or system traits in `$HOME/kylinos-desktop-v11-skill/SKILL.md`, the relevant `references/*.md` routing file, or a concrete `knowledge/` chapter.

If the resolved KylinOS Desktop V11 system issue was not previously covered by this skill, add an appropriate `references/*.md` file as the category entry and put the detailed experience under `knowledge/`; then link it from `SKILL.md`.
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

The AI tool should read `SKILL.md`, selectively load the relevant `references/*.md`, continue into `knowledge/` only when the selected reference points there, and then follow the flow: diagnosis -> repair -> verification -> record reusable findings.

## Repository Structure And Routing

This repository uses progressive disclosure so AI tools do not load unnecessary context up front.

```text
kylinos-desktop-v11-skill/
├── SKILL.md                  # Main entry: classify the issue and choose the minimal reference
├── references/               # Scenario categories and routing entries, like a dictionary index
│   ├── README.md             # Reference naming and routing rules
│   ├── system-maintenance.md  # Maintenance mode, safety boundaries, and the minimal loop
│   ├── ukui-search.md         # UKUI global-search category entry
│   └── ...
├── knowledge/                # Concrete troubleshooting chapters
│   ├── README.md             # How knowledge/ differs from references/
│   ├── system/               # Includes README.md; maintenance, safety, system noise
│   ├── applications/         # Includes README.md; installation and isolation boundaries
│   ├── ukui/                 # Includes README.md; autostart, search, tray, services
│   ├── network/              # Includes README.md; proxy and TUN
│   ├── hardware/             # Includes README.md; biometrics, graphics, frequency
│   ├── storage/              # Includes README.md; partitions, mounts, overlay views
│   ├── agent-tools/          # Includes README.md; Codex/Claude/opencode prompts
│   └── source-rebuild/       # Source rebuilds, local customization indexes, and cases
├── README.md                 # Chinese README
└── README.en.md              # English README
```

Recommended loading path:

```text
User issue
  -> SKILL.md
  -> references/<minimal-matching-scenario>.md
  -> knowledge/<category>/<chapter>.md (only when the reference points there or the issue requires deeper handling)
```

For example, when handling “UKUI global search has hard-coded default web engines and needs Bing/Google”:

```text
SKILL.md
  -> references/ukui-search.md
  -> references/source-rebuild.md
  -> knowledge/source-rebuild/README.md
  -> knowledge/source-rebuild/ukui-search-web-engine.md
```

New findings should follow the same structure: keep `references/` as the category entry, minimal diagnosis, and routing layer; put detailed background, source matching, repair steps, verification, rollback, and cleanup rules under the relevant `knowledge/` chapter.

### References And Knowledge Routing

This README documents both `references/` and `knowledge/`: references are entry points and indexes, while knowledge files contain the concrete reasoning and procedures. Common routes:

| Scenario | Reference entry | Knowledge chapter |
| --- | --- | --- |
| General system maintenance, maintenance mode, PanShi boundaries | [`references/system-maintenance.md`](references/system-maintenance.md) | [`knowledge/system/README.md`](knowledge/system/README.md), [`knowledge/system/system-maintenance.md`](knowledge/system/system-maintenance.md) |
| System health noise cleanup | [`references/system-health-noise.md`](references/system-health-noise.md) | [`knowledge/system/README.md`](knowledge/system/README.md), [`knowledge/system/system-health-noise.md`](knowledge/system/system-health-noise.md) |
| Application installation, AppImage, third-party apt sources | [`references/application-installation.md`](references/application-installation.md) | [`knowledge/applications/README.md`](knowledge/applications/README.md), [`knowledge/applications/application-installation.md`](knowledge/applications/application-installation.md) |
| Application isolation and host boundaries | [`references/application-isolation.md`](references/application-isolation.md) | [`knowledge/applications/README.md`](knowledge/applications/README.md), [`knowledge/applications/kare-namespace.md`](knowledge/applications/kare-namespace.md) |
| Proxy and TUN | [`references/proxy-tun.md`](references/proxy-tun.md) | [`knowledge/network/README.md`](knowledge/network/README.md), [`knowledge/network/clash-verge-tun.md`](knowledge/network/clash-verge-tun.md) |
| UKUI autostart | [`references/ukui-autostart.md`](references/ukui-autostart.md) | [`knowledge/ukui/README.md`](knowledge/ukui/README.md), [`knowledge/ukui/autostart.md`](knowledge/ukui/autostart.md) |
| UKUI global shortcuts | [`references/ukui-keybindings.md`](references/ukui-keybindings.md) | [`knowledge/ukui/README.md`](knowledge/ukui/README.md), [`knowledge/ukui/keybindings.md`](knowledge/ukui/keybindings.md) |
| UKUI global search | [`references/ukui-search.md`](references/ukui-search.md) | [`knowledge/ukui/README.md`](knowledge/ukui/README.md), [`knowledge/ukui/search.md`](knowledge/ukui/search.md) |
| Source-rebuild repairs | [`references/source-rebuild.md`](references/source-rebuild.md) | [`knowledge/source-rebuild/README.md`](knowledge/source-rebuild/README.md), [`knowledge/source-rebuild/local-customization-index.md`](knowledge/source-rebuild/local-customization-index.md), [`knowledge/source-rebuild/ukui-search-web-engine.md`](knowledge/source-rebuild/ukui-search-web-engine.md), [`knowledge/source-rebuild/ukui-system-tray.md`](knowledge/source-rebuild/ukui-system-tray.md) |
| UKUI right-side tray | [`references/ukui-system-tray.md`](references/ukui-system-tray.md) | [`knowledge/ukui/README.md`](knowledge/ukui/README.md), [`knowledge/ukui/system-tray.md`](knowledge/ukui/system-tray.md) |
| Desktop service activation | [`references/desktop-service-activation.md`](references/desktop-service-activation.md) | [`knowledge/ukui/README.md`](knowledge/ukui/README.md), [`knowledge/ukui/system-service-manager.md`](knowledge/ukui/system-service-manager.md) |
| Desktop AI component cleanup | [`references/desktop-ai-components.md`](references/desktop-ai-components.md) | [`knowledge/ukui/README.md`](knowledge/ukui/README.md), [`knowledge/ukui/kylin-ai-subsystem.md`](knowledge/ukui/kylin-ai-subsystem.md) |
| Biometric authentication | [`references/biometric-authentication.md`](references/biometric-authentication.md) | [`knowledge/hardware/README.md`](knowledge/hardware/README.md), [`knowledge/hardware/biometric-fingerprint.md`](knowledge/hardware/biometric-fingerprint.md) |
| Graphics, frequency, hardware stability | [`references/graphics-frequency.md`](references/graphics-frequency.md) | [`knowledge/hardware/README.md`](knowledge/hardware/README.md), [`knowledge/hardware/graphics-frequency.md`](knowledge/hardware/graphics-frequency.md) |
| Partitions, mounts, overlay views | [`references/storage-layout.md`](references/storage-layout.md) | [`knowledge/storage/README.md`](knowledge/storage/README.md), [`knowledge/storage/layout.md`](knowledge/storage/layout.md) |
| AI tool permissions | [`references/agent-tool-permissions.md`](references/agent-tool-permissions.md) | [`knowledge/agent-tools/README.md`](knowledge/agent-tools/README.md), [`knowledge/agent-tools/codex-config.md`](knowledge/agent-tools/codex-config.md) |
| Multi-tool global prompts | [`references/agent-global-prompts.md`](references/agent-global-prompts.md) | [`knowledge/agent-tools/README.md`](knowledge/agent-tools/README.md), [`knowledge/agent-tools/global-prompts.md`](knowledge/agent-tools/global-prompts.md) |

## Core Requirements

When using this skill for system troubleshooting, the AI tool must follow these baseline rules:

- For any KylinOS Desktop V11 desktop-system maintenance task, read [`SKILL.md`](SKILL.md) first, then selectively read the relevant `references/*.md` files listed there; do not preload every reference file.
- `references/` is the category and routing layer; `knowledge/` contains concrete troubleshooting chapters. Continue into `knowledge/` only when the selected reference points there.
- If no specific reference matches, read the general maintenance reference [`references/system-maintenance.md`](references/system-maintenance.md) at minimum.
- If the local skill has been read but does not cover the current system issue, before exploring a repair from scratch, try syncing the GitHub upstream for this repository to check for new reusable knowledge; only do this when the worktree is clean, and use `fetch` plus `pull --ff-only` rather than force-overwriting local changes. Sync failure does not block troubleshooting; continue with the current material, model capability, and general system-maintenance knowledge.
- If an issue requires rebuilding a system source package, replacing a system shared library, assessing ABI/SONAME/dependency/RPATH risk, or preserving local customization source trees, build directories, and rollback-package indexes, read the source-rebuild category entry [`references/source-rebuild.md`](references/source-rebuild.md), then continue into the `knowledge/source-rebuild/` chapters it points to; each local customization project must keep its index in `/data/usershare/kylinos-local-sources/<component-or-fix>/CUSTOMIZATION.md`.
- Do not load this skill for ordinary coding, documentation, Git operations, or unrelated tasks.
- Follow the loop: diagnosis -> repair -> verification -> record reusable findings.
- Treat persistent repair as the default goal for system issues; after any runtime workaround, verify whether the fix survives reboot, relogin, service restart, or app restart.
- Do not treat restoring official packages, deleting local customizations, reverting source-level changes, or reinstalling components as the default first step. First establish evidence from logs, call chains, package verification, and reproduction. Only temporarily restore the official version when the evidence points to the customization, or when the user confirms an A/B test and a backup/rollback path exists.
- Workarounds, watchdogs, scheduled restarts, or automatic relaunch mechanisms are temporary recovery measures. Prefer root-cause diagnosis and direct repair first.
- Before system-level repairs, run `mm-cli -s` to check maintenance mode; outside maintenance mode, only perform non-destructive diagnostics such as reading state or simulating installs/removals.
- If the system is not in maintenance mode, enter maintenance mode and ask the user to reboot; after the fix is complete, exit maintenance mode and ask the user to reboot again to return to normal mode.
- Do not delete, move, or overwrite existing executables, configs, subscription files, proxy cores, systemd units, or user data unless the user explicitly asks and the impact has been verified.
- After a fix is confirmed, record reusable diagnosis steps, repair steps, risks, or system traits in `SKILL.md`, the relevant `references/*.md` routing file, or a concrete `knowledge/` chapter.
- If the resolved KylinOS Desktop V11 system issue was not previously covered by this skill, add an appropriate `references/*.md` file as the category entry and put the detailed experience under `knowledge/`; then link it from `SKILL.md`.
- Before running `git commit` in this repository, check whether `README.md` and `README.en.md` need to be updated. If the change affects installation, core requirements, supported issue coverage, reference entry points, safety boundaries, global prompts, or the public usage workflow, update the READMEs in the same commit.
- When running any `git commit`, do not include AI-related author, co-author, generator, or assistant attribution in the commit author, commit body, or commit trailers.

## Supported Issues

The skill currently covers the issue types below. `references/` is the category entry layer, while `knowledge/` contains concrete chapters; AI tools should load only the relevant files instead of preloading the whole repository.

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

### Application Isolation And Host Boundaries

- Application isolation environments, KARE/Kaiming namespaces, applications showing hostname as `kare`, host hostname validation, and isolation-boundary risks: [`references/application-isolation.md`](references/application-isolation.md)
- Isolated-environment desktop-entry overrides, pinned menu entries still pointing to KARE/Kaiming, and host-native entry validation: [`references/application-isolation.md`](references/application-isolation.md)
- Recovery after accidentally starting the UKUI panel from an isolated environment, including namespace validation: [`references/application-isolation.md`](references/application-isolation.md)

### Network Proxy And TUN

- Proxy-client TUN installation failures, missing `/dev/net/tun`, and persistent TUN device handling: [`references/proxy-tun.md`](references/proxy-tun.md)
- Proxy service installation, startup, status validation, and permission issues, such as Clash Verge Rev `clash-verge-service`: [`references/proxy-tun.md`](references/proxy-tun.md)
- Missing or misplaced proxy cores, isolated-environment shadow/upper path recovery, and proxy group disappearance after core-path problems: [`references/proxy-tun.md`](references/proxy-tun.md)

### UKUI Desktop And System Services

- UKUI autostart failures, missing Settings entries, original `.desktop` repair, icon resolution, and `sort-app-list` / `statusMap` issues: [`references/ukui-autostart.md`](references/ukui-autostart.md)
- UKUI global shortcut conflicts, Settings reporting that a shortcut is occupied by the system, global search shortcuts, and `Alt+Space` conflicts with the window menu: [`references/ukui-keybindings.md`](references/ukui-keybindings.md)
- UKUI global-search result sources, Software Center results for uninstalled apps, and disabling or rolling back the Software Center search D-Bus provider: [`references/ukui-search.md`](references/ukui-search.md)
- Source matching, building, ABI-risk checks, and local customization indexing for adding Bing/Google, Software Center result toggles, or other hard-coded UKUI global-search options: [`references/source-rebuild.md`](references/source-rebuild.md)
- UKUI right-side system tray icon order and folded/hidden area persistence, hidden items filling visible gaps after a visible app exits, `systemTray.json`, `orderedItems`, and `separateIndex`: [`references/ukui-system-tray.md`](references/ukui-system-tray.md)
- Desktop service startup timeouts, D-Bus activation failures, service names owned by orphan processes, panel/taskbar issues caused by startup-order races, and persistent activation repair: [`references/desktop-service-activation.md`](references/desktop-service-activation.md)
- Taskbar/tray AI assistants, desktop AI components, Kaiming AI assistant removal boundaries, and residue cleanup: [`references/desktop-ai-components.md`](references/desktop-ai-components.md)

### Biometric Authentication

- Biometric authentication, fingerprint driver recovery, authentication-service validation, and diagnostics for registered drivers whose devices are not detected: [`references/biometric-authentication.md`](references/biometric-authentication.md)

### Graphics, Frequency, And Hardware-Specific Stability

- Graphics drivers, GPU/display frequency, `devfreq` DVFS failures, and `failed to set <driver> frequency`: [`references/graphics-frequency.md`](references/graphics-frequency.md)
- Hardware-specific graphics stability diagnosis, such as Phytium FTG / `PHYT0048:00`, and UKUI power-management policy handling: [`references/graphics-frequency.md`](references/graphics-frequency.md)
- NVIDIA probing on systems without NVIDIA hardware, `NVRM: No NVIDIA GPU found`, and NVIDIA suspend/resume hook boundaries: [`references/graphics-frequency.md`](references/graphics-frequency.md)

### Storage, Partitions, And Overlay Views

- Root partition, DATA partition, actual `/home` mount location, and disk-usage interpretation: [`references/storage-layout.md`](references/storage-layout.md)
- PanShi, ostree, overlay, and KARE merged-view interpretation: [`references/storage-layout.md`](references/storage-layout.md)
- Diagnosis boundaries and risk checks before root expansion, backup partition shrinking, or DATA partition changes: [`references/storage-layout.md`](references/storage-layout.md)

### AI Tool Configuration And Reuse

- AI tool user-level permissions, Codex default full access, permission display, and maintenance-mode/root permission boundaries: [`references/agent-tool-permissions.md`](references/agent-tool-permissions.md)
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

## Appendix: Installing AI Coding Tools

This skill can be used by Codex, Claude Code, opencode, and similar AI coding tools. The commands below are common official installation entry points; check the official docs before installing.

### Codex CLI

Official docs:

```text
https://developers.openai.com/codex/cli
```

Common macOS/Linux install:

```bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

Non-interactive install:

```bash
curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh
```

You can also install it with npm:

```bash
npm install -g @openai/codex
```

Verify and launch:

```bash
codex --version
codex
```

### Claude Code

Official docs:

```text
https://code.claude.com/docs/en/setup
```

Recommended macOS/Linux/WSL install:

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

You can also install it with npm. This requires Node.js 18 or later:

```bash
npm install -g @anthropic-ai/claude-code
```

Verify and launch:

```bash
claude --version
claude doctor
claude
```

Note: the Claude Code docs advise against `sudo npm install -g` because it can cause permission and security issues. If you install through apt/dnf/apk or another system package manager on KylinOS Desktop V11, follow the maintenance-mode rules first.

### opencode

Official docs:

```text
https://opencode.ai/docs/
```

Common install:

```bash
curl -fsSL https://opencode.ai/install | bash
```

You can also install it with npm:

```bash
npm install -g opencode-ai
```

Verify and launch:

```bash
opencode --version
opencode
```

### KylinOS Desktop V11 Notes

- If the installer writes only to the user directory, maintenance mode is usually not required.
- If the installation writes to `/usr`, `/etc`, package repositories, system services, or uses apt/dnf/apk, run `mm-cli -s` first and proceed only in maintenance mode.
- If the system is not in maintenance mode, enter maintenance mode and reboot before continuing with system-level installation.
- After installation, add the global-prompt snippet from this README to the selected tool's user-level global prompt file.

## License

MIT
