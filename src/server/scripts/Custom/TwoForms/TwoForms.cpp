#include "Player.h"
#include "ScriptMgr.h"
#include "Log.h"
#include "Spell.h"
#include "SpellScript.h"
#include "SpellAuras.h"
#include "SpellAuraEffects.h"
#include <algorithm>
#include <unordered_map>

namespace
{
    constexpr uint8 RACE_WORGEN_CUSTOM = 16;
    constexpr uint8 RACE_DRACTHYR_CUSTOM = 27;
    constexpr uint8 RACE_NAGA_CUSTOM = 25;

    constexpr uint32 SPELL_WORGEN_TWO_FORMS_MALE = 97709;
    constexpr uint32 SPELL_WORGEN_TWO_FORMS_FEMALE = 97710;
    constexpr uint32 SPELL_DRACTHYR_DRAGON_FORM = 320555;
    constexpr uint32 SPELL_WARLOCK_METAMORPHOSIS = 47241;
    // 娜迦两个自定义种族被动(克隆5227模板做的，客户端+服务端Spell.dbc都已加)：
    //  100301 水下呼吸：被动+永久，说明改成"永久在水中呼吸永不淹死"(真正"无呼吸条"由
    //          Player::getMaxTimer里的娜迦种族判断实现，这个技能主要是法术书里的图标+说明)。
    //  100302 游泳加速：被动+永久，aura=58(MOD_INCREASE_SWIM_SPEED)+150%。实际生效同时也有
    //          Unit::UpdateSpeed里的娜迦代码兜底，两者取max不会叠加。
    constexpr uint32 SPELL_NAGA_WATER_BREATHING = 100301;
    constexpr uint32 SPELL_NAGA_SWIM_SPEED      = 100302;

    // 龙希尔"御空术"技能：100210(原名音爆/Skyburst，客户端显示名字+说明文字+
    // 冲刺特效都通过单独的DBC补丁清掉、改名了)，"龙形态限定的起飞技能"——
    // 人形状态点了会被拦下来+提示切换龙形，骑乘状态点了也会被拦下来(不然会把
    // 自己从坐骑上弹飞)，只有龙形态+没骑乘+骑术够，才会真正获得飞行能力。
    //
    // 飞行能力单独一个干净的官方技能，运行时用AddAura直接给(不学进法术书，
    // 是这个技能触发的隐藏内部效果)：
    //   34873：纯净"获得飞行能力"(只有一个SPELL_AURA_FLY效果，永久)
    //
    // 飞行速度不再用"一个技能+运行时改数字"了——之前发现客户端buff提示框上的
    // 百分比是读技能自己DBC里原本写死的数值，跟server端runtime改的数字对不上
    // (会一直显示某个技能的原始数值，不会跟着变)。改成四个不同骑术档位各自
    // 对应一个真实的、数值本来就对的官方技能，缺哪档用哪个，界面显示永远正确：
    //   61453 "飞行"：骑术75(学徒级)档，真实数值59% ≈ 60%
    //   43775 "飞行"：骑术150(熟练级)档，真实数值99% ≈ 100%
    //   33948 "飞行形态（被动）"：骑术225(精通级)档，真实数值149% ≈ 150%
    //         (这就是德鲁伊飞行形态自带的被动技能，官方验证过的真实数据)
    //   44423 "翱翔"：骑术300(专家级)档，真实数值299% ≈ 300%(比280%还高一点，
    //         但这个是DBC里真实存在的数值，不是编的，跟"迅捷"级坐骑一个档次)
    constexpr uint32 SPELL_DRACTHYR_FLIGHT_ACTIVATE = 100210;
    constexpr uint32 SPELL_DRACTHYR_FLY_CAPABILITY = 34873;
    constexpr uint32 SPELL_DRACTHYR_FLY_SPEED_TIER1_60 = 61453;
    constexpr uint32 SPELL_DRACTHYR_FLY_SPEED_TIER2_100 = 43775;
    constexpr uint32 SPELL_DRACTHYR_FLY_SPEED_TIER3_150 = 33948;
    constexpr uint32 SPELL_DRACTHYR_FLY_SPEED_TIER4_300 = 44423;

