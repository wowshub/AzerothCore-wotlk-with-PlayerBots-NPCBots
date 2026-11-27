# RETAIL-PACK-WMO-20261127：瘦身包工具与高版本建筑显示修复

## SLIM1A(瘦身包)
用户装包后把 `path=` 指到不存在的目录模拟另一台电脑，传送测试四张地图，原话“没有啥问题”。离线验证：9789 项成功，2 个模型在装有零售数据时同样失败，缺文件 0。另一台实体电脑未测。

`tools/collect.py` 从 `aliases_maps.csv` 出发收集 WDT/ADT/WMO/M2 引用闭包，写成引擎的解码缓存；`tools/verify.py` 用不存在的零售路径复验。脚本里的路径是本机路径，需要引擎自带的 RetailAssetProbe 工具和一份零售数据来源。**缓存内容是游戏原版素材，不入库、不放 Release。**

## WMOSPLIT2(拱门远处看穿、室内空缺)
用户原话“都正常的了”(大洞)、“其他几个 都修复的很棒”。
- 原因范围：`wmoindoor=both/outdoor` 使地下建筑远处内容不画；不写该项时 3.3.5 画不出零售“拆分分块”。
- 修复：只给室内拆分分块(MOGP flags2 0x40/0x80)加 0x8，以 overlay 文件交付；`RetailCasc.ini` 不写 `wmoindoor`。不改程序。
- 范围：建筑 4235933、4530996、4320278、6224922，共 28 个 overlay 文件(清单见 manifests，文件本身不入库)。用 `tools/build_wmosplit2.py` 从本机缓存重新生成；新移植地图后先跑 `tools/split_scan.py`。
