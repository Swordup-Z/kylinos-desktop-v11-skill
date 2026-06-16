# 系统问题修复：源码重编译

## 适用场景

- 配置级方案不足，必须修改系统组件源码才能修复系统异常。
- 需要替换系统共享库、控制中心插件或服务。
- 需要评估 ABI、SONAME、NEEDED、RPATH/RUNPATH、导出符号风险。

## 知识入口

进入源码重编译索引后，先判断是否真的无法用配置、服务、包状态或用户级覆盖修复；只有证据明确指向源码级修复时才继续读取构建、ABI、回滚和试装知识。

- [`../../knowledge/system-repair/source-rebuild/README.md`](../../knowledge/system-repair/source-rebuild/README.md)

## 最小诊断

```bash
dpkg-query -W -f='${binary:Package} ${Version} ${Source}\n' <package>
apt-cache policy <package>
readelf -d <candidate-binary> | rg 'NEEDED|SONAME|RUNPATH|RPATH'
```
