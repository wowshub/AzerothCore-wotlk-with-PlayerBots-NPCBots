# 大白话教学：在武僧右侧加猎巫者图标

这次只做“招牌”，不发“能创建角色的许可证”。DBC和服务端暂时都不动。原来创建页已有左右排位工具，不需要重新安排全页，也不需要再做一个方形预览窗口。

## 三个文件

1. YB里的Interface/GlueXML/CharacterCreate.lua：新增摆放函数，再在原武僧摆放函数中调用一次。
2. YB里的同目录CharacterCreate.xml：增加一个职业样式的按钮节点，脚本只响应显示与鼠标。
3. XB里的Interface/Glues/CharacterCreate/Reborn-WitchHunter-Classes.blp：CoA原图集原字节，改私有文件名以免覆盖现有图集。

完整原文件在backup，两个逐行差异在checks/*.diff.txt。下面是新增Lua，行后逐条解释。

```lua
-- WHUI1A: icon-only entry. It never selects or creates a native class.
function CharacterCreate_PositionWitchHunterIcon()
    local button = CharCreateWitchHunterPreviewButton;
    if not button or not CharCreateClassFrame then return; end
    button:SetParent(CharCreateClassFrame);
    CharacterCreate_StyleAscendClassButton(button);
    button:ClearAllPoints();
    button:SetPoint("BOTTOM", "CharCreateClassFrame", "TOP", CharacterCreate_AscendClassSlotX(2), MONK_CLASS_BUTTON_Y);
    button:SetFrameStrata("HIGH");
    button:SetFrameLevel(CharCreateClassFrame:GetFrameLevel() + 30);
    button:SetChecked(0);
    button:Enable();
    if button.nameFrame and button.nameFrame.text then
        button.nameFrame.text:SetText("猎巫者");
    end
    button.tooltip = "|cffffffff猎巫者 / Witch Hunter|r|n|n|cffffd200CoA 新职业|r|n|n|cffffffff移植开发中，暂未开放创建。|r";
    if PAID_SERVICE_TYPE then button:Hide(); else button:Show(); end
end
-- WHUI1A end.

```

- 第一行注释标识WHUI1A是图标阶段，不执行代码。
- function给摆放过程命名，只有调用才执行，末尾end结束这个过程。
- local button拿到XML建立的按钮对象；局部名字不会改全局职业表。
- if not button…return：按钮或父框尚未加载就退出，避免空对象报错。
- SetParent挂到原职业区域，父区域隐藏时图标跟着隐藏，不留在下一页。
- StyleAscendClassButton调用既有样式函数，统一42像素头像、48像素圆环与52像素高亮；不会新造全局样式。
- ClearAllPoints先清旧锚点，反复刷新不会积累互相冲突的位置。
- SetPoint的五个参数依次为本按钮BOTTOM、参照框、参照框TOP、水平偏移、垂直偏移。slot函数参数2返回+62；原巫医参数1返回-62，武僧本身0，所以对称。
- SetFrameStrata("HIGH")和SetFrameLevel(父级+30)沿用已有按钮的绘制层，避免压到背景下面。
- SetChecked(0)取消自己的临时勾选，不修改原生角色当前职业。
- Enable允许鼠标悬停和点击；它不表示服务器允许创建此职业，实际创建资格完全没改。
- if nameFrame…end先确认继承的文字区域存在，再设置“猎巫者”。
- tooltip保存鼠标提示；白色名称、黄色类别、白色开发说明，|n换行，|r结束颜色。
- PAID_SERVICE_TYPE存在时Hide，正常创建页Show，避免把此入口带入付费转换流程。

原PositionMonkButton中只多这一行，位置在已有巫医摆放调用后：

```lua
CharacterCreate_PositionWitchHunterIcon(); -- WHUI1A
```

意思是旧流程摆完武僧和巫医后，顺便摆猎巫者。没有新增OnUpdate循环、没有改引擎枚举函数。

## XML关键行

```xml
<CheckButton name="CharCreateWitchHunterPreviewButton" inherits="CharCreateClassButtonTemplate" frameStrata="HIGH" motionScriptsWhileDisabled="true">
```

CheckButton是可勾选按钮；唯一name供Lua查找；inherits沿用原职业按钮的文字、阴影与高亮，避免做一套风格不同的控件。OnLoad用SetID(0)保持独立显示入口；不把15塞进真实职业列表。

```lua
self:SetChecked(0); -- WHUI1A: presentation only; keep the current native class.
```

这是OnClick的全部行为：点击先让自己不勾选。没有调用CharacterClass_OnClick、SetSelectedClass或CreateCharacter。原职业选择因此保持原状。OnEnter给既有CharacterCreateTooltip设所属按钮并设置说明，OnLeave隐藏它。

NormalTexture与PushedTexture都指向XB的私有图集，每处用：

```xml
<TexCoords left="0.875" right="1" top="0.75" bottom="1"/>
```

图集1024×512，横8格、竖4格，每格128×128。left/right圈定横向最后一格，top/bottom圈定纵向最后一格；这正是原CoA AtlasInfo写的class-round-witchhunter，图像自身四角透明，外面再叠原按钮圆环。不是猜位置，也没有改原图片像素。

## 工具与核对

StormLib只读提取当前MPQ和原CoA资源；Python的Path处理路径，re定位唯一函数/按钮，hashlib记录SHA256，difflib给源文件/新文件对照；XML解析检查原有节点保持；lupa.lua51用真正Lua5.1解析并重放新增函数和XML事件。接口替身验证参数和调用，不替代WoW渲染。

24项离线验证已通过，游戏验收未测。先同时导入YB脚本和XB资源、保存关闭编辑器，再进创建页看位置/圆环/提示与原职业回归。不需要编译服务器或导入SQL。
