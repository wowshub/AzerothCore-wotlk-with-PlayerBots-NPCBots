## 2026-09-17 EV1G限定成功：装备包双龙UI
用户截图EV1G并说“这个和coawow很搭了 很棒”。确认的是整窗双龙美术、背景后退和文字/装备可读性的视觉结果。来源：000Ascendupdate/000Ascendupdate20260917/codexfix_202609170211_阶段EV1G_背景退后与装备可读性。
适用于独立RebornEquipmentVault预览窗：FULLSCREEN_DIALOG与完整构建；整窗BORDER背景，当前BLP2/DXT1 1024方画布、有效UV(0,1,170/1024,853/1024)，左右暗罩.35/.50、人物区域.16、槽暗底.55、空图标alpha .65。复用已确认文件字节优先，不将PNG/TGA直接放入旧客户端。
只记录视觉成功，不扩展成存取、购买、整套换装、天赋联动已验证。EV2A服务端资格校验候选位于D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260917\codexfix_202609170239_阶段EV2A_装备原件与穿戴资格服务端校验，仍待实机。

## 2026-09-17 WD18 两处圆环实机通过

用户明确反馈“好的 修复好了”。来源：000Ascendupdate/000Ascendupdate20260917/codexfix_202609170357_阶段WD18_双面板圆环淡黑方底修复。
WD17只裁头像，圆环本身ClassPortraitRing的方形UV区域仍含淡黑方底。WD18对天赋Panel.lua和衣柜Vault.lua的圆环也几何裁圆：72显示尺寸、UV .25-.75、144个半单位水平条带（142有效），边缘宽度按条带较远边的圆方程计算。仅初始化创建，旧客户端无需现代MaskTexture，无资源重编码。
复用时同时检查图标和圆环/阴影两层；不能把圆环当成下层头像遮罩。验收仅限此次两个圆环方底消除，不扩展到装备存取或数据库故障保证。
