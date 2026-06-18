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

## `noauto` backup 分区

`/etc/fstab` 中 backup 分区使用 `noauto`，只表示它不会在开机时自动挂载，不等于这个分区一定无用。恢复、快照、系统备份或厂商工具可能在需要时按需挂载它。

判断 backup 分区是否实际承载数据时，先只读挂载检查内容和占用：

```bash
mount -o ro /dev/<backup-partition> <mountpoint>
find <mountpoint> -maxdepth 2 -mindepth 1 -print
du -sh <mountpoint>
umount <mountpoint>
```

如果只看到 `snapshots`、`current`、`lost+found` 等目录且占用极小，可以认为当前没有实际备份数据；但仍不应直接删除该分区，除非已经确认系统恢复链路不依赖它，或用户明确接受删除独立备份分区的风险。

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

## Kaiming/KARE 与 ostree 空间增长

Kaiming 应用会在 `/var/opt/kaiming` 下保存 app、runtime 和 base 层。空间占用增长时，先确认是否存在同一 app/runtime/base 的多版本目录或孤儿层，不要直接删除 `/var/opt/kaiming/layers`：

```bash
/opt/kaiming-tools/bin/kaiming list
/opt/kaiming-tools/bin/kaiming update --upgradable
du -sh /var/opt/kaiming/layers/stable/*/*/*/*/* 2>/dev/null | sort -h
find /var/opt/kaiming/layers/stable -mindepth 5 -maxdepth 5 -type d -printf '%p\n' 2>/dev/null | sort
```

如果每个应用、runtime、base 只有一个版本目录，则大占用通常不是“旧版本不断复制”，而是 Kaiming base/runtime 本身体积较大。此时安全策略是：

- 空间清理工具不要把“卸载应用”作为主清理动作；卸载应用属于应用管理，不等同于清理旧版本容器。
- 不需要某个 Kaiming 应用时，才用 `kaiming uninstall <app-id>` 卸载，不手工删除 app 层。
- 只要仍保留任何 Kaiming 应用，base/runtime 通常仍会保留。
- 若怀疑有孤儿版本目录，优先从 `/var/opt/kaiming/info/*.list` 读取当前实际安装层目录，再与 `/var/opt/kaiming/layers/stable/<arch>/<kind>/<id>/<module>/<version>` 对比；不要只解析 `kaiming list` 的对齐表格，因为“名称”列可能包含空格，容易把版本列读错。
- 旧版本容器候选必须确认不属于当前 info 清单、没有被 mount 或进程使用；优先移动到 DATA 分区隔离目录，而不是直接删除。
- 对自动启动或预热造成的持续占用，可优先在用户级 `.config/autostart` 写入 `Hidden=true` 覆盖，而不是删除系统级 `.desktop`。

Kaiming/KARE/ostree 空间治理适合做成独立工具。推荐工具形态是“桌面 GUI + 可审计 helper”：GUI 负责扫描、展示和触发授权，helper 负责 dry-run、维护模式检查、旧容器识别和回滚隔离。原型可用脚本快速验证规则；长期桌面应用更适合用 C++/Qt 实现界面和本地扫描逻辑，并用小型 C++ Polkit helper 承担提权动作。工具必须默认只报告，不应自动清理。任何“禁用自启动”“清理旧容器”等会改变系统或用户会话行为的按钮，都应先弹出候选项选择和执行计划；主界面下方应展示“将做什么、正在做什么、结果如何”，原始日志只放在可展开详情里，不能让按钮直接静默执行。

ostree 部署、`/boot`、EFI、GRUB、loader entries、`/etc/fstab` 和分区表不属于普通空间清理对象。即使 `/sysroot/ostree/deploy` 看起来很大，也不能据此删除 deployment 或 boot 文件；应先确认当前 `root=UUID`、`ostree=`、loader entry、EFI 启动路径和双 SYSROOT/SYSBOOT 分区状态。

## 根分区扩容判断

缩小 DATA 分区后是否能扩给根分区，取决于 GPT 分区顺序。只有空闲空间紧邻根分区之后，才容易扩容根分区。如果根分区和 DATA 分区之间隔着备份分区、swap 或其他分区，缩小 DATA 通常不能直接扩给根分区，可能需要移动/删除中间分区，风险显著升高。

