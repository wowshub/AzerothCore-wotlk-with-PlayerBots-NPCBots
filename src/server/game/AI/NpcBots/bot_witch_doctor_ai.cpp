// WDN1A: controlled NPCBot Shadowhunting foundation, not a Playerbot context.
#include "bot_ai.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellMgr.h"
#include "Log.h"
#include "../../../../../modules/mod-reborn-witchdoctor/src/RebornWitchDoctorNpcBrewing2.h"
#include "../../../../../modules/mod-reborn-witchdoctor/src/RebornWitchDoctorNpcBrewEcho2.h"
#include "../../../../../modules/mod-reborn-witchdoctor/src/RebornWitchDoctorNpcActor1.h"
#include "../../../../../modules/mod-reborn-witchdoctor/src/RebornWitchDoctorNpcVoodoo2.h"
#include "../../../../../modules/mod-reborn-witchdoctor/src/RebornWitchDoctorNpcWard1.h"
#include "../../../../../modules/mod-reborn-witchdoctor/src/RebornWitchDoctorNpcDebuff2.h"
#include "../../../../../modules/mod-reborn-witchdoctor/src/RebornWitchDoctorNpcMassWard2.h"
#include "../../../../../modules/mod-reborn-witchdoctor/src/RebornWitchDoctorNpcMimic2.h"
#include "../../../../../modules/mod-reborn-witchdoctor/src/RebornWitchDoctorNpcIdol2.h"
#include "../../../../../modules/mod-reborn-witchdoctor/src/RebornWitchDoctorNpcEffigy2.h"

namespace
{
constexpr uint32 Wrath=9003100,Brew=9003101,Vigil=9003855;
constexpr uint32 Arrow=9003970, Reclamation=9003980, Eclipse=9004000, Glaive=9004030;
std::vector<uint32> const supportSpells={WDN2P::Thistle,WDN2P::Fish,WDN2P::Bones,WDN2O::SpellId,Vigil,WDN2D::Serene,WDN2D::Swift,WDN2D::SpellId,WDN2E::SpellId,WDN2E::Hex,WDN2E::Graven,WDN2E::Cursed};
std::vector<uint32> const healingSpells={WDN2P::Splash,WDN2P::Toss,WDN2P::Prep,Brew,WDN1C::Healing};
std::vector<uint32> const damageSpells={Wrath,Arrow,Reclamation,Eclipse,Glaive,WDN1::AutoShot,WDN2::Hex,WDN2::Lethargy,WDN2::Shrinking,WDN2B::SpellId,WDN2C::SpellId};
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
        bool preferWrath=false;
        uint32 spiritOwner=0,spiritMap=0,diagnosticTimer=0,hexRetry=0,jinxRetry=0,massRetry=0,mimicRetry=0,idolRetry=0,effigyRetry=0,hexEffigyRetry=0,gravenRetry=0,cursedRetry=0,swiftRetry=0,sereneRetry=0,brewingRetry=0,allyBrewRetry=0;
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