    constexpr uint32 DISPLAY_DRACTHYR_VISAGE_MALE = 566212;
    constexpr uint32 DISPLAY_DRACTHYR_VISAGE_FEMALE = 566213;
    constexpr uint8 DRACTHYR_DRAGON_SKIN_VARIANTS = 15;
    constexpr uint8 DRACTHYR_VISAGE_SKINS_PER_COLOR_GROUP = 8;
    constexpr uint8 DRACTHYR_DRAGON_ARMOR_VARIANTS = 8;
    constexpr uint8 DRACTHYR_DRAGON_DEFAULT_ARMOR_VARIANT = 0;
    constexpr uint8 DRACTHYR_DRAGON_DISPLAY_VARIANTS = DRACTHYR_DRAGON_SKIN_VARIANTS * DRACTHYR_DRAGON_ARMOR_VARIANTS;
    constexpr uint32 DISPLAY_DRACTHYR_DRAGON_MALE_BASE = 1100000;
    constexpr uint32 DISPLAY_DRACTHYR_DRAGON_FEMALE_BASE = 1101000;

    enum class DracthyrVisibleMode : uint8
    {
        Normal,
        Dragon
    };

    constexpr uint32 DRACTHYR_DRAGON_FORM_AURA_SYNC_MS = 1500;
    constexpr uint32 DRACTHYR_DRAGON_FORM_AURA_CANCEL_MS = 750;

    std::unordered_map<uint64, DracthyrVisibleMode> DracthyrVisibleModes;
    std::unordered_map<uint64, uint32> DracthyrDragonFormAuraSyncTimers;
    std::unordered_map<uint64, uint32> DracthyrDragonFormAuraCancelTimers;

    uint64 GetDracthyrStateKey(Player const* player)
    {
        return player->GetGUID().GetCounter();
    }

    void ClearDracthyrDragonFormAuraState(Player const* player)
    {
        uint64 key = GetDracthyrStateKey(player);
        DracthyrDragonFormAuraSyncTimers.erase(key);
        DracthyrDragonFormAuraCancelTimers.erase(key);
    }

    void StartDracthyrDragonFormAuraSync(Player const* player)
    {
        uint64 key = GetDracthyrStateKey(player);
        DracthyrDragonFormAuraSyncTimers[key] = DRACTHYR_DRAGON_FORM_AURA_SYNC_MS;
        DracthyrDragonFormAuraCancelTimers.erase(key);
    }

    void QueueDracthyrDragonFormAuraCancel(Player* player)
    {
        uint64 key = GetDracthyrStateKey(player);
        DracthyrDragonFormAuraCancelTimers[key] = DRACTHYR_DRAGON_FORM_AURA_CANCEL_MS;
        DracthyrDragonFormAuraSyncTimers.erase(key);
        player->RemoveAurasDueToSpell(SPELL_DRACTHYR_DRAGON_FORM);
    }

    bool TickDracthyrDragonFormAuraSync(Player* player, uint32 diff)
    {
        uint64 key = GetDracthyrStateKey(player);
        auto itr = DracthyrDragonFormAuraSyncTimers.find(key);
        if (itr == DracthyrDragonFormAuraSyncTimers.end())
            return false;

        if (player->HasAura(SPELL_DRACTHYR_DRAGON_FORM))
        {
            DracthyrDragonFormAuraSyncTimers.erase(itr);
            return false;
        }

        if (itr->second <= diff)
        {
            DracthyrDragonFormAuraSyncTimers.erase(itr);
            return false;
        }

        itr->second -= diff;
        return true;
    }

    bool TickDracthyrDragonFormAuraCancel(Player* player, uint32 diff)
    {
        uint64 key = GetDracthyrStateKey(player);
        auto itr = DracthyrDragonFormAuraCancelTimers.find(key);
        if (itr == DracthyrDragonFormAuraCancelTimers.end())
            return false;

        player->RemoveAurasDueToSpell(SPELL_DRACTHYR_DRAGON_FORM);

        if (itr->second <= diff)
        {
            DracthyrDragonFormAuraCancelTimers.erase(itr);
            return false;
        }

        itr->second -= diff;
        return true;
    }

    uint8 GetDracthyrOriginalGender(Player const* player)
    {
        return player->GetByteValue(PLAYER_BYTES_3, PLAYER_BYTES_3_OFFSET_GENDER);
    }

    uint32 GetDracthyrVisageDisplayId(Player const* player)
    {
        return GetDracthyrOriginalGender(player) == GENDER_FEMALE ? DISPLAY_DRACTHYR_VISAGE_FEMALE : DISPLAY_DRACTHYR_VISAGE_MALE;
    }

