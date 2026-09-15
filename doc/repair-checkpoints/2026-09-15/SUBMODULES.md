# 子模块提交与恢复

2026-09-15：以下三个本地修复提交已完成，但现有登录账号 `wowshub` 对其 `lisancth` 远端无写权限，三次推送均返回403。主仓库保留原有可拉取gitlink，不指向未发布的提交。完整增量提交保存在本目录的Git bundle中；它们需要原gitlink指向的基础提交。

| 子模块 | 新提交 | 随主仓库保存的bundle |
|---|---|---|
| modules/mod-ale | 1f7cf175fc0c13f22a11510c0768ede053ebe29a | ale.bundle |
| modules/mod-playerbots | 831a25ee396532cb3276675d70d239b068667871 | playerbots.bundle |
| modules/mod-starting-pet | 5599cf5695d2453d04e2e703180a9c06f492ddc7 | starting-pet.bundle |

当前工作目录已经处于这三个新提交，不要在本机直接运行submodule update把它们退回旧版本。新克隆主仓库后，先初始化子模块，再导入bundle并选择新提交，才能得到本次完整源码。

## 新克隆的恢复步骤

以下在主仓库根目录执行，前提是子模块工作区干净；有本地改动时先保存，不使用强制切换。

```powershell
git submodule update --init --recursive
git -C modules/mod-ale fetch ../../doc/repair-checkpoints/2026-09-15/ale.bundle refs/heads/fixes/20260915-runtime-checkpoint
git -C modules/mod-ale switch --detach 1f7cf175fc0c13f22a11510c0768ede053ebe29a
git -C modules/mod-playerbots fetch ../../doc/repair-checkpoints/2026-09-15/playerbots.bundle refs/heads/fixes/20260915-runtime-checkpoint
git -C modules/mod-playerbots switch --detach 831a25ee396532cb3276675d70d239b068667871
git -C modules/mod-starting-pet fetch ../../doc/repair-checkpoints/2026-09-15/starting-pet.bundle refs/heads/fixes/20260915-runtime-checkpoint
git -C modules/mod-starting-pet switch --detach 5599cf5695d2453d04e2e703180a9c06f492ddc7
```

导入后主仓库显示三个子模块版本不同是预期现象，直到这些提交发布到可访问子模块远端并更新主仓库gitlink。以后取得权限或明确改用可写fork后，可正常推送这些提交，再提交gitlink更新。

三个bundle都已通过 `git bundle verify`。本次没有替换子模块远端，没有强推，没有丢弃工作目录修改。
