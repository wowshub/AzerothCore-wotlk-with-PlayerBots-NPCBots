# -*- coding: utf-8 -*-
"""ALLY1F V1 (55981 55988 55989 55990) and ALLY1G V1 (55992 55991): the Alliance end of the Exile's Reach chain,
cloned from the final Horde state (DARK1A/1B, DARK2A-DARK3F)."""
import os, hashlib, struct
B = chr(92)
WS = r'D:\000rebornWOW\000RebornWOWHighForkPRO'
DAY25 = os.path.join(WS, '000Ascendupdate', '000Ascendupdate20261125')
DAY = os.path.join(WS, '000Ascendupdate', '000Ascendupdate20261126')
NF = 'claudefix_20261126_阶段ALLY1F_V1_联盟暗槌外圈4任务55981到55990_食人魔伪装_Claude'
NG = 'claudefix_20261126_阶段ALLY1G_V1_联盟暗槌副本与终章55992和55991_回暴风城_Claude'
PF, PG = os.path.join(DAY, NF), os.path.join(DAY, NG)
assert not os.path.exists(PF) and not os.path.exists(PG)
SRVLUA = WS + r'\beascendserver\wowshub_playerbot_npcbot_newrace20261122Ascend\lua_scripts'
ADDON = r'C:\000ref\WarcraftXL试装_client\Interface\AddOns\RebornQuestPins\RebornQuestPins.lua'
sha = lambda b: hashlib.sha256(b).hexdigest()
q = lambda s: "'" + s.replace("'", "''") + "'"


def pack(pattern):
    import glob
    r = glob.glob(os.path.join(DAY25, pattern))
    assert len(r) == 1, (pattern, r)
    return r[0]


def read(p):
    return open(p, encoding='utf-8-sig').read().replace('\r\n', '\n')


def sub(t, old, new, count=1):
    assert t.count(old) == count, (old, t.count(old), count)
    return t.replace(old, new)


def box(cx, cy):
    return [(cx - 9, cy - 9), (cx + 9, cy - 9), (cx + 9, cy + 9), (cx - 9, cy + 9)]


# ------------------------------------------------------------------ shared SQL helpers
def tpl_sql(e, display, flag, name, subname=None, level=1, uclass=1, ctype=7, scale=1):
    return ['INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `HealthModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `ScriptName`) VALUES '
            "(%d, %s, %s, %d, %d, 35, %d, 1, 1.14286, 0, %d, 0, %d, '', 3, 1, 1, 0, '');" % (e, q(name), q(subname) if subname else 'NULL', level, level, flag, uclass, ctype),
            'INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (%d, 0, %d, %s, 1, 0);' % (e, display, scale)]


def spawn_sql(n, entry, mapid, phase, x, y, z, o, comment):
    return ('INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES '
            "(@g + %d, %d, %d, 1, %d, 0, %s, %s, %s, %s, 120, 0, 0, %s);" % (n, entry, mapid, phase, x, y, z, o, q(comment)))


QT = (('quest_template', 'ID'), ('quest_template_addon', 'ID'), ('quest_offer_reward', 'ID'), ('quest_request_items', 'ID'),
      ('creature_queststarter', 'quest'), ('creature_questender', 'quest'), ('quest_poi_points', 'QuestID'), ('quest_poi', 'QuestID'))


def quest_sql(quests, objectives, poi):
    s = []
    for qid, diff, prev, nxt, title, log, desc, done, offer, req, givers, enders in quests:
        s.append('INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `RewardXPDifficulty`, `Flags`, `LogTitle`, `LogDescription`, `QuestDescription`, `QuestCompletionLog`, `AreaDescription`) VALUES '
                 "(%d, 2, 1, 1, %d, 0, %s, %s, %s, %s, '');" % (qid, diff, q(title), q(log), q(desc), q(done)))
        for k, (o, n, text) in enumerate(objectives.get(qid, []), 1):
            s.append('UPDATE `quest_template` SET `RequiredNpcOrGo%d` = %d, `RequiredNpcOrGoCount%d` = %d, `ObjectiveText%d` = %s WHERE `ID` = %d;' % (k, o, k, n, k, q(text), qid))
        s.append('INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`, `NextQuestID`) VALUES (%d, %d, %d);' % (qid, prev, nxt))
        s.append('INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `EmoteDelay1`, `EmoteDelay2`, `RewardText`, `VerifiedBuild`) VALUES (%d, 1, 0, 0, 0, %s, 0);' % (qid, q(offer)))
        s.append('INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES (%d, 0, 0, %s, 0);' % (qid, q(req)))
        for e in givers:
            s.append('INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (%d, %d);' % (e, qid))
        for e in enders:
            s.append('INSERT INTO `creature_questender` (`id`, `quest`) VALUES (%d, %d);' % (e, qid))
    nrow = 0
    for qid, parts in poi.items():
        for idx, (obj, mapid, area, pts) in enumerate(parts):
            s.append('INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`) VALUES (%d, %d, %d, %d, %d, 0, 0, 1, 0);' % (qid, idx, obj, mapid, area))
            nrow += 1
            for j, (x, y) in enumerate(pts):
                s.append('INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (%d, %d, %d, %d, %d, 0);' % (qid, idx, j, x, y))
    return s, nrow


def isle(obj, pts):
    return (obj, 12175, 20414, pts)


# ================================================================== ALLY1F
MEREDY, JAINA_IN, WRATHION, KELRA = 156943, 156961, 156942, 156965
JAINA_OUT = 156941
CHEF, GORGROTH, ENTRANCE = 154103, 153580, 9100210
CAT_H, CAT_A, RUNE_H, RUNE_A = 9326651, 9326652, 9339865, 9339866
F_QUESTS = (55981, 55988, 55989, 55990)
FQL = ', '.join(map(str, F_QUESTS))
F_NPC = (MEREDY, JAINA_IN, WRATHION, KELRA)
FNL = ', '.join(map(str, F_NPC))
SHARED_F = '153239, 154103, 153580, 153581, 153582, 153583'
HORDE_F = '167596, 167633, 167598, 167632, 167631, 167183'

