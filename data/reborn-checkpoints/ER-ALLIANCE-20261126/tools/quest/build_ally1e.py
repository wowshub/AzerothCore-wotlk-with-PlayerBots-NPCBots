# -*- coding: utf-8 -*-
"""ALLY1E V1: Alliance 55194 supplies -> 55965 west -> 55639 pit -> 56344 Darkmaul, cloned from the Horde 59950 / PIT1A-1D."""
import os, hashlib
B = chr(92)
WS = r'D:\000rebornWOW\000RebornWOWHighForkPRO'
DAY = os.path.join(WS, '000Ascendupdate', '000Ascendupdate20261125')
NAME = 'claudefix_20261125_阶段ALLY1E_V1_联盟补给西行深坑暗槌4任务55194到56344_Claude'
P = os.path.join(DAY, NAME)
assert not os.path.exists(P)
SRVLUA = WS + r'\beascendserver\wowshub_playerbot_npcbot_newrace20261122Ascend\lua_scripts'
q = lambda s: "'" + s.replace("'", "''") + "'"
QUESTS = (55194, 55965, 55639, 56344)
QL = ', '.join(map(str, QUESTS))
COCOON_H, COCOON_A, MOUNT_H, MOUNT_A = 9350796, 9350797, 9167011, 9167012
Q_SUPPLY, Q_PIT, RICHTER, HRUN, RALIA = 55194, 55639, 156800, 156900, 156929

NPC = [  # entry, display, npcflag, name
    (154300, 1628, 2, 'Bjorn Stouthands 比约恩·石手'),
    (156891, 1628, 2, 'Bjorn Stouthands 比约恩·石手'),
    (156803, 3270, 2, 'Alaria 阿拉莉亚'),
    (156800, 1612, 129, 'Quartermaster Richter 军需官里希特'),
    (156929, 1992, 1, 'Ralia Dreamchaser 拉莉亚·追梦者'),
    (156941, 710006, 2, 'Lady Jaina Proudmoore 吉安娜·普罗德摩尔'),
]
NL = ', '.join(str(n[0]) for n in NPC)
ALL_NEW = NL + ', %d' % MOUNT_A
SPAWN = [(154300, '184.972', '-2292.13', '81.7709', '1.90291', 'Bjorn camp'),
         (156800, '178.518', '-2291.15', '81.8501', '0.869839', 'Richter camp'),
         (156891, '89.7534', '-2249.43', '94.7218', '1.8747', 'Bjorn pit rim'),
         (156803, '91.9826', '-2246.83', '94.4823', '2.02451', 'Alaria pit rim'),
         (156929, '73.1613', '-2127.24', '-29.6948', '4.98427', 'Ralia pit bottom'),
         (156941, '323.295', '-2179.64', '106.099', '2.52876', 'Jaina Darkmaul')]
COCOONS = [('72.9353', '-2183.72', '23.7982'), ('123.301', '-2237.83', '-5.8769'), ('64.7351', '-2276.11', '-0.592913'),
           ('36.3941', '-2190.78', '19.3433'), ('109.15', '-2223.37', '33.1916')]