    uint8 GetDracthyrVisageSkinColorGroup(Player const* player)
    {
        uint8 skin = player->GetByteValue(PLAYER_BYTES, PLAYER_BYTES_OFFSET_SKIN_ID);
        return skin / DRACTHYR_VISAGE_SKINS_PER_COLOR_GROUP;
    }

    uint8 GetDracthyrVisageSkinShade(Player const* player)
    {
        uint8 skin = player->GetByteValue(PLAYER_BYTES, PLAYER_BYTES_OFFSET_SKIN_ID);
        return skin % DRACTHYR_VISAGE_SKINS_PER_COLOR_GROUP;
    }

    uint8 MapDracthyrVisageSkinGroupToDragonSkin(uint8 visageSkinGroup)
    {
        // Race27 CharSections are ordered as:
        // skin = visageColorGroup * 8 + shade.
        // Dragon textures are ordered as 15 color groups. Group 00 is the pale/no-scale
        // fallback, then groups 01-15 and 16-30 match dragon skins 00-14.
        if (visageSkinGroup == 0)
            return DRACTHYR_DRAGON_SKIN_VARIANTS - 1;

        return (visageSkinGroup - 1) % DRACTHYR_DRAGON_SKIN_VARIANTS;
    }

    uint8 GetDracthyrDragonSkinVariant(Player const* player)
    {
        return MapDracthyrVisageSkinGroupToDragonSkin(GetDracthyrVisageSkinColorGroup(player));
    }

    uint8 GetDracthyrDragonArmorVariant(Player const* player)
    {
        // Sirus dragon displays are arranged as 15 skin colors * 8 baked armor textures.
        // The normal WotLK item models do not fit the dragon body, so dragon form uses
        // these baked armor rows instead of showing chest/leg/helmet equipment directly.
        switch (player->getClass())
        {
            case CLASS_PRIEST:
            case CLASS_MAGE:
            case CLASS_WARLOCK:
                return 0;
            case CLASS_ROGUE:
            case CLASS_DRUID:
                return 1;
            case CLASS_HUNTER:
            case CLASS_SHAMAN:
                return 2;
            case CLASS_WARRIOR:
                return 3;
            case CLASS_PALADIN:
                return 4;
            case CLASS_DEATH_KNIGHT:
                return 5;
            default:
                return DRACTHYR_DRAGON_DEFAULT_ARMOR_VARIANT;
        }
    }

    uint32 GetDracthyrDragonDisplayId(Player const* player)
    {
        uint8 skinVariant = GetDracthyrDragonSkinVariant(player);
        uint8 armorVariant = std::min<uint8>(GetDracthyrDragonArmorVariant(player), DRACTHYR_DRAGON_ARMOR_VARIANTS - 1);
        uint32 displayIndex = skinVariant * DRACTHYR_DRAGON_ARMOR_VARIANTS + armorVariant;
        uint32 displayBase = GetDracthyrOriginalGender(player) == GENDER_FEMALE ? DISPLAY_DRACTHYR_DRAGON_FEMALE_BASE : DISPLAY_DRACTHYR_DRAGON_MALE_BASE;
        return displayBase + displayIndex;
    }

    bool IsDracthyrDragonDisplay(uint32 displayId)
    {
        return (displayId >= DISPLAY_DRACTHYR_DRAGON_MALE_BASE && displayId < DISPLAY_DRACTHYR_DRAGON_MALE_BASE + DRACTHYR_DRAGON_DISPLAY_VARIANTS) ||
            (displayId >= DISPLAY_DRACTHYR_DRAGON_FEMALE_BASE && displayId < DISPLAY_DRACTHYR_DRAGON_FEMALE_BASE + DRACTHYR_DRAGON_DISPLAY_VARIANTS);
    }

    bool IsWeaponEquipmentSlot(uint8 slot)
    {
        return slot == EQUIPMENT_SLOT_MAINHAND || slot == EQUIPMENT_SLOT_OFFHAND || slot == EQUIPMENT_SLOT_RANGED;
    }

