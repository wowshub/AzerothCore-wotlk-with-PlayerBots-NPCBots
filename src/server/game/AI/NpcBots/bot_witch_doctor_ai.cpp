// WDN1A: controlled NPCBot Shadowhunting foundation, not a Playerbot context.
#include "bot_ai.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellMgr.h"
#include "Log.h"
#include "../../../../../modules/mod-reborn-witchdoctor/src/RebornWitchDoctorNpcActor1.h"
#include "../../../../../modules/mod-reborn-witchdoctor/src/RebornWitchDoctorNpcWard1.h"

namespace
{
constexpr uint32 Arrow=9003970, Reclamation=9003980, Eclipse=9004000, Glaive=9004030;
std::vector<uint32> const damageSpells={Arrow,Reclamation,Eclipse,Glaive,WDN1::AutoShot};
}
class witch_doctor_bot : public CreatureScript
{
public:
    witch_doctor_bot() : CreatureScript("witch_doctor_bot") { }
    CreatureAI* GetAI(Creature* c) const override { return new witch_doctor_botAI(c); }
    bool OnGossipHello(Player* p,Creature* c) override { return c->GetBotAI()->OnGossipHello(p,0); }
    bool OnGossipSelect(Player* p,Creature* c,uint32 sender,uint32 action) override
    { if(auto* ai=c->GetBotAI())return ai->OnGossipSelect(p,c,sender,action);return true; }
    bool OnGossipSelectCode(Player* p,Creature* c,uint32 sender,uint32 action,char const* code) override
    { if(auto* ai=c->GetBotAI())return ai->OnGossipSelectCode(p,c,sender,action,code);return true; }

    struct witch_doctor_botAI : public bot_ai
    {
        uint32 spiritOwner=0,spiritMap=0,diagnosticTimer=0;
        void Trace(char const* reason,uint32 spell=0,int32 result=0)
        {
            if(diagnosticTimer||IAmFree())return;
            Player* owner=GetBotOwner();
            if(!me->IsInCombat()&&!(owner&&owner->IsInCombat())&&
               !IsActionNext(NpcBotActionTypes::BOT_ACTION_PULL))return;
            diagnosticTimer=10000;
            LOG_ERROR("npcbots", "[WDN1D3] entry={} owner={} gate={} spell={} result={} commands={} mana={}/{} arrow={} reclaim={}",
                me->GetEntry(),GetBotOwnerGuid(),reason,spell,result,GetBotCommandState(),
                me->GetPower(POWER_MANA),me->GetMaxPower(POWER_MANA),GetSpell(Arrow),GetSpell(Reclamation));
        }
        explicit witch_doctor_botAI(Creature* c) : bot_ai(c)
        { _botclass=BOT_CLASS_WITCH_DOCTOR;InitUnitFlags();LOG_ERROR("npcbots", "[WDN1D3] initialized entry={}",me->GetEntry()); }

        void Reset() override { WDN1C::Clear(me); me->RemoveAurasDueToSpell(WDN1::Spirit,me->GetGUID());DefaultInit(); }
        void JustDied(Unit* killer) override
        { WDN1C::Clear(me);me->RemoveAurasDueToSpell(WDN1::Spirit,me->GetGUID());bot_ai::JustDied(killer); }
        void InitPowers() override { me->SetPowerType(POWER_MANA);bot_ai::InitPowers(); }
        void ApplyClassPassives() const override { } // No Hunter or Player talent inheritance.