FQ = [
    (55981, 5, 56344, 55988, 'Right Beneath Their Eyes / 就在他们眼皮底下',
     'Have Meredy transform you into an ogre, then scout the nearby ogre citadel. / 请梅瑞迪把你变成食人魔，再去侦察附近的食人魔要塞。',
     "We need to get inside Darkmaul Citadel, rescue the captain of the expedition, and stop the ogre behind all of this.$B$BMeredy is going to cast an illusion to make you look like an ogre, and you're going to take us all in as \"prisoners.\"$B$BI'll be hiding my efforts to suppress the shadow magic in the meantime.$B$BSpeak with Meredy when you're ready for her to cast the spell.$B$B我们得进入暗槌要塞，救出远征队长，阻止幕后的那个食人魔。$B$B梅瑞迪会施一个幻术让你看起来像食人魔，然后你把我们当作“俘虏”带进去。$B$B这期间我会暗中压制那股暗影魔法。$B$B准备好了就和梅瑞迪说话。",
     'Report to Lady Jaina Proudmoore inside the citadel. / 到要塞里向吉安娜复命。',
     "We're close to stopping all of this. We just need to push a little further.$B$B我们离阻止这一切很近了，只要再往前推进一点。",
     'Have you scouted the citadel yet?$B$B你侦察过要塞了吗？', [JAINA_OUT], [JAINA_IN]),
    (55988, 5, 55981, 55989, 'Like Ogres to the Slaughter / 如同食人魔去屠宰', 'Slay 8 ogres within Darkmaul Citadel. / 在暗槌要塞内击杀8个食人魔。',
     "This is bad, $n. Captain Kelra is bound by magic, the ogres are preparing to attack our friends, and the ritual is almost complete!$B$BWe're behind enemy lines, so we'll be able to get the jump on them and draw their focus away from the camp.$B$BTake down any ogres that you can.$B$B情况不妙，$n。凯尔拉队长被魔法束缚着，食人魔正准备进攻我们的朋友，仪式也快完成了！$B$B我们在敌后，可以打他们个措手不及，把他们的注意力从营地引开。$B$B能放倒多少食人魔就放倒多少。",
     'Report back to Wrathion. / 向瑞斯拉克复命。', 'This should buy us enough time to stop the ritual!$B$B这应该能为阻止仪式争取到足够的时间！',
     'Keep fighting.$B$B继续战斗。', [WRATHION], [WRATHION]),
    (55989, 5, 55988, 55990, 'Catapult Destruction / 摧毁投石机', 'Blow up 4 catapults within Darkmaul Citadel. / 炸毁暗槌要塞内的4架投石机。',
     "Did you notice the catapults on our way up? It appears the ogres plan to attack our allies below.$B$BLindie anticipated something like this and provided several bombs to handle siege weapons.$B$BJust don't shake them too hard.$B$B上来的路上你注意到那些投石机了吗？食人魔似乎打算进攻下面的盟友。$B$B琳迪早料到了，给了几颗对付攻城器械的炸弹。$B$B只是别晃得太用力。",
     'Report back to Wrathion. / 向瑞斯拉克复命。', "Great work! Lindie will be glad to hear that those bombs worked perfectly.$B$B干得漂亮！琳迪听说炸弹这么好使一定很高兴。",
     'The catapults must burn.$B$B投石机必须炸掉。', [WRATHION], [WRATHION]),
    (55990, 5, 55989, 55992, 'Controlling their Stones / 夺取他们的石头',
     'Defeat Jugnug, Wug and Grunk to recover the ward stones, then use the runes to free Captain Kelra. / 击败朱格努格、沃格和格伦克夺回结界石，再用符文石解放凯尔拉队长。',
     "Captain Kelra won't last much longer. We need to acquire the ward stones to break the ritual before it kills her.$B$BI'll continue weakening the main ritual. Get those ward stones from the ogre lieutenants nearby.$B$B凯尔拉队长撑不了多久了。我们得拿到结界石，在仪式害死她之前打破它。$B$B我继续削弱主仪式，你去附近的食人魔副官身上取结界石。",
     'Speak with Captain Kelra. / 和凯尔拉队长说话。',
     'Thank you for saving me, but we have no time to lose. The ogres will not stop until they have raised the dragon!$B$B谢谢你救了我，但没时间耽搁了。食人魔不把那条龙弄起来是不会罢手的！',
     'So, these were the stones used to bind me?$B$B原来就是这些石头束缚了我？', [JAINA_IN], [KELRA]),
]
FO = {
    55981: [(MEREDY, 1, 'Ask Meredy to perform the ogre transformation spell / 请梅瑞迪施展食人魔变身术'),
            (CHEF, 1, 'Find the ogre cooking area / 找到食人魔的厨房区'),
            (GORGROTH, 1, "Greet Gor'groth (talk to him) / 向戈尔格罗斯致意（和他说话）"),
            (ENTRANCE, 1, 'Reach the citadel entrance / 抵达要塞入口')],
    55988: [(153239, 8, 'Ogres slain / 已击杀的食人魔')],
    55989: [(-CAT_A, 4, 'Catapults destroyed / 已炸毁的投石机')],
    55990: [(153583, 1, "Jugnug's ward stone recovered (defeat Jugnug) / 夺回朱格努格的结界石（击败朱格努格）"),
            (153582, 1, "Wug's ward stone recovered (defeat Wug) / 夺回沃格的结界石（击败沃格）"),
            (153581, 1, "Grunk's ward stone recovered (defeat Grunk) / 夺回格伦克的结界石（击败格伦克）"),
            (-RUNE_A, 3, 'Disable the runes holding Captain Kelra / 解除囚禁凯尔拉队长的符文')],
}
CHEF_POLY = [(589, -2091), (610, -2083), (619, -2061), (610, -2040), (589, -2031), (568, -2040), (559, -2061), (568, -2083)]
OGRE_POLY = [(603, -2121), (739, -2091), (736, -2076), (732, -2071), (691, -2032), (582, -1975), (481, -1975), (431, -2025), (452, -2114)]
FPOI = {
    55981: [isle(-1, box(699, -1873)), isle(0, box(322, -2182)), isle(1, CHEF_POLY), isle(2, box(592, -2055)), isle(3, box(695, -1897))],
    55988: [isle(-1, box(695, -1875)), isle(0, OGRE_POLY)],
    55989: [isle(-1, box(695, -1875)), isle(0, [(609, -2118), (462, -1997), (488, -2052), (534, -2086)])],
    55990: [isle(-1, box(699, -1875)), isle(0, box(661, -2128)), isle(1, box(591, -2003)), isle(2, box(508, -1964)), isle(3, [(712, -1873), (710, -1861), (701, -1869)])],
}

dk1 = read(os.path.join(pack('claudefix_20261125_阶段DARK1A_V1_*'), '01_服务端_SQL', 'world_dark1a.sql'))


