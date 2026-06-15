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

## 根分区扩容判断

缩小 DATA 分区后是否能扩给根分区，取决于 GPT 分区顺序。只有空闲空间紧邻根分区之后，才容易扩容根分区。如果根分区和 DATA 分区之间隔着备份分区、swap 或其他分区，缩小 DATA 通常不能直接扩给根分区，可能需要移动/删除中间分区，风险显著升高。

分区调整前必须先备份重要数据，并在维护模式或离线环境中操作；不要在未确认分区顺序、文件系统类型、备份分区用途和回滚方案前执行缩容、移动或删除分区。

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

且目标是“扩大根分区，同时缩小 backup，不移动 DATA”，可行性取决于目标根分区大小是否能只通过 p4 腾出的前段空间满足：

- 若根分区目标大小小于等于 `p3 + p4可让出的空间`，可以只调整 p3/p4，不移动 DATA，风险相对较低。
- 若还要保留独立 backup，且根分区目标需要超过 p4 可让出的空间，就必须移动或缩小 DATA 的起点，通常应改用离线环境处理。
- ext4 根文件系统可以在线扩容，但分区表和 backup 分区重建仍属于高风险系统级操作，必须先处于维护模式并做好回滚备份。

流程：

1. 只读确认真实布局和挂载：

```bash
df -hT / /home /data /backup 2>/dev/null || true
lsblk -o NAME,PATH,SIZE,TYPE,FSTYPE,LABEL,UUID,FSUSED,FSAVAIL,FSUSE%,MOUNTPOINTS
pkexec parted -s /dev/<disk> unit GiB print free
```

2. 备份分区表、`/etc/fstab` 和 backup 分区内容：

```bash
sfdisk --dump /dev/<disk> > <backup-dir>/<disk>.sfdisk
parted -s /dev/<disk> unit GiB print free > <backup-dir>/<disk>.parted.txt
cp -a /etc/fstab <backup-dir>/fstab.before-resize
mount -o ro /dev/<backup-partition> <mountpoint>
tar -C <mountpoint> -cpf <backup-dir>/backup-partition.tar .
umount <mountpoint>
```

3. 删除旧 backup 分区，扩大根分区末尾，再在根分区和 DATA 之间的剩余精确扇区区间重建 backup 分区。

```bash
parted -s /dev/<disk> unit GiB rm <backup-part-number>
parted /dev/<disk> unit GiB resizepart <root-part-number> <new-root-end>
parted -s /dev/<disk> unit s mkpart backup ext4 <backup-start-sector>s <backup-end-sector>s
partprobe /dev/<disk> || true
udevadm settle || true
```

4. 在线扩容根 ext4，重建 backup 文件系统，恢复 backup 内容：

```bash
resize2fs /dev/<root-partition>
mkfs.ext4 -F -L KYLIN-BACKUP /dev/<backup-partition>
mount /dev/<backup-partition> <mountpoint>
tar -C <mountpoint> -xpf <backup-dir>/backup-partition.tar
umount <mountpoint>
```

5. 更新 `/etc/fstab` 中 `/backup` 的 UUID，并验证：

```bash
blkid /dev/<backup-partition>
mount /backup
findmnt /backup
umount /backup
df -hT /
lsblk -o NAME,PATH,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINTS
```

注意事项：

- 不要用十进制 GB 和 GiB 混算判断是否能达到“200G”等目标；以 `parted unit s print free` 的精确扇区为准。
- 若 `parted` 报告请求区间与可管理最近区间不一致，停止继续猜测，重新读取扇区级空闲区间后再创建分区。
- 如果 backup 分区包含真实恢复镜像或快照数据，不要直接格式化；先确认恢复机制和备份内容是否可以丢弃或迁移。
- 修改完成后，保存维护模式改动并要求用户重启，再验证根分区容量、DATA 挂载和 `/backup` 手动挂载。
