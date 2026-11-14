# H_button摘录.lua 逐行读法
原件见03_代码原件；这里每行引用真实代码。空行只起分隔作用。下述是历史构建/测试代码，别直接向运行端执行。

**第1行**
```
 local function button(b)
```
定义可复用函数；名称表明用途，参数来自调用方；函数主体在后续行。

**第2行**
```
  if not b or b._rebornActionFrameH then return end
```
条件分支：只有满足当前条件才执行这一段，其他情形走后面的分支。

**第3行**
```
  b._rebornActionFrameH=true
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第4行**
```
  b._rebornCreatorSkin=true
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第5行**
```
  -- Clear only once: repeated list refreshes must not erase our new button textures.
```
注释或编译/导入说明：阅读它确认这一段意图；注释本身不证明游戏行为。

**第6行**
```
  for _,region in ipairs({b:GetRegions()}) do
```
仅首次清理旧的匿名贴图，避免刷新时把新贴图也隐藏。

**第7行**
```
   if region:GetObjectType()=='Texture' then region:SetAlpha(0) end
```
把旧纹理透明度设0，不删除角色/物品。

**第8行**
```
  end
```
结束当前函数、分支或结构；作用范围到这里为止。

**第9行**
```
  local function state(setter,color,layer)
```
定义可复用函数；名称表明用途，参数来自调用方；函数主体在后续行。

**第10行**
```
   local t=solid(b,layer or 'BACKGROUND',color[4]);t:SetAllPoints(b)
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第11行**
```
   t:SetBlendMode('BLEND');t:SetVertexColor(unpack(color));b[setter](b,t)
```
颜色通道与alpha乘在纹理上，RGB为0..1。

**第12行**
```
  end
```
结束当前函数、分支或结构；作用范围到这里为止。

**第13行**
```
  state('SetNormalTexture',{0.025,0.030,0.040,0.52})
```
普通状态使用淡黑底；不是换点击回调。

**第14行**
```
  state('SetPushedTexture',{0.010,0.015,0.020,0.74})
```
按下状态更深，提供按压反馈。

**第15行**
```
  state('SetHighlightTexture',{0.70,0.58,0.32,0.16},'HIGHLIGHT')
```
悬停使用淡金色高亮。

**第16行**
```
  state('SetDisabledTexture',{0.025,0.030,0.040,0.34})
```
禁用状态淡化底色。

**第17行**
```
  -- Quiet one-pixel edges retain the dark-glass style without a heavy frame.
```
注释或编译/导入说明：阅读它确认这一段意图；注释本身不证明游戏行为。

**第18行**
```
  for _,side in ipairs({'TOP','BOTTOM','LEFT','RIGHT'}) do
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第19行**
```
   local edge=solid(b,'BORDER',0.27);edge:SetVertexColor(0.48,0.43,0.32,0.27)
```
颜色通道与alpha乘在纹理上，RGB为0..1。

**第20行**
```
   if side=='TOP' or side=='BOTTOM' then
```
条件分支：只有满足当前条件才执行这一段，其他情形走后面的分支。

**第21行**
```
    edge:SetHeight(1);edge:SetPoint(side..'LEFT',b,side..'LEFT',0,0);edge:SetPoint(side..'RIGHT',b,side..'RIGHT',0,0)
```
指定相对锚点；相同CENTER让新视觉框居中。

**第22行**
```
   else
```
条件分支：只有满足当前条件才执行这一段，其他情形走后面的分支。

**第23行**
```
    edge:SetWidth(1);edge:SetPoint('TOP'..side,b,'TOP'..side,0,0);edge:SetPoint('BOTTOM'..side,b,'BOTTOM'..side,0,0)
```
指定相对锚点；相同CENTER让新视觉框居中。

**第24行**
```
   end
```
结束当前函数、分支或结构；作用范围到这里为止。

**第25行**
```
  end
```
结束当前函数、分支或结构；作用范围到这里为止。

**第26行**
```
  if not RebornSelectActionNormalH then
```
条件分支：只有满足当前条件才执行这一段，其他情形走后面的分支。

**第27行**
```
   local colors={Normal={0.91,0.77,0.42},Highlight={1.0,0.90,0.64},Disabled={0.48,0.48,0.46}}
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第28行**
```
   for name,color in pairs(colors) do
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第29行**
```
    local f=CreateFont('RebornSelectAction'..name..'H');font(f,14);f:SetTextColor(unpack(color))
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第30行**
```
   end
```
结束当前函数、分支或结构；作用范围到这里为止。

**第31行**
```
  end
```
结束当前函数、分支或结构；作用范围到这里为止。

**第32行**
```
  b:SetNormalFontObject(RebornSelectActionNormalH)
```
执行当前表达式或方法；它仍受所在循环/分支限制。对文件的影响以旁边的白名单和断言为边界。

**第33行**
```
  b:SetHighlightFontObject(RebornSelectActionHighlightH)
```
执行当前表达式或方法；它仍受所在循环/分支限制。对文件的影响以旁边的白名单和断言为边界。

**第34行**
```
  b:SetDisabledFontObject(RebornSelectActionDisabledH)
```
执行当前表达式或方法；它仍受所在循环/分支限制。对文件的影响以旁边的白名单和断言为边界。

**第35行**
```
 end
```
结束当前函数、分支或结构；作用范围到这里为止。
