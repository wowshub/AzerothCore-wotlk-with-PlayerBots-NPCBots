#include <algorithm>
#include <initializer_list>
#include <cstdint>
using uint32=uint32_t; using int32=int32_t;
enum {EFFECT_0, SPELLMOD_COOLDOWN, TRIGGERED_IGNORE_SPELL_AND_CATEGORY_CD, TRIGGERED_IGNORE_EFFECTS, SPELL_COOLDOWN_FLAG_NONE};
struct SpellModifier {int op;};
struct AuraEffect {SpellModifier* GetSpellModifier(){return nullptr;}};
struct Info {uint32 Id=0; bool IsPassive(){return false;} bool IsCooldownStartedOnEvent(){return false;}};
struct WorldPacket {};
struct Player {
 int getClass(){return 13;} bool HasAura(uint32){return true;}
 AuraEffect* GetAuraEffect(uint32,int){return nullptr;}
 bool IsAffectedBySpellmod(Info*,SpellModifier*,void*){return true;}
 uint32 GetSpellCooldownDelay(uint32){return 10000;}
 void SendClearCooldown(uint32,Player*){} void BuildCooldownPacket(WorldPacket&,int,uint32,uint32){} void SendDirectMessage(WorldPacket*){}
};
struct Caster {Player* ToPlayer(){return nullptr;}};
struct Spell {Caster* m_caster=nullptr;Info* m_spellInfo=nullptr;void* m_CastItem=nullptr;
 void SendSpellGo(){} bool HasTriggeredCastFlag(int){return false;}
 void Test(){
    SendSpellGo();

    // WD63E: correct server-only Hastened prediction AFTER SMSG_SPELL_GO.
    // SPELL_GO can start the client's unmodified DBC cooldown. Replace only
    // that client's timer; never recalculate or erase the server cooldown.
    if (Player* player = m_caster->ToPlayer())
    {
        if (player->getClass() == 13 && !m_CastItem &&
            !m_spellInfo->IsPassive() && !m_spellInfo->IsCooldownStartedOnEvent() &&
            !HasTriggeredCastFlag(TRIGGERED_IGNORE_SPELL_AND_CATEGORY_CD) &&
            !HasTriggeredCastFlag(TRIGGERED_IGNORE_EFFECTS))
        {
            // WD121B: Gonk has the same server-only prediction issue as Hastened.
            // AddSpellAndCategoryCooldowns runs BEFORE SPELL_GO; its earlier packet
            // can be replaced by the client's base DBC timer when SPELL_GO arrives.
            // WD127F: both potion families need the same post-GO correction.
            // Use the cooldown already stored by Player; do not subtract twice.
            bool exactCooldown = ((m_spellInfo->Id >= 9003870 && m_spellInfo->Id <= 9003876) ||
                                  (m_spellInfo->Id >= 9003890 && m_spellInfo->Id <= 9003896)) &&
                                 player->HasAura(9003897);
            for (uint32 source : {9003653u, 9003862u})
            {
                if (source == 9003862 && m_spellInfo->Id != 9003861)
                    continue;
                AuraEffect* effect = player->GetAuraEffect(source, EFFECT_0);
                SpellModifier* modifier = effect ? effect->GetSpellModifier() : nullptr;
                if (modifier && modifier->op == SPELLMOD_COOLDOWN &&
                    player->IsAffectedBySpellmod(m_spellInfo, modifier, this))
                {
                    exactCooldown = true;
                    break;
                }
            }
            if (exactCooldown)
            {
                uint32 remaining = player->GetSpellCooldownDelay(m_spellInfo->Id);
                if (remaining)
                {
                    player->SendClearCooldown(m_spellInfo->Id, player);
                    WorldPacket cooldown;
                    player->BuildCooldownPacket(cooldown, SPELL_COOLDOWN_FLAG_NONE,
                        m_spellInfo->Id, remaining);
                    player->SendDirectMessage(&cooldown);
                }
            }
        }
    }

} };
constexpr int32 clamp(int32 rec,uint32 base){return std::min<int32>(rec,std::max<int32>(0,int32(base)-5000));}
static_assert(clamp(10000,15000)==10000,"no double reduction");
static_assert(clamp(15000,15000)==10000,"fallback");
static_assert(clamp(8000,15000)==8000,"preserve stronger modifiers");
static_assert(clamp(0,15000)==0,"zero");