def positions(entry):
    """the object spawn positions of the verified Horde SQL"""
    r = []
    for line in dk1.split('\n'):
        if line.startswith('(@o + ') and (', %d, 12175, ' % entry) in line:
            f = [x.strip() for x in line.split('(', 1)[1].rsplit(')', 1)[0].split(',')]
            r.append((f[5], f[6], f[7], f[8]))
    return r


cats, runes = positions(CAT_H), positions(RUNE_H)
assert len(cats) == 4 and len(runes) == 3, (cats, runes)

s = ['-- ALLY1F V1 (2026-11-26, Claude): Alliance 55981 -> 55988 -> 55989 -> 55990 (Darkmaul Citadel outer ring).',
     '-- Needs the Horde DARK1A + DARK3F SQL, ALLY1B and ALLY1E. Safe to run twice. Keep worldserver stopped.',
     'SET NAMES utf8mb4;',
     'SET @spawn_limit := 16777215;',
     "DELETE FROM `creature` WHERE `map` = 12175 AND `Comment` LIKE 'ALLY1F %';",
     "DELETE FROM `gameobject` WHERE `map` = 12175 AND `Comment` LIKE 'ALLY1F %';",
     'SELECT (SELECT COUNT(*) FROM `gameobject_template` WHERE `entry` IN (%d, %d)) AS horde_objects_2,' % (CAT_H, RUNE_H),
     '       (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (%s, %d)) AS shared_npcs_7,' % (SHARED_F, ENTRANCE),
     '       (SELECT COUNT(*) FROM `creature_template` WHERE `entry` = %d) AS jaina_outside_1,' % JAINA_OUT,
     '       (SELECT COUNT(*) FROM `creature_model_info` WHERE `DisplayID` IN (30194, 3270, 710006, 710007)) AS model_info_4;',
     'DELETE FROM `creature_template` WHERE `entry` IN (%s);' % FNL,
     'DELETE FROM `creature_template_model` WHERE `CreatureID` IN (%s);' % FNL,
     'DELETE FROM `gameobject_template` WHERE `entry` IN (%d, %d);' % (CAT_A, RUNE_A)]
for tab, col in QT:
    s.append('DELETE FROM `%s` WHERE `%s` IN (%s);' % (tab, col, FQL))
s += ['SELECT COALESCE(MAX(`guid`), 0) INTO @g FROM `creature` WHERE `guid` < @spawn_limit;',
      'SELECT COALESCE(MAX(`guid`), 0) INTO @o FROM `gameobject` WHERE `guid` < @spawn_limit;',
      "SELECT IF(@g + 100 + 10000 < @spawn_limit AND @o + 100 + 10000 < @spawn_limit, 'guid base OK', 'ABORT: no guid room, do not continue') AS guid_check;"]
s += tpl_sql(MEREDY, 30194, 1, 'Meredy Huntswell 梅瑞迪·亨茨威尔')
s += tpl_sql(JAINA_IN, 710006, 2, 'Lady Jaina Proudmoore 吉安娜·普罗德摩尔')
s += tpl_sql(WRATHION, 710007, 2, 'Wrathion 瑞斯拉克')
s += tpl_sql(KELRA, 3270, 2, 'Captain Kelra 凯尔拉队长')
for src, dst, quest in ((CAT_H, CAT_A, 55989), (RUNE_H, RUNE_A, 55990)):
    s += ['DROP TEMPORARY TABLE IF EXISTS tmp_ally1f;',
          'CREATE TEMPORARY TABLE tmp_ally1f AS SELECT * FROM `gameobject_template` WHERE `entry` = %d;' % src,
          'UPDATE tmp_ally1f SET `entry` = %d, `Data1` = %d;' % (dst, quest),
          'INSERT INTO `gameobject_template` SELECT * FROM tmp_ally1f;',
          'DROP TEMPORARY TABLE tmp_ally1f;']
s += ['-- phases: Horde friendly NPCs and Horde click objects 1, Alliance 2, monsters shared 3',
      'UPDATE `creature` SET `phaseMask` = 3 WHERE `map` = 12175 AND `id1` IN (%s);' % SHARED_F,
      'UPDATE `creature` SET `phaseMask` = 1 WHERE `map` = 12175 AND `id1` IN (%s);' % HORDE_F,
      'UPDATE `gameobject` SET `phaseMask` = 1 WHERE `map` = 12175 AND `id` IN (%d, %d);' % (CAT_H, RUNE_H)]
FSP = [(MEREDY, '322.175', '-2181.68', '105.866', '1.54521', 'Meredy outside Darkmaul'),
       (JAINA_IN, '699.477', '-1872.71', '186.882', '0.76879', 'Jaina inside'),
       (WRATHION, '695.299', '-1874.61', '186.508', '0.570084', 'Wrathion inside'),
       (KELRA, '699.068', '-1874.73', '186.882', '0.570084', 'Captain Kelra')]
for i, (e, x, y, z, o, label) in enumerate(FSP, 1):
    s.append(spawn_sql(i, e, 12175, 2, x, y, z, o, 'ALLY1F ' + label))
n = 0
for entry, plist, label in ((CAT_A, cats, 'catapult'), (RUNE_A, runes, 'rune')):
    for x, y, z, o in plist:
        n += 1
        s.append('INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES '
                 "(@o + %d, %d, 12175, 1, 2, %s, %s, %s, %s, 0, 0, 0, 1, 60, 255, 1, 'ALLY1F %s');" % (n, entry, x, y, z, o, label))
qs, nrow_f = quest_sql(FQ, FO, FPOI)
s += qs
s += ['SELECT (SELECT COUNT(*) FROM `quest_template` WHERE `ID` IN (%s)) AS quests_4,' % FQL,
      "       (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'ALLY1F %') AS npcs_4,",
      "       (SELECT COUNT(*) FROM `gameobject` WHERE `Comment` LIKE 'ALLY1F %') AS objects_7,",
      '       (SELECT GROUP_CONCAT(`Data1` ORDER BY `entry`) FROM `gameobject_template` WHERE `entry` IN (%d, %d)) AS object_quests_55989_55990,' % (CAT_A, RUNE_A),
      '       (SELECT COUNT(*) FROM `creature_queststarter` WHERE `quest` IN (%s)) AS starters_4,' % FQL,
      '       (SELECT COUNT(*) FROM `creature_questender` WHERE `quest` IN (%s)) AS enders_4,' % FQL,
      "       (SELECT COUNT(*) FROM `creature` WHERE `map` = 12175 AND `id1` IN (%s) AND `phaseMask` <> 3) AS monsters_not_shared_0," % SHARED_F,
      '       (SELECT COUNT(*) FROM `quest_poi` WHERE `QuestID` IN (%s)) AS poi_%d;' % (FQL, nrow_f)]