Q = [  # id, difficulty, prev, next, title, log, desc, done, offer, request, giver, ender
    (55194, 4, 55882, 55965, 'Stocking Up on Supplies / 补充补给', 'Speak with Quartermaster Richter and look at her wares. / 与军需官里希特交谈，看看她的货物。',
     "Quartermaster Richter was able to scavenge supplies from the wreckages on this island.$B$BWhy don't you visit her and see if she has anything that you need?$B$BYou'll want to be well equipped for whatever we encounter next.$B$B军需官里希特从岛上的残骸里搜集到一些补给。$B$B去看看有没有你需要的东西，接下来遇到什么都得准备充分。",
     'Return to Lady Jaina Proudmoore. / 回到吉安娜那里。',
     "All stocked up? That's great.$B$BPrivate Cole and Quartermaster Richter also found this bag in the nearby ruins. They thought you might make good use of it.$B$B补给好了？很好。$B$B科尔列兵和军需官在附近废墟里还找到了这个背包，他们觉得你用得上。", 'Have you seen the quartermaster?$B$B见过军需官了吗？', 156807, 156807),
    (55965, 3, 55194, 55639, 'Westward Bound / 向西前进', 'Meet Bjorn Stouthands west of the Alliance Camp. / 在联盟营地以西与比约恩·石手会合。',
     "Captain Garrick wants us tae search west o' camp fer any other members of the expedition.$B$BAlaria and I will go on ahead. Meet us tae the west and we'll see what we can find.$B$B队长要我们到营地西边搜找远征队的其他人。$B$B阿拉莉亚和我先走一步，到西边找我们碰头。",
     'Meet Bjorn Stouthands west of the Alliance Camp. / 在营地以西与比约恩会合。',
     "A giant pit of spiders right on our doorstep! Aren't we the lucky ones?$B$B家门口就是个蜘蛛大坑！咱们可真走运。", 'Over here.$B$B这边。', 154300, 156891),
    (55639, 6, 55965, 56344, 'Who Lurks in the Pit / 深坑里的潜伏者', 'Rescue 5 Trapped Expedition Members. / 解救5名被困的远征队成员。',
     "The winds whisper of people being trapped in the pit. It seems there may be more members of the expedition within.$B$BI fear it will be up to you to make the descent and save the survivors.$B$BThe winds say one is farther away from the others... With our luck, the last survivor is at the bottom of the pit.$B$BGood luck, $n. And... make sure no spiders follow you back out.$B$B风在低语，说有人困在这深坑里，恐怕远征队还有人在下面。$B$B只能靠你下去救他们了。$B$B风还说有一个人离其他人很远……照咱们的运气，最后那个肯定在坑底。$B$B祝你好运，$n。还有……别让蜘蛛跟着你上来。",
     'Report back to Lady Jaina Proudmoore. / 回到营地向吉安娜复命。',
     "Ralia Dreamchaser is a druid of the Cenarion Circle, an order dedicated to protecting the wilds of Azeroth.$B$BThank you for rescuing her. Her aid is sure to be of use against the ogres.$B$B拉莉亚·追梦者是塞纳里奥议会的德鲁伊，这个组织致力于守护艾泽拉斯的荒野。$B$B谢谢你救了她，对付食人魔一定用得上她的帮助。", 'Free them all, then get out of there.$B$B把他们都救出来，然后赶紧出来。', 156803, 156807),
    (56344, 3, 55639, 0, 'To Darkmaul Citadel / 前往暗槌要塞', 'Meet Lady Jaina Proudmoore outside of Darkmaul Citadel. / 在暗槌要塞外与吉安娜会合。',
     "We've rescued everyone except for the expedition's captain. Lindie's Scout-o-Matic spotted her just outside Darkmaul Citadel.$B$BMeredy has come up with an... interesting plan to rescue the captain. It may be our only chance.$B$BCome. We'll convene in the shadow of Darkmaul Citadel, and there we will begin our rescue mission.$B$B除了远征队的队长，人都救回来了。琳迪的侦察机在暗槌要塞外发现了她。$B$B梅瑞迪想出了一个……挺有意思的营救计划，这也许是唯一的机会。$B$B来吧，我们在暗槌要塞的阴影下集合，从那里开始营救。",
     'Meet Jaina outside Darkmaul Citadel. / 到暗槌要塞外与吉安娜会合。',
     "All right, $n. I hope you're a good actor, because you're about to play to a very tough crowd.$B$B好了，$n。希望你演技不错，因为你要面对一群很难糊弄的观众。", 'You made it.$B$B你到了。', 156807, 156941),
]
OBJ = {55194: [(RICHTER, 1, 'Speak with Quartermaster Richter / 与军需官里希特交谈')],
       55639: [(-COCOON_A, 5, 'Trapped Expedition Members rescued from cocoons / 从茧中解救的被困远征队成员'),
               (HRUN, 1, 'Defeat Hrun to rescue Ralia Dreamchaser / 击败赫鲁恩，解救拉莉亚'),
               (RALIA, 1, 'Ride Ralia Dreamchaser to escape / 骑乘拉莉亚逃出深坑')]}


def box(cx, cy):
    return [(cx - 9, cy - 9), (cx + 9, cy - 9), (cx + 9, cy + 9), (cx - 9, cy + 9)]


