# 2026-10-26/27 分批提交清单

21阶段、22个功能/资料提交，另有1个引用汇总提交。测试状态不因提交改变。

|阶段|仓库|提交|
|---|---|---|
|WDN5A|main|077908adafb46ddd6cfe0bfdd3aeed7da1d1d3e6|
|WDN5B|main|e0334774b12e5908ba5867863edda9859f28af7c|
|WDN5C|main|d9781b4d14eeb60c4639b332fa8ed81d3b5c1f63|
|WDN5D|main|8c48f19dec0531b37e58622f02b759bb33eb0ecc|
|WDN5F|main|41df32e3503c4852320e2e0028229dd5103ae036|
|WDN5G|main|8e3393be044fed56ccc8eea558572a147671446a|
|WDN5H|main|22951b2fcdf017fa4155f6630bb742dba8d14eef|
|TG24A|main|9b940837cac89fb30471047eff2da119b6d3153e|
|TG24B|main|4fa6b688ebfc71f515c8e2b730c2304d9880aadc|
|TG25A|main|2f46a5ac7434ab966007689ef78720ee9d4cef66|
|TG26A|main|bc9dd07f55acff69142b21d779c74a66d9005120|
|TG27A|main|043c25284d2dd0735be51d23fc37c36cdc2ed423|
|TG28A|main|f9af4990559e53ca8a45e111c35a57829640f8d2|
|TG29A|main|e477b72f127092d67b49bc34eedd505e8cf424f6|
|TG30A|main|72462ced5563febd4f5c3cd3b82124cc1c4f1864|
|TG31A|main|90be274cb3c63e819996d64183f9938c58623eab|
|TG31B|main|7351339357c281b295d6b70bccf15028f517aaf4|
|WDN5I|main|1fda17a5a851184e8936534d857c511f6ba5cab6|
|WDN6A|main|ac19c8025cf2c2dc38c65a84ebccf39e25f16e6d|
|WDN6B|main|2f1a8105b6be02aa2b8e4fb75cdc45c38204ddec|
|PBAOE1A|pb|c9616a40b8e82c1cb47266020565e9506bd5c0d3|
|PBAOE1A|main|81f7f4d04ee34d9ec83ce9eac67bc7f546311e67|

60 个Lua解析通过；合并后的Engine.cpp与AiFactory.cpp /Zs通过。
源码文本与冻结包核对；仅PB Context采用诊断增量保留远端原职业循环，不夹带此前WD205候选。
图片/DBC保留原资源ZIP；Git每阶段SOURCE.json记录来源与SHA256。未发布tag/Release。
WDN5F采用090633，TG29A采用175651；重复目录不另造提交。
推送状态：自动审批拒绝首次PB push，尚未推送。
目标主仓：wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots，threemodelcardpro。
目标子仓：wowshub/mod-playerbots，reborn-dcai1a-20261009。
下一步：明确目标授权后先推PB并读回，再推主仓并读回。