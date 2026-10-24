/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license, you may redistribute it
 * and/or modify it under version 3 of the License, or (at your option), any later version.
 */

#include "TestRun/DcPrepSnapshot.h"

#include <algorithm>
#include <sstream>
#include <unordered_map>

#include "Bag.h"
#include "DBCStores.h"
#include "Item.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Playerbots.h"
#include "PlayerbotAI.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "StringFormat.h"

namespace DcPrep
{
    namespace
    {
        // spell id -> 'F' flask / 'E' elixir / 'W' food, built once from what the consumable items
        // cast: the item's own spell and the spell that one triggers (food casts "eating", which
        // triggers the "Well Fed" aura). Read from the item table, not from names, so it holds in
        // every client language and covers the custom consumables of this server too.
        std::unordered_map<std::uint32_t, char> const& BuffKinds()
        {
            static std::unordered_map<std::uint32_t, char> const kinds = []
            {
                std::unordered_map<std::uint32_t, char> m;
                auto add = [&m](std::uint32_t spellId, char kind)
                {
                    if (!spellId)
                        return;
                    m.emplace(spellId, kind);
                    if (SpellInfo const* si = sSpellMgr->GetSpellInfo(spellId))
                        for (SpellEffectInfo const& eff : si->Effects)
                            if (eff.TriggerSpell)
                                m.emplace(eff.TriggerSpell, kind);
                };
                for (auto const& entry : *sObjectMgr->GetItemTemplateStore())
                {
                    ItemTemplate const& proto = entry.second;
                    if (proto.Class != ITEM_CLASS_CONSUMABLE)
                        continue;
                    char kind = 0;
                    if (proto.SubClass == ITEM_SUBCLASS_FLASK)
                        kind = 'F';
                    else if (proto.SubClass == ITEM_SUBCLASS_ELIXIR)
                        kind = 'E';
                    else if (proto.SubClass == ITEM_SUBCLASS_FOOD)
                        kind = 'W';
                    if (!kind)
                        continue;
                    for (auto const& sp : proto.Spells)
                        add(sp.SpellId, kind);
                }
                return m;
            }();
            return kinds;
        }

        // The eating / drinking aura itself is not a buff worth showing: the food that counts is the
        // stat aura it leaves behind.
        bool IsEatingAura(SpellInfo const* si)
        {
            return si->HasAura(SPELL_AURA_OBS_MOD_HEALTH) || si->HasAura(SPELL_AURA_OBS_MOD_POWER);
        }

        char StockKind(ItemTemplate const* proto)
        {
            if (proto->Class != ITEM_CLASS_CONSUMABLE)
                return 0;
            switch (proto->SubClass)
            {
                case ITEM_SUBCLASS_FLASK:
                    return 'F';
                case ITEM_SUBCLASS_ELIXIR:
                    return 'E';
                case ITEM_SUBCLASS_FOOD:
                    return 'W';
                case ITEM_SUBCLASS_POTION:
                    for (auto const& sp : proto->Spells)
                    {
                        SpellInfo const* si = sp.SpellId ? sSpellMgr->GetSpellInfo(sp.SpellId) : nullptr;
                        if (!si)
                            continue;
                        for (SpellEffectInfo const& eff : si->Effects)
                        {
                            if (eff.Effect == SPELL_EFFECT_HEAL)
                                return 'H';
                            if (eff.Effect == SPELL_EFFECT_ENERGIZE && eff.MiscValue == POWER_MANA)
                                return 'M';
                        }
                    }
                    return 0;
                default:
                    return 0;
            }
        }

        void AddStock(std::vector<Stock>& out, ItemTemplate const* proto, std::uint32_t count, char kind)
        {
            for (Stock& s : out)
                if (s.kind == kind)
                {
                    s.count += count;
                    // the best stack: the higher required level, then the higher item level
                    ItemTemplate const* cur = sObjectMgr->GetItemTemplate(s.itemId);
                    if (!cur || proto->RequiredLevel > cur->RequiredLevel ||
                        (proto->RequiredLevel == cur->RequiredLevel && proto->ItemLevel > cur->ItemLevel))
                        s.itemId = proto->ItemId;
                    return;
                }
            Stock s;
            s.kind = kind;
            s.itemId = proto->ItemId;
            s.count = count;
            out.push_back(s);
        }

        void ScanItem(Item* item, std::vector<Stock>& out)
        {
            ItemTemplate const* proto = item ? item->GetTemplate() : nullptr;
            if (!proto)
                return;
            if (char kind = StockKind(proto))
                AddStock(out, proto, item->GetCount(), kind);
        }