        template<std::size_t N> void InitFamily(uint32 base,WD19A::Rank const(&ranks)[N])
        {
            uint32 best=0;
            for(auto const& rank:ranks)if(me->GetLevel()>=rank.level)best=rank.spell;
            InitSpellMap(base,true,false);
            auto const& spells=GetSpellMap();auto it=spells.find(base);
            if(it!=spells.end()&&it->second)it->second->spellId=best;
        }
        void InitSpells() override
        {
            InitSpellMap(WDN1C::SpellId,true,false);
            auto* wardInfo=sSpellMgr->GetSpellInfo(WDN1C::SpellId);
            auto const& wardMap=GetSpellMap();auto ward=wardMap.find(WDN1C::SpellId);
            if(ward!=wardMap.end()&&ward->second)
                ward->second->spellId=wardInfo&&me->GetLevel()>=wardInfo->SpellLevel?WDN1C::SpellId:0;
            InitSpellMap(WDN1::AutoShot,true,false);
            auto const& spells=GetSpellMap();auto shot=spells.find(WDN1::AutoShot);
            if(shot!=spells.end()&&shot->second)shot->second->spellId=me->GetLevel()>=10?WDN1::AutoShot:0;
            InitFamily(Arrow,WD19A::Arrow143Ranks);
            InitFamily(Reclamation,WD19A::Reclamation143Ranks);
            InitFamily(Eclipse,WDN1::EclipseRanks);
            InitFamily(Glaive,WDN1::GlaiveRanks);
        }
        bool CastOffensive(Unit* target,uint32 base)
        {
            uint32 spell=GetSpell(base);
            if(!spell||!WDN1::Known(me,spell)||!WDN1::Safe(me,target))
            { Trace("spell-qualification",spell);return false; }
            SpellCastResult result=CheckBotCast(target,spell);
            if(result!=SPELL_CAST_OK){Trace("check-bot-cast",spell,int32(result));return false;}
            bool cast=bot_ai::doCast(target,spell); // Native cost, cast checks, GCD and cooldowns.
            Trace(cast?"cast-started":"do-cast-rejected",spell);
            return cast;
        }
        bool CastGlaive(Unit* target)
        {
            uint32 spell=GetSpell(Glaive);auto* info=sSpellMgr->GetSpellInfo(spell);
            if(!spell||!info||!WDN1::Known(me,spell)||!WDN1::Safe(me,target))return false;
            // The cone's real reach comes from EffectRadius, not its self range entry.
            float radius=info->Effects[EFFECT_0].CalcRadius(me);
            if(radius<=0||!me->IsWithinDistInMap(target,radius)||CheckBotCast(me,spell)!=SPELL_CAST_OK)return false;
            me->SetInFront(target);
            return bot_ai::doCast(me,spell);
        }
        void KeepAutoShot(Unit* target)
        {
            uint32 spell=GetSpell(WDN1::AutoShot);
            SpellInfo const* info=spell?sSpellMgr->GetSpellInfo(spell):nullptr;
            Spell const* current=me->GetCurrentSpell(CURRENT_AUTOREPEAT_SPELL);
            bool ready=info&&WDN1::Known(me,spell)&&HasRole(NPC_BOT_ROLE_DPS)&&
                HasRole(NPC_BOT_ROLE_RANGED)&&!me->isMoving()&&WDN1::Safe(me,target)&&
                me->GetDistance(target)>info->GetMinRange(false)&&
                me->GetDistance(target)<=CalcSpellMaxRange(spell);
            if(current&&current->GetSpellInfo()->Id==WDN1::AutoShot&&
                (!ready||current->m_targets.GetUnitTarget()!=target))
            {me->InterruptSpell(CURRENT_AUTOREPEAT_SPELL);current=nullptr;}
            if(!ready||current)return;
            // The native autorepeat timer fires subsequent arrows; never re-cast it every AI tick.
            CastOffensive(target,WDN1::AutoShot);
        }
        void OnClassSpellGo(SpellInfo const* info) override
        {
            // Explicit private rank families need a stable cooldown key even on
            // databases without the optional spell_chain rows for these ranks.
            uint32 base=WDN1::Base(info->Id);
            if(base==Arrow||base==Reclamation||base==Eclipse||base==Glaive)
            {
                uint32 cooldown=info->GetRecoveryTime();
                ApplyBotSpellCooldownMods(info,cooldown);
                SetSpellCooldown(base,cooldown);
            }
        }
        void UpdateAI(uint32 diff) override
        {
            if(spiritOwner!=GetBotOwnerGuid()||spiritMap!=me->GetMapId())
            {
                me->RemoveAurasDueToSpell(WDN1::Spirit,me->GetGUID());
                WDN1C::Clear(me);
                spiritOwner=GetBotOwnerGuid();spiritMap=me->GetMapId();
            }
            WDN1C::Current(me); // Clear on lost recruitment, role, skill, map or distance.
            diagnosticTimer=diagnosticTimer>diff?diagnosticTimer-diff:0;
            if(!GlobalUpdate(diff)){Trace("global-update");return;}
            if(IAmFree()||!WDN1::Actor(me))
            { me->InterruptSpell(CURRENT_AUTOREPEAT_SPELL);me->RemoveAurasDueToSpell(WDN1::Spirit,me->GetGUID());return; }
            DoVehicleActions(diff);
            if(!CanBotAttackOnVehicle()||ProcessImmediateNonAttackTarget()){Trace("vehicle-or-immediate");return;}
            if(!CheckAttackTarget())
            { Trace("no-native-target");me->InterruptSpell(CURRENT_AUTOREPEAT_SPELL);return; }
            Unit* target=opponent?opponent:disttarget;
            if(!target||!WDN1::Engaged(me,target))
            { Trace("engagement");me->InterruptSpell(CURRENT_AUTOREPEAT_SPELL);return; }
            if(IsCasting()||!HasRole(NPC_BOT_ROLE_DPS)){if(!HasRole(NPC_BOT_ROLE_DPS))me->InterruptSpell(CURRENT_AUTOREPEAT_SPELL);Trace("casting-or-role");return;}
            // False also means "already attacking"; it must not suppress the rotation.
            bot_ai::StartAttack(target,false);
            bool pulling=IsActionNext(NpcBotActionTypes::BOT_ACTION_PULL,0,target->GetGUID());
            SpellInfo const* opener=sSpellMgr->GetSpellInfo(GetSpell(Arrow));
            bool pullInRange=pulling&&opener&&WDN1::Safe(me,target)&&
                me->GetDistance(target)>opener->GetMinRange(false)&&
                me->GetDistance(target)<=CalcSpellMaxRange(GetSpell(Arrow));
            if(pullInRange)
            {
                // A pull needs one settled first shot, not a new random attack point each tick.
                if(!JumpingOrFalling()&&me->isMoving())me->BotStopMovement();
            }
            else GetInPosition(pulling&&!me->isMoving(),target); // Keep native STAY/positioning checks.
            if(me->isMoving()||!WDN1::Safe(me,target)){Trace("moving-or-unsafe");return;}
            KeepAutoShot(target);
            if(!pulling&&me->IsInCombatWith(target)&&me->IsWithinDistInMap(target,28.0f)&&
               WDN1C::Known(me)&&!WDN1C::Current(me)&&IsSpellReady(WDN1C::SpellId,diff)&&
               CheckBotCast(me,WDN1C::SpellId)==SPELL_CAST_OK&&bot_ai::doCast(me,WDN1C::SpellId))return;
            if(WDN1::Count(me)<5&&IsSpellReady(Reclamation,diff)&&CastOffensive(target,Reclamation))return;
            if(WDN1::Count(me)==5&&IsSpellReady(Eclipse,diff)&&!target->HasAura(GetSpell(Eclipse),me->GetGUID())&&CastOffensive(target,Eclipse))return;
            if(IsSpellReady(Glaive,diff)&&CastGlaive(target))return;
            if(IsSpellReady(Arrow,diff))CastOffensive(target,Arrow);
        }
        std::vector<uint32> const* GetDamagingSpellsList() const override { return &damageSpells; }
    };
};
void AddSC_witch_doctor_bot() { new witch_doctor_bot(); }
