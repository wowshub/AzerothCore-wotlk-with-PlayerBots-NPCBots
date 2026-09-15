#include "Chat.h"
#include "CommandScript.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "DBCStores.h"
#include "Item.h"
#include "Log.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptDefines/PlayerScript.h"
#include "SpellAuras.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"

#include <algorithm>
#include <array>
#include <sstream>

using namespace Acore::ChatCommands;

namespace
{
constexpr char BuildMarker[] = "A31-B0.9B-NATIVE-AURA-FIX-202608160805";
constexpr char TitanGripBuildMarker[] = "A40-B0.9.17.2-TITAN-GRIP-AURA-LIFECYCLE-202608202138";
constexpr char TalentAuraBuildMarker[] = "A40-B0.9.21.6-TALENT-PET-AURA-DIAG-202608221650";
constexpr uint32 FirstRankSpell = 20257;
constexpr uint32 LastRankSpell = 20261;
constexpr uint32 TitanGripSpell = 46917;
constexpr uint32 TitanGripPenaltySpell = 49152;

void LogSpellMetadata(Player* player, uint32 spellId);

// Verified pure-stat chains plus the next composite-Aura candidate. These are
// diagnostics only: gameplay remains owned by Talent.dbc, SpellInfo and
// LearnCustomTalentSpell.
constexpr std::array<uint32, 12> TalentAuraTrackedChains =
{
    34151, // Living Spirit
    19255, // Survivalist
    19168, // Lightning Reflexes
    44397, // Student of the Mind
    11232, // Arcane Mind
    18551, // Mental Strength
    18697, // Demonic Embrace
    16252, // Toughness: stamina and movement-impair duration
    30816, // Precise Actions: melee/ranged hit, 2/4/6 percent
    29590, // Precision: melee/ranged hit, 1/2/3 percent
    23584, // Dual Wield Specialization: offhand damage, 5/10/15/20/25 percent
    23785  // Master Demonologist: active demon selects owner/pet native Aura
};

TalentEntry const* FindTalentByRankSpell(uint32 spellId, uint8* rankIndex = nullptr)
{
    for (TalentEntry const* talent : sTalentStore)
    {
        if (!talent)
            continue;

        for (uint8 rank = 0; rank < MAX_TALENT_RANK; ++rank)
        {
            if (talent->RankID[rank] == spellId)
            {
                if (rankIndex)
                    *rankIndex = rank;
                return talent;
            }
        }
    }
    return nullptr;
}

bool IsTalentAuraTrackedSpell(uint32 spellId)
{
    TalentEntry const* talent = FindTalentByRankSpell(spellId);
    if (!talent)
        return false;

    for (uint32 firstRank : TalentAuraTrackedChains)
        if (talent->RankID[0] == firstRank)
            return true;
    return false;
}

std::string BuildRankSpellList(TalentEntry const* talent)
{
    std::ostringstream spells;
    bool first = true;
    for (uint32 spellId : talent->RankID)
    {
        if (!spellId)
            continue;
        if (!first)
            spells << ',';
        spells << spellId;
        first = false;
    }
    return spells.str();
}

uint32 CountChainRows(char const* table, char const* guidColumn, uint32 guid, std::string const& rankSpells)
{
    if (rankSpells.empty())
        return 0;

    if (QueryResult result = CharacterDatabase.Query(
        "SELECT COUNT(*) FROM `{}` WHERE `{}` = {} AND `spell` IN ({})",
        table, guidColumn, guid, rankSpells))
        return result->Fetch()[0].Get<uint32>();
    return 0;
}

void EmitTalentAuraDiagnostic(Player* player, ChatHandler* handler, uint32 requestedSpellId, char const* reason)
{
    if (!player)
        return;

    uint8 requestedRank = 0;
    TalentEntry const* talent = FindTalentByRankSpell(requestedSpellId, &requestedRank);
    if (!talent)
    {
        if (handler)
            handler->PSendSysMessage("[SCTA] SpellID {} is not a Talent.dbc rank spell.", requestedSpellId);
        return;
    }

    uint32 const guid = player->GetGUID().GetCounter();
    std::string const rankSpells = BuildRankSpellList(talent);
    uint32 storedRank = 0;
    uint32 manualRows = 0;

    if (QueryResult result = CharacterDatabase.Query(
        "SELECT `spell_id` FROM `manually_acquired_talents` "
        "WHERE `player_guid` = {} AND `spell_id` IN ({})", guid, rankSpells))
    {
        do
        {
            uint32 const storedSpell = result->Fetch()[0].Get<uint32>();
            ++manualRows;
            for (uint8 rank = 0; rank < MAX_TALENT_RANK; ++rank)
                if (talent->RankID[rank] == storedSpell)
                    storedRank = std::max<uint32>(storedRank, rank + 1);
        } while (result->NextRow());
    }

    uint32 const characterSpellRows = CountChainRows("character_spell", "guid", guid, rankSpells);
    uint32 const characterTalentRows = CountChainRows("character_talent", "guid", guid, rankSpells);
    uint32 const characterAuraRows = CountChainRows("character_aura", "guid", guid, rankSpells);
    Item* const mainHand = player->GetWeaponForAttack(BASE_ATTACK);
    Item* const offHand = player->GetWeaponForAttack(OFF_ATTACK);
    uint32 const mainItem = mainHand ? mainHand->GetEntry() : 0;
    uint32 const offItem = offHand ? offHand->GetEntry() : 0;
    float const mainPct = player->GetPctModifierValue(UNIT_MOD_DAMAGE_MAINHAND, TOTAL_PCT);
    float const offPct = player->GetPctModifierValue(UNIT_MOD_DAMAGE_OFFHAND, TOTAL_PCT);

    LOG_INFO("module",
        "[SCTA DBG] BEGIN Build={} Reason={} GUID={} Name={} Class={} Level={} TalentID={} "
        "RequestedSpell={} RequestedRank={} StoredRank={} ManualRows={} CharacterSpellRows={} "
        "CharacterTalentRows={} CharacterAuraRows={} STR={}/{} AGI={}/{} STA={}/{} INT={}/{} SPI={}/{} "
        "Health={}/{} Mana={}/{} Armor={} HitMelee={} HitRanged={} HitSpell={} "
        "HitAuraWeapon={} HitAuraSpell={} HitRatingMelee={} HitRatingRanged={} HitRatingSpell={} "
        "CanDualWield={} MainItem={} OffItem={} MainPct={} OffPct={} MainMin={} MainMax={} OffMin={} OffMax={}",
        TalentAuraBuildMarker, reason, guid, player->GetName(), uint32(player->getClass()),
        uint32(player->GetLevel()), talent->TalentID, requestedSpellId, uint32(requestedRank + 1),
        storedRank, manualRows, characterSpellRows, characterTalentRows, characterAuraRows,
        player->GetStat(STAT_STRENGTH), player->GetTotalStatValue(STAT_STRENGTH),
        player->GetStat(STAT_AGILITY), player->GetTotalStatValue(STAT_AGILITY),
        player->GetStat(STAT_STAMINA), player->GetTotalStatValue(STAT_STAMINA),
        player->GetStat(STAT_INTELLECT), player->GetTotalStatValue(STAT_INTELLECT),
        player->GetStat(STAT_SPIRIT), player->GetTotalStatValue(STAT_SPIRIT),
        player->GetHealth(), player->GetMaxHealth(), player->GetPower(POWER_MANA),
        player->GetMaxPower(POWER_MANA), player->GetArmor(), player->m_modMeleeHitChance,
        player->m_modRangedHitChance, player->m_modSpellHitChance,
        player->GetTotalAuraModifier(SPELL_AURA_MOD_HIT_CHANCE),
        player->GetTotalAuraModifier(SPELL_AURA_MOD_SPELL_HIT_CHANCE),
        player->GetRatingBonusValue(CR_HIT_MELEE), player->GetRatingBonusValue(CR_HIT_RANGED),
        player->GetRatingBonusValue(CR_HIT_SPELL), player->CanDualWield(), mainItem, offItem, mainPct, offPct,
        player->GetWeaponDamageRange(BASE_ATTACK, MINDAMAGE),
        player->GetWeaponDamageRange(BASE_ATTACK, MAXDAMAGE),
        player->GetWeaponDamageRange(OFF_ATTACK, MINDAMAGE),
        player->GetWeaponDamageRange(OFF_ATTACK, MAXDAMAGE));

    for (uint8 rank = 0; rank < MAX_TALENT_RANK; ++rank)
    {
        uint32 const spellId = talent->RankID[rank];
        if (!spellId)
            continue;

        SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spellId);
        LOG_INFO("module", "[SCTA DBG] Build={} TalentID={} Rank={} Spell={} Name={} HasSpell={} HasAura={} Passive={}",
            TalentAuraBuildMarker, talent->TalentID, uint32(rank + 1), spellId,
            spellInfo ? spellInfo->SpellName[0] : "<missing>", player->HasSpell(spellId),
            player->HasAura(spellId), spellInfo && spellInfo->IsPassive());
        LogSpellMetadata(player, spellId);
    }