sql_f = '\n'.join(s) + '\n'

undo_f = ['-- undo ALLY1F V1',
          "DELETE FROM `creature` WHERE `map` = 12175 AND `Comment` LIKE 'ALLY1F %';",
          "DELETE FROM `gameobject` WHERE `map` = 12175 AND `Comment` LIKE 'ALLY1F %';",
          'DELETE FROM `creature_template` WHERE `entry` IN (%s);' % FNL,
          'DELETE FROM `creature_template_model` WHERE `CreatureID` IN (%s);' % FNL,
          'DELETE FROM `gameobject_template` WHERE `entry` IN (%d, %d);' % (CAT_A, RUNE_A),
          '-- back to the phases left by ALLY1B',
          'UPDATE `gameobject` SET `phaseMask` = 3 WHERE `map` = 12175 AND `id` IN (%d, %d);' % (CAT_H, RUNE_H),
          'UPDATE `creature` SET `phaseMask` = 1 WHERE `map` = 12175 AND `id1` IN (154103, 153580);']
for tab, col in QT:
    undo_f.append('DELETE FROM `%s` WHERE `%s` IN (%s);' % (tab, col, FQL))

# ------------------------------------------------------------------ Dark1A.lua for both factions (built on DARK1B V1)
base1 = read(os.path.join(pack('claudefix_20261125_阶段DARK1B_V1_*'), '02_服务端_lua_scripts', 'Dark1A.lua'))
live1 = read(os.path.join(SRVLUA, 'Dark1A.lua'))
a1 = read(os.path.join(pack('claudefix_20261125_阶段DARK1A_V1_*'), '02_服务端_lua_scripts', 'Dark1A.lua'))
assert live1 in (a1, base1), 'live Dark1A.lua differs from the packaged versions'
live1_name = 'DARK1B V1' if live1 == base1 else 'DARK1A V1'
head_end = base1.index('local Q_DISGUISE = 59978')
lua = '''-- Dark1A.lua (ALLY1F V1 = Dark1A V3, 2026-11-26, Claude) - candidate, NOT user-tested. Replaces the Dark1A.lua file.
-- Darkmaul Citadel outer ring for BOTH factions (Exile's Reach):
--   Horde 59978/59980/59981, Alliance 55981/55989/55990.
--   * ogre disguise (from DARK1B): talking to Herbert (Horde) or Meredy (Alliance) turns the player into an ogre of the ogres' faction until the
--     disguise quest is turned in or abandoned, or the player leaves the island.
--   * Gor'groth's gossip gives the greeting credit; the cooking area and the citadel entrance are area credits checked every 2 s.
--   * catapults and runestones of both factions: the core gives the credit on use; this script despawns the object and refuses a second click.
''' + base1[head_end:]
lua = sub(lua, 'local Q_DISGUISE = 59978\nlocal HERBERT, GORGROTH, CHEF = 167598, 153580, 154103\n',
          'local DISGUISE_QUESTS = {59978, 55981}          -- Horde, Alliance\n'
          'local HERBERT, GORGROTH, CHEF = 167598, 153580, 154103\n'
          'local MEREDY = %d\n' % MEREDY)
lua = sub(lua, 'local CATAPULT, RUNE = 9326651, 9339865\n', 'local CATAPULT, RUNE = %d, %d\nlocal CATAPULT_A, RUNE_A = %d, %d\nlocal ISLAND = 12175\n' % (CAT_H, RUNE_H, CAT_A, RUNE_A))
lua = sub(lua, 'local function msg(p, s) p:SendBroadcastMessage(s) end\n',
          'local function msg(p, s) p:SendBroadcastMessage(s) end\n\n'
          'local function wantsDisguise(p)\n'
          '    for _, id in ipairs(DISGUISE_QUESTS) do\n'
          '        if p:HasQuest(id) then return true end\n'
          '    end\n'
          '    return false\n'
          'end\n')
g0 = lua.index('-- ---------------------------------------------------------------- Herbert / Gor')
g1 = lua.index('-- ---------------------------------------------------------------- area credits')
gossip = '''-- ---------------------------------------------------------------- Herbert / Meredy / Gor'groth gossip
-- the handlers return nothing: "return false" lets the core open its default window on top
local function disguiser(npc, quest)
    RegisterCreatureGossipEvent(npc, 1, function(event, player, creature)
        local ok, err = pcall(function()
            player:GossipComplete()
            if player:HasQuest(quest) then
                player:KilledMonsterCredit(npc)
                if player:IsMounted() then player:Dismount() end
                disguiseOn(player)
                msg(player, "|cff00ff00You are disguised as an ogre. Ogres will not attack you. / 你伪装成了食人魔，食人魔不会攻击你。|r")
                creature:SendUnitSay("Hold still... there! You look like an ogre now. Mostly. 别动……好了！你现在看起来像食人魔了。差不多吧。", 0)
            else
                creature:SendUnitSay("Ogres are not as clever as they look. 食人魔没有看起来那么聪明。", 0)
            end
        end)
        if not ok then print("[Dark1A] disguise gossip ERROR: " .. tostring(err)) end
    end)
end
disguiser(HERBERT, 59978)
disguiser(MEREDY, 55981)

RegisterCreatureGossipEvent(GORGROTH, 1, function(event, player, creature)
    local ok, err = pcall(function()
        player:GossipComplete()
        if wantsDisguise(player) then
            player:KilledMonsterCredit(GORGROTH)
            creature:SendUnitSay("Hrm. Ogre. Good. Go away. 嗯。食人魔。好。走开。", 0)
        end
    end)
    if not ok then print("[Dark1A] Gor'groth gossip ERROR: " .. tostring(err)) end
end)

'''
lua = lua[:g0] + gossip + lua[g1:]
lua = sub(lua, '                if not p:HasQuest(Q_DISGUISE) then\n                    disguiseOff(p)                                   -- turned in or abandoned\n',
          '                if not wantsDisguise(p) or p:GetMapId() ~= ISLAND then\n                    disguiseOff(p)                                   -- turned in, abandoned or left the island\n')
