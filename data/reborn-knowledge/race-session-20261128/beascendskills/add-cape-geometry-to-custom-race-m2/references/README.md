# 脚本说明
- `sethcape.py`：构建披风（用法见文件头注释：`STYLE=A3 python sethcape.py female|male 输出目录 [骨骼17 骨骼3]`）。路径写死在 `D:/_zsdc`、`D:/000rebornWOW/...`，复用前先改；女性基底读 1D 备份的无披风真原件，男性读 1A 备份。**最终女性 1J = `STYLE=A3`，不带骨骼参数。**
- `godi_check.py`：用 StormLib 按客户端 Data 目录读 MPQ（`read(name)`），脚本都依赖它；StormLib.dll 路径写死 `D:/_zsdc/pkg`。
- `findm2.py`：按通配符枚举 MPQ（大档案很慢，优先直接按路径试读）。
- 校验/诊断脚本（`capewind.py` 三角面朝向、`capeuv.py`、`mat15.py`、`units2.py`）见 [repair-m2-cape-holes-backface-culling/references](../../repair-m2-cape-holes-backface-culling/references/)。
