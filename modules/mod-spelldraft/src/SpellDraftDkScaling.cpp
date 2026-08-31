/*
 * SpellDraft level-one Death Knight damage scaling.
 * Adapted 2026-08-10 from VenomekPL/mod-classic-deathknight, commit
 * 71ddff924d0fb2508756a7a72a1b09470256b4ec (MIT License).
 *
 * Important project change: the upstream module applies to every DK. This
 * version first reads spelldraft_character_mode and applies only to mode 2
 * (Random Draft), so Classic mode remains stock WotLK.
 */

#include "AllSpellScript.h"
#include "Configuration/Config.h"
#include "DBCStores.h"
#include "DatabaseEnv.h"
#include "Item.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"
#include "UnitScript.h"
#include <algorithm>
#include <cmath>
#include <mutex>
#include <unordered_set>

namespace
{
std::unordered_set<uint32> DraftDeathKnights;
std::mutex DraftDeathKnightsLock;
constexpr uint16 DK_STARTER_OUTFIT_VERSION = 2;

// A level-one Draft DK should look like a newly-created member of its race,
// not like a naked level-55 hero class.  The project already owns the exact
// race/gender outfit mapping in CharStartOutfit.dbc.  We deliberately use the
// warrior row because every supported race has one and its weapon/armor are
// suitable for a Death Knight.  No class change is performed here.
bool EnsureDraftDkStarterOutfit(Player* player)
{
    if (!player || player->getClass() != CLASS_DEATH_KNIGHT || player->GetLevel() != 1)
        return false;

    uint32 guid = player->GetGUID().GetCounter();
    QueryResult bootstrap = CharacterDatabase.Query(
        "SELECT eligible, state, version FROM spelldraft_dk_bootstrap WHERE guid = {} LIMIT 1", guid);
    if (!bootstrap)
        return false;

    Field* fields = bootstrap->Fetch();
    uint8 eligible = fields[0].Get<uint8>();
    uint8 state = fields[1].Get<uint8>();
    uint16 version = fields[2].Get<uint16>();
    if (eligible != 1 || (state != 1 && state != 2) || version >= DK_STARTER_OUTFIT_VERSION)
        return false;

    CharStartOutfitEntry const* outfit = GetCharStartOutfitEntry(
        player->getRace(), CLASS_WARRIOR, player->GetGender());
    if (!outfit)
    {
        LOG_ERROR("module", "[SpellDraft/DK] No warrior starter outfit for race {}, gender {}, guid {}.",
            player->getRace(), player->GetGender(), guid);
        return false;
    }

    std::unordered_set<uint32> outfitItems;
    bool foundWearableItem = false;
    bool allItemsStored = true;

    for (int index = 0; index < MAX_OUTFIT_ITEMS; ++index)
    {
        if (outfit->ItemId[index] <= 0)
            continue;

        uint32 itemId = static_cast<uint32>(outfit->ItemId[index]);
        ItemTemplate const* itemTemplate = sObjectMgr->GetItemTemplate(itemId);
        if (!itemTemplate || itemTemplate->InventoryType == INVTYPE_NON_EQUIP)
            continue;

        foundWearableItem = true;
        outfitItems.insert(itemId);
        if (!player->HasItemCount(itemId, 1, true) && !player->StoreNewItemInBestSlots(itemId, 1))
            allItemsStored = false;
    }

    // StoreNewItemInBestSlots equips newly-created gear immediately.  This
    // second pass also equips a weapon/clothing item left in the backpack by
    // the older Lua-only implementation, so existing naked test characters
    // repair themselves on their next login.
    for (uint8 slot = INVENTORY_SLOT_ITEM_START; slot < INVENTORY_SLOT_ITEM_END; ++slot)
    {
        Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
        if (!item || outfitItems.find(item->GetEntry()) == outfitItems.end())
            continue;

        uint16 destination;
        if (player->CanEquipItem(NULL_SLOT, destination, item, false) != EQUIP_ERR_OK)
            continue;

        player->RemoveItem(INVENTORY_SLOT_BAG_0, slot, true);
        player->EquipItem(destination, item, true);
        player->AutoUnequipOffhandIfNeed();
    }

    if (!foundWearableItem || !allItemsStored)
    {
        LOG_ERROR("module", "[SpellDraft/DK] Starter outfit incomplete for race {}, gender {}, guid {}; will retry next login.",
            player->getRace(), player->GetGender(), guid);
        return false;
    }

    // This fork exposes SaveToDB(create, logout) without zero-argument
    // defaults.  The character already exists and this is a live login, so
    // both flags must be false.
    player->SaveToDB(false, false);
    CharacterDatabase.Execute(
        "UPDATE spelldraft_dk_bootstrap SET version = {} WHERE guid = {} AND version < {}",
        DK_STARTER_OUTFIT_VERSION, guid, DK_STARTER_OUTFIT_VERSION);
    LOG_INFO("module", "[SpellDraft/DK] Equipped racial level-one starter outfit for guid {}, race {}, gender {}.",
        guid, player->getRace(), player->GetGender());
    return true;
}

bool IsDraftDeathKnight(Player const* player)
{
    if (!player || player->getClass() != CLASS_DEATH_KNIGHT)
        return false;
    std::lock_guard<std::mutex> guard(DraftDeathKnightsLock);
    return DraftDeathKnights.find(player->GetGUID().GetCounter()) != DraftDeathKnights.end();
}

float GetDraftDkMultiplier(uint8 level)
{
    if (!sConfigMgr->GetOption<bool>("SpellDraft.DraftDkDamageScaleEnable", true))
        return 1.0f;

    uint8 fullLevel = static_cast<uint8>(sConfigMgr->GetOption<uint32>(
        "SpellDraft.DraftDkDamageScaleFullLevel", 55));
    float minimum = sConfigMgr->GetOption<float>(
        "SpellDraft.DraftDkDamageScaleMinMultiplier", 0.10f);

    minimum = std::max(0.01f, std::min(minimum, 1.0f));
    if (fullLevel <= 1 || level >= fullLevel)
        return 1.0f;
    if (level <= 1)
        return minimum;

    float progress = float(level - 1) / float(fullLevel - 1);
    return minimum + (1.0f - minimum) * progress;
}

bool ShouldScale(Unit const* caster, SpellInfo const* spellInfo)
{
    if (!caster || !caster->IsPlayer() || !spellInfo)
        return false;
    if (spellInfo->SpellFamilyName != SPELLFAMILY_DEATHKNIGHT)
        return false;
    return IsDraftDeathKnight(caster->ToPlayer());
}

template <typename T>
void ScaleAmount(Unit const* caster, T& amount)
{
    if (amount <= 0)
        return;
    amount = static_cast<T>(std::max(1.0f,
        std::round(float(amount) * GetDraftDkMultiplier(caster->GetLevel()))));
}
}