lua = sub(lua, 'if p:GetMapId() == 12175 and p:HasQuest(Q_DISGUISE) and p:IsAlive() then', 'if p:GetMapId() == ISLAND and wantsDisguise(p) and p:IsAlive() then')
lua = sub(lua, 'useOnce(RUNE, "|cff00ff00The rune flickers out. / 符文熄灭了。|r")\n',
          'useOnce(RUNE, "|cff00ff00The rune flickers out. / 符文熄灭了。|r")\n'
          'useOnce(CATAPULT_A, "|cff00ff00BOOM! The catapult is wrecked. / 轰！投石机被炸毁了。|r")\n'
          'useOnce(RUNE_A, "|cff00ff00The rune flickers out. / 符文熄灭了。|r")\n')
p = lua.index('print("[Dark1A] DARK1B V1 loaded')
lua = lua[:p] + 'print("[Dark1A] ALLY1F V1 loaded: both factions, disguise quests 59978/55981")\n'
assert 'return false\nend)' not in lua and 'Q_DISGUISE' not in lua
lua_f = lua

# ================================================================== ALLY1G
KALEC, GARRICK = 161350, 154169
TUNK, GOR_BOSS, KALEC_BOSS, CREDIT = 157300, 156814, 156501, 244389
G_QUESTS = (55992, 55991)
GQL = ', '.join(map(str, G_QUESTS))
GNL = '%d, %d' % (KALEC, GARRICK)
SHARED_G = '157300, 156814, 156501, 9159801, 9159802, 9159803, 6491'
SW = (-8833.38, 628.63, 94.01, 1.065)                      # game_tele 'Stormwind'
GAR = ('-8832.9', '633.8', '94.4', '4.62')                 # a few yards in front of the arrival point
GQ = [
    (55992, 8, 55990, 55991, 'Dungeon: Darkmaul Citadel / 地下城：暗槌要塞',
     "Defeat Tunk and Gor'groth, stop the ritual, then speak with Kalecgos. / 击败图克和戈尔格罗斯，阻止仪式，然后和卡雷苟斯说话。",
     "You've slowed Gor'groth's efforts to control Kalecgos atop the citadel, but the ritual itself needs to be thwarted.$B$BYou must storm the citadel and stop him from completing the ritual. His dark magic is an affront to the Light.$B$BWe will need all the help we can get. Gor'groth's most elite lieutenants await within the citadel.$B$B(Accepting this quest takes you to the entrance of the citadel interior. Defeat Tunk and Gor'groth, fighting your way inward. Then Kalecgos, bound by the ritual, appears on the top platform. When he falls you are brought back here. 接任务后你会被传送到要塞内部入口。一路向里击败图克和戈尔格罗斯，之后被仪式控制的卡雷苟斯会出现在最高处的平台，击败他后你会被送回这里。)$B$B你拖慢了戈尔格罗斯在要塞顶上控制卡雷苟斯的进度，但仪式本身还得破除。$B$B你必须强攻要塞，不让他完成仪式。他的黑暗魔法是对圣光的亵渎。$B$B我们需要一切能得到的帮助，戈尔格罗斯最精锐的副手就在要塞里等着。",
     'Return to Lady Jaina Proudmoore. / 回去向吉安娜复命。',
     "It seems things are finally looking up for us. I think it's time we returned to Stormwind.$B$B事情总算有了转机。我想是时候回暴风城了。",
     'Has the ritual been stopped?$B$B仪式阻止了吗？', [KELRA], [JAINA_IN]),
    (55991, 8, 55992, 0, 'An End to Beginnings / 终结即开始',
     'Speak with Kalecgos to travel to Stormwind, then report to Captain Garrick. / 和卡雷苟斯说话前往暴风城，再向加里克队长复命。',
     "You've done fine work within Exile's Reach, $n.$B$BI must go back to Stormwind. I need to find out how the ogres found such powerful shadow magic.$B$BSpeak with Kalecgos. He will take you there. Report to Captain Garrick when you arrive.$B$B你在流放者之岛干得很出色，$n。$B$B我得回暴风城，查清食人魔是从哪里弄到这么强大的暗影魔法的。$B$B去和卡雷苟斯说话，他会带你过去。到了以后向加里克队长报到。",
     'Report to Captain Garrick in Stormwind. / 到暴风城向加里克队长复命。',
     "Good to see you back in Stormwind, $n. We have much to report to the king, and your journey has only begun.$B$B欢迎回到暴风城，$n。我们有很多事要向国王禀报，而你的旅程才刚刚开始。",
     'Welcome to Stormwind.$B$B欢迎来到暴风城。', [JAINA_IN], [GARRICK]),
]
GO_ = {
    55992: [(TUNK, 1, 'Tunk slain / 图克已被击杀'), (GOR_BOSS, 1, "Gor'groth slain / 戈尔格罗斯已被击杀"),
            (KALEC_BOSS, 1, "Gor'groth's final ritual stopped (defeat Kalecgos) / 阻止戈尔格罗斯的最后仪式（击败卡雷苟斯）"),
            (KALEC, 1, 'Speak with Kalecgos to leave Darkmaul Citadel / 和卡雷苟斯说话离开暗槌要塞')],
    55991: [(CREDIT, 1, 'Speak to Kalecgos to travel to Stormwind / 和卡雷苟斯说话前往暴风城')],
}
GPOI = {
    55992: [isle(-1, box(699, -1873)), isle(0, box(753, -1442)), isle(1, box(852, -1625)), isle(2, box(753, -1440)), isle(3, box(714, -1874))],
    55991: [(-1, 0, 301, box(-8833, 634)), isle(0, box(714, -1874))],
}
s = ['-- ALLY1G V1 (2026-11-26, Claude): Alliance 55992 (dungeon) and 55991 (finale, turn-in in Stormwind).',
     '-- Needs the Horde DARK2A/3A/3E/3F SQL and ALLY1F V1. Safe to run twice. Keep worldserver stopped.',
     'SET NAMES utf8mb4;',
     'SET @spawn_limit := 16777215;',
     "DELETE FROM `creature` WHERE `Comment` LIKE 'ALLY1G %';",
     'SELECT (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (157300, 156814, 156501, %d)) AS bosses_and_credit_4,' % CREDIT,
     '       (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (%d, %d)) AS ally1f_npcs_2,' % (JAINA_IN, KELRA),
     '       (SELECT COUNT(*) FROM `creature_model_info` WHERE `DisplayID` IN (26752, 3450)) AS model_info_2;',
     'DELETE FROM `creature_template` WHERE `entry` IN (%s);' % GNL,
     'DELETE FROM `creature_template_model` WHERE `CreatureID` IN (%s);' % GNL]