POI = {55194: [(0, box(178, -2291)), (-1, box(186, -2289))],
       55965: [(-1, box(90, -2249))],
       55639: [(0, [(79, -2280), (123, -2239), (110, -2218), (35, -2199), (64, -2277)]), (1, box(69, -2122)), (2, box(74, -2134)), (-1, box(186, -2289))],
       56344: [(-1, box(323, -2180))]}

s = ['-- ALLY1E V1 (2026-11-25, Claude): Alliance 55194 -> 55965 -> 55639 -> 56344, cloned from the Horde 59950 / PIT1A-1D.',
     '-- Needs PIT1A/PIT1B/PIT1D, ALLY1D and MODEL1A. Safe to run twice. Keep worldserver stopped.',
     'SET NAMES utf8mb4;',
     'SET @spawn_limit := 16777215;',
     "DELETE FROM `creature` WHERE `map` = 12175 AND `Comment` LIKE 'ALLY1E %';",
     "DELETE FROM `gameobject` WHERE `map` = 12175 AND `Comment` LIKE 'ALLY1E %';",
     'SELECT (SELECT COUNT(*) FROM `gameobject_template` WHERE `entry` = %d) AS horde_cocoon_must_be_1,' % COCOON_H,
     '       (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (%d, %d)) AS hrun_and_mount_must_be_2,' % (HRUN, MOUNT_H),
     '       (SELECT COUNT(*) FROM `creature_model_info` WHERE `DisplayID` IN (1628, 3270, 1612, 1992, 710006)) AS model_info_must_be_5,',
     '       (SELECT COUNT(*) FROM `npc_vendor` WHERE `entry` = 9167001) AS horde_vendor_items;',
     'DELETE FROM `creature_template` WHERE `entry` IN (%s);' % ALL_NEW,
     'DELETE FROM `creature_template_model` WHERE `CreatureID` IN (%s);' % ALL_NEW,
     'DELETE FROM `npc_vendor` WHERE `entry` = %d;' % RICHTER]
for tab, col in (('quest_template', 'ID'), ('quest_template_addon', 'ID'), ('quest_offer_reward', 'ID'), ('quest_request_items', 'ID'),
                 ('creature_queststarter', 'quest'), ('creature_questender', 'quest'), ('quest_poi_points', 'QuestID'), ('quest_poi', 'QuestID')):
    s.append('DELETE FROM `%s` WHERE `%s` IN (%s);' % (tab, col, QL))
s += ['SELECT COALESCE(MAX(`guid`), 0) INTO @g FROM `creature` WHERE `guid` < @spawn_limit;',
      'SELECT COALESCE(MAX(`guid`), 0) INTO @o FROM `gameobject` WHERE `guid` < @spawn_limit;',
      "SELECT IF(@g + 100 + 10000 < @spawn_limit AND @o + 100 + 10000 < @spawn_limit, 'guid base OK', 'ABORT: no guid room, do not continue') AS guid_check;"]
for e, d, flag, n in NPC:
    s.append('INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `HealthModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `ScriptName`) VALUES '
             "(%d, %s, NULL, 1, 1, 35, %d, 1, 1.14286, 0, 1, 0, 7, '', 3, 1, 1, 0, '');" % (e, q(n), flag))
    s.append('INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (%d, 0, %d, 1, 1, 0);' % (e, d))
