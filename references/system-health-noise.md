# KylinOS Desktop V11 系统体检与噪声清理

此文档适用于全盘体检后处理明确无用或缺依赖的系统噪声，例如 `motd-news.service`、PAM 残留引用、rsyslog 旧式配置指令等。不要把真正影响桌面启动、网络、图形、认证或数据安全的问题归类为噪声。

## 目录

- [`motd-news.service`](#motd-newsservice)
- [PAM 引用缺失的 `pam_gnome_keyring.so`](#pam-引用缺失的-pam_gnome_keyringso)
- [rsyslog 旧式 imjournal 指令](#rsyslog-旧式-imjournal-指令)

## `motd-news.service`

`motd-news.service` 用于终端登录时的 Message of the Day 新闻/公告，不是桌面环境核心组件。若用户不需要新闻/公告，或 `/etc/update-motd.d/50-motd-news` 缺失导致 `status=203/EXEC`，可以禁用定时器并清理失败状态：

```bash
systemctl status motd-news.timer motd-news.service --no-pager
sudo systemctl disable --now motd-news.timer
sudo systemctl reset-failed motd-news.service
systemctl --failed --no-pager
```

不要直接删除 `/usr/lib/systemd/system/*.service`；这些文件属于软件包管理范围。

## PAM 引用缺失的 `pam_gnome_keyring.so`

如果日志中反复出现：

```text
PAM unable to dlopen(pam_gnome_keyring.so)
PAM adding faulty module: pam_gnome_keyring.so
```

先确认 PAM 配置和包状态：

```bash
rg -n 'pam_gnome_keyring' /etc/pam.d /usr/share/pam-configs 2>/dev/null
dpkg -S pam_gnome_keyring.so 2>/dev/null || true
apt-cache policy libpam-gnome-keyring gnome-keyring
```

如果 `gnome-keyring` 已安装但 `libpam-gnome-keyring` 未安装，优先安装缺失的 PAM 模块，保留登录/锁屏时解锁 keyring 的原有设计：

```bash
sudo apt-get install libpam-gnome-keyring
dpkg -L libpam-gnome-keyring | rg 'pam_gnome_keyring\.so|/security/'
```

只有在明确不需要 gnome-keyring 集成时，才考虑把对应 PAM 行改成缺失模块可静默忽略的写法或移除该引用。修改 PAM 文件前必须备份。

## rsyslog 旧式 imjournal 指令

如果 `rsyslog.service` 启动时出现：

```text
invalid or yet-unknown config file command 'IMJournalStateFile'
```

检查 `/etc/rsyslog.conf` 是否存在 `$IMJournalStateFile imjournal.state`，但没有加载 `imjournal` 模块：

```bash
rg -n 'IMJournalStateFile|imjournal' /etc/rsyslog.conf /etc/rsyslog.d 2>/dev/null
```

在 KylinOS Desktop V11 上，rsyslog 常见配置是通过 `imuxsock` 从 systemd journal 的 syslog socket 收日志；若没有启用 `imjournal`，应注释该旧式指令，而不是额外启用 `imjournal` 造成日志重复。修改前备份，修改后验证语法并重启：

```bash
sudo sed -i.bak-<date> \
  -e '/^\$IMJournalStateFile imjournal\.state$/i # Disabled: imjournal is not loaded.' \
  -e 's/^\$IMJournalStateFile imjournal\.state$/# $IMJournalStateFile imjournal.state/' \
  /etc/rsyslog.conf
sudo /usr/sbin/rsyslogd -N1
sudo systemctl restart rsyslog.service
journalctl -u rsyslog.service --since '5 minutes ago' --no-pager
```