        std::string Talents(Player* p)
        {
            std::uint8_t const spec = p->GetActiveSpec();
            std::uint32_t points[3] = { 0, 0, 0 };
            for (std::uint32_t i = 0; i < sTalentStore.GetNumRows(); ++i)
            {
                TalentEntry const* talent = sTalentStore.LookupEntry(i);
                if (!talent)
                    continue;
                TalentTabEntry const* tab = sTalentTabStore.LookupEntry(talent->TalentTab);
                if (!tab || !(tab->ClassMask & p->getClassMask()) || tab->tabpage > 2)
                    continue;
                std::uint32_t learned = 0;
                for (std::uint32_t r = 0; r < MAX_TALENT_RANK; ++r)
                    if (talent->RankID[r] && p->HasTalent(talent->RankID[r], spec))
                        learned = r + 1;
                points[tab->tabpage] += learned;
            }
            return Acore::StringFormat("{}/{}/{}", points[0], points[1], points[2]);
        }
    }

    Snapshot Capture(Player* p, std::string const& role)
    {
        Snapshot s;
        if (!p)
            return s;
        s.valid = true;
        s.classId = p->getClass();
        s.level = p->GetLevel();
        s.role = !role.empty() ? role : (PlayerbotAI::IsTank(p) ? "tank" : (PlayerbotAI::IsHeal(p) ? "heal" : "dps"));
        s.talents = Talents(p);
        s.avgIlvl = static_cast<std::uint32_t>(p->GetAverageItemLevel() + 0.5f);

        // the slots every class fills: no shirt, tabard, ranged or off-hand (not every class has one)
        static constexpr std::uint8_t kRequired[] = {
            EQUIPMENT_SLOT_HEAD, EQUIPMENT_SLOT_NECK, EQUIPMENT_SLOT_SHOULDERS, EQUIPMENT_SLOT_CHEST,
            EQUIPMENT_SLOT_WAIST, EQUIPMENT_SLOT_LEGS, EQUIPMENT_SLOT_FEET, EQUIPMENT_SLOT_WRISTS,
            EQUIPMENT_SLOT_HANDS, EQUIPMENT_SLOT_FINGER1, EQUIPMENT_SLOT_FINGER2, EQUIPMENT_SLOT_TRINKET1,
            EQUIPMENT_SLOT_TRINKET2, EQUIPMENT_SLOT_BACK, EQUIPMENT_SLOT_MAINHAND };
        std::uint32_t minIlvl = 0;
        for (std::uint8_t slot : kRequired)
        {
            Item* item = p->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
            ItemTemplate const* proto = item ? item->GetTemplate() : nullptr;
            if (!proto)
            {
                ++s.emptySlots;
                continue;
            }
            if (!minIlvl || proto->ItemLevel < minIlvl)
                minIlvl = proto->ItemLevel;
        }
        s.minIlvl = minIlvl;

        std::uint32_t lowest = 100;
        for (std::uint8_t slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
        {
            Item* item = p->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
            if (!item)
                continue;
            std::uint32_t const maxDur = item->GetUInt32Value(ITEM_FIELD_MAXDURABILITY);
            if (maxDur)
                lowest = std::min(lowest, item->GetUInt32Value(ITEM_FIELD_DURABILITY) * 100 / maxDur);
        }
        s.durabilityPct = lowest;

        s.needsPet = s.classId == CLASS_HUNTER || s.classId == CLASS_WARLOCK;
        s.hasPet = p->GetPet() != nullptr;

        Stats& st = s.stats;
        st.hp = p->GetMaxHealth();
        st.powerType = p->getPowerType();
        st.mana = p->GetMaxPower(p->getPowerType());
        st.armor = p->GetArmor();
        st.ap = static_cast<std::uint32_t>(std::max(0.f, p->GetTotalAttackPowerValue(BASE_ATTACK)));
        st.rap = static_cast<std::uint32_t>(std::max(0.f, p->GetTotalAttackPowerValue(RANGED_ATTACK)));
        st.sp = static_cast<std::uint32_t>(std::max(0, p->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_MAGIC)));
        st.healSp = static_cast<std::uint32_t>(std::max(0, p->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_MAGIC)));
        st.expertise = p->GetUInt32Value(PLAYER_EXPERTISE);
        st.defense = p->GetDefenseSkillValue();
        st.resilience = p->GetUInt32Value(PLAYER_FIELD_COMBAT_RATING_1 + CR_CRIT_TAKEN_MELEE);
        st.crit = p->GetFloatValue(PLAYER_CRIT_PERCENTAGE);
        st.rcrit = p->GetFloatValue(PLAYER_RANGED_CRIT_PERCENTAGE);
        for (std::uint32_t school = 1; school < MAX_SPELL_SCHOOL; ++school)
            st.scrit = std::max(st.scrit, p->GetFloatValue(PLAYER_SPELL_CRIT_PERCENTAGE1 + school));
        st.hit = p->GetRatingBonusValue(CR_HIT_MELEE);
        st.rhit = p->GetRatingBonusValue(CR_HIT_RANGED);
        st.shit = p->GetRatingBonusValue(CR_HIT_SPELL);
        st.haste = std::max({ p->GetRatingBonusValue(CR_HASTE_MELEE), p->GetRatingBonusValue(CR_HASTE_RANGED),
                              p->GetRatingBonusValue(CR_HASTE_SPELL) });
        st.dodge = p->GetFloatValue(PLAYER_DODGE_PERCENTAGE);
        st.parry = p->GetFloatValue(PLAYER_PARRY_PERCENTAGE);
        st.block = p->GetFloatValue(PLAYER_BLOCK_PERCENTAGE);

