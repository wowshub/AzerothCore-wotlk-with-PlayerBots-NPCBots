# UI_AMMO1A 用户验收 2026-10-10
用户原话：“弩的弹药槽和 战士防护的显示正常了”。验收限显示；不扩大为全部职业、射击规则或机器人天赋加点验收。
基线57d3860f2fd8ff8bfc0a17ab855df858bc453c0d，fetch远端一致；两份运行客户端Lua与已交付包逐字节一致。
弩识别不再以拍卖行紧凑分类列表下标代替ItemSubClass ID；MultiBot Warrior3简中修正为防护。
仅覆盖Interface下两份Lua，非战斗/reload。无SQL、DBC、服务端Data或编译要求。与衣柜文件无重叠。
16项离线Lua检查已通过。完整回滚与教学见原包，原包不改写。
源ZIP SHA256: 6406c4c9310d73d263529ef352a1aed334997ee2f3848344dd5d75636d13cea9