    void RefreshDracthyrVisibleItems(Player* player, bool showEquipment, bool showWeapons)
    {
        for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
        {
            Item* item = (showEquipment || (showWeapons && IsWeaponEquipmentSlot(slot)))
                ? player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot)
                : nullptr;
            player->SetVisibleItemSlot(slot, item);
        }
    }

    void ApplyDracthyrVisibleMode(Player* player, DracthyrVisibleMode mode, bool force = false)
    {
        uint64 key = GetDracthyrStateKey(player);
        auto itr = DracthyrVisibleModes.find(key);
        if (!force && itr != DracthyrVisibleModes.end() && itr->second == mode)
            return;

        DracthyrVisibleModes[key] = mode;

        if (mode == DracthyrVisibleMode::Dragon)
            RefreshDracthyrVisibleItems(player, false, true);
        else
            RefreshDracthyrVisibleItems(player, true, true);
    }

    // MAP_NORTHREND(571)引擎自己的头文件(AreaDefines.h)里已经定义过了，
    // 之前我又在这里重复定义了一遍同名同值的常量，两边"撞名"导致编译器
    // 不知道用哪一个，报"ambiguous symbol"——这里删掉，直接用引擎自带的那个。
    constexpr uint32 SPELL_COLD_WEATHER_FLYING = 54197; // 官方"寒冷天气飞行"，诺森德飞行的真实门槛

    // 根据骑术技能挑一个"数值本来就对"的真实技能ID(不再用运行时改数字这招，
    // 客户端buff提示框只认技能自己DBC里原本写死的数值，改了也不会跟着变)。
    // 骑术不够75返回0，表示完全不给飞行。
    uint32 GetDracthyrFlightSpeedSpellId(Player* player)
    {
        uint16 riding = player->GetSkillValue(SKILL_RIDING);
        if (riding >= 300)
            return SPELL_DRACTHYR_FLY_SPEED_TIER4_300;
        if (riding >= 225)
            return SPELL_DRACTHYR_FLY_SPEED_TIER3_150;
        if (riding >= 150)
            return SPELL_DRACTHYR_FLY_SPEED_TIER2_100;
        if (riding >= 75)
            return SPELL_DRACTHYR_FLY_SPEED_TIER1_60;
        return 0;
    }

    // 四档速度技能一次性全部移除，换挡/落地的时候用，避免旧档位的速度技能残留。
    void ClearDracthyrFlightSpeedAuras(Player* player)
    {
        player->RemoveAurasDueToSpell(SPELL_DRACTHYR_FLY_SPEED_TIER1_60);
        player->RemoveAurasDueToSpell(SPELL_DRACTHYR_FLY_SPEED_TIER2_100);
        player->RemoveAurasDueToSpell(SPELL_DRACTHYR_FLY_SPEED_TIER3_150);
        player->RemoveAurasDueToSpell(SPELL_DRACTHYR_FLY_SPEED_TIER4_300);
    }

    // "是不是在飞"，直接看有没有那个"能飞"能力buff，不用另外维护一份状态。
    bool IsDracthyrFlying(Player* player)
    {
        return player->HasAura(SPELL_DRACTHYR_FLY_CAPABILITY);
    }

    // 变回原形(或任何离开龙形态的路径)/落地时收回飞行能力。
    void RevokeDracthyrFlight(Player* player)
    {
        player->RemoveAurasDueToSpell(SPELL_DRACTHYR_FLY_CAPABILITY);
        ClearDracthyrFlightSpeedAuras(player);
    }

    // 真正的起飞逻辑：给"能飞"能力 + 按骑术挑对应档位速度技能。
    void TakeOffDracthyrFlight(Player* player)
    {
        uint32 speedSpellId = GetDracthyrFlightSpeedSpellId(player);
        if (speedSpellId == 0)
        {
            player->GetSession()->SendAreaTriggerMessage("骑术等级不够，至少需要学徒级骑术(75)才能飞行！");
            LOG_INFO("server", "TwoForms: Race27 Dracthyr {} tried to fly without enough riding skill", player->GetName());
            return;
        }

        // 诺森德必须学过"寒冷天气飞行"才能飞，跟真坐骑规则一致(外域/东部王国/
        // 卡利姆多不受这条限制，骑术够就能飞)。
        if (player->GetMapId() == MAP_NORTHREND && !player->HasSpell(SPELL_COLD_WEATHER_FLYING))
        {
            player->GetSession()->SendAreaTriggerMessage("需要学会寒冷天气飞行才能在诺森德飞行！");
            LOG_INFO("server", "TwoForms: Race27 Dracthyr {} tried to fly in Northrend without Cold Weather Flying", player->GetName());
            return;
        }

        Aura* capabilityAura = player->AddAura(SPELL_DRACTHYR_FLY_CAPABILITY, player);

        // SetMaxDuration/SetDuration强制永久，防止哪档技能自己在DBC里带了个
        // 短暂持续时间(之前44423就踩过这个坑，4秒后掉速度)。
        Aura* speedAura = player->AddAura(speedSpellId, player);
        if (speedAura)
        {
            speedAura->SetMaxDuration(-1);
            speedAura->SetDuration(-1);
        }

        // ★诊断日志：低档位骑术(75/150/225)反馈"没有buff图标显示"，先确认清楚
        // 到底是AddAura本身就没成功(返回空指针)，还是加成功了只是客户端不画出来——
        // 这两种是完全不同的bug，得先看这行日志才能确定往哪个方向修。
        LOG_INFO("server", "TwoForms: Race27 Dracthyr {} flight aura debug - capabilityAura={} speedAura={} HasAura(cap)={} HasAura(speed)={}",
            player->GetName(),
            capabilityAura ? "OK" : "NULL",
            speedAura ? "OK" : "NULL",
            player->HasAura(SPELL_DRACTHYR_FLY_CAPABILITY),
            player->HasAura(speedSpellId));

        player->GetSession()->SendAreaTriggerMessage("御空而起！");
        LOG_INFO("server", "TwoForms: Race27 Dracthyr {} took flight (speed spell {})", player->GetName(), speedSpellId);
    }

    // 御空术现在是"骑坐骑同款"的开关式技能：龙形态+没在飞 -> 起飞；
    // 已经在飞 -> 再点一次就是降落，跟点一下骑乘坐骑技能上马、再点一下下马
    // 是同一个交互逻辑。
    void ToggleDracthyrFlight(Player* player)
    {
        if (IsDracthyrFlying(player))
        {
            RevokeDracthyrFlight(player);
            player->GetSession()->SendAreaTriggerMessage("降落。");
            LOG_INFO("server", "TwoForms: Race27 Dracthyr {} landed", player->GetName());
            return;
        }

        TakeOffDracthyrFlight(player);
    }

    void SetDracthyrDisplay(Player* player, uint32 displayId)
    {
        bool dragonForm = IsDracthyrDragonDisplay(displayId);

        // Keep native display as visage. Only current display changes.
        // This avoids forcing normal equipment meshes onto the Sirus dragon body.
        player->SetNativeDisplayId(GetDracthyrVisageDisplayId(player));
        player->SetDisplayId(displayId);
        ApplyDracthyrVisibleMode(player, dragonForm ? DracthyrVisibleMode::Dragon : DracthyrVisibleMode::Normal, true);
        player->SetSheath(player->GetSheath());

        // 只要不是龙形态了(切回原形/被打断/退出等任何路径最终都会走到这里)，
        // 飞行能力必须一起收回，不然会出现"变回人形还能飞"的bug。
        if (!dragonForm)
            RevokeDracthyrFlight(player);
    }

    void ResetDracthyrDragonForm(Player* player)
    {
        uint64 key = GetDracthyrStateKey(player);
        DracthyrVisibleModes.erase(key);
        ClearDracthyrDragonFormAuraState(player);
        player->RemoveAurasDueToSpell(SPELL_DRACTHYR_DRAGON_FORM);
        SetDracthyrDisplay(player, GetDracthyrVisageDisplayId(player));
    }

    void TeachDracthyrDragonForm(Player* player, char const* reason)
    {
        if (!player->HasSpell(SPELL_DRACTHYR_DRAGON_FORM))
        {
            player->learnSpell(SPELL_DRACTHYR_DRAGON_FORM, false);
            LOG_INFO("server", "TwoForms: Race27 Dracthyr learns Dragon Form ({}) on {}", SPELL_DRACTHYR_DRAGON_FORM, reason);
        }
    }

    // 出生就学会音爆(Skyburst)本身——但现在这个技能"能不能飞"要看施法那一刻在不在
    // 龙形态，判断逻辑在OnPlayerSpellCast里，不在这里。59553已按要求整个删掉，不再教。
    void TeachDracthyrFlightSpell(Player* player, char const* reason)
    {
        if (!player->HasSpell(SPELL_DRACTHYR_FLIGHT_ACTIVATE))
        {
            player->learnSpell(SPELL_DRACTHYR_FLIGHT_ACTIVATE, false);
            LOG_INFO("server", "TwoForms: Race27 Dracthyr learns Skyburst ({}) on {}", SPELL_DRACTHYR_FLIGHT_ACTIVATE, reason);
        }
    }

    // 娜迦种族出生技能：水下呼吸(100301)+游泳加速(100302)，都是自定义的被动+永久技能
    // (克隆5227模板做的)。跟双形态(learnSpell)同一个套路——学一次，spellbook里常驻一个
    // 被动图标，效果自动一直生效，不需要像限时buff那样反复补。
    void TeachNagaWaterBreathing(Player* player, char const* reason)
    {
        if (!player->HasSpell(SPELL_NAGA_WATER_BREATHING))
        {
            player->learnSpell(SPELL_NAGA_WATER_BREATHING, false);
            LOG_INFO("server", "TwoForms: Race25 Naga learns Water Breathing ({}) on {}", SPELL_NAGA_WATER_BREATHING, reason);
        }

        if (!player->HasSpell(SPELL_NAGA_SWIM_SPEED))
        {
            player->learnSpell(SPELL_NAGA_SWIM_SPEED, false);
            LOG_INFO("server", "TwoForms: Race25 Naga learns Swim Speed ({}) on {}", SPELL_NAGA_SWIM_SPEED, reason);
        }
    }
}

