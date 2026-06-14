# kylinos-desktop-v11-skill

[中文](README.md)

A reusable skill and knowledge base for diagnosing, fixing, verifying, and recording KylinOS Desktop V11 system issues. It covers UKUI, KARE/Kaiming, TUN, autostart, maintenance mode, system services, partitions, mounts, overlay views, and the PanShi system architecture.

## Usage

Use `SKILL.md` as the entry point:

```bash
sed -n '1,160p' "$HOME/kylinos-desktop-v11-skill/SKILL.md"
```

To make AI coding tools such as Codex, Claude Code, or opencode use this skill automatically, configure a user-level global prompt that routes KylinOS Desktop V11 system issues to this repository. See:

```text
references/agent-global-prompts.md
```

The intended loading flow is progressive:

```text
SKILL.md -> relevant references/*.md -> diagnosis -> repair -> verification -> record reusable findings
```

## Safety

System-level repairs on KylinOS Desktop V11 may require maintenance mode. Before modifying `/usr`, `/etc`, `/opt`, system packages, services, device nodes, partitions, or KSaf policy, check:

```bash
mm-cli -s
```

Only proceed with system-level changes after confirming maintenance mode.

## License

MIT