for tab, col in QT:
    s.append('DELETE FROM `%s` WHERE `%s` IN (%s);' % (tab, col, GQL))
s += ['SELECT COALESCE(MAX(`guid`), 0) INTO @g FROM `creature` WHERE `guid` < @spawn_limit;',
      "SELECT IF(@g + 100 + 10000 < @spawn_limit, 'guid base OK', 'ABORT: no guid room, do not continue') AS guid_check;"]
s += tpl_sql(KALEC, 26752, 1, 'Kalecgos 卡雷苟斯', uclass=8, ctype=2, scale=0.3)
s += tpl_sql(GARRICK, 3450, 2, 'Captain Garrick 加里克队长', level=80)
s += ['UPDATE `creature` SET `phaseMask` = 3 WHERE `map` = 12175 AND `id1` IN (%s);' % SHARED_G,
      'UPDATE `gameobject` SET `phaseMask` = 3 WHERE `map` = 12175 AND `id` IN (9159851, 9159852, 9159853);',
      'UPDATE `creature` SET `phaseMask` = 1 WHERE `map` = 12175 AND `id1` = 167663;',
      spawn_sql(1, KALEC, 12175, 2, '714.359', '-1874.25', '186.882', '4.28795', 'ALLY1G Kalecgos'),
      spawn_sql(2, GARRICK, 0, 1, *(GAR + ('ALLY1G Captain Garrick in Stormwind',)))]
qs, nrow_g = quest_sql(GQ, GO_, GPOI)
s += qs
s += ['SELECT (SELECT COUNT(*) FROM `quest_template` WHERE `ID` IN (%s)) AS quests_2,' % GQL,
      "       (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'ALLY1G %') AS npcs_2,",
      '       (SELECT COUNT(*) FROM `creature_queststarter` WHERE `quest` IN (%s)) AS starters_2,' % GQL,
      '       (SELECT COUNT(*) FROM `creature_questender` WHERE `quest` IN (%s)) AS enders_2,' % GQL,
      '       (SELECT COUNT(*) FROM `creature` WHERE `map` = 12175 AND `id1` IN (%s) AND `phaseMask` <> 3) AS dungeon_not_shared_0,' % SHARED_G,
      '       (SELECT COUNT(*) FROM `quest_poi` WHERE `QuestID` IN (%s)) AS poi_%d;' % (GQL, nrow_g)]
sql_g = '\n'.join(s) + '\n'
undo_g = ['-- undo ALLY1G V1', "DELETE FROM `creature` WHERE `Comment` LIKE 'ALLY1G %';",
          'DELETE FROM `creature_template` WHERE `entry` IN (%s);' % GNL,
          'DELETE FROM `creature_template_model` WHERE `CreatureID` IN (%s);' % GNL]
for tab, col in QT:
    undo_g.append('DELETE FROM `%s` WHERE `%s` IN (%s);' % (tab, col, GQL))

# ------------------------------------------------------------------ Dark2A.lua for both factions (built on the live DARK3F)
base2 = read(os.path.join(pack('claudefix_20261125_阶段DARK3F_V1_*'), '02_服务端_lua_scripts', 'Dark2A.lua'))
live2 = read(os.path.join(SRVLUA, 'Dark2A.lua'))
assert live2 == base2, 'live Dark2A.lua differs from DARK3F V1'
lua = base2
lua = '-- Dark2A.lua (ALLY1G V1, 2026-11-26, Claude) - candidate, NOT user-tested. Both factions: Horde 59984/59985, Alliance 55992/55991.\n' + lua
lua = sub(lua, 'local Q_DUNGEON, Q_END = 59984, 59985\nlocal TUNK, GORGROTH, KALEC_BOSS, KALEC_FRIEND = 157300, 156814, 156501, 167663\n',
          'local TUNK, GORGROTH, KALEC_BOSS = 157300, 156814, 156501\n')
lua = sub(lua, 'local ORG = {1, 1631.5, -4443.5, 15.8, 1.2}                               -- Orgrimmar, Grommash Hold, next to Wrathion 9167675\n',
          'local ORG = {1, 1631.5, -4443.5, 15.8, 1.2}                               -- Orgrimmar, Grommash Hold, next to Wrathion 9167675\n'
          'local STORMWIND = {0, %s, %s, %s, %s}                    -- Stormwind, next to Captain Garrick 154169\n' % SW)
a = lua.index('-- ---------------------------------------------------------------- accept: go to the entrance')
lua = lua[:a] + '''-- one row per faction: dungeon quest, finale quest, friendly Kalecgos, destination of the finale
local SIDES = {
    {dungeon = 59984, finale = 59985, friend = 167663, dest = ORG, city = "Orgrimmar", cityCn = "奥格瑞玛", leader = "Thrall", leaderCn = "萨尔"},
    {dungeon = 55992, finale = 55991, friend = %d, dest = STORMWIND, city = "Stormwind", cityCn = "暴风城", leader = "Jaina", leaderCn = "吉安娜"},
}

''' % KALEC + lua[a:]
lua = sub(lua, '        if quest:GetId() ~= Q_DUNGEON then return end\n',
          '        local id = quest:GetId()\n'
          '        if id ~= SIDES[1].dungeon and id ~= SIDES[2].dungeon then return end\n')
lua = sub(lua, 'You are taken back to Mulgrin; speak with Kalecgos there. / 卡雷苟斯自由了。你被送回穆格林那里，去和那里的卡雷苟斯说话。',
          'You are taken back to the upper platform; speak with Kalecgos there. / 卡雷苟斯自由了。你被送回高处的平台，去和那里的卡雷苟斯说话。')