class TwoForms : public PlayerScript
{
public:
    TwoForms() : PlayerScript("TwoForms")
    {
        LOG_INFO("server", "TwoForms PlayerScript registered!");
    }

    void OnPlayerFirstLogin(Player* player) override
    {
        uint8 race = player->getRace();
        uint8 gender = player->GetByteValue(PLAYER_BYTES_3, PLAYER_BYTES_3_OFFSET_GENDER);

        LOG_INFO("server", "TwoForms: OnPlayerFirstLogin triggered for player {} (Race: {}, Gender: {})",
            player->GetName(), (uint32)race, (uint32)gender);

        if (race == RACE_WORGEN_CUSTOM)
        {
            uint32 spellId = (gender == GENDER_FEMALE) ? SPELL_WORGEN_TWO_FORMS_FEMALE : SPELL_WORGEN_TWO_FORMS_MALE;
            LOG_INFO("server", "TwoForms: Player is Worgen, teaching spell ID: {}", spellId);
            player->learnSpell(spellId, false);

            // Worgen extra racial spells are managed by the Heritage menu in this repack.
            // Keep only Two Forms here.
        }
        else if (race == RACE_DRACTHYR_CUSTOM)
        {
            TeachDracthyrDragonForm(player, "first login");
            TeachDracthyrFlightSpell(player, "first login");
        }
        else if (race == RACE_NAGA_CUSTOM)
        {
            TeachNagaWaterBreathing(player, "first login");
        }
        else
        {
            LOG_INFO("server", "TwoForms: Player is not Worgen or Dracthyr (Race is {}), skipping.", (uint32)race);
        }
    }

