# 存储布局与 overlay 挂载

此文档用于判断 Kylin Desktop V11 上根分区、DATA 分区、`/home`、磐石架构/ostree overlay 和 KARE overlay 的真实关系。

## 诊断命令

先做只读诊断：

```bash
df -hT / /home "$HOME" /data /data/home 2>/dev/null || true
findmnt -o TARGET,SOURCE,FSTYPE,SIZE,USED,AVAIL,USE%,OPTIONS / /home "$HOME" /data 2>/dev/null || true
findmnt -t overlay -o TARGET,SOURCE,FSTYPE,SIZE,USED,AVAIL,USE%,OPTIONS
lsblk -o NAME,PATH,SIZE,FSTYPE,LABEL,UUID,FSUSED,FSAVAIL,FSUSE%,MOUNTPOINTS
```

查看分区起止位置需要 root，但属于只读检查：

```bash
pkexec parted -s /dev/<disk> unit GiB print free
```

## `/home` 和 DATA 分区

DATA 分区可能同时挂载到 `/data`，并把其中的 `/home` 子目录挂载为系统 `/home`。例如：

```text
/data  /dev/<disk-part>
/home  /dev/<disk-part>[/home]
```

此时用户目录实际在 DATA 分区上，`$HOME` 等价于 `/data/home/<user>`。文件管理器中的“数据盘”快捷方式可能指向 `/data/usershare`，它是共享目录，不等于用户主目录；看到 `/data` 顶层或 `/data/usershare` 为空，不代表 `$HOME` 没有使用 DATA 分区。

## overlay 挂载判断

Kylin Desktop V11 上常见 overlay 分两类：

- 磐石架构/ostree 系统 overlay：如 `/usr`、`/etc`、`/var/lib`，用于把只读系统基线和可写层合并成当前系统视图。
- KARE 应用 overlay：如 `/var/opt/kare-applications/*/merge/usr`、`merge/var`、`merge/etc`、`merge/opt`、`merge/root`，用于 KARE 应用运行环境。

这些 overlay 是实际使用中的挂载视图，不能随意卸载或删除。`df` 中多个 overlay 显示相同容量和相同已用空间时，不表示每个 overlay 都额外占用了同样大小；它们通常映射到底层同一个根分区。

判断真实额外占用时，看各 overlay 的 `upperdir`，不要看 `merge` 目录的 `du` 结果。`merge` 是合并视图，可能把 lowerdir 的内容重复算入，看起来很大但不代表新增占用。

示例：

```bash
findmnt -t overlay -o TARGET,OPTIONS
du -sh /sysroot/ostree/pkgs/*/*-ovl/*-upper /sysroot/ostree/pkgs/*/*-ovl/*-tmpupper 2>/dev/null || true
du -sh /opt/kare-applications/*/upper /opt/kare-applications/*/work 2>/dev/null || true
du -xhd2 /opt/kare-applications/*/upper 2>/dev/null | sort -h | tail -80
```

不要用下面这类结果判断真实占用：

```bash
du -sh /opt/kare-applications/*/merge
```

因为 `merge` 是 overlay 合并后的视图。

## 根分区扩容判断

缩小 DATA 分区后是否能扩给根分区，取决于 GPT 分区顺序。只有空闲空间紧邻根分区之后，才容易扩容根分区。如果根分区和 DATA 分区之间隔着备份分区、swap 或其他分区，缩小 DATA 通常不能直接扩给根分区，可能需要移动/删除中间分区，风险显著升高。

分区调整前必须先备份重要数据，并在维护模式或离线环境中操作；不要在未确认分区顺序、文件系统类型、备份分区用途和回滚方案前执行缩容、移动或删除分区。