    LOG_INFO("module", "[SCTA DBG] END Build={} Reason={} GUID={} TalentID={}",
        TalentAuraBuildMarker, reason, guid, talent->TalentID);

    if (handler)
    {
        handler->PSendSysMessage(
            "[SCTA] Build={} TalentID={} Requested={}/{} StoredRank={} Rows(M/S/T/A)={}/{}/{}/{}",
            TalentAuraBuildMarker, talent->TalentID, requestedSpellId, uint32(requestedRank + 1), storedRank,
            manualRows, characterSpellRows, characterTalentRows, characterAuraRows);
        handler->PSendSysMessage(
            "[SCTA] STR={} AGI={} STA={} INT={} SPI={} Health={} Mana={} Armor={}",
            player->GetStat(STAT_STRENGTH), player->GetStat(STAT_AGILITY), player->GetStat(STAT_STAMINA),
            player->GetStat(STAT_INTELLECT), player->GetStat(STAT_SPIRIT), player->GetMaxHealth(),
            player->GetMaxPower(POWER_MANA), player->GetArmor());
        handler->PSendSysMessage(
            "[SCTA] Hit(Melee/Ranged/Spell)={}/{}/{} Aura(Weapon/Spell)={}/{} Rating(M/R/S)={}/{}/{}",
            player->m_modMeleeHitChance, player->m_modRangedHitChance, player->m_modSpellHitChance,
            player->GetTotalAuraModifier(SPELL_AURA_MOD_HIT_CHANCE),
            player->GetTotalAuraModifier(SPELL_AURA_MOD_SPELL_HIT_CHANCE),
            player->GetRatingBonusValue(CR_HIT_MELEE), player->GetRatingBonusValue(CR_HIT_RANGED),
            player->GetRatingBonusValue(CR_HIT_SPELL));
        handler->PSendSysMessage(
            "[SCTA] DualWield={} MainItem={} OffItem={} MainPct={} OffPct={} Damage(Main/Off)={}-{} / {}-{}",
            player->CanDualWield(), mainItem, offItem, mainPct, offPct,
            player->GetWeaponDamageRange(BASE_ATTACK, MINDAMAGE),
            player->GetWeaponDamageRange(BASE_ATTACK, MAXDAMAGE),
            player->GetWeaponDamageRange(OFF_ATTACK, MINDAMAGE),
            player->GetWeaponDamageRange(OFF_ATTACK, MAXDAMAGE));
        handler->PSendSysMessage("[SCTA] Full rank/Aura/effect metadata written to worldserver log.");
    }
}

