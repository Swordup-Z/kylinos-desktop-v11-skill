# os-fix-skill

[中文](README.md)

This repository is a structured knowledge base for KylinOS Desktop V11. It records reusable workflows for desktop-system repair and feature enhancement. It is not an executable program and is not tied to one AI tool's built-in skill directory. Humans can browse the directories directly, and multiple AI tools can start from `$HOME/.os-fix-skill/SKILL.md` and progressively load only the relevant references.

It currently covers UKUI, KARE/Kaiming, Clash Verge TUN, application installation, aTrust/UEM security clients, autostart, global search, system tray behavior, input methods, system services, maintenance mode, the PanShi architecture, fingerprint and graphics hardware, storage layout, local source customizations, and AI-tool configuration.

## Install an AI Coding Tool First

If you do not already have an AI coding tool, install one of Codex, Claude Code, or opencode first. The commands below target Linux/macOS terminals. For other systems or installation methods, use the linked official docs.

### Codex

Official docs:

- Codex CLI: https://developers.openai.com/codex/cli
- Codex quickstart: https://developers.openai.com/codex/quickstart

Recommended install command:

```bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

Start it with:

```bash
codex
```

### Claude Code

Official docs:

- Claude Code quickstart: https://docs.anthropic.com/en/docs/claude-code/quickstart
- Claude Code setup: https://docs.anthropic.com/en/docs/claude-code/setup

Recommended install command:

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

Start it with:

```bash
claude
```

### opencode

Official docs:

- opencode docs: https://opencode.ai/docs/
- opencode download: https://opencode.ai/download

Recommended install command:

```bash
curl -fsSL https://opencode.ai/install | bash
```

Start it with:

```bash
opencode
```

If your system policy does not allow `curl | sh` or `curl | bash`, open the official pages above and choose a standalone package, Homebrew, npm, or another trusted installation method for your system.

## Install This Knowledge Base

### Option 1: Ask an AI Tool to Install It

Send this prompt to Codex, Claude Code, opencode, or a similar tool:

```text
Please install this KylinOS Desktop V11 system knowledge base:

https://github.com/Swordup-Z/kylinos-desktop-v11-skill

Requirements:
1. Clone it to $HOME/.os-fix-skill.
2. Configure the user-level global prompt for the current tool, for example:
   - Codex: $HOME/.codex/AGENTS.md
   - Claude Code: $HOME/.claude/CLAUDE.md
   - opencode: $HOME/.config/opencode/AGENTS.md