        // the flask / elixir / food the character is wearing right now
        auto const& kinds = BuffKinds();
        for (auto const& entry : p->GetAppliedAuras())
        {
            AuraApplication const* app = entry.second;
            Aura const* aura = app ? app->GetBase() : nullptr;
            if (!aura)
                continue;
            auto it = kinds.find(aura->GetId());
            if (it == kinds.end())
                continue;
            SpellInfo const* si = aura->GetSpellInfo();
            if (!si || IsEatingAura(si))
                continue;
            bool known = false;
            for (Buff const& b : s.buffs)
                known = known || b.spellId == aura->GetId();
            if (known)
                continue;
            Buff b;
            b.kind = it->second;
            b.spellId = aura->GetId();
            b.secs = aura->GetDuration() > 0 ? static_cast<std::uint32_t>(aura->GetDuration() / 1000) : 0;
            s.buffs.push_back(b);
        }

        // the potions, flasks, elixirs and food in the bags
        for (std::uint8_t slot = INVENTORY_SLOT_ITEM_START; slot < INVENTORY_SLOT_ITEM_END; ++slot)
            ScanItem(p->GetItemByPos(INVENTORY_SLOT_BAG_0, slot), s.stock);
        for (std::uint8_t bagSlot = INVENTORY_SLOT_BAG_START; bagSlot < INVENTORY_SLOT_BAG_END; ++bagSlot)
            if (Bag* bag = p->GetBagByPos(bagSlot))
                for (std::uint32_t i = 0; i < bag->GetBagSize(); ++i)
                    ScanItem(bag->GetItemByPos(static_cast<std::uint8_t>(i)), s.stock);
        return s;
    }

    std::string ToJson(Snapshot const& s)
    {
        std::ostringstream o;
        if (!s.valid)
        {
            o << "{\"valid\":false}";
            return o.str();
        }
        Stats const& t = s.stats;
        o << "{\"valid\":true,\"class\":" << s.classId << ",\"level\":" << s.level << ",\"role\":\"" << s.role
          << "\",\"talents\":\"" << s.talents << "\",\"avgIlvl\":" << s.avgIlvl << ",\"minIlvl\":" << s.minIlvl
          << ",\"emptySlots\":" << s.emptySlots << ",\"durability\":" << s.durabilityPct
          << ",\"pet\":[" << (s.needsPet ? 1 : 0) << ',' << (s.hasPet ? 1 : 0) << "],\"stats\":{"
          << "\"hp\":" << t.hp << ",\"power\":" << t.mana << ",\"powerType\":" << t.powerType
          << ",\"armor\":" << t.armor << ",\"ap\":" << t.ap << ",\"rap\":" << t.rap << ",\"sp\":" << t.sp
          << ",\"healSp\":" << t.healSp << ",\"expertise\":" << t.expertise << ",\"defense\":" << t.defense
          << ",\"resilience\":" << t.resilience
          << ",\"crit\":" << Acore::StringFormat("{:.1f}", t.crit) << ",\"rcrit\":" << Acore::StringFormat("{:.1f}", t.rcrit)
          << ",\"scrit\":" << Acore::StringFormat("{:.1f}", t.scrit)
          << ",\"hit\":" << Acore::StringFormat("{:.1f}", t.hit) << ",\"rhit\":" << Acore::StringFormat("{:.1f}", t.rhit)
          << ",\"shit\":" << Acore::StringFormat("{:.1f}", t.shit) << ",\"haste\":" << Acore::StringFormat("{:.1f}", t.haste)
          << ",\"dodge\":" << Acore::StringFormat("{:.1f}", t.dodge) << ",\"parry\":" << Acore::StringFormat("{:.1f}", t.parry)
          << ",\"block\":" << Acore::StringFormat("{:.1f}", t.block) << "},\"buffs\":[";
        for (std::size_t i = 0; i < s.buffs.size(); ++i)
            o << (i ? "," : "") << "[\"" << s.buffs[i].kind << "\"," << s.buffs[i].spellId << ',' << s.buffs[i].secs << ']';
        o << "],\"stock\":[";
        for (std::size_t i = 0; i < s.stock.size(); ++i)
            o << (i ? "," : "") << "[\"" << s.stock[i].kind << "\"," << s.stock[i].itemId << ',' << s.stock[i].count << ']';
        o << "]}";
        return o.str();
    }
}