s += ['INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`) SELECT %d, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild` FROM `npc_vendor` WHERE `entry` = 9167001;' % RICHTER,
      '-- escape mount: copy of the Horde mount creature, model changed later by the optional model package',
      'DROP TEMPORARY TABLE IF EXISTS tmp_mount_a;',
      'CREATE TEMPORARY TABLE tmp_mount_a AS SELECT * FROM `creature_template` WHERE `entry` = %d;' % MOUNT_H,
      "UPDATE tmp_mount_a SET `entry` = %d, `name` = 'Ralia''s Stag 拉莉亚的雄鹿';" % MOUNT_A,
      'INSERT INTO `creature_template` SELECT * FROM tmp_mount_a;',
      'DROP TEMPORARY TABLE tmp_mount_a;',
      'INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (%d, 0, 1992, 1.2, 1, 0);' % MOUNT_A,
      '-- Alliance cocoon: same row as the Horde cocoon, only the quest (Data1) differs',
      'DELETE FROM `gameobject_template` WHERE `entry` = %d;' % COCOON_A,
      'DROP TEMPORARY TABLE IF EXISTS tmp_cocoon_a;',
      'CREATE TEMPORARY TABLE tmp_cocoon_a AS SELECT * FROM `gameobject_template` WHERE `entry` = %d;' % COCOON_H,
      'UPDATE tmp_cocoon_a SET `entry` = %d, `Data1` = %d;' % (COCOON_A, Q_PIT),
      'INSERT INTO `gameobject_template` SELECT * FROM tmp_cocoon_a;',
      'DROP TEMPORARY TABLE tmp_cocoon_a;',
      '-- phases: Horde cocoons 1, Alliance cocoons 2; Hrun and the spiders shared 3',
      'UPDATE `gameobject` SET `phaseMask` = 1 WHERE `map` = 12175 AND `id` = %d;' % COCOON_H,
      'UPDATE `creature` SET `phaseMask` = 3 WHERE `map` = 12175 AND `id1` IN (%d, 160394, 160433);' % HRUN]
for i, (e, x, y, z, o, label) in enumerate(SPAWN, 1):
    s.append('INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES '
             "(@g + %d, %d, 12175, 1, 2, 0, %s, %s, %s, %s, 120, 0, 0, 'ALLY1E %s');" % (i, e, x, y, z, o, label))
for i, (x, y, z) in enumerate(COCOONS, 1):
    s.append('INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES '
             "(@o + %d, %d, 12175, 1, 2, %s, %s, %s, 0, 0, 0, 0, 1, 60, 255, 1, 'ALLY1E cocoon');" % (i, COCOON_A, x, y, z))
for qid, diff, prev, nxt, title, log, desc, done, offer, req, giver, ender in Q:
    reward = (', `RewardItem1`, `RewardAmount1`', ', 4498, 1') if qid == Q_SUPPLY else ('', '')
    s.append('INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `RewardXPDifficulty`, `Flags`, `LogTitle`, `LogDescription`, `QuestDescription`, `QuestCompletionLog`, `AreaDescription`%s) VALUES '
             "(%d, 2, 1, 1, %d, 0, %s, %s, %s, %s, ''%s);" % (reward[0], qid, diff, q(title), q(log), q(desc), q(done), reward[1]))
    for k, (o, n, text) in enumerate(OBJ.get(qid, []), 1):
        s.append('UPDATE `quest_template` SET `RequiredNpcOrGo%d` = %d, `RequiredNpcOrGoCount%d` = %d, `ObjectiveText%d` = %s WHERE `ID` = %d;' % (k, o, k, n, k, q(text), qid))
    s.append('INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`, `NextQuestID`) VALUES (%d, %d, %d);' % (qid, prev, nxt))
    s.append('INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `EmoteDelay1`, `EmoteDelay2`, `RewardText`, `VerifiedBuild`) VALUES (%d, 1, 0, 0, 0, %s, 0);' % (qid, q(offer)))
    s.append('INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES (%d, 0, 0, %s, 0);' % (qid, q(req)))
    s.append('INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (%d, %d);' % (giver, qid))
    s.append('INSERT INTO `creature_questender` (`id`, `quest`) VALUES (%d, %d);' % (ender, qid))
nrow = npt = 0
for qid, parts in POI.items():
    for idx, (obj, pts) in enumerate(parts):
        s.append('INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`) VALUES (%d, %d, %d, 12175, 20414, 0, 0, 1, 0);' % (qid, idx, obj))
        nrow += 1
        for j, (x, y) in enumerate(pts):
            s.append('INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (%d, %d, %d, %d, %d, 0);' % (qid, idx, j, x, y))
            npt += 1