分区调整前必须先备份重要数据，并在离线环境中操作；不要在未确认分区顺序、文件系统类型、boot/EFI/ostree 引导链、备份分区用途和回滚方案前执行缩容、移动或删除分区。在线会话中只做只读评估和备份，不提供直接执行分区修改的命令流程。

KylinOS Desktop V11 可能同时存在旧 SYSROOT/SYSBOOT 和当前 SYSROOT/SYSBOOT，例如旧分区被桌面自动挂载到 `/run/media/<user>/SYSROOT` 或 `/run/media/<user>/SYSBOOT`。这种状态下，任何 `grub-install`、`update-grub`、loader entry 修复、EFI 文件复制、fstab 修改或分区扩容都必须先确认当前实际启动链路：

```bash
cat /proc/cmdline
findmnt -o TARGET,SOURCE,FSTYPE,UUID,OPTIONS / /boot /boot/efi /sysroot 2>/dev/null || true
lsblk -o NAME,PATH,SIZE,FSTYPE,LABEL,UUID,PARTUUID,MOUNTPOINTS
rg -n 'root=UUID=|search(_fs_uuid|\.fs_uuid)|ostree=' /boot /boot/efi 2>/dev/null || true
```

如果 boot 文件引用了非当前根分区 UUID，或者 EFI/GRUB 指向旧 SYSBOOT，不要继续做空间清理或分区调整；先按引导修复问题处理，并在离线介质或明确回滚方案下操作。

## 分区回滚资料保存位置

分区、挂载、`fstab`、`sfdisk`、`parted`、`blkid`、backup 分区快照等非源码类系统回滚资料，不应长期散放在 `$HOME` 根目录，也不应放入源码客制化目录。统一保存到 DATA 分区共享回滚目录：

```text
/data/usershare/kylinos-system-rollbacks/storage/<scenario>/<timestamp>/
```

例如根分区和 backup 分区调整资料：

```text
/data/usershare/kylinos-system-rollbacks/storage/partition-resize/<timestamp>/
```

至少包含：

```text
<disk>.sfdisk
<disk>.parted.txt
blkid.txt
fstab.before-resize
fstab.after-resize
<partition>/backup-partition.tar
```

若目录原先临时建在 `$HOME` 下，确认内容属于回滚资料后，应移动到上述目录，并在 `/data/usershare/kylinos-system-rollbacks/README.md` 记录索引。源码重编译和本地客制化源码的回滚包仍按源码重编译知识库要求保存到 `/data/usershare/kylinos-local-sources/<component-or-fix>/rollback/<timestamp>/`。

## 根分区后紧邻 backup 分区时的扩容

如果 GPT 顺序类似：

```text
p3  SYSROOT       /        ext4
p4  KYLIN-BACKUP  /backup  ext4,noauto
p5  DATA          /data    ext4
```

且目标是“扩大根分区，同时缩小 backup，不移动 DATA”，可行性只能作为只读评估结论记录，不应在普通桌面会话中直接执行。判断原则：

- 若根分区目标大小小于等于 `p3 + p4可让出的空间`，可以只调整 p3/p4，不移动 DATA，风险相对较低。
- 若还要保留独立 backup，且根分区目标需要超过 p4 可让出的空间，就必须移动或缩小 DATA 的起点，通常应改用离线环境处理。
- 即使文件系统支持在线扩容，分区表、backup 分区重建、boot/EFI/ostree 引导链同步仍属于高风险操作，应改用离线维护方案，不在经验库中提供可直接复制执行的破坏性命令。

注意事项：

- 不要用十进制 GB 和 GiB 混算判断是否能达到“200G”等目标；以 `parted unit s print free` 的精确扇区为准。
- 若 `parted` 报告请求区间与可管理最近区间不一致，停止继续猜测，重新读取扇区级空闲区间后再创建分区。
- 如果 backup 分区包含真实恢复镜像或快照数据，不要直接格式化；先确认恢复机制和备份内容是否可以丢弃或迁移。
- 修改完成后必须重启验证根分区容量、DATA 挂载、boot/EFI 引导项、ostree deployment 和 `/backup` 手动挂载。