        void Reset() override { allyBrewRetry=brewingRetry=0; healingReserve=false;preferWrath=false; hexRetry=jinxRetry=massRetry=mimicRetry=idolRetry=effigyRetry=hexEffigyRetry=gravenRetry=cursedRetry=swiftRetry=sereneRetry=0; WDN2Y::Clear(me);WDN2P::Clear(me);WDN2O::Clear(me);WDN1C::Clear(me);WDN2B::Clear(me);WDN2C::Clear(me);WDN2D::Clear(me);WDN2E::Clear(me); me->RemoveAurasDueToSpell(Vigil,me->GetGUID());me->RemoveAurasDueToSpell(WDN1::Spirit,me->GetGUID());DefaultInit(); }
        void JustDied(Unit* killer) override
        { WDN2Y::Clear(me);WDN2P::Clear(me);WDN2O::Clear(me);WDN1C::Clear(me);WDN2B::Clear(me);WDN2C::Clear(me);WDN2D::Clear(me);WDN2E::Clear(me);me->RemoveAurasDueToSpell(Vigil,me->GetGUID());me->RemoveAurasDueToSpell(WDN1::Spirit,me->GetGUID());bot_ai::JustDied(killer); }
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
            InitSpellMap(WDN2P::Thistle,true,false);
            auto*thistleInfo=sSpellMgr->GetSpellInfo(WDN2P::Thistle);auto const&thistleMap=GetSpellMap();auto thistle=thistleMap.find(WDN2P::Thistle);
            if(thistle!=thistleMap.end()&&thistle->second)thistle->second->spellId=thistleInfo&&me->GetLevel()>=thistleInfo->SpellLevel?WDN2P::Thistle:0;
            InitSpellMap(WDN2P::Fish,true,false);
            auto*fishInfo=sSpellMgr->GetSpellInfo(WDN2P::Fish);auto const&fishMap=GetSpellMap();auto fish=fishMap.find(WDN2P::Fish);
            if(fish!=fishMap.end()&&fish->second)fish->second->spellId=fishInfo&&me->GetLevel()>=fishInfo->SpellLevel?WDN2P::Fish:0;
            InitSpellMap(WDN2P::Bones,true,false);
            auto*bonesInfo=sSpellMgr->GetSpellInfo(WDN2P::Bones);auto const&bonesMap=GetSpellMap();auto bones=bonesMap.find(WDN2P::Bones);
            if(bones!=bonesMap.end()&&bones->second)bones->second->spellId=bonesInfo&&me->GetLevel()>=bonesInfo->SpellLevel?WDN2P::Bones:0;
            InitFamily(WDN2P::Splash,WDN2P::SplashRanks);
            InitFamily(WDN2P::Toss,WDN2P::TossRanks);
            InitSpellMap(WDN2P::Prep,true,false);
            auto*prepInfo=sSpellMgr->GetSpellInfo(WDN2P::Prep);auto const&prepMap=GetSpellMap();auto prep=prepMap.find(WDN2P::Prep);
            if(prep!=prepMap.end()&&prep->second)prep->second->spellId=prepInfo&&me->GetLevel()>=prepInfo->SpellLevel?WDN2P::Prep:0;
            InitSpellMap(WDN2O::SpellId,true,false);
            auto*voodooInfo=sSpellMgr->GetSpellInfo(WDN2O::SpellId);auto const&voodooMap=GetSpellMap();auto voodoo=voodooMap.find(WDN2O::SpellId);
            if(voodoo!=voodooMap.end()&&voodoo->second)voodoo->second->spellId=voodooInfo&&me->GetLevel()>=voodooInfo->SpellLevel?WDN2O::SpellId:0;
            InitSpellMap(WDN1C::Healing,true,false);
            auto* healInfo=sSpellMgr->GetSpellInfo(WDN1C::Healing);auto const& healMap=GetSpellMap();auto heal=healMap.find(WDN1C::Healing);
            if(heal!=healMap.end()&&heal->second)heal->second->spellId=healInfo&&me->GetLevel()>=healInfo->SpellLevel?WDN1C::Healing:0;
            // WDN2M: NPC spell-map authority; never borrow the owner's talent build.
            InitSpellMap(Vigil,true,false);
            auto* vigilInfo=sSpellMgr->GetSpellInfo(Vigil);
            auto const& vigilMap=GetSpellMap();auto vigil=vigilMap.find(Vigil);
            if(vigil!=vigilMap.end()&&vigil->second)
                vigil->second->spellId=vigilInfo&&me->GetLevel()>=vigilInfo->SpellLevel?Vigil:0;
            InitSpellMap(WDN2D::Serene,true,false);
            auto* sereneInfo=sSpellMgr->GetSpellInfo(WDN2D::Serene);auto const& sereneMap=GetSpellMap();auto serene=sereneMap.find(WDN2D::Serene);
            if(serene!=sereneMap.end()&&serene->second)serene->second->spellId=sereneInfo&&me->GetLevel()>=sereneInfo->SpellLevel?WDN2D::Serene:0;
            InitSpellMap(WDN2D::Swift,true,false);
            auto* swiftInfo=sSpellMgr->GetSpellInfo(WDN2D::Swift);auto const& swiftMap=GetSpellMap();auto swift=swiftMap.find(WDN2D::Swift);
            if(swift!=swiftMap.end()&&swift->second)swift->second->spellId=swiftInfo&&me->GetLevel()>=swiftInfo->SpellLevel?WDN2D::Swift:0;
            InitSpellMap(WDN2D::SpellId,true,false);
            auto* idolInfo=sSpellMgr->GetSpellInfo(WDN2D::SpellId);auto const& idolMap=GetSpellMap();auto idol=idolMap.find(WDN2D::SpellId);
            if(idol!=idolMap.end()&&idol->second)idol->second->spellId=idolInfo&&me->GetLevel()>=idolInfo->SpellLevel?WDN2D::SpellId:0;
            InitSpellMap(WDN2E::SpellId,true,false);
            auto* effigyInfo=sSpellMgr->GetSpellInfo(WDN2E::SpellId);auto const& effigyMap=GetSpellMap();auto effigy=effigyMap.find(WDN2E::SpellId);
            if(effigy!=effigyMap.end()&&effigy->second)effigy->second->spellId=effigyInfo&&me->GetLevel()>=effigyInfo->SpellLevel?WDN2E::SpellId:0;
            InitSpellMap(WDN2E::Hex,true,false);
            auto* hexInfo=sSpellMgr->GetSpellInfo(WDN2E::Hex);auto hex=effigyMap.find(WDN2E::Hex);
            if(hex!=effigyMap.end()&&hex->second)hex->second->spellId=hexInfo&&me->GetLevel()>=hexInfo->SpellLevel?WDN2E::Hex:0;
            InitSpellMap(WDN2E::Graven,true,false);
            auto* gravenInfo=sSpellMgr->GetSpellInfo(WDN2E::Graven);auto graven=effigyMap.find(WDN2E::Graven);
            if(graven!=effigyMap.end()&&graven->second)graven->second->spellId=gravenInfo&&me->GetLevel()>=gravenInfo->SpellLevel?WDN2E::Graven:0;
            InitSpellMap(WDN2E::Cursed,true,false);
            auto* cursedInfo=sSpellMgr->GetSpellInfo(WDN2E::Cursed);auto cursed=effigyMap.find(WDN2E::Cursed);
            if(cursed!=effigyMap.end()&&cursed->second)cursed->second->spellId=cursedInfo&&me->GetLevel()>=cursedInfo->SpellLevel?WDN2E::Cursed:0;
            InitFamily(Wrath,WD19A::WrathRanks);InitFamily(Brew,WD19A::BrewRanks);
            InitSpellMap(WDN2C::SpellId,true,false);
            auto* mimicInfo=sSpellMgr->GetSpellInfo(WDN2C::SpellId);auto const& mimicMap=GetSpellMap();auto mimic=mimicMap.find(WDN2C::SpellId);
            if(mimic!=mimicMap.end()&&mimic->second)mimic->second->spellId=mimicInfo&&me->GetLevel()>=mimicInfo->SpellLevel?WDN2C::SpellId:0;
            InitSpellMap(WDN2B::SpellId,true,false);
            auto* massInfo=sSpellMgr->GetSpellInfo(WDN2B::SpellId);
            auto const& massMap=GetSpellMap();auto mass=massMap.find(WDN2B::SpellId);
            if(mass!=massMap.end()&&mass->second)mass->second->spellId=massInfo&&me->GetLevel()>=massInfo->SpellLevel?WDN2B::SpellId:0;
            InitFamily(WDN2::Hex,WD19A::HexRanks);
            InitFamily(WDN2::Lethargy,WD19A::LethargyRanks);
            InitFamily(WDN2::Shrinking,WD19A::ShrinkingRanks);
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
        bool CastDebuff(Unit* target,uint32 base,uint32 diff,uint32& retry)
        {
            uint32 spell=GetSpell(base);
            if(retry||!spell||!IsSpellReady(base,diff)||!WDN2::Allowed(me,target,spell))return false;
            // Immune/missed/failed casts must not consume every rotation opportunity.
            retry=5000;
            if(CheckBotCast(target,spell)!=SPELL_CAST_OK)return false;
            return bot_ai::doCast(target,spell);
        }
        bool MaintainDebuffs(Unit* target,uint32 diff)
        {
            if(CastDebuff(target,WDN2::Hex,diff,hexRetry))return true;
            if(jinxRetry||WDN2::JinxOccupied(target))return false;
            uint32 preferred=target->IsNonMeleeSpellCast(false,false,true)?WDN2::Lethargy:WDN2::Shrinking;
            if(!GetSpell(preferred)||!WDN2::Known(me,GetSpell(preferred)))
                preferred=preferred==WDN2::Shrinking?WDN2::Lethargy:WDN2::Shrinking;
            return CastDebuff(target,preferred,diff,jinxRetry);
        }
        bool TryCursedEffigy(Unit*target,uint32 diff)
        {
            if(cursedRetry||!WDN2E::CanPlace(me,WDN2E::Cursed)||!IsSpellReady(WDN2E::Cursed,diff)||
               !WDN1::Safe(me,target)||!me->IsWithinDistInMap(target,13.f)||
               uint64(me->GetPower(POWER_MANA))*100<uint64(me->GetMaxPower(POWER_MANA))*30)return false;
            Unit*victim=target->GetVictim();
            if(!victim||!victim->IsAlive()||victim->GetHealthPct()>=65.f||!me->IsFriendlyTo(victim)||
               (victim!=me&&!IsInBotParty(victim)))return false;
            cursedRetry=2000;
            return CheckBotCast(me,WDN2E::Cursed)==SPELL_CAST_OK&&bot_ai::doCast(me,WDN2E::Cursed);
        }
        bool TryHexingEffigy(Unit*target,uint32 diff)
        {
            if(hexEffigyRetry||!WDN2E::CanPlace(me,WDN2E::Hex)||!IsSpellReady(WDN2E::Hex,diff)||!WDN1::Safe(me,target)||
               target->GetVictim()!=me||!target->IsNonMeleeSpellCast(false,false,true)||!me->IsWithinDistInMap(target,28.f)||
               uint64(me->GetPower(POWER_MANA))*100<uint64(me->GetMaxPower(POWER_MANA))*35)return false;
            hexEffigyRetry=2000;
            return CheckBotCast(me,WDN2E::Hex)==SPELL_CAST_OK&&bot_ai::doCast(me,WDN2E::Hex);
        }
        bool TryGravenEffigy(Unit*target,uint32 diff)
        {
            if(gravenRetry||!WDN2E::CanPlace(me,WDN2E::Graven)||!IsSpellReady(WDN2E::Graven,diff)||
               !WDN1::Safe(me,target)||!me->IsWithinDistInMap(target,28.f)||
               !target->HasAuraType(SPELL_AURA_MOD_DECREASE_SPEED)||
               uint64(me->GetPower(POWER_MANA))*100<uint64(me->GetMaxPower(POWER_MANA))*35)return false;
            gravenRetry=2000;
            return CheckBotCast(me,WDN2E::Graven)==SPELL_CAST_OK&&bot_ai::doCast(me,WDN2E::Graven);
        }
        bool TryShadowEffigy(Unit*target,uint32 diff)
        {
            if(effigyRetry||!WDN2E::Known(me)||WDN2E::Current(me)||!IsSpellReady(WDN2E::SpellId,diff)||
               !WDN1::Safe(me,target)||!me->IsWithinDistInMap(target,28.f)||
               uint64(me->GetPower(POWER_MANA))*100<uint64(me->GetMaxPower(POWER_MANA))*35)return false;
            effigyRetry=2000;
            bool useful=target->IsNonMeleeSpellCast(false,false,true);
            if(!useful)
            {
                std::list<Unit*> nearby;GetNearbyTargetsList(nearby,28.f,1);std::vector<ObjectGuid> enemies;
                for(Unit*t:nearby)if(WDN1::Safe(me,t)&&me->IsWithinDistInMap(t,28.f)&&std::find(enemies.begin(),enemies.end(),t->GetGUID())==enemies.end())enemies.push_back(t->GetGUID());
                useful=enemies.size()>=3;
            }
            return useful&&CheckBotCast(me,WDN2E::SpellId)==SPELL_CAST_OK&&bot_ai::doCast(me,WDN2E::SpellId);
        }
        bool TrySereneIdol(uint32 diff)
        {
            if(sereneRetry||IsCasting()||!IsSpellReady(WDN2D::Serene,diff)||
               uint64(me->GetPower(POWER_MANA))*100<uint64(me->GetMaxPower(POWER_MANA))*40)return false;
            sereneRetry=2000;if(!WDN2D::SereneNeeded(me))return false;
            return CheckBotCast(me,WDN2D::Serene)==SPELL_CAST_OK&&bot_ai::doCast(me,WDN2D::Serene);
        }
        bool TrySwiftIdol(uint32 diff)
        {
            if(swiftRetry||IsCasting()||!IsSpellReady(WDN2D::Swift,diff)||
               uint64(me->GetPower(POWER_MANA))*100<uint64(me->GetMaxPower(POWER_MANA))*50)return false;
            swiftRetry=2000;if(!WDN2D::SwiftNeeded(me))return false;
            return CheckBotCast(me,WDN2D::Swift)==SPELL_CAST_OK&&bot_ai::doCast(me,WDN2D::Swift);
        }
        bool TryManaIdol(uint32 diff)
        {
            if(idolRetry||IsCasting()||!IsSpellReady(WDN2D::SpellId,diff))return false;
            idolRetry=2000;
            if(!WDN2D::Needed(me))return false;
            return CheckBotCast(me,WDN2D::SpellId)==SPELL_CAST_OK&&bot_ai::doCast(me,WDN2D::SpellId);
        }
        bool TryVoodoo(uint32 diff)
        {
            if(IsCasting()||!WDN2O::Needed(me)||!IsSpellReady(WDN2O::SpellId,diff)||
               !me->GetMaxPower(POWER_MANA)||uint64(me->GetPower(POWER_MANA))*100<uint64(me->GetMaxPower(POWER_MANA))*30)return false;
            return CheckBotCast(me,WDN2O::SpellId)==SPELL_CAST_OK&&bot_ai::doCast(me,WDN2O::SpellId);
        }
        bool TrySplash(uint32 diff)
        {
            uint32 spell=GetSpell(WDN2P::Splash);
            if(IsCasting()||!WDN2P::Prepared(me)||!WDN2P::Known(me,spell)||!IsSpellReady(WDN2P::Splash,diff)||
               !me->GetMaxPower(POWER_MANA)||uint64(me->GetPower(POWER_MANA))*100<uint64(me->GetMaxPower(POWER_MANA))*35)return false;
            Unit*anchor=WDN2P::SplashAnchor(me);if(!anchor)return false;
            // Native InitExplicitTargets copies this ally's location to the ground destination.
            // doCast preserves normal 20% base-mana cost, prepare checks, GCD and cooldown.
            return CheckBotCast(anchor,spell)==SPELL_CAST_OK&&bot_ai::doCast(anchor,spell);
        }
        bool healingReserve=false;
        bool ReserveHealingMana()
        {
            // WDN2T: role policy only; never change native spell costs or cooldowns.
            uint32 maximum=me->GetMaxPower(POWER_MANA);
            if(!HasRole(NPC_BOT_ROLE_HEAL)||!maximum){healingReserve=false;return false;}
            uint64 current=uint64(me->GetPower(POWER_MANA))*100;
            if(current<=uint64(maximum)*40)healingReserve=true;
            else if(current>=uint64(maximum)*60)healingReserve=false;
            return healingReserve;
        }
        bool TryBrewing(uint32 diff)
        {
            if(brewingRetry||IsCasting()||!WDN2P::Active(me)||!WDN2P::Selected(me))return false;
            brewingRetry=1000; // Bound grid scans and rejected-cast retries.
            auto targets=WDN2P::Targets(me);if(targets.empty())return false;
            if(!WDN2P::Prepared(me))
                {uint32 prep=WDN2P::Selected(me);return IsSpellReady(prep,diff)&&CheckBotCast(me,prep)==SPELL_CAST_OK&&bot_ai::doCast(me,prep);}
            Unit*t=targets.front();uint32 spell=GetSpell(WDN2P::Toss);
            // A single critically injured ally gets the stronger single-target potion first.
            bool const groupFirst=t->GetHealthPct()>=35.f||!IsSpellReady(WDN2P::Toss,diff);
            if(groupFirst&&TrySplash(diff))return true;
            if(t->GetHealthPct()<75.f&&WDN2P::Known(me,spell)&&IsSpellReady(WDN2P::Toss,diff)&&WDN2P::Eligible(me,t)&&
               CheckBotCast(t,spell)==SPELL_CAST_OK&&bot_ai::doCast(t,spell))return true;
            // WDN2S: a rejected emergency toss must not suppress a legal group rescue.
            // Each path is attempted at most once; native cast checks still own GCD/cost/range.
            return !groupFirst&&TrySplash(diff);
        }
        bool TryHealingWard(uint32 diff)
        {
            if(IsCasting()||!WDN1C::HealingNeeded(me)||!IsSpellReady(WDN1C::Healing,diff)||
               !me->GetMaxPower(POWER_MANA)||uint64(me->GetPower(POWER_MANA))*100<uint64(me->GetMaxPower(POWER_MANA))*30)return false;
            return CheckBotCast(me,WDN1C::Healing)==SPELL_CAST_OK&&bot_ai::doCast(me,WDN1C::Healing);
        }
        bool TryVigil(uint32 diff)
        {
            // Native Aura 87 reduces incoming damage; Aura 23 triggers the percent heal.
            // No custom heal tick, no forced cast and no interruption of an active spell.
            if(!WDN1::Actor(me)||!me->IsInCombat()||me->GetHealthPct()>=50.f||
               IsCasting()||HasBotCommandState(BOT_COMMAND_FULLSTOP|BOT_COMMAND_INACTION)||
               GetSpell(Vigil)!=Vigil||me->HasAura(Vigil)||me->HasAura(9003581)||
               me->HasAura(9003800)||!IsSpellReady(Vigil,diff))return false;
            return CheckBotCast(me,Vigil)==SPELL_CAST_OK&&bot_ai::doCast(me,Vigil);
        }
        bool TryAllyBrew(uint32 diff)
        {
            if(allyBrewRetry||!HasRole(NPC_BOT_ROLE_HEAL)||IsCasting()||!WDN2P::Active(me))return false;
            uint32 spell=GetSpell(Brew);
            if(!spell||!WDN1::Known(me,spell)||!IsSpellReady(Brew,diff))return false;
            allyBrewRetry=500; // Bound scans and rejected casts; native cooldown/mana stay authoritative.
            for(Unit* target:WDN2P::Targets(me))
            {
                if(target==me||target->GetHealthPct()>=70.f)continue;
                if(CheckBotCast(target,spell)==SPELL_CAST_OK&&bot_ai::doCast(target,spell))return true;
            }
            return false;
        }
        bool TrySelfHeal(uint32 diff)
        {
            uint32 spell=GetSpell(Brew);
            if(me->GetHealthPct()>=45.f||IsCasting()||HasBotCommandState(BOT_COMMAND_FULLSTOP|BOT_COMMAND_INACTION)||
               !spell||!WDN1::Known(me,spell)||!IsSpellReady(Brew,diff))return false;
            return CheckBotCast(me,spell)==SPELL_CAST_OK&&bot_ai::doCast(me,spell);
        }
        bool TryMimic(Unit* target,uint32 diff)
        {
            if(mimicRetry||!WDN2C::Known(me)||WDN2C::Current(me)||!IsSpellReady(WDN2C::SpellId,diff)||
               !WDN1::Safe(me,target)||!me->IsWithinDistInMap(target,28.f)||
               uint64(me->GetPower(POWER_MANA))*100<uint64(me->GetMaxPower(POWER_MANA))*40||target->GetHealthPct()<=40.f)return false;
            if(!GetSpell(Wrath)&&!GetSpell(Arrow)&&!GetSpell(Reclamation))return false;
            mimicRetry=3000;
            return CheckBotCast(me,WDN2C::SpellId)==SPELL_CAST_OK&&bot_ai::doCast(me,WDN2C::SpellId);
        }
        bool TryMassWards(Unit* target,uint32 diff)
        {
            if(massRetry||!WDN2B::Known(me)||WDN2B::Active(me)||!IsSpellReady(WDN2B::SpellId,diff)||
               !WDN1::Safe(me,target)||!me->IsWithinDistInMap(target,25.f)||
               uint64(me->GetPower(POWER_MANA))*100<uint64(me->GetMaxPower(POWER_MANA))*45)return false;
            massRetry=2000; // Bound nearby scans and rejected-cast retries.
            bool boss=false;
            if(Creature* enemy=target->ToCreature())boss=enemy->IsDungeonBoss()||enemy->isWorldBoss();
            if(!boss)
            {
                std::list<Unit*> nearby;GetNearbyTargetsList(nearby,25.f,1);
                std::vector<ObjectGuid> engaged;
                for(Unit* enemy:nearby)
                    if(WDN1::Safe(me,enemy)&&me->IsWithinDistInMap(enemy,25.f)&&
                       std::find(engaged.begin(),engaged.end(),enemy->GetGUID())==engaged.end())engaged.push_back(enemy->GetGUID());
                if(engaged.size()<3)return false;
            }
            if(CheckBotCast(me,WDN2B::SpellId)!=SPELL_CAST_OK)return false;
            return bot_ai::doCast(me,WDN2B::SpellId);
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
            if(uint32 brewingBase=WDN2P::Base(info->Id))
            {uint32 cooldown=info->GetRecoveryTime();ApplyBotSpellCooldownMods(info,cooldown);SetSpellCooldown(brewingBase,cooldown);return;}
            uint32 base=WDN1::Base(info->Id);
            if(!base)base=WDN2::Base(info->Id);
            if(info->Id==WDN2O::SpellId||info->Id==WDN1C::Healing||info->Id==Vigil||info->Id==WDN2D::Serene||info->Id==WDN2D::Swift||info->Id==WDN2E::Cursed||info->Id==WDN2E::Graven||info->Id==WDN2E::Hex||info->Id==WDN2E::SpellId||info->Id==WDN2D::SpellId||info->Id==WDN2B::SpellId||info->Id==WDN2C::SpellId)base=info->Id;
            if(base==WDN2O::SpellId||base==WDN1C::Healing||base==Vigil||base==WDN2D::Serene||base==WDN2D::Swift||base==WDN2E::Cursed||base==WDN2E::Graven||base==WDN2E::Hex||base==WDN2E::SpellId||base==WDN2D::SpellId||base==Wrath||base==Brew||base==Arrow||base==Reclamation||base==Eclipse||base==Glaive||base==WDN2::Hex||base==WDN2::Lethargy||base==WDN2::Shrinking||base==WDN2B::SpellId||base==WDN2C::SpellId)
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
                me->RemoveAurasDueToSpell(Vigil,me->GetGUID());me->RemoveAurasDueToSpell(WDN1::Spirit,me->GetGUID());
                WDN2Y::Clear(me);WDN2P::Clear(me);WDN2O::Clear(me);WDN1C::Clear(me);WDN2B::Clear(me);WDN2C::Clear(me);WDN2D::Clear(me);WDN2E::Clear(me);
                spiritOwner=GetBotOwnerGuid();spiritMap=me->GetMapId();
            }
            hexEffigyRetry=hexEffigyRetry>diff?hexEffigyRetry-diff:0;gravenRetry=gravenRetry>diff?gravenRetry-diff:0;cursedRetry=cursedRetry>diff?cursedRetry-diff:0;swiftRetry=swiftRetry>diff?swiftRetry-diff:0;sereneRetry=sereneRetry>diff?sereneRetry-diff:0;
            allyBrewRetry=allyBrewRetry>diff?allyBrewRetry-diff:0;
            brewingRetry=brewingRetry>diff?brewingRetry-diff:0;
            WDN2Y::Maintain(me);
            WDN2P::Maintain(me);
            WDN2O::Current(me);
            WDN2E::Current(me);
            effigyRetry=effigyRetry>diff?effigyRetry-diff:0;
            WDN2D::Current(me);
            idolRetry=idolRetry>diff?idolRetry-diff:0;
            WDN2C::Current(me);
            WDN2B::Active(me);
            WDN1C::Current(me); // Clear on lost recruitment, role, skill, map or distance.
            diagnosticTimer=diagnosticTimer>diff?diagnosticTimer-diff:0;
            mimicRetry=mimicRetry>diff?mimicRetry-diff:0;
            massRetry=massRetry>diff?massRetry-diff:0;
            hexRetry=hexRetry>diff?hexRetry-diff:0;
            jinxRetry=jinxRetry>diff?jinxRetry-diff:0;
            if(GetSpell(Vigil)!=Vigil)me->RemoveAurasDueToSpell(Vigil,me->GetGUID());
            // WDN2R: cancel an old offensive auto-repeat even if support/global logic returns early.
            // Keep combat/threat and ordinary follow movement; never CombatStop a healer.
            if(!HasRole(NPC_BOT_ROLE_DPS))
            {
                me->InterruptSpell(CURRENT_AUTOREPEAT_SPELL);
                if(me->GetVictim())me->AttackStop();
                opponent=nullptr;disttarget=nullptr;
            }
            if(!GlobalUpdate(diff)){Trace("global-update");return;}
            if(IAmFree()||!WDN1::Actor(me))
            { me->InterruptSpell(CURRENT_AUTOREPEAT_SPELL);me->RemoveAurasDueToSpell(Vigil,me->GetGUID());me->RemoveAurasDueToSpell(WDN1::Spirit,me->GetGUID());return; }
            DoVehicleActions(diff);
            if(!CanBotAttackOnVehicle()||ProcessImmediateNonAttackTarget()){Trace("vehicle-or-immediate");return;}
            bool const reserveHealingMana=ReserveHealingMana();
            if(TryVoodoo(diff))return;
            if(TryVigil(diff))return;
            if(TrySelfHeal(diff))return;
            if(TryBrewing(diff))return;
            if(TryAllyBrew(diff))return;
            if(reserveHealingMana&&TryManaIdol(diff))return;
            if(TryHealingWard(diff))return;
            if(TryManaIdol(diff))return;
            if(TrySereneIdol(diff))return;
            if(TrySwiftIdol(diff))return;
            if(!HasRole(NPC_BOT_ROLE_DPS)){Trace("support-only");return;}
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
            if(!WDN1::Safe(me,target)){Trace("unsafe-target");return;}
            // Native doCast handles movement/real cast time; do not suppress instant spells.
            KeepAutoShot(target);
            if(reserveHealingMana){Trace("healing-mana-reserve");return;}
            if(!pulling&&TryCursedEffigy(target,diff))return;
            if(!pulling&&TryHexingEffigy(target,diff))return;
            if(!pulling&&TryGravenEffigy(target,diff))return;
            if(!pulling&&TryShadowEffigy(target,diff))return;
            if(!pulling&&TryMassWards(target,diff))return;
            if(!pulling&&TryMimic(target,diff))return;
            if(!pulling&&MaintainDebuffs(target,diff))return;
            if(!pulling&&me->IsWithinDistInMap(target,28.0f)&&
               WDN1C::Known(me)&&!WDN1C::Current(me)&&IsSpellReady(WDN1C::SpellId,diff)&&
               CheckBotCast(me,WDN1C::SpellId)==SPELL_CAST_OK&&bot_ai::doCast(me,WDN1C::SpellId))return;
            if(!pulling&&WDN2C::Current(me)&&IsSpellReady(Wrath,diff)&&CastOffensive(target,Wrath))return;
            if(!pulling&&preferWrath&&IsSpellReady(Wrath,diff)&&CastOffensive(target,Wrath)){preferWrath=false;return;}
            if(WDN1::Count(me)<5&&IsSpellReady(Reclamation,diff)&&CastOffensive(target,Reclamation)){preferWrath=true;return;}
            if(WDN1::Count(me)==5&&IsSpellReady(Eclipse,diff)&&!target->HasAura(GetSpell(Eclipse),me->GetGUID())&&CastOffensive(target,Eclipse))return;
            if(IsSpellReady(Glaive,diff)&&CastGlaive(target))return;
            if(IsSpellReady(Arrow,diff)&&CastOffensive(target,Arrow))return;
            if(IsSpellReady(Wrath,diff))CastOffensive(target,Wrath);
        }
        std::vector<uint32> const* GetSupportSpellsList() const override { return &supportSpells; }
        std::vector<uint32> const* GetHealingSpellsList() const override { return &healingSpells; }
        std::vector<uint32> const* GetDamagingSpellsList() const override { return &damageSpells; }
    };
};
void AddSC_witch_doctor_bot() { new witch_doctor_bot(); }