struct DatabaseSnapshot
{
    uint32 manualRank = 0;
    uint32 manualRows = 0;
    uint32 characterSpellRows = 0;
    uint32 characterTalentRows = 0;
    uint32 characterAuraRows = 0;
};

DatabaseSnapshot ReadDatabaseSnapshot(uint32 guid)
{
    DatabaseSnapshot snapshot;

    if (QueryResult result = CharacterDatabase.Query(
        "SELECT COALESCE(MAX(CASE `spell_id` "
        "WHEN 20257 THEN 1 WHEN 20258 THEN 2 WHEN 20259 THEN 3 "
        "WHEN 20260 THEN 4 WHEN 20261 THEN 5 ELSE 0 END), 0), COUNT(*) "
        "FROM `manually_acquired_talents` "
        "WHERE `player_guid` = {} AND `spell_id` BETWEEN 20257 AND 20261", guid))
    {
        Field* fields = result->Fetch();
        snapshot.manualRank = fields[0].Get<uint32>();
        snapshot.manualRows = fields[1].Get<uint32>();
    }

    if (QueryResult result = CharacterDatabase.Query(
        "SELECT COUNT(*) FROM `character_spell` "
        "WHERE `guid` = {} AND `spell` BETWEEN 20257 AND 20261", guid))
        snapshot.characterSpellRows = result->Fetch()[0].Get<uint32>();

    if (QueryResult result = CharacterDatabase.Query(
        "SELECT COUNT(*) FROM `character_talent` "
        "WHERE `guid` = {} AND `spell` BETWEEN 20257 AND 20261", guid))
        snapshot.characterTalentRows = result->Fetch()[0].Get<uint32>();

    if (QueryResult result = CharacterDatabase.Query(
        "SELECT COUNT(*) FROM `character_aura` "
        "WHERE `guid` = {} AND `spell` BETWEEN 20257 AND 20261", guid))
        snapshot.characterAuraRows = result->Fetch()[0].Get<uint32>();

    return snapshot;
}