3. When the user works on KylinOS Desktop V11, UKUI, KARE/Kaiming, Clash Verge, TUN, maintenance mode, the PanShi architecture, system services, partitions, mounts, or desktop AI subsystem issues, first read $HOME/.os-fix-skill/SKILL.md, then follow its references routing.
4. After installation, tell me the entry file path and how to use it later.
```

### Option 2: Manual Installation

```bash
cd "$HOME"
git clone https://github.com/Swordup-Z/kylinos-desktop-v11-skill.git "$HOME/.os-fix-skill"
```

Entry file:

```text
$HOME/.os-fix-skill/SKILL.md
```

Common user-level prompt files:

```text
Codex:       $HOME/.codex/AGENTS.md
Claude Code: $HOME/.claude/CLAUDE.md
opencode:    $HOME/.config/opencode/AGENTS.md
```

Use a fixed session name for system maintenance, such as `os-fix`:

```bash
codex resume os-fix
claude resume os-fix
opencode resume os-fix
```

## Architecture

The skill is split into two top-level task types:

- **System Repair**: existing system behavior is broken, failing, noisy, or not persistent. Examples include TUN failures, autostart not working, system-tray hidden state not persisting, disconnected fingerprint devices, and service failures.
- **Feature Enhancement**: the system works, but the user wants new capabilities, changed defaults, or local customization. Examples include adding Bing/Google to UKUI global search, adding a custom command panel, preserving local source patches, or configuring AI-tool global prompts.

Both task types use the same scenario categories:

```text
system
applications
ukui
network
hardware
storage
agent-tools
source-rebuild
```

## Directory Layout

```text
$HOME/.os-fix-skill/
├── SKILL.md
├── references/
│   ├── README.md
│   ├── system-repair/
│   │   ├── README.md
│   │   ├── system.md
│   │   ├── applications.md
│   │   ├── ukui.md
│   │   ├── network.md
│   │   ├── hardware.md
│   │   ├── storage.md
│   │   ├── agent-tools.md
│   │   └── source-rebuild.md
│   └── feature-enhancement/
│       ├── README.md
│       ├── system.md
│       ├── applications.md
│       ├── ukui.md
│       ├── network.md
│       ├── hardware.md
│       ├── storage.md
│       ├── agent-tools.md
│       └── source-rebuild.md
├── knowledge/
│   ├── README.md
│   ├── system-repair/
│   └── feature-enhancement/
├── scripts/
│   └── cleanup-kylin-ai.sh
├── README.md
└── README.en.md
```

`references/` is the scenario routing layer. Each reference contains scope, a short explanation, a knowledge entry, and minimal diagnostics. `knowledge/<type>/<scenario>/README.md` is the scenario index that routes to one concrete chapter. The concrete `<topic>.md` files contain background, diagnosis, repair or enhancement steps, verification, rollback, and cleanup notes. Reusable source-level features also keep patch sets and `PATCHSET.md` metadata under the same scenario's `patches/<feature-id>/` directory.

Fixed loading path:

```text
task type
-> scenario reference
-> scenario knowledge README
-> concrete knowledge chapter
```

## Routing Examples

Clash Verge TUN failure:

```text
SKILL.md
-> references/system-repair/network.md
-> knowledge/system-repair/network/README.md
-> knowledge/system-repair/network/proxy-tun.md
```

UKUI global search showing uninstalled Software Center apps:

```text
SKILL.md
-> references/system-repair/ukui.md
-> knowledge/system-repair/ukui/README.md
-> knowledge/system-repair/ukui/search.md
```

Adding a custom command panel to UKUI global search:

```text
SKILL.md
-> references/feature-enhancement/ukui.md
-> knowledge/feature-enhancement/ukui/README.md
-> knowledge/feature-enhancement/ukui/search-command-provider.md
```

Configuring Codex, Claude Code, or opencode to load this knowledge base:

```text
SKILL.md
-> references/feature-enhancement/agent-tools.md
-> knowledge/feature-enhancement/agent-tools/README.md
-> knowledge/feature-enhancement/agent-tools/global-prompts.md
```

## Coverage

### System Repair

- Maintenance mode, the PanShi architecture, and system-level modification boundaries.
- Application installation, AppImage, third-party apt sources, KARE/Kaiming isolation, and aTrust/UEM security-client components.
- Clash Verge TUN, `/dev/net/tun`, proxy services, and proxy core paths.
- UKUI autostart, global-search issues, shortcuts, system tray, input methods, panel/taskbar behavior, and open-with file-dialog behavior.
- Desktop AI components, AI subsystem cleanup, and residues.
- Fingerprint/biometric authentication, graphics frequency, and hardware stability.
- Root partition, DATA partition, `/home` mount location, overlay views, Kaiming/KARE, and ostree disk-usage analysis.

### Feature Enhancement

- UKUI global-search search-engine customization.
- UKUI global-search custom command provider and graphical command configuration.
- UKUI system-tray input-method status badges and similar desktop interaction enhancements.
- Local source customization workspaces, commits, patches, and build-artifact cleanup.
- Reusable source patch sets, upstream repositories, base nodes, and conflict migration rules.
- AI-tool global prompts, permission configuration, and multi-tool loading rules.
- DATA partition layout for local source and build work.

## Safety Boundary

System-level changes on KylinOS Desktop V11 often require maintenance mode. Before touching `/usr`, `/etc`, `/opt`, system packages, systemd units, device nodes, partitions, KSaf, or system services, check:

```bash
mm-cli -s
```

Enter maintenance mode:

```bash
sudo mm-cli -o
```

Exit and save:

```bash
sudo mm-cli -c -a
```

Switching maintenance mode usually requires a reboot. Detailed operational rules live in `SKILL.md` and the relevant reference/knowledge chapters.

## Companion Tools

Space cleanup, Kaiming/KARE layer control, and ostree usage auditing should live in a companion application instead of large embedded scripts inside knowledge files. The recommended local companion app is **Kylin Space Guard**:

```text
$HOME/kylin-space-guard
```

It should keep a "GUI + auditable CLI helper" structure: the GUI displays scan results, lets the user choose actions, and triggers Polkit authorization; the helper owns dry-run mode, maintenance-mode checks, official `kaiming` uninstall calls, orphan-layer quarantine, and periodic reports. The tool must not automatically delete ostree deployments, EFI files, GRUB config, loader entries, `/etc/fstab`, or partition tables.

## License

MIT License. See [LICENSE](LICENSE).