s += ['SELECT (SELECT COUNT(*) FROM `quest_template` WHERE `ID` IN (%s)) AS quests_4,' % QL,
      "       (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'ALLY1E %') AS npcs_6,",
      "       (SELECT COUNT(*) FROM `gameobject` WHERE `Comment` LIKE 'ALLY1E %') AS cocoons_5,",
      '       (SELECT `Data1` FROM `gameobject_template` WHERE `entry` = %d) AS cocoon_quest_55639,' % COCOON_A,
      '       (SELECT COUNT(*) FROM `npc_vendor` WHERE `entry` = %d) AS vendor_items,' % RICHTER,
      '       (SELECT COUNT(*) FROM `creature_queststarter` WHERE `quest` IN (%s)) AS starters_4,' % QL,
      '       (SELECT COUNT(*) FROM `creature_questender` WHERE `quest` IN (%s)) AS enders_4,' % QL,
      '       (SELECT COUNT(*) FROM `quest_poi` WHERE `QuestID` IN (%s)) AS poi_%d;' % (QL, nrow)]


def wr(rel, text, nl='\n'):
    f = os.path.join(P, rel.replace('/', B))
    os.makedirs(os.path.dirname(f), exist_ok=True)
    open(f, 'w', encoding='utf-8', newline=nl).write(text)


# ---------------------------------------------------------------- Lua: the Horde Pit1A.lua without its Hrun section (Hrun is shared)
src = open(os.path.join(SRVLUA, 'Pit1A.lua'), encoding='utf-8').read()


def sub(t, old, new, count=1):
    assert t.count(old) == count, (old, t.count(old))
    return t.replace(old, new)


a = src.index('local Q_PIT = 59949')
h = src.index('-- ---------------------------------------------------------------- Hrun')
r = src.index("-- ---------------------------------------------------------------- Crenna's ride")
head = ('-- Ally1E.lua (ALLY1E V1, 2026-11-25, Claude) - candidate, NOT user-tested.\n'
        '-- Alliance quests 55194 (Quartermaster Richter) and 55639 (pit): cocoons 9350797, Ralia Dreamchaser 156929 and her ride out of the pit.\n'
        '-- The cocoon and ride code is the Horde Pit1A.lua (PIT1D V1). Hrun the Exiled is shared by both factions and stays scripted by Pit1A.lua,\n'
        '-- which must be loaded too.\n')
lua = head + src[a:h] + src[r:]
lua = sub(lua, 'local Q_PIT = 59949', 'local Q_PIT = %d' % Q_PIT)
lua = sub(lua, 'local COCOON, HRUN, CRENNA = 9350796, 156900, 167254', 'local COCOON, HRUN, CRENNA = %d, %d, %d      -- CRENNA = Ralia Dreamchaser on the Alliance side' % (COCOON_A, HRUN, RALIA))
lua = sub(lua, "local ELK = 9167011                        -- taxi mount creature with the elk-like display (world_pit1b.sql)",
          "local ELK = %d                        -- taxi mount creature of Ralia (world_ally1e.sql)" % MOUNT_A)
lua = sub(lua, 'local YIELD_PCT = 20\n', '')
lua = sub(lua, 'local SPELL_STRIKE, SPELL_THUNDERCLAP = 11976, 8078\n', '')
lua = sub(lua, 'Report back to Thrall. / 你逃出了深坑！回去向萨尔复命。', 'Report back to Jaina. / 你逃出了深坑！回去向吉安娜复命。')
lua = sub(lua, 'talk to Crenna again. / 骑乘没有开始，请再和克蕾娜说话。', 'talk to Ralia again. / 骑乘没有开始，请再和拉莉亚说话。')
lua = sub(lua, 'if hrun and hrun:IsAlive() and not yielded[hrun:GetGUIDLow()] then',
          'if hrun and hrun:IsAlive() and hrun:GetFaction() ~= FACTION_FRIENDLY then      -- Pit1A.lua makes him friendly when he yields')