void LogSpellMetadata(Player* player, uint32 spellId)
{
    SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spellId);
    if (!spellInfo)
    {
        LOG_ERROR("module", "[SCDI DBG] Build={} Spell={} SpellInfo=MISSING", BuildMarker, spellId);
        return;
    }

    LOG_INFO("module",
        "[SCDI DBG] Build={} Spell={} Passive={} Stances=0x{:08X} StancesNot=0x{:08X} "
        "Attr0=0x{:08X} Attr1=0x{:08X} Attr2=0x{:08X} Attr3=0x{:08X} "
        "EquipClass={} EquipSubMask={} EquipInvMask={}",
        BuildMarker, spellId, spellInfo->IsPassive(), spellInfo->Stances, spellInfo->StancesNot,
        spellInfo->Attributes, spellInfo->AttributesEx, spellInfo->AttributesEx2,
        spellInfo->AttributesEx3, spellInfo->EquippedItemClass,
        spellInfo->EquippedItemSubClassMask, spellInfo->EquippedItemInventoryTypeMask);

    for (SpellEffectInfo const& effect : spellInfo->Effects)
    {
        LOG_INFO("module",
            "[SCDI DBG] Build={} Spell={} EffectIndex={} Effect={} Aura={} Misc={} MiscB={} "
            "BasePoints={} CalcValue={}",
            BuildMarker, spellId, uint32(effect.EffectIndex), effect.Effect,
            uint32(effect.ApplyAuraName), effect.MiscValue, effect.MiscValueB,
            effect.BasePoints, effect.CalcValue(player));
    }
}

