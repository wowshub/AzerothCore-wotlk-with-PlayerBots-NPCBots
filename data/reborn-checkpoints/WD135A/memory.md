# WD135A 候选记录 — 2026-10-07

前序：WD134A+B已验收，commit912959a6e，tag reborn-wd134-20261007，Release完成且附件SHA匹配。兽人武僧语言d1d508eca与观察者重力33fc9762f分别推送，专项实机未据此声明通过。SOAP及其余无关工作树未提交。

本批灵魂链接雕像13133/9003953/Creature900232，free level50，需4733，index104 bit116；14秒/2秒/10码/180秒/3%基础法力。复用Idol槽与1101122既有模型。纯玩家团队健康重分配，不支持NPCBot，不造血、不触发治疗链。

来源技能：plan-coa-class-migration（按依赖选完整小批）、trace-and-port-coa-spell-resources（独立双端资源链）、build-wotlk-three-build-projection（保存所有权）。新候选不晋升永久已验证Skill。

线上上游main固定64188b25575c1244a23b6051d1044350aaabc610，Summons.cpp Link用10码、玩家筛选、最大生命加权、余数补偿，已适配本地Idol槽。Issue1891已关闭但最初误归Necromancer并仅静态发现；不把关闭本身当实机证据。检索含开放/关闭Issue和PR，保留spirit_link_issues.json与最新源。官方20260930 patch-T Spell706369/500992/500993，locale-enUS Duration305=14000、Radius13=10；官方Spell仍3%mana/180秒。实际客户端/服务端输入与已验收WD134B逐字节一致。

188隔离SQL、29数据/Lua、两单元/Zs、实际头文件10000守恒测试通过。首轮SQL因缺测试masks夹具中断，补齐后两轮通过；旧非法bit116测试更新为117，不放宽数据校验。新World模板禁经验与自回血。当前只在独立包改动，未覆盖运行目录、未完整编译、未生产SQL、未提交WD135。