a = lua.index('-- DARK3F: the handlers return nothing.')
p = lua.index('print("[Dark2A] DARK3F V1 loaded')
lua = lua[:a] + '''-- the handlers return nothing. With "return false" the engine goes on with the core default and its greeting window
-- replaces our menu (no travel option).
local function friendlyKalecgos(side)
    RegisterCreatureGossipEvent(side.friend, 1, function(event, player, creature)           -- GOSSIP_EVENT_ON_HELLO
        local ok, err = pcall(function()
            if player:HasQuest(side.finale) then
                player:GossipClearMenu()
                player:GossipMenuAddItem(GOSSIP_ICON_TAXI, "Take me to " .. side.city .. " now. / 现在就带我去" .. side.cityCn .. "。", 0, OPT_GO, false,
                    "Travel to " .. side.city .. " now? / 现在就前往" .. side.cityCn .. "吗？", 0)
                player:GossipMenuAddItem(GOSSIP_ICON_CHAT, "Not yet. / 先不去。", 0, OPT_STAY)
                player:GossipSendMenu(MENU_TEXT, creature)
                return
            end
            if player:HasQuest(side.dungeon) then
                player:KilledMonsterCredit(side.friend)
                creature:SendUnitSay("Thank you. Report to " .. side.leader .. ". 谢谢你。去向" .. side.leaderCn .. "复命吧。", 0)
            else
                creature:SendUnitSay("Come back when " .. side.leader .. " sends you. 等" .. side.leaderCn .. "派你来的时候再来找我。", 0)
            end
            player:GossipComplete()
        end)
        if not ok then print("[Dark2A] Kalecgos gossip ERROR: " .. tostring(err)); pcall(function() player:GossipComplete() end) end
    end)

    RegisterCreatureGossipEvent(side.friend, 2, function(event, player, creature, sender, intid, code)   -- GOSSIP_EVENT_ON_SELECT
        local ok, err = pcall(function()
            player:GossipComplete()
            if intid == OPT_GO and player:HasQuest(side.finale) then
                player:KilledMonsterCredit(END_CREDIT)
                creature:SendUnitSay("Hold on to something. 抓紧了。", 0)
                local d = side.dest
                player:Teleport(d[1], d[2], d[3], d[4], d[5])
            end
        end)
        if not ok then print("[Dark2A] Kalecgos select ERROR: " .. tostring(err)) end
    end)
end
for _, side in ipairs(SIDES) do friendlyKalecgos(side) end

print("[Dark2A] ALLY1G V1 loaded: both factions, quests 59984/59985 and 55992/55991, bosses " .. TUNK .. "/" .. GORGROTH .. "/" .. KALEC_BOSS)
'''
assert not any(x in lua for x in ('Q_DUNGEON', 'Q_END', 'KALEC_FRIEND'))
lua_g = lua

# ------------------------------------------------------------------ quest pins addon
addon_old = open(ADDON, 'rb').read()
t = addon_old.decode('utf-8')
nl = '\r\n' if '\r\n' in t else '\n'
t = sub(t, '}' + nl + '-- WorldMapArea.dbc bounds',
        '    { quest = 55991, show = "active", map = "ExilesReach", x = 714.4, y = -1874.2, title = "Kalecgos 卡雷苟斯", text = "An End to Beginnings / 终结即开始" },' + nl +
        '    { quest = 55991, show = "complete", map = "Stormwind", x = -8832.9, y = 633.8, title = "Captain Garrick 加里克队长", text = "An End to Beginnings / 终结即开始" },' + nl +
        '}' + nl + '-- WorldMapArea.dbc bounds')
t = sub(t, '    Ogrimmar = { left = -3680.6, right = -5083.21, top = 2273.88, bottom = 1338.46 },' + nl,
        '    Ogrimmar = { left = -3680.6, right = -5083.21, top = 2273.88, bottom = 1338.46 },' + nl +
        '    Stormwind = { left = 1722.92, right = -14.58, top = -7995.83, bottom = -9154.17 },' + nl)
t = sub(t, '-- RebornQuestPins 1.1 (DARK3F V1, 2026-11-25, Claude) - candidate, NOT user-tested.',
        '-- RebornQuestPins 1.2 (ALLY1G V1, 2026-11-26, Claude): Alliance quest 55991 added.' + nl +
        '-- RebornQuestPins 1.1 (DARK3F V1, 2026-11-25, Claude) - candidate, NOT user-tested.')
addon_new = t.encode('utf-8')


# ------------------------------------------------------------------ write
def wr(P, rel, data, nl='\n'):
    f = os.path.join(P, rel.replace('/', B))
    os.makedirs(os.path.dirname(f), exist_ok=True)
    if isinstance(data, bytes):
        open(f, 'wb').write(data)
    else:
        open(f, 'w', encoding='utf-8', newline=nl).write(data)


wr(PF, '01_服务端_SQL/world_ally1f.sql', sql_f, '\r\n')
wr(PF, '02_服务端_lua_scripts/Dark1A.lua', lua_f)
wr(PF, '03_撤销/undo_ally1f.sql', '\n'.join(undo_f) + '\n', '\r\n')
wr(PF, '03_撤销/lua_scripts/Dark1A.lua', live1)
wr(PG, '01_服务端_SQL/world_ally1g.sql', sql_g, '\r\n')
wr(PG, '02_服务端_lua_scripts/Dark2A.lua', lua_g)
wr(PG, '03_覆盖到客户端根目录/Interface/AddOns/RebornQuestPins/RebornQuestPins.lua', addon_new)
wr(PG, '04_撤销/undo_ally1g.sql', '\n'.join(undo_g) + '\n', '\r\n')
wr(PG, '04_撤销/lua_scripts/Dark2A.lua', live2)
wr(PG, '04_撤销/原客户端根目录/Interface/AddOns/RebornQuestPins/RebornQuestPins.lua', addon_old)