    void OnPlayerLogin(Player* player) override
    {
        if (player->getRace() == RACE_NAGA_CUSTOM)
        {
            TeachNagaWaterBreathing(player, "login");
            // 立刻套用娜迦种族游泳加速(+150%)，不用等下水时的某个事件触发重算。
            player->UpdateSpeed(MOVE_SWIM, true);
        }

        if (player->getRace() != RACE_DRACTHYR_CUSTOM)
            return;

        player->LearnDefaultSkills();
        ResetDracthyrDragonForm(player);
        TeachDracthyrDragonForm(player, "login");
        TeachDracthyrFlightSpell(player, "login");
    }

    // 之前"地图切换后人形也能飞"那个bug的根因：切地图这类场景不一定会走
    // SetDracthyrDisplay这个函数，导致飞行能力可能残留。这里专门在切地图这个
    // 时机再做一次强制清理，双重保险(不管有没有经过SetDracthyrDisplay，切图
    // 之后只要不是龙形态，飞行能力必须清掉)。
    void OnPlayerMapChanged(Player* player) override
    {
        if (player->getRace() != RACE_DRACTHYR_CUSTOM)
            return;

        if (!IsDracthyrDragonDisplay(player->GetDisplayId()) && IsDracthyrFlying(player))
        {
            RevokeDracthyrFlight(player);
            LOG_INFO("server", "TwoForms: Race27 Dracthyr {} had stale flight cleared after map change", player->GetName());
        }
    }