void EmitDiagnostic(Player* player, char const* reason)
{
    if (!player || !player->GetSession())
        return;

    uint32 const guid = player->GetGUID().GetCounter();
    DatabaseSnapshot const db = ReadDatabaseSnapshot(guid);

    LOG_INFO("module",
        "[SCDI DBG] BEGIN Build={} Reason={} GUID={} Name={} Class={} Level={} "
        "DBRank={} ManualRows={} CharacterSpellRows={} CharacterTalentRows={} CharacterAuraRows={} "
        "GetStatINT={} GetTotalStatINT={} UNIT_FIELD_STAT3={}",
        BuildMarker, reason, guid, player->GetName(), uint32(player->getClass()),
        uint32(player->GetLevel()), db.manualRank, db.manualRows, db.characterSpellRows,
        db.characterTalentRows, db.characterAuraRows, player->GetStat(STAT_INTELLECT),
        player->GetTotalStatValue(STAT_INTELLECT), player->GetUInt32Value(UNIT_FIELD_STAT3));

    for (uint32 spellId = FirstRankSpell; spellId <= LastRankSpell; ++spellId)
    {
        LOG_INFO("module", "[SCDI DBG] Build={} Spell={} HasSpell={} HasAura={}",
            BuildMarker, spellId, player->HasSpell(spellId), player->HasAura(spellId));
        LogSpellMetadata(player, spellId);
    }

    LOG_INFO("module", "[SCDI DBG] END Build={} Reason={} GUID={}", BuildMarker, reason, guid);
}

struct EquippedWeaponSnapshot
{
    uint32 entry = 0;
    uint32 inventoryType = 0;
    uint32 subclass = 0;
};

EquippedWeaponSnapshot ReadWeapon(Player* player, WeaponAttackType attackType)
{
    EquippedWeaponSnapshot snapshot;
    if (Item* item = player->GetWeaponForAttack(attackType))
    {
        snapshot.entry = item->GetEntry();
        snapshot.inventoryType = item->GetTemplate()->InventoryType;
        snapshot.subclass = item->GetTemplate()->SubClass;
    }
    return snapshot;
}

void EmitTitanGripDiagnostic(Player* player, ChatHandler* handler, char const* reason)
{
    if (!player)
        return;

    EquippedWeaponSnapshot const mainHand = ReadWeapon(player, BASE_ATTACK);
    EquippedWeaponSnapshot const offHand = ReadWeapon(player, OFF_ATTACK);
    Aura* penaltyAura = player->GetAura(TitanGripPenaltySpell);
    AuraEffect const* penaltyEffect = penaltyAura ? penaltyAura->GetEffect(EFFECT_0) : nullptr;
    int32 const penaltyAmount = penaltyEffect ? penaltyEffect->GetAmount() : 0;
    float const mainPct = player->GetPctModifierValue(UNIT_MOD_DAMAGE_MAINHAND, TOTAL_PCT);
    float const offPct = player->GetPctModifierValue(UNIT_MOD_DAMAGE_OFFHAND, TOTAL_PCT);

    LOG_INFO("module",
        "[SCTG DBG] Build={} Reason={} GUID={} Name={} Class={} Has46917={} CanDualWield={} CanTitanGrip={} "
        "Has49152={} PenaltyAmount={} MainEntry={} MainInvType={} MainSubclass={} "
        "OffEntry={} OffInvType={} OffSubclass={} MainPct={} OffPct={} "
        "MainMin={} MainMax={} OffMin={} OffMax={}",
        TitanGripBuildMarker, reason, player->GetGUID().GetCounter(), player->GetName(),
        uint32(player->getClass()), player->HasSpell(TitanGripSpell), player->CanDualWield(), player->CanTitanGrip(),
        penaltyAura != nullptr, penaltyAmount,
        mainHand.entry, mainHand.inventoryType, mainHand.subclass,
        offHand.entry, offHand.inventoryType, offHand.subclass,
        mainPct, offPct,
        player->GetWeaponDamageRange(BASE_ATTACK, MINDAMAGE),
        player->GetWeaponDamageRange(BASE_ATTACK, MAXDAMAGE),
        player->GetWeaponDamageRange(OFF_ATTACK, MINDAMAGE),
        player->GetWeaponDamageRange(OFF_ATTACK, MAXDAMAGE));

    LogSpellMetadata(player, TitanGripSpell);
    LogSpellMetadata(player, TitanGripPenaltySpell);

    if (handler)
    {
        handler->PSendSysMessage(
            "[SCTG] Build={} Has46917={} CanDualWield={} CanTitanGrip={} Has49152={} Penalty={} MainItem={} OffItem={} MainPct={} OffPct={}",
            TitanGripBuildMarker, player->HasSpell(TitanGripSpell), player->CanDualWield(), player->CanTitanGrip(),
            penaltyAura != nullptr, penaltyAmount, mainHand.entry, offHand.entry, mainPct, offPct);
        handler->PSendSysMessage("[SCTG] Full metadata and weapon damage ranges written to worldserver log.");
    }
}

}