wr(PF, 'README_覆盖与测试说明.md', '''# ALLY1F V1：联盟暗槌要塞外圈 4 任务(55981、55988、55989、55990)

状态：候选，实机未测。服务端 SQL 一个、Lua 一个(覆盖)；客户端不用改。
前提：部落 DARK1A 到 DARK3F 的 SQL 已装，联盟 ALLY1B、ALLY1E、MODEL1A/1C 已装。

## 安装
1. 关闭 worldserver。
2. world 库执行 `01_服务端_SQL/world_ally1f.sql`。
   开头读回：horde_objects 2、shared_npcs 7、jaina_outside 1、model_info 4。
   末尾读回：quests 4、npcs 4、objects 7、物体任务 55989,55990、starters 4、enders 4、monsters_not_shared 0、poi %d。
3. 用 `02_服务端_lua_scripts/Dark1A.lua` 覆盖 `lua_scripts` 里的同名文件(实装的是 %s)。
4. 启动 worldserver，控制台应打印 `[Dark1A] ALLY1F V1 loaded`；客户端删除 Cache/WDB。

以后如果重跑 ALLY1B 或部落 DARK1A 的 SQL，要接着再跑本包(它们会改回分相位)。

## 测试(联盟角色，.gm off；前置 56344 已交)
| 任务 | 做什么 | 位置 `.go xyz … 12175` |
|---|---|---|
| 55981 就在他们眼皮底下 | 要塞外吉安娜接；和梅瑞迪说话变成食人魔；走到厨房区；和戈尔格罗斯说话；到要塞入口；向要塞里的吉安娜交 | `323 -2180 106` 起，厨房 `604 -2064 160`，入口 `695 -1897 188` |
| 55988 击杀食人魔 | 瑞斯拉克接，杀 8 个，交回 | `695 -1875 187` |
| 55989 投石机 | 瑞斯拉克接，点 4 架，交回 | `612 -2119 159` 起 |
| 55990 结界石 | 吉安娜接，打三个头目，点 3 块符文石，向凯尔拉队长交 | `663 -2128 162`、`592 -2011 176`、`510 -1965 145` |

变身只改变你自己：队伍里的机器人、NPCBot 和宠物没有伪装，食人魔照样会打它们。

重点看：变身后食人魔不主动攻击；交掉 55981 后恢复原样、食人魔重新敌对；投石机和符文石只看到一套、点一次计一次。

## 对部落的影响(请用部落号顺带看一眼)
新的 Dark1A.lua 两阵营共用。它带上了之前做过但没装过的食人魔变身(DARK1B)：部落 59978 和赫伯特说话现在也会真的变身。部落的投石机、符文石照常。

## 和零售不同的地方
- 零售要对戈尔格罗斯做 /招手、在厨房跳舞；这里是和他说话、走到厨房区(任务目标上限 4 个)。
- 零售的结界石是物品；这里击败头目直接记数(和部落版一致)。
- 梅瑞迪、凯尔拉队长是定制外观人形，用原版外观替代。食人魔暂时仍是原版外观。
- 中文文本为 Claude 自译。

## 撤销
执行 `03_撤销/undo_ally1f.sql`，用 `03_撤销/lua_scripts/Dark1A.lua` 覆盖回去，重启。
''' % (nrow_f, live1_name))
wr(PG, 'README_覆盖与测试说明.md', '''# ALLY1G V1：联盟暗槌要塞副本与终章(55992、55991)

状态：候选，实机未测。服务端 SQL 一个、Lua 一个(覆盖)；客户端覆盖一个插件文件。
前提：部落 DARK2A 到 DARK3F 已装，本批 ALLY1F V1 已装。

## 安装
1. 关闭 worldserver 和客户端。
2. world 库执行 `01_服务端_SQL/world_ally1g.sql`。
   开头读回：bosses_and_credit 4、ally1f_npcs 2、model_info 2。
   末尾读回：quests 2、npcs 2、starters 2、enders 2、dungeon_not_shared 0、poi %d。
3. 用 `02_服务端_lua_scripts/Dark2A.lua` 覆盖 `lua_scripts` 里的同名文件。
4. 把 `03_覆盖到客户端根目录` 覆盖到客户端根目录(插件 RebornQuestPins，加联盟终章的地图标记)。
5. 启动 worldserver，控制台应打印 `[Dark2A] ALLY1G V1 loaded`；客户端删除 Cache/WDB。

## 测试(联盟角色，.gm off；前置 55990 已交)
1. 55992：向凯尔拉队长接任务(`.go xyz 699 -1875 187 12175`)，应被传送到要塞内部入口。击败图克、戈尔格罗斯，最高平台出现卡雷苟斯，击败后被送回高处平台；和卡雷苟斯说话，向吉安娜交。
2. 55991：吉安娜接，和卡雷苟斯说话，选"现在就带我去暴风城"，确认。应到达暴风城，身边是加里克队长，交任务。
3. 大地图和小地图上有卡雷苟斯和加里克队长的标记。
4. 回归：部落号的 59984/59985 照常(卡雷苟斯菜单去奥格瑞玛)。

重点看：暴风城传送落点是否正常、加里克队长是否站在地面上(坐标是按附近原版刷新点估的)。位置不合适就告诉我你想放的坐标。

## 和零售不同的地方
- 零售是独立副本地图和寻求组队；这里沿用部落版的开放世界做法。
- 终章零售去巨龙群岛前改道回暴风城；奖励里的炉石不发(角色已有，重复发会导致交不了任务)。
- 卡雷苟斯、加里克队长和副本怪物暂时用原版外观。

## 撤销
执行 `04_撤销/undo_ally1g.sql`，用 `04_撤销/lua_scripts/Dark2A.lua` 覆盖回去，客户端用 `04_撤销/原客户端根目录` 覆盖回插件，重启。
''' % nrow_g)
wr(PF, 'memory.md', '''# memory - ALLY1F V1 (2026-11-26, Claude, 候选未测)
- 用户："这下对了 继续开始下一轮的任务修复"(吉安娜动作已正常)。
- 55981/55988/55989/55990；NPC 156943/156961/156942/156965；联盟投石机 9326652、符文石 9339866。
- Dark1A.lua 改为两阵营共用并带上 DARK1B 食人魔变身(此前部落未实装)。对话处理函数不 return false。
- 食人魔、厨师、戈尔格罗斯、三头目设相位 3；部落友方和部落物体相位 1。
''')
wr(PG, 'memory.md', '''# memory - ALLY1G V1 (2026-11-26, Claude, 候选未测)
- 55992/55991；友方卡雷苟斯 161350(原版龙外观)、暴风城加里克 154169(外观 3450，坐标 -8832.9 633.8 94.4 为估计值)。
- Dark2A.lua 按阵营表 SIDES 处理接任务传送、卡雷苟斯菜单和终点。RebornQuestPins 1.2。
- 待办：食人魔(模型 7062)、戈尔格罗斯、图克、卡雷苟斯的零售显示 ExtendedDisplayInfoID=0，可导入高版本模型。
''')
wr(PF, 'tutor.md', '''# tutor - 两阵营共用的剧情脚本 (ALLY1F V1, 未实测)
怪物相位 3，两阵营各自的 NPC 和点击物体相位 1/2；点击物体按阵营复制模板只改任务编号。
同一个生物的对话事件放在一个脚本里按任务号分支。
''')
wr(PG, 'tutor.md', '''# tutor - 副本与终章复用 (ALLY1G V1, 未实测)
把任务号、友方 NPC、传送终点放进一张阵营表，用工厂函数注册对话，头目逻辑不复制。
''')
for P in (PF, PG):
    out = []
    for dp, dn, fn in os.walk(P):
        for f in sorted(fn):
            pp = os.path.join(dp, f)
            out.append('%s  %s' % (sha(open(pp, 'rb').read()), os.path.relpath(pp, P).replace(B, '/')))
    wr(P, 'SHA256SUMS.txt', '\n'.join(out) + '\n')
    print(os.path.basename(P), len(out), 'files')
print('poi', nrow_f, nrow_g, '| live Dark1A', live1_name)
