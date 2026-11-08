# 新族客户端_CharacterCreate.lua：逐行讲解
只新增39/49识别、同阵营姓名池与选角场景别名，复用此前已验收的职业刷新。
来源：`B_客户端_整合候选/交付/02_MPQ导入目录/导入PATCH-YB/Interface/GlueXML/CharacterCreate.lua`。以下行号是所附原件的真实行号；空行/注释也保留。
## 函数和接口先读表
| 名称 | 在这份文件中的作用 |
|---|---|
| `RaceUIKind` | 从当前枚举项的内部token识别新族，不把按钮下标当raceID |
| `RaceUIRandomName` | 先尝试原生随机名，缺失或重复时用同性别候选池 |
| `SetBackgroundModel` | 选择Glue舞台背景；只对CharacterSelect做场景token别名 |
| `CharacterCreate_RefreshRaceClassState` | 在本次种族/性别确定后统一重算职业及独立职业按钮状态 |

## 本次修改涉及的实际代码片段

原件第7–12行：
```lua
   if token=="REBORNSETHRAK" then return "SETHRAK" end
   if token=="REBORNOGRE" then return "OGRE" end
   if token=="REBORNKULTIRAN" then return "KULTIRAN" end   -- RACENEXT3A
   if token=="MAGHAR" then return "MAGHAR" end   -- RACENEXT3A
   return nil
  end
```

原件第4914–4920行：
```lua
-- RACEUI1A: native NameGen has no rows for the two new tokens.
local RaceUINamePools={["SETHRAK0"]={"Agamand","Andromath","Antonidas","Fordred","Nielas","Arius","Arugal","Sten","Ballador","Barthilas","Aedelas","Conjurus","Rex","Danath","Saidin","Dalar","Alonsus","Tenn","Tirion","Taelan","Gavinrad","Granis","Genn","Nandis","Geros","Jorn","Khadgar","Landazar","Shal","Anduin","Doril","Marn","Malak","Manadar","Medivh","Arthas","Terenas","Morlune","Moroes","Daelin","Rhonin","Sage","Duncan","Manos","Peril","Aran","Thoras","Turalyon","Uther","Varien","Llane","Zann","Aimery","Alex","Alonso","Ander","Anselm","Apollo","Arlan","Benedict","Berenger","Bertren","Bruce","Carl","Carlin","Carter","Cedric","Clement","Clinton","Daniel","Darren","Derek","Eric","Errol","Everard","Garth","Geoff","Graham","Gregory","Guillaume"},["SETHRAK1"]={"Aegwynn","Taretha","Calia","Maevis","Alexis","Ariandra","Kassandra","Wilhelmina","Gloriana","Sarah","Samantha","Kitiara","April","Jorune","Brunhilde","Sithaya","Andra","Amora","Dierdre","Sandris","Adelaide","Alice","Amaria","Amelia","Avelina","Barbara","Beatrix","Betta","Brigit","Calli","Candis","Carolyn","Catherine","Catin","Christiana","Christine","Cicely","Constance","Cristina","Dagny","Danielle","Darcy","Desiree","Felicity","Florencia","Giliana","Gladys","Grace","Heloise","Honor","Hope","Jane","Joy","Kaisa","Kamilla","Kimberly","Lia","Lois","Lola","Lucille","Margery","Marilyn","Marlena","Meghan","Mercy","Mirabell","Naomi","Pamela","Peggy","Prudence","Reyna","Rhoda","Sabeline","Theda","Thelma","Theresa","Tiffany","Tina","Tracy","Verity"},["OGRE0"]={"Akinos","Arashicage","Baelgun","Bale","Blackhand","Kargath","Broxxigar","Chogall","Clawhand","Magis","Kazil","Daisho","Kilrogg","Dentarg","Orgrim","Doomroar","Naz","Drekthar","Durotan","Eitrigg","Fenrisar","Fenris","Foerend","Gathras","Gardal","Gorr","Guldan","Negal","Grom","Irontusk","Kajind","Kalthar","Kazragore","Kigami","Maim","Mazuru","Mikasa","Nazgrel","Nikoro","Zess","Rend","Rexxar","Samuro","Nekros","Tagar","Thrall","Thundrax","Tojara","Uglaz","Kag","Warmaul","Borr","Pand","Kagar","Wolfsong","Morg","Yozshura","Zuluhed","Zargil","Asato","Asuya","Azuma","Baku","Chuugo","Dahr","Dai","Daichi","Dugan","Dugrum","Emok","Engo","Fukashi","Fusao","Goragon","Gor-Ka","Gulmore","Gunga","Gyousei","Hakuba","Iku"},["OGRE1"]={"Draka","Garona","Nekra","Gara","Theg","Markas","Sendra","Sergra","Gaine","Dala","Morisha","Galvania","Titania","Jenka","Ragos","Mirsha","Misha","Korvis","Mandiss","Germana","Agata","Agna","Akana","Akheena","Anga","Asako","Atsuko","Aya","Boka","Chantu","Cora","Damah","Doba","Doska","Duka","Eghala","Elka","Eta","Garuka","Ghana","Gisa","Gruta","Hedda","Hilar","Iria","Junna","Kaia","Kama","Kasa","Kaya","Loka","Luka","Machiko","Magda","Maiko","Maja","Makha","Moka","Mugallah","Nagisa","Nanaka","Nayu","Nodoka","Onela","Palka","Rana","Rela","Roka","Saaya","Sana","Tabitha","Tamao","Tamsin","Tanya","Teruna","Tetsumi","Tokimi","Yatsumi","Yukari","Agasa"}}
-- RACENEXT3A: Kul Tiran uses the human name pools, Mag'har the orc ones.
RaceUINamePools["KULTIRAN0"]=RaceUINamePools["SETHRAK0"] RaceUINamePools["KULTIRAN1"]=RaceUINamePools["SETHRAK1"]
RaceUINamePools["MAGHAR0"]=RaceUINamePools["OGRE0"] RaceUINamePools["MAGHAR1"]=RaceUINamePools["OGRE1"]
local function RaceUIRandomName()
 local kind=RaceUISelected()
```