a = lua.index('RegisterCreatureGossipEvent(CRENNA')
b = lua.index('-- PIT1D: taking the quest')
gossip = lua[a:b]
gossip = sub(gossip, 'return false\n', 'return\n', gossip.count('return false\n'))
gossip = gossip.replace('player:GossipComplete(); return false end', 'player:GossipComplete(); return end')
assert 'return false' not in gossip
lua = lua[:a] + gossip + lua[b:]
lua = lua.replace('[Pit1A] Crenna ride path', '[Ally1E] Ralia ride path').replace('[Pit1A]', '[Ally1E]')
p = lua.index('print("[Ally1E] PIT1D V1 loaded')
lua = lua[:p] + '''-- ---------------------------------------------------------------- Quartermaster Richter (55194)
local Q_SUPPLY, RICHTER = %d, %d
RegisterCreatureGossipEvent(RICHTER, 1, function(event, player, creature)
    if player:HasQuest(Q_SUPPLY) then
        player:KilledMonsterCredit(RICHTER)
        creature:SendUnitSay("Take a look. We saved what we could. 看看吧，能抢救的我们都抢救出来了。", 0)
    end
    player:SendListInventory(creature)
end)

print("[Ally1E] ALLY1E V1 loaded: quests %d / %d, cocoon " .. COCOON .. ", Ralia " .. CRENNA .. ", mount " .. ELK)
''' % (Q_SUPPLY, RICHTER, Q_SUPPLY, Q_PIT)
wr('02_服务端_lua_scripts/Ally1E.lua', lua)

undo = ['-- undo ALLY1E V1',
        "DELETE FROM `creature` WHERE `map` = 12175 AND `Comment` LIKE 'ALLY1E %';",
        "DELETE FROM `gameobject` WHERE `map` = 12175 AND `Comment` LIKE 'ALLY1E %';",
        'DELETE FROM `creature_template` WHERE `entry` IN (%s);' % ALL_NEW,
        'DELETE FROM `creature_template_model` WHERE `CreatureID` IN (%s);' % ALL_NEW,
        'DELETE FROM `npc_vendor` WHERE `entry` = %d;' % RICHTER,
        'DELETE FROM `gameobject_template` WHERE `entry` = %d;' % COCOON_A,
        'UPDATE `gameobject` SET `phaseMask` = 3 WHERE `map` = 12175 AND `id` = %d;' % COCOON_H]
for tab, col in (('quest_template', 'ID'), ('quest_template_addon', 'ID'), ('quest_offer_reward', 'ID'), ('quest_request_items', 'ID'),
                 ('creature_queststarter', 'quest'), ('creature_questender', 'quest'), ('quest_poi_points', 'QuestID'), ('quest_poi', 'QuestID')):
    undo.append('DELETE FROM `%s` WHERE `%s` IN (%s);' % (tab, col, QL))