class SpellDraftDkMode_PlayerScript : public PlayerScript
{
public:
    SpellDraftDkMode_PlayerScript() : PlayerScript("SpellDraftDkMode_PlayerScript") { }

    static void ActivateDraftDeathKnight(Player* player)
    {
        if (!player || player->getClass() != CLASS_DEATH_KNIGHT)
            return;

        uint32 guid = player->GetGUID().GetCounter();
        QueryResult result = CharacterDatabase.Query(
            "SELECT mode FROM spelldraft_character_mode WHERE guid = {} LIMIT 1", guid);
        if (!result || result->Fetch()[0].Get<uint8>() != 2)
            return;

        {
            std::lock_guard<std::mutex> guard(DraftDeathKnightsLock);
            DraftDeathKnights.insert(guid);
        }
        EnsureDraftDkStarterOutfit(player);
    }

    void OnPlayerLogin(Player* player) override
    {
        uint32 guid = player->GetGUID().GetCounter();
        {
            std::lock_guard<std::mutex> guard(DraftDeathKnightsLock);
            DraftDeathKnights.erase(guid);
        }
        ActivateDraftDeathKnight(player);
    }

    void OnPlayerLevelChanged(Player* player, uint8 /*oldLevel*/) override
    {
        // Hot mode selection writes mode=2 before Lua converts the fresh DK
        // from level 55 to level 1.  The level hook therefore supplies the same
        // scaling-cache and starter-outfit work that previously required relog.
        if (player && player->GetLevel() == 1)
            ActivateDraftDeathKnight(player);
    }

    void OnPlayerLogout(Player* player) override
    {
        std::lock_guard<std::mutex> guard(DraftDeathKnightsLock);
        DraftDeathKnights.erase(player->GetGUID().GetCounter());
    }
};

class SpellDraftDkMode_UnitScript : public UnitScript
{
public:
    SpellDraftDkMode_UnitScript() : UnitScript("SpellDraftDkMode_UnitScript", true,
        { UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN,
          UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK,
          UNITHOOK_MODIFY_HEAL_RECEIVED }) { }

    void ModifySpellDamageTaken(Unit*, Unit* attacker, int32& damage,
        SpellInfo const* spellInfo) override
    {
        if (ShouldScale(attacker, spellInfo)) ScaleAmount(attacker, damage);
    }

    void ModifyPeriodicDamageAurasTick(Unit*, Unit* attacker, uint32& damage,
        SpellInfo const* spellInfo) override
    {
        if (ShouldScale(attacker, spellInfo)) ScaleAmount(attacker, damage);
    }

    void ModifyHealReceived(Unit*, Unit* healer, uint32& heal,
        SpellInfo const* spellInfo) override
    {
        if (ShouldScale(healer, spellInfo)) ScaleAmount(healer, heal);
    }
};

void AddSpellDraftDkScalingScripts()
{
    new SpellDraftDkMode_PlayerScript();
    new SpellDraftDkMode_UnitScript();
}