    void OnPlayerSpellCast(Player* player, Spell* spell, bool /*skipCheck*/) override
    {
        if (!spell || player->getRace() != RACE_DRACTHYR_CUSTOM)
            return;

        SpellInfo const* spellInfo = spell->GetSpellInfo();
        if (!spellInfo)
            return;

        // 御空术：真正的"能不能施放"拦截已经挪到下面spell_dracthyr_skyburst_gate
        // 那个SpellScript的OnCheckCast里了(施法前拦，不会浪费CD/不会触发冲刺效果)。
        // 走到这里说明前置检查已经全部通过(龙形态+没骑乘+骑术够)，交给开关逻辑：
        // 没在飞->起飞，已经在飞->降落。
        if (spellInfo->Id == SPELL_DRACTHYR_FLIGHT_ACTIVATE)
        {
            ToggleDracthyrFlight(player);
            return;
        }

        if (spellInfo->Id != SPELL_DRACTHYR_DRAGON_FORM)
            return;

        // 飞行状态下不能切换形态(跟骑乘坐骑的时候不能变身一个道理，总不能飞到
        // 一半突然变回人形摔下去)，必须先用御空术降落。
        if (IsDracthyrFlying(player))
        {
            player->GetSession()->SendAreaTriggerMessage("飞行状态下不能切换形态，请先使用御空术降落！");
            LOG_INFO("server", "TwoForms: Race27 Dracthyr {} tried to toggle form while flying", player->GetName());
            return;
        }

        if (player->HasAura(SPELL_WARLOCK_METAMORPHOSIS))
        {
            QueueDracthyrDragonFormAuraCancel(player);
            LOG_INFO("server", "TwoForms: Race27 Dracthyr {} ignored Dragon Form while Metamorphosis is active", player->GetName());
            return;
        }

        bool currentlyDragon = IsDracthyrDragonDisplay(player->GetDisplayId());
        uint32 nextDisplayId = currentlyDragon ? GetDracthyrVisageDisplayId(player) : GetDracthyrDragonDisplayId(player);

        SetDracthyrDisplay(player, nextDisplayId);

        if (currentlyDragon)
            QueueDracthyrDragonFormAuraCancel(player);
        else
            StartDracthyrDragonFormAuraSync(player);

        LOG_INFO("server", "TwoForms: Race27 Dracthyr {} toggled Dragon Form to {} display {} (skin={}, visageSkinGroup={}, visageSkinShade={}, dragonSkin={}, armorVariant={}, gender={})",
            player->GetName(),
            currentlyDragon ? "visage" : "dragon",
            nextDisplayId,
            player->GetByteValue(PLAYER_BYTES, PLAYER_BYTES_OFFSET_SKIN_ID),
            GetDracthyrVisageSkinColorGroup(player),
            GetDracthyrVisageSkinShade(player),
            GetDracthyrDragonSkinVariant(player),
            GetDracthyrDragonArmorVariant(player),
            (uint32)GetDracthyrOriginalGender(player));
    }

    void OnPlayerAfterSetVisibleItemSlot(Player* player, uint8 slot, Item* item) override
    {
        if (!item || player->getRace() != RACE_DRACTHYR_CUSTOM)
            return;

        if (player->HasAura(SPELL_WARLOCK_METAMORPHOSIS))
            return;

        if (!IsDracthyrDragonDisplay(player->GetDisplayId()) || IsWeaponEquipmentSlot(slot))
            return;

        // Sirus dragon form uses baked body/armor textures. Gear remains equipped
        // and keeps stats, but non-weapon visible item models are hidden.
        player->SetVisibleItemSlot(slot, nullptr);
    }