wr('01_服务端_SQL/world_ally1e.sql', '\n'.join(s) + '\n', '\r\n')
wr('03_撤销/undo_ally1e.sql', '\n'.join(undo) + '\n', '\r\n')
wr('README_覆盖与测试说明.md', '''# ALLY1E V1：联盟补给、西行、深坑、前往暗槌要塞(4 个任务)

状态：候选，实机未测。服务端 SQL 一个、Lua 一个；客户端不用改。
前提：部落的 PIT1A/PIT1B/PIT1D、联盟 ALLY1D、模型包 MODEL1A 已装；`lua_scripts/Pit1A.lua` 保留(赫鲁恩两阵营共用，由它控制)。

## 安装
1. 关闭 worldserver。
2. world 库执行 `01_服务端_SQL/world_ally1e.sql`。开头读回：1、2、5，部落货物数大于 0。
   末尾读回：quests 4、npcs 6、cocoons 5、茧任务 55639、vendor_items 大于 0、starters 4、enders 4、poi 8。
3. 把 `02_服务端_lua_scripts/Ally1E.lua` 放进 `lua_scripts`(新文件)。
4. 启动 worldserver，控制台应打印 `[Ally1E] ALLY1E V1 loaded`；客户端删除 Cache/WDB。

重跑 ALLY1B 的 SQL 会把部落的茧改回两边可见，之后要接着再跑本包。

## 测试(联盟角色，.gm off；前置 55882 已交)
| 任务 | 做什么 | 位置 |
|---|---|---|
| 55194 补充补给 | 吉安娜接，和军需官对话(出商店)，回吉安娜交，得到一个 8 格背包 | `.go xyz 182 -2290 82 12175` |
| 55965 向西前进 | 营地比约恩接，到深坑边交给比约恩 | `.go xyz 91 -2248 95 12175` |
| 55639 深坑 | 阿拉莉亚接；割开 5 个茧；坑底打赫鲁恩到他认输；和拉莉亚(鹿)说话骑出来；回营地交给吉安娜 | 坑底 `.go xyz 73 -2127 -29 12175` |
| 56344 前往暗槌要塞 | 营地吉安娜接，到要塞外交给另一处吉安娜 | `.go xyz 323 -2180 106 12175` |

重点看：茧点一次计一次、起手后消失；赫鲁恩认输后能和拉莉亚对话；骑行贴着螺旋坡上来、落地后计数；对话窗口没有被默认问候盖住。
另请用部落角色看一眼：部落的茧(59949)和克蕾娜照常，没有两个茧叠在一起。

## 和零售不同的地方
- 补给任务：对话即完成，不要求真的买和卖；货物沿用部落供给官的；背包用原版"棕色皮挎包"。
- 深坑按部落版的简化做法(茧点击即救出、无过场、骑行是飞行路线)；零售说有 6 人，这里 5 个茧加坑底 1 人。
- 拉莉亚和坐骑暂用原版麋鹿外观；高版本原版鹿模型在单独的可选模型包里。比约恩、阿拉莉亚、军需官是定制外观人形，用原版替代。
- 暗槌要塞这一批只到会合，要塞内任务在下一批。中文文本为 Claude 自译。

## 撤销
执行 `03_撤销/undo_ally1e.sql`，删除 `lua_scripts/Ally1E.lua`，重启。
''')
wr('memory.md', '''# memory - ALLY1E V1 (2026-11-25, Claude, 候选未测)
- 用户："你继续下一阶段的任务吧 我一会回来测试"。
- 55194(军需官 156800) / 55965 / 55639(茧 9350797、拉莉亚 156929、坐骑 9167012) / 56344(要塞外吉安娜 156941，外观 710006)。
- Ally1E.lua 由实装 Pit1A.lua 生成(去掉赫鲁恩段，对话不 return false)；Pit1A.lua 仍需加载。
''')
wr('tutor.md', '''# tutor - 两阵营共用头目、各自剧情物体 (ALLY1E V1, 未实测)
头目脚本只能由一个文件注册；另一阵营的脚本通过头目可见状态(认输后变友好)判断，不要读对方脚本的内部变量。
点击物体按阵营复制模板改任务编号、分相位刷新；载具/坐骑生物也各复制一份，方便单独换外观。
''')
lines_ = []
for dp, dn, fn in os.walk(P):
    for f in sorted(fn):
        pp = os.path.join(dp, f)
        lines_.append('%s  %s' % (hashlib.sha256(open(pp, 'rb').read()).hexdigest(), os.path.relpath(pp, P).replace(B, '/')))
wr('SHA256SUMS.txt', '\n'.join(lines_) + '\n')
from lupa import LuaRuntime
print('lua compile:', LuaRuntime(unpack_returned_tuples=True).eval('function(s) local f, e = load(s); return f ~= nil, e end')(lua))
log = os.path.join(WS, '协作说明_并行开发.md')
t = open(log, 'rb').read()
assert 'ALLY1E V1' not in t.decode('utf-8', 'replace')
e = b'\r\n' if b'\r\n' in t else b'\n'
row = '| 2026-11-25 | Claude | ALLY1E V1(联盟任务55194/55965/55639/56344) | 候选(实机未测) | 服务端SQL(6模板+坐骑9167012、茧9350797、4任务+POI、部落茧改相位1)+Ally1E.lua | 基线：PIT1D V1 实装、ALLY1D、MODEL1A | 包 000Ascendupdate20261125/%s | 无共享客户端文件 |' % NAME
open(log, 'ab').write((b'' if t.endswith(b'\n') else e) + row.encode('utf-8') + e)
led = os.path.join(WS, '台账_流放者之岛联盟任务链.md')
t = open(led, encoding='utf-8', newline='').read()
for qid in QUESTS:
    i = t.index('| %d |' % qid)
    j = t.index('\n', i)
    line = t[i:j]
    assert '未做' in line, line
    t = t[:i] + line.replace('未做', 'ALLY1E V1 候选') + t[j:]
open(led, 'w', encoding='utf-8', newline='').write(t)
print('poi', nrow, npt, 'files', len(lines_))