## 一行一行读
| 原件行号 | 代码 | 大白话解释 |
|---:|---|---|
| 7 | <code>   if token=="REBORNSETHRAK" then return "SETHRAK" end</code> | 条件分支：只有`if token=="REBORNSETHRAK"  return "SETHRAK" end`成立才走随后分支；不满足进入else/跳过。 |
| 8 | <code>   if token=="REBORNOGRE" then return "OGRE" end</code> | 条件分支：只有`if token=="REBORNOGRE"  return "OGRE" end`成立才走随后分支；不满足进入else/跳过。 |
| 9 | <code>   if token=="REBORNKULTIRAN" then return "KULTIRAN" end   -- RACENEXT3A</code> | 条件分支：只有`if token=="REBORNKULTIRAN"  return "KULTIRAN" end   -- RACENEXT3A`成立才走随后分支；不满足进入else/跳过。 |
| 10 | <code>   if token=="MAGHAR" then return "MAGHAR" end   -- RACENEXT3A</code> | 条件分支：只有`if token=="MAGHAR"  return "MAGHAR" end   -- RACENEXT3A`成立才走随后分支；不满足进入else/跳过。 |
| 11 | <code>   return nil</code> | 返回失败/空结果，结束当前函数；不会继续后面的学习或写入。 |
| 12 | <code>  end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 4914 | <code>-- RACEUI1A: native NameGen has no rows for the two new tokens.</code> | 说明注释：RACEUI1A: native NameGen has no rows for the two new tokens.；它不执行，实际条件仍以相邻代码为准。 |
| 4915 | <code>local RaceUINamePools={["SETHRAK0"]={"Agamand","Andromath","Antonidas","Fordred","Nielas","Arius","Arugal","Sten","Ballador","Barthilas","Aedelas","Conjurus","Rex","Danath","Saidin","Dalar","Alonsus","Tenn","Tirion","Taelan","Gavinrad","Granis","Genn","Nandis","Geros","Jorn","Khadgar","Landazar","Shal","Anduin","Doril","Marn","Malak","Manadar","Medivh","Arthas","Terenas","Morlune","Moroes","Daelin","Rhonin","Sage","Duncan","Manos","Peril","Aran","Thoras","Turalyon","Uther","Varien","Llane","Zann","Aimery","Alex","Alonso","Ander","Anselm","Apollo","Arlan","Benedict","Berenger","Bertren","Bruce","Carl","Carlin","Carter","Cedric","Clement","Clinton","Daniel","Darren","Derek","Eric","Errol","Everard","Garth","Geoff","Graham","Gregory","Guillaume"},["SETHRAK1"]={"Aegwynn","Taretha","Calia","Maevis","Alexis","Ariandra","Kassandra","Wilhelmina","Gloriana","Sarah","Samantha","Kitiara","April","Jorune","Brunhilde","Sithaya","Andra","Amora","Dierdre","Sandris","Adelaide","Alice","Amaria","Amelia","Avelina","Barbara","Beatrix","Betta","Brigit","Calli","Candis","Carolyn","Catherine","Catin","Christiana","Christine","Cicely","Constance","Cristina","Dagny","Danielle","Darcy","Desiree","Felicity","Florencia","Giliana","Gladys","Grace","Heloise","Honor","Hope","Jane","Joy","Kaisa","Kamilla","Kimberly","Lia","Lois","Lola","Lucille","Margery","Marilyn","Marlena","Meghan","Mercy","Mirabell","Naomi","Pamela","Peggy","Prudence","Reyna","Rhoda","Sabeline","Theda","Thelma","Theresa","Tiffany","Tina","Tracy","Verity"},["OGRE0"]={"Akinos","Arashicage","Baelgun","Bale","Blackhand","Kargath","Broxxigar","Chogall","Clawhand","Magis","Kazil","Daisho","Kilrogg","Dentarg","Orgrim","Doomroar","Naz","Drekthar","Durotan","Eitrigg","Fenrisar","Fenris","Foerend","Gathras","Gardal","Gorr","Guldan","Negal","Grom","Irontusk","Kajind","Kalthar","Kazragore","Kigami","Maim","Mazuru","Mikasa","Nazgrel","Nikoro","Zess","Rend","Rexxar","Samuro","Nekros","Tagar","Thrall","Thundrax","Tojara","Uglaz","Kag","Warmaul","Borr","Pand","Kagar","Wolfsong","Morg","Yozshura","Zuluhed","Zargil","Asato","Asuya","Azuma","Baku","Chuugo","Dahr","Dai","Daichi","Dugan","Dugrum","Emok","Engo","Fukashi","Fusao","Goragon","Gor-Ka","Gulmore","Gunga","Gyousei","Hakuba","Iku"},["OGRE1"]={"Draka","Garona","Nekra","Gara","Theg","Markas","Sendra","Sergra","Gaine","Dala","Morisha","Galvania","Titania","Jenka","Ragos","Mirsha","Misha","Korvis","Mandiss","Germana","Agata","Agna","Akana","Akheena","Anga","Asako","Atsuko","Aya","Boka","Chantu","Cora","Damah","Doba","Doska","Duka","Eghala","Elka","Eta","Garuka","Ghana","Gisa","Gruta","Hedda","Hilar","Iria","Junna","Kaia","Kama","Kasa","Kaya","Loka","Luka","Machiko","Magda","Maiko","Maja","Makha","Moka","Mugallah","Nagisa","Nanaka","Nayu","Nodoka","Onela","Palka","Rana","Rela","Roka","Saaya","Sana","Tabitha","Tamao","Tamsin","Tanya","Teruna","Tetsumi","Tokimi","Yatsumi","Yukari","Agasa"}}</code> | 只对指定发布工作树执行Git核对；正式发布白名单，不包含日常未知修改。 |
| 4916 | <code>-- RACENEXT3A: Kul Tiran uses the human name pools, Mag'har the orc ones.</code> | 说明注释：RACENEXT3A: Kul Tiran uses the human name pools, Mag'har the orc ones.；它不执行，实际条件仍以相邻代码为准。 |
| 4917 | <code>RaceUINamePools["KULTIRAN0"]=RaceUINamePools["SETHRAK0"] RaceUINamePools["KULTIRAN1"]=RaceUINamePools["SETHRAK1"]</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`RaceUINamePools["KULTIRAN0"]=RaceUINamePools["SETHRAK0"] RaceUINamePools["KULTIRAN1"]=RaceUINamePools["SETHRAK1"]`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 4918 | <code>RaceUINamePools["MAGHAR0"]=RaceUINamePools["OGRE0"] RaceUINamePools["MAGHAR1"]=RaceUINamePools["OGRE1"]</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`RaceUINamePools["MAGHAR0"]=RaceUINamePools["OGRE0"] RaceUINamePools["MAGHAR1"]=RaceUINamePools["OGRE1"]`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 4919 | <code>local function RaceUIRandomName()</code> | 定义/进入函数：先尝试原生随机名，缺失或重复时用同性别候选池。 |
| 4920 | <code> local kind=RaceUISelected()</code> | 定义局部变量：local kind=RaceUISelected()；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