    void OnPlayerUpdate(Player* player, uint32 diff) override
    {
        // 娜迦水下呼吸(5227)是学一次永久生效的被动技能，不需要像限时buff那样
        // 每帧检查续期，OnPlayerFirstLogin/OnPlayerLogin里学过就够了。

        if (player->getRace() != RACE_DRACTHYR_CUSTOM)
            return;

        // 兜底安全网：不管是什么原因(切图/掉线重登/其他没预料到的路径)导致
        // "不是龙形态却还挂着飞行能力"这种不一致状态，这里每帧都会发现并清掉，
        // 不依赖某一个特定函数一定会被调用到。
        if (!IsDracthyrDragonDisplay(player->GetDisplayId()) && IsDracthyrFlying(player))
            RevokeDracthyrFlight(player);

        if (player->HasAura(SPELL_WARLOCK_METAMORPHOSIS))
            return;

        bool cancelPending = TickDracthyrDragonFormAuraCancel(player, diff);
        bool waitingForAura = TickDracthyrDragonFormAuraSync(player, diff);
        bool dragonDisplay = IsDracthyrDragonDisplay(player->GetDisplayId());

        if (dragonDisplay)
        {
            if (!cancelPending && !waitingForAura && !player->HasAura(SPELL_DRACTHYR_DRAGON_FORM))
            {
                LOG_INFO("server", "TwoForms: Race27 Dracthyr {} returned to visage because Dragon Form aura was removed", player->GetName());
                SetDracthyrDisplay(player, GetDracthyrVisageDisplayId(player));
                return;
            }

            ApplyDracthyrVisibleMode(player, DracthyrVisibleMode::Dragon);
            return;
        }

        if (player->HasAura(SPELL_DRACTHYR_DRAGON_FORM))
            player->RemoveAurasDueToSpell(SPELL_DRACTHYR_DRAGON_FORM);

        ApplyDracthyrVisibleMode(player, DracthyrVisibleMode::Normal);
    }

    void OnPlayerBeforeLogout(Player* player) override
    {
        if (player->getRace() == RACE_DRACTHYR_CUSTOM)
            ResetDracthyrDragonForm(player);
    }

    void OnPlayerLogout(Player* player) override
    {
        if (player->getRace() == RACE_DRACTHYR_CUSTOM)
            ResetDracthyrDragonForm(player);
    }
};

// 音爆(Skyburst, 100210)真正的"能不能施放"拦截。用SpellScript的OnCheckCast，
// 这个钩子在施法真正生效之前跑，返回失败码就能把整次施法拦下来——
// 不会进CD、技能自带的冲刺/缓降效果也不会触发，这才是之前"人形态/骑乘状态下
// 也能用、还进CD"那个bug的真正修法(之前用PlayerScript::OnPlayerSpellCast只能
// "事后"反应，拦不住已经发生的效果)。
class spell_dracthyr_skyburst_gate : public SpellScriptLoader
{
public:
    spell_dracthyr_skyburst_gate() : SpellScriptLoader("spell_dracthyr_skyburst_gate") { }

    class spell_dracthyr_skyburst_gate_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_dracthyr_skyburst_gate_SpellScript);

        SpellCastResult CheckDracthyrFlightConditions()
        {
            Player* caster = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
            if (!caster || caster->getRace() != RACE_DRACTHYR_CUSTOM)
                return SPELL_CAST_OK; // 理论上只有龙希尔学得到这个技能，这里是双保险

            if (caster->IsMounted())
            {
                caster->GetSession()->SendAreaTriggerMessage("骑乘状态下不能使用这个技能！");
                return SPELL_FAILED_DONT_REPORT; // 静默拦截，不进CD，不弹官方红字
            }

            if (!IsDracthyrDragonDisplay(caster->GetDisplayId()))
            {
                caster->GetSession()->SendAreaTriggerMessage("需要切换到龙形态才能使用这个技能！");
                return SPELL_FAILED_DONT_REPORT;
            }

            if (GetDracthyrFlightSpeedSpellId(caster) == 0)
            {
                caster->GetSession()->SendAreaTriggerMessage("骑术等级不够，至少需要学徒级骑术(75)才能飞行！");
                return SPELL_FAILED_DONT_REPORT;
            }

            if (caster->GetMapId() == MAP_NORTHREND && !caster->HasSpell(SPELL_COLD_WEATHER_FLYING))
            {
                caster->GetSession()->SendAreaTriggerMessage("需要学会寒冷天气飞行才能在诺森德飞行！");
                return SPELL_FAILED_DONT_REPORT;
            }

            return SPELL_CAST_OK;
        }

        void Register() override
        {
            OnCheckCast += SpellCheckCastFn(spell_dracthyr_skyburst_gate_SpellScript::CheckDracthyrFlightConditions);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_dracthyr_skyburst_gate_SpellScript();
    }
};

void AddSC_TwoForms()
{
    new TwoForms();
    new spell_dracthyr_skyburst_gate();
}