class SpellDraftNativeAuraDiagPlayerScript final : public PlayerScript
{
public:
    SpellDraftNativeAuraDiagPlayerScript() : PlayerScript("SpellDraftNativeAuraDiagPlayerScript",
    {
        PLAYERHOOK_ON_LOGIN,
        PLAYERHOOK_ON_LEARN_SPELL
    }) { }

    void OnPlayerLogin(Player* player) override
    {
        if (!sConfigMgr->GetOption<bool>("SpellDraft.Diagnostics.AutoHooks", false))
            return;

        EmitDiagnostic(player, "CPP_PLAYER_LOGIN");
    }

    void OnPlayerLearnSpell(Player* player, uint32 spellId) override
    {
        if (!sConfigMgr->GetOption<bool>("SpellDraft.Diagnostics.AutoHooks", false))
            return;

        if (spellId >= FirstRankSpell && spellId <= LastRankSpell)
            EmitDiagnostic(player, "CPP_LEARN_DIVINE_INTELLECT");

        if (IsTalentAuraTrackedSpell(spellId))
            EmitTalentAuraDiagnostic(player, nullptr, spellId, "CPP_LEARN_TRACKED_TALENT");
    }
};

class SpellDraftNativeAuraDiagCommandScript final : public CommandScript
{
public:
    SpellDraftNativeAuraDiagCommandScript() : CommandScript("SpellDraftNativeAuraDiagCommandScript") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable commandTable =
        {
            { "sdtitan", HandleTitanGripDiagnosticCommand, SEC_GAMEMASTER, Console::No },
            { "sdtalentdiag", HandleTalentAuraDiagnosticCommand, SEC_GAMEMASTER, Console::No },
            { "spelldraftdiag", HandleDiagnosticCommand, SEC_GAMEMASTER, Console::No },
            { "spelldrafttitandiag", HandleTitanGripDiagnosticCommand, SEC_GAMEMASTER, Console::No }
        };
        return commandTable;
    }

    static bool HandleDiagnosticCommand(ChatHandler* handler)
    {
        Player* player = handler->GetPlayer();
        if (!player)
            return false;

        EmitDiagnostic(player, "GM_COMMAND");
        handler->PSendSysMessage("[SCDI DBG] Build {} written to worldserver log.", BuildMarker);
        return true;
    }

    static bool HandleTitanGripDiagnosticCommand(ChatHandler* handler)
    {
        Player* player = handler->GetPlayer();
        if (!player)
            return false;

        EmitTitanGripDiagnostic(player, handler, "GM_COMMAND");
        return true;
    }

    static bool HandleTalentAuraDiagnosticCommand(ChatHandler* handler, uint32 spellId)
    {
        Player* player = handler->GetPlayer();
        if (!player)
            return false;

        EmitTalentAuraDiagnostic(player, handler, spellId, "GM_COMMAND");
        return true;
    }

};

void AddSpellDraftNativeAuraDiagScripts()
{
    LOG_INFO("module", "[SCDI DBG] Build marker loaded: {}", BuildMarker);
    LOG_INFO("module", "[SCTG DBG] Build marker loaded: {}", TitanGripBuildMarker);
    LOG_INFO("module", "[SCTA DBG] Build marker loaded: {}", TalentAuraBuildMarker);
    LOG_INFO("module", "SpellDraft automatic talent diagnostics: {}.",
        sConfigMgr->GetOption<bool>("SpellDraft.Diagnostics.AutoHooks", false) ? "enabled" : "disabled");
    new SpellDraftNativeAuraDiagPlayerScript();
    new SpellDraftNativeAuraDiagCommandScript();
}
