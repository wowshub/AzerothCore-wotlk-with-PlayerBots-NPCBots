// WDN1A: controlled NPCBot Shadowhunting foundation, not a Playerbot context.
#include "bot_ai.h"
#include "botmgr.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "Corpse.h"
#include "Group.h"
#include "SpellMgr.h"
#include "Log.h"
#include "Config.h"
#include "InstanceScript.h"
#include "../../../../../modules/mod-reborn-witchdoctor/src/RebornWitchDoctorNpcCleansing5.h"
#include "../../../../../modules/mod-reborn-witchdoctor/src/RebornWitchDoctorNpcHealing5.h"
#include "../../../../../modules/mod-reborn-witchdoctor/src/RebornWitchDoctorNpcSurvival3.h"
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
constexpr uint32 Wrath=9003100,Brew=9003101,Vigil=9003855,Reclaim=9003260;
constexpr uint32 Arrow=9003970, Reclamation=9003980, Eclipse=9004000, Glaive=9004030;
std::vector<uint32> const supportSpells={WDN5D::Hexbreak,WDN5D::Allcure,WDN5D::MassAllcure,Reclaim,WDN3A::Death,WDN3A::Slither,WDN3A::Mirage,WDN2P::Thistle,WDN2P::Fish,WDN2P::Bones,WDN2O::SpellId,Vigil,WDN2D::Serene,WDN2D::Swift,WDN2D::SpellId,WDN2E::SpellId,WDN2E::Hex,WDN2E::Graven,WDN2E::Cursed};
std::vector<uint32> const healingSpells={WDN2P::Splash,WDN2P::Toss,WDN2P::Prep,Brew,WDN1C::Healing};
std::vector<uint32> const damageSpells={Wrath,Arrow,Reclamation,Eclipse,Glaive,WDN1::AutoShot,WDN2::Hex,WDN2::Lethargy,WDN2::Shrinking,WDN1C::SpellId,WDN2B::SpellId,WDN2C::SpellId};
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
        WDN3A::State survival;
        uint32 utilityDelay=0,pullMoveDelay=0,survivalLogDelay=0,recentHostileDamage=0;
        bool preferWrath=false;
        uint32 healMoveDelay=0,healLogDelay=0,rezRetry=0,cleanseRetry=0,rezLogDelay=0,rezCastLogDelay=0;
        uint32 spiritOwner=0,spiritMap=0,spiritPhase=0,spiritInstance=0,diagnosticTimer=0,hexRetry=0,jinxRetry=0,massRetry=0,mimicRetry=0,idolRetry=0,effigyRetry=0,hexEffigyRetry=0,gravenRetry=0,cursedRetry=0,swiftRetry=0,sereneRetry=0,brewingRetry=0,allyBrewRetry=0;
        void Trace(char const* reason,uint32 spell=0,int32 result=0)
        {
            if(diagnosticTimer||IAmFree())return;
            Player* owner=GetBotOwner();
            if(!me->IsInCombat()&&!(owner&&owner->IsInCombat())&&
               !IsActionNext(NpcBotActionTypes::BOT_ACTION_PULL))return;
            diagnosticTimer=10000;
            LOG_ERROR("server", "[WDN5A combat] entry={} owner={} gate={} spell={} result={} commands={} mana={}/{} arrow={} reclaim={} roles={} pull={} utilityMs={} wardKnown={} wardReady={} wardCheck={}",
                me->GetEntry(),GetBotOwnerGuid(),reason,spell,result,GetBotCommandState(),
                me->GetPower(POWER_MANA),me->GetMaxPower(POWER_MANA),GetSpell(Arrow),GetSpell(Reclamation),GetBotRoles(),IsActionNext(NpcBotActionTypes::BOT_ACTION_PULL),utilityDelay,WDN1C::Known(me),IsSpellReady(WDN1C::SpellId,0),WDN1C::Known(me)?int32(CheckBotCast(me,WDN1C::SpellId)):-1);
        }
        explicit witch_doctor_botAI(Creature* c) : bot_ai(c)
        { _botclass=BOT_CLASS_WITCH_DOCTOR;InitUnitFlags();LOG_ERROR("server", "[WDN5F] initialized entry={}",me->GetEntry()); }

        void ClearLocalScheduling()
        {
            // These are AI retry delays, not the native spell cooldowns or saved ability settings.
            pullMoveDelay=survivalLogDelay=diagnosticTimer=recentHostileDamage=utilityDelay=0;
            hexRetry=jinxRetry=massRetry=mimicRetry=idolRetry=effigyRetry=0;
            hexEffigyRetry=gravenRetry=cursedRetry=swiftRetry=sereneRetry=0;
            brewingRetry=allyBrewRetry=healMoveDelay=healLogDelay=rezRetry=cleanseRetry=rezLogDelay=rezCastLogDelay=0;healingReserve=false;preferWrath=false;
        }
        void Reset() override { ClearLocalScheduling();survival.Clear(me); WDN2Y::Clear(me);WDN2P::Clear(me);WDN2O::Clear(me);WDN1C::Clear(me);WDN2B::Clear(me);WDN2C::Clear(me);WDN2D::Clear(me);WDN2E::Clear(me); me->RemoveAurasDueToSpell(Vigil,me->GetGUID());me->RemoveAurasDueToSpell(WDN1::Spirit,me->GetGUID());DefaultInit(); }
        void JustDied(Unit* killer) override
        { ClearLocalScheduling();survival.Clear(me);WDN2Y::Clear(me);WDN2P::Clear(me);WDN2O::Clear(me);WDN1C::Clear(me);WDN2B::Clear(me);WDN2C::Clear(me);WDN2D::Clear(me);WDN2E::Clear(me);me->RemoveAurasDueToSpell(Vigil,me->GetGUID());me->RemoveAurasDueToSpell(WDN1::Spirit,me->GetGUID());bot_ai::JustDied(killer); }
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
            for(uint32 id:{WDN5D::Hexbreak,WDN5D::Allcure,WDN5D::MassAllcure})
            {
                InitSpellMap(id,true,false);auto* info=sSpellMgr->GetSpellInfo(id);
                auto const& spells=GetSpellMap();auto it=spells.find(id);
                if(it!=spells.end()&&it->second)it->second->spellId=info&&me->GetLevel()>=info->SpellLevel?id:0;
            }
            for(uint32 id:{WDN3A::Death,WDN3A::Slither,WDN3A::Mirage})
            {
                InitSpellMap(id,true,false);auto*info=sSpellMgr->GetSpellInfo(id);
                auto const&spells=GetSpellMap();auto it=spells.find(id);
                if(it!=spells.end()&&it->second)it->second->spellId=info&&me->GetLevel()>=info->SpellLevel?id:0;
            }
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
            InitFamily(Reclaim,WD19A::ReclaimRanks);
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
            if(CastDebuff(target,preferred,diff,jinxRetry))return true;
            uint32 alternative=preferred==WDN2::Shrinking?WDN2::Lethargy:WDN2::Shrinking;
            uint32 fallbackRetry=0;
            bool cast=CastDebuff(target,alternative,diff,fallbackRetry);
            jinxRetry=std::max(jinxRetry,fallbackRetry);
            return cast;
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
            if(utilityDelay||gravenRetry||!WDN2E::CanPlace(me,WDN2E::Graven)||!IsSpellReady(WDN2E::Graven,diff)||
               !WDN1::Safe(me,target)||!me->IsWithinDistInMap(target,28.f)||
               !target->HasAuraType(SPELL_AURA_MOD_DECREASE_SPEED)||
               uint64(me->GetPower(POWER_MANA))*100<uint64(me->GetMaxPower(POWER_MANA))*35)return false;
            gravenRetry=2000;
            return CheckBotCast(me,WDN2E::Graven)==SPELL_CAST_OK&&bot_ai::doCast(me,WDN2E::Graven);
        }
        bool TryShadowEffigy(Unit*target,uint32 diff)
        {
            if(utilityDelay||effigyRetry||!WDN2E::Known(me)||WDN2E::Current(me)||!IsSpellReady(WDN2E::SpellId,diff)||
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
            if(utilityDelay||sereneRetry||IsCasting()||!IsSpellReady(WDN2D::Serene,diff)||
               uint64(me->GetPower(POWER_MANA))*100<uint64(me->GetMaxPower(POWER_MANA))*40)return false;
            sereneRetry=2000;if(!WDN2D::SereneNeeded(me))return false;
            return CheckBotCast(me,WDN2D::Serene)==SPELL_CAST_OK&&bot_ai::doCast(me,WDN2D::Serene);
        }
        bool TrySwiftIdol(uint32 diff)
        {
            if(utilityDelay||swiftRetry||IsCasting()||!IsSpellReady(WDN2D::Swift,diff)||
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
        bool HealingCandidate(Unit* t) const
        {
            return t && t->IsAlive() && t->IsInWorld() && me->IsInMap(t) && me->InSamePhase(t) &&
                me->IsFriendlyTo(t) && (t==me || ((t->GetTypeId()==TYPEID_PLAYER || t->IsNPCBot()) && IsInBotParty(t))) &&
                me->IsWithinDistInMap(t,60.f);
        }
        bool HealingTank(Unit* t) const
        {
            // Playerbots may use a bear build without a native NPC/LFG tank flag.
            // Recognize the actual bear receiving attacks, not a class-name assumption.
            return IsTank(t) || (t && !t->getAttackers().empty() &&
                (t->GetShapeshiftForm()==FORM_BEAR || t->GetShapeshiftForm()==FORM_DIREBEAR));
        }
        Unit* HealingTarget()
        {
            if(!HasRole(NPC_BOT_ROLE_HEAL)||!WDN2P::Active(me))return nullptr;
            std::list<Unit*> units;
            Acore::AnyUnitInObjectRangeCheck check(me,60.f);
            Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(me,units,check);
            Cell::VisitObjects(me,search,60.f);
            Unit* best=nullptr;
            for(Unit* t:units)
            {
                if(!HealingCandidate(t)||!WDN5A::NeedsHeal(t->GetHealthPct(),HealingTank(t)))continue;
                if(!best || WDN5A::Priority(t->GetHealthPct(),HealingTank(t)) < WDN5A::Priority(best->GetHealthPct(),HealingTank(best)) ||
                   (WDN5A::Priority(t->GetHealthPct(),HealingTank(t)) == WDN5A::Priority(best->GetHealthPct(),HealingTank(best)) && t->GetGUID()<best->GetGUID()))best=t;
            }
            return best;
        }
        // WDN5F: observation only; do not relax resurrection or mutate combat state.
        void DiagnoseResurrection(uint32 diff)
        {
            if(!sConfigMgr->GetOption<bool>("RebornBotTelemetry.NpcBotRezLog",false))return;
            rezCastLogDelay=rezCastLogDelay>diff?rezCastLogDelay-diff:0;
            rezLogDelay=rezLogDelay>diff?rezLogDelay-diff:0;if(rezLogDelay)return;
            rezLogDelay=5000;
            Player* owner=GetBotOwner();if(!owner||IAmFree()||!me->IsInWorld())return;
            std::vector<Player*> players{owner};
            if(Group* group=owner->GetGroup())for(GroupReference* ref=group->GetFirstMember();ref;ref=ref->next())
                if(Player* p=ref->GetSource())if(p!=owner)players.push_back(p);
            Unit* blocker=nullptr;
            auto blocked=[&](Unit* u){if(!blocker&&u&&u->IsInWorld()&&me->IsInMap(u)&&me->InSamePhase(u)&&u->IsInCombat())blocker=u;};
            for(Player* p:players){blocked(p);if(p->HaveBot())for(auto const& pair:*p->GetBotMgr()->GetBotMap())blocked(pair.second);}
            uint32 id=GetSpell(Reclaim);auto* info=sSpellMgr->GetSpellInfo(id);
            int32 cost=info?info->CalcPowerCost(me,info->GetSchoolMask()):-1;
            bool known=WDN1::Known(me,id),state=me->IsMounted()||me->GetVehicle()||WDN1::Escaping(me)||
                HasBotCommandState(BOT_COMMAND_FULLSTOP|BOT_COMMAND_INACTION|BOT_COMMAND_NO_CAST);
            auto report=[&](Unit* dead,WorldObject* body,bool requested,bool selfRez,bool autoRez)
            {
                if(!dead||dead->IsAlive())return;
                bool valid=body&&body->IsInWorld()&&me->IsInMap(body)&&me->InSamePhase(body);
                float distance=valid?me->GetDistance(body):-1.f;
                bool los=valid&&me->IsWithinLOSInMap(body,VMAP::ModelIgnoreFlags::M2,LINEOFSIGHT_ALL_CHECKS);
                bool pending=valid&&owner->GetBotMgr()->IsBeingResurrected(body);
                char const* reason=!WDN1::Actor(me)?"actor-unavailable":!known?"skill-disabled-or-unlearned":
                    state?"state-forbidden":me->IsInCombat()?"caster-combat":blocker?"party-combat":
                    requested?"request-pending":selfRez?"self-resurrection":autoRez?"npc-auto-revive-soon":
                    pending?"another-rez-in-progress":!valid?"body-map-phase-unavailable":distance>60.f?"outside-scan-range":
                    IsCasting()?"casting":!IsSpellReady(Reclaim,0)?"cooldown-or-gcd":
                    cost<0||int32(me->GetPower(POWER_MANA))<cost?"insufficient-mana":
                    distance>28.f||!los?"approach-needed":"eligible-await-native-cast";
                auto* instance=me->GetInstanceScript();
                LOG_INFO("server","[NPCBOT-REZ] bot={} owner={} ownerGuid={} target={} targetGuid={} reason={} spell={} known={} mana={}/{} cost={} distance={} los={} commands={} casting={} combat={} blocker={} blockerGuid={} blockerAttackers={} blockerVictim={} request={} pending={} selfRez={} autoRez={} encounter={} map={} instance={}",
                    me->GetName(),owner->GetName(),GetBotOwnerGuid(),dead->GetName(),dead->GetGUID().GetCounter(),reason,id,known,
                    me->GetPower(POWER_MANA),me->GetMaxPower(POWER_MANA),cost,distance,los,GetBotCommandState(),IsCasting(),me->IsInCombat(),
                    blocker?blocker->GetName():"none",blocker?blocker->GetGUID().GetCounter():0,blocker?blocker->getAttackers().size():0,
                    blocker&&blocker->GetVictim()?blocker->GetVictim()->GetName():"none",requested,pending,selfRez,autoRez,
                    instance&&instance->IsEncounterInProgress(),me->GetMapId(),me->GetInstanceId());
            };
            for(Player* p:players)
            {
                if(!p->IsGameMaster())report(p,p->HasFlag(PLAYER_FLAGS,PLAYER_FLAGS_GHOST)?static_cast<WorldObject*>(p->GetCorpse()):p,
                    p->isResurrectRequested(),p->GetUInt32Value(PLAYER_SELF_RES_SPELL)!=0,false);
                if(p->HaveBot())for(auto const& pair:*p->GetBotMgr()->GetBotMap())if(Creature* c=pair.second)
                    if(c->GetBotAI())report(c,c,false,c->GetBotAI()->GetSelfRezSpell()!=0,c->GetBotAI()->GetReviveTimer()<15000);
            }
        }
        // WDN5C: typed corpses, fresh pointers per tick, no combat resurrection.
        WorldObject* ResurrectionTarget()
        {
            if(!WDN1::Actor(me)||me->IsInCombat()||me->IsMounted()||me->GetVehicle()||
               HasBotCommandState(BOT_COMMAND_FULLSTOP|BOT_COMMAND_INACTION|BOT_COMMAND_NO_CAST)||
               WDN1::Escaping(me)||!WDN1::Known(me,GetSpell(Reclaim)))return nullptr;
            Player* owner=GetBotOwner();
            if(!owner||owner->GetGUID().GetCounter()!=GetBotOwnerGuid())return nullptr;
            std::vector<Player*> players{owner};
            if(Group* group=owner->GetGroup())
                for(GroupReference* ref=group->GetFirstMember();ref;ref=ref->next())
                    if(Player* p=ref->GetSource())if(p!=owner)players.push_back(p);
            // Do not abandon a still-fighting party to resurrect someone.
            for(Player* p:players)
            {
                if(p->IsInWorld()&&me->IsInMap(p)&&me->InSamePhase(p)&&p->IsInCombat())return nullptr;
                if(!p->HaveBot())continue;
                for(auto const& item:*p->GetBotMgr()->GetBotMap())
                    if(Creature* c=item.second)
                        if(c->IsInWorld()&&me->IsInMap(c)&&me->InSamePhase(c)&&c->IsInCombat())return nullptr;
            }
            auto available=[&](WorldObject* t)
            {
                return t&&t->IsInWorld()&&me->IsInMap(t)&&me->InSamePhase(t)&&
                    me->GetDistance(t)<=60.f&&!owner->GetBotMgr()->IsBeingResurrected(t);
            };
            for(Player* p:players)
            {
                if(p->IsAlive()||p->IsGameMaster()||p->isResurrectRequested()||p->GetUInt32Value(PLAYER_SELF_RES_SPELL))continue;
                WorldObject* t=p->HasFlag(PLAYER_FLAGS,PLAYER_FLAGS_GHOST)?
                    static_cast<WorldObject*>(p->GetCorpse()):static_cast<WorldObject*>(p);
                if(available(t))return t;
            }
            for(Player* p:players)
            {
                if(!p->HaveBot())continue;
                for(auto const& item:*p->GetBotMgr()->GetBotMap())
                {
                    Creature* c=item.second;
                    if(!c||c->IsAlive()||!c->GetBotAI()||c->GetBotAI()->GetSelfRezSpell()||
                       c->GetBotAI()->GetReviveTimer()<15000)continue;
                    if(available(c))return c;
                }
            }
            return nullptr;
        }
        bool TryResurrection(uint32 diff)
        {
            if(IsCasting())return false;
            WorldObject* target=ResurrectionTarget();
            if(!target||!IsSpellReady(Reclaim,diff))return false;
            uint32 spellId=GetSpell(Reclaim);
            SpellInfo const* info=sSpellMgr->GetSpellInfo(spellId);
            if(!info||int32(me->GetPower(POWER_MANA))<info->CalcPowerCost(me,info->GetSchoolMask()))return false;
            if(rezRetry)return true;
            rezRetry=1000;
            float range=std::min(28.f,info->GetMaxRange(true));
            if(me->GetDistance(target)>range||!me->IsWithinLOSInMap(target,VMAP::ModelIgnoreFlags::M2,LINEOFSIGHT_ALL_CHECKS))
            {
                if(!HasBotCommandState(BOT_COMMAND_MASK_UNMOVING)&&!JumpingOrFalling()&&!CCed(me,true)&&
                   GetBotOwner()->GetBotMgr()->GetBotAllowCombatPositioning())
                    BotMovement(BOT_MOVE_POINT,target);
                return true;
            }
            if(JumpingOrFalling()||CCed(me,true))return false;
            // Stop before native doCast: its moving/no-victim raid guard rejects stationary rez intent.
            me->BotStopMovement();
            if(Corpse* corpse=target->ToCorpse())
            {
                // Native doCast takes Unit*: never reinterpret a Corpse as Unit.
                feast_health=feast_mana=false;
                me->SetStandState(UNIT_STAND_STATE_STAND);
                SpellCastTargets targets;targets.SetCorpseTarget(corpse);
                Spell* spell=new Spell(me,info,TRIGGERED_NONE);
                SpellCastResult result=spell->prepare(&targets);
                if(result==SPELL_CAST_OK)GC_Timer=1500;
                if(sConfigMgr->GetOption<bool>("RebornBotTelemetry.NpcBotRezLog",false)&&!rezCastLogDelay)
                {
                    rezCastLogDelay=5000;
                    LOG_INFO("server","[NPCBOT-REZ-CAST] bot={} target={} spell={} prepare={}",me->GetName(),target->GetGUID().GetCounter(),spellId,uint32(result));
                }
                // Spell owns its completion/failure lifetime; do not dereference after prepare.
            }
            else if(Unit* unit=target->ToUnit())
            {
                SpellCastResult result=CheckBotCast(unit,spellId);bool started=result==SPELL_CAST_OK&&doCast(unit,spellId);
                if(sConfigMgr->GetOption<bool>("RebornBotTelemetry.NpcBotRezLog",false)&&!rezCastLogDelay)
                {
                    rezCastLogDelay=5000;
                    LOG_INFO("server","[NPCBOT-REZ-CAST] bot={} target={} spell={} check={} started={}",me->GetName(),unit->GetGUID().GetCounter(),spellId,uint32(result),started);
                }
            }
            return true;
        }
        bool TryCleansing(uint32 diff)
        {
            if(!WDN1::Actor(me)||WDN1::Escaping(me)||me->IsMounted()||me->GetVehicle()||IsCasting()||
               HasBotCommandState(BOT_COMMAND_FULLSTOP|BOT_COMMAND_INACTION|BOT_COMMAND_NO_CAST)||cleanseRetry)return false;
            cleanseRetry=750;
            std::list<Unit*> units;
            Acore::AnyUnitInObjectRangeCheck check(me,30.f);
            Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(me,units,check);
            Cell::VisitObjects(me,search,30.f);
            if(std::find(units.begin(),units.end(),me)==units.end())units.push_back(me);
            auto ready=[&](uint32 id)
            {
                auto* info=sSpellMgr->GetSpellInfo(id);
                return info&&WDN1::Known(me,id)&&IsSpellReady(id,diff)&&
                    int32(me->GetPower(POWER_MANA))>=info->CalcPowerCost(me,info->GetSchoolMask());
            };
            bool groupReady=ready(WDN5D::MassAllcure),singleReady=ready(WDN5D::Allcure),curseReady=ready(WDN5D::Hexbreak);
            uint32 affected=0;Unit* best=nullptr;uint32 bestMask=0;
            for(Unit* t:units)
            {
                if(!WDN5D::Eligible(me,t))continue;
                uint32 mask=WDN5D::Afflictions(t);if(!mask)continue;
                ++affected;
                if(!WDN5D::Choose(1,mask,false,singleReady,curseReady))continue;
                if(!best||WDN5A::Priority(t->GetHealthPct(),HealingTank(t))<WDN5A::Priority(best->GetHealthPct(),HealingTank(best))||
                   (WDN5A::Priority(t->GetHealthPct(),HealingTank(t))==WDN5A::Priority(best->GetHealthPct(),HealingTank(best))&&t->GetGUID()<best->GetGUID()))
                {best=t;bestMask=mask;}
            }
            uint32 id=WDN5D::Choose(affected,bestMask,groupReady,singleReady,curseReady);
            Unit* target=id==WDN5D::MassAllcure?me:best;
            return id&&WDN5D::Eligible(me,target)&&CheckBotCast(target,id)==SPELL_CAST_OK&&doCast(target,id);
        }
        bool HasPriorityHealingTarget() override
        {
            if(HasBotCommandState(BOT_COMMAND_MASK_UNMOVING)||IAmFree()||!GetBotOwner()||
               !GetBotOwner()->GetBotMgr()->GetBotAllowCombatPositioning())return false;
            if(IsSpellReady(Reclaim,0))
            {
                SpellInfo const* info=sSpellMgr->GetSpellInfo(GetSpell(Reclaim));
                if(info&&int32(me->GetPower(POWER_MANA))>=info->CalcPowerCost(me,info->GetSchoolMask())&&
                   ResurrectionTarget())return true;
            }
            Unit* t=HealingTarget();
            return t && (me->IsInCombat()||t->IsInCombat());
        }
        void TraceHealing(char const* gate,Unit* t,uint32 spell=0,int32 result=0)
        {
            if(healLogDelay || IAmFree())return;
            healLogDelay=2000;
            LOG_ERROR("server","[WDN5A heal] entry={} owner={} gate={} target={} targetGuid={} hp={} tank={} distance={} spell={} result={} mana={}/{} roles={} commands={}",
                me->GetEntry(),GetBotOwnerGuid(),gate,t?t->GetName():"none",t?t->GetGUID().GetCounter():0,t?t->GetHealthPct():0.f,t?HealingTank(t):false,
                t?me->GetDistance(t):0.f,spell,result,me->GetPower(POWER_MANA),me->GetMaxPower(POWER_MANA),GetBotRoles(),GetBotCommandState());
        }
        bool CastHealing(Unit* t,uint32 base,uint32 diff)
        {
            uint32 spell=GetSpell(base);
            if(!HealingCandidate(t)||!spell||!IsSpellReady(base,diff))return false;
            if(base==WDN2P::Toss ? !WDN2P::Known(me,spell) : !WDN1::Known(me,spell))return false;
            auto result=CheckBotCast(t,spell);
            if(result!=SPELL_CAST_OK){TraceHealing("check-rejected",t,spell,int32(result));return false;}
            bool cast=bot_ai::doCast(t,spell);
            TraceHealing(cast?"cast-started":"prepare-rejected",t,spell);
            return cast;
        }
        bool TryPriorityHeal(Unit* t,uint32 diff)
        {
            if(!HealingCandidate(t)||!HasRole(NPC_BOT_ROLE_HEAL)||!WDN2P::Active(me))return false;
            bool urgent=WDN5A::Urgent(t->GetHealthPct(),HealingTank(t));
            if(IsCasting()) {TraceHealing("casting",t);return urgent;}
            // Brewing effects use a 30-yard ally contract. Move into it before selecting
            // unrelated utility, without routing a friendly target through attack movement.
            if(t!=me && (!me->IsWithinDistInMap(t,28.f)||!me->IsWithinLOSInMap(t)))
            {
                if(!healMoveDelay && !HasBotCommandState(BOT_COMMAND_MASK_UNMOVING) &&
                   !JumpingOrFalling() && !CCed(me,true) && !me->GetVehicle() &&
                   GetBotOwner() && GetBotOwner()->GetBotMgr()->GetBotAllowCombatPositioning())
                {
                    Position pos=me->GetPosition();
                    me->MovePositionToFirstCollision(pos,std::max(3.f,me->GetDistance(t)-20.f),me->GetRelativeAngle(t));
                    BotMovement(BOT_MOVE_POINT,&pos);healMoveDelay=1000;
                }
                TraceHealing("approach",t);return true;
            }
            if(allyBrewRetry)return false;
            allyBrewRetry=500;
            if(WDN2P::Prepared(me)&&CastHealing(t,WDN2P::Toss,diff))return true;
            if(CastHealing(t,Brew,diff))return true;
            TraceHealing("cooldown-or-unavailable",t);
            return false; // Allow mana recovery; the caller reserves this tick from DPS.
        }
        bool TryAllyBrew(uint32 diff)
        { return TryPriorityHeal(HealingTarget(),diff); }
        bool TrySelfHeal(uint32 diff)
        {
            uint32 spell=GetSpell(Brew);
            if(me->GetHealthPct()>=45.f||IsCasting()||HasBotCommandState(BOT_COMMAND_FULLSTOP|BOT_COMMAND_INACTION)||
               !spell||!WDN1::Known(me,spell)||!IsSpellReady(Brew,diff))return false;
            return CheckBotCast(me,spell)==SPELL_CAST_OK&&bot_ai::doCast(me,spell);
        }
        bool TryMimic(Unit* target,uint32 diff)
        {
            if(utilityDelay||mimicRetry||!WDN2C::Known(me)||WDN2C::Current(me)||!IsSpellReady(WDN2C::SpellId,diff)||
               !WDN1::Safe(me,target)||!me->IsWithinDistInMap(target,28.f)||
               uint64(me->GetPower(POWER_MANA))*100<uint64(me->GetMaxPower(POWER_MANA))*40||target->GetHealthPct()<=40.f)return false;
            if(!GetSpell(Wrath)&&!GetSpell(Arrow)&&!GetSpell(Reclamation))return false;
            mimicRetry=3000;
            return CheckBotCast(me,WDN2C::SpellId)==SPELL_CAST_OK&&bot_ai::doCast(me,WDN2C::SpellId);
        }
        bool TryMassWards(Unit* target,uint32 diff)
        {
            if(utilityDelay||massRetry||!WDN2B::Known(me)||WDN2B::Active(me)||!IsSpellReady(WDN2B::SpellId,diff)||
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
        static bool IsScheduledUtility(uint32 id)
        {
            return id==WDN2D::Serene||id==WDN2D::Swift||id==WDN2E::Graven||id==WDN2E::SpellId||
                id==WDN2B::SpellId||id==WDN2C::SpellId||id==WDN1C::SpellId;
        }
        void OnClassSpellGo(SpellInfo const* info) override
        {
            if(info->Id==WDN5D::Allcure||info->Id==WDN5D::MassAllcure)
            {
                uint32 cooldown=info->GetRecoveryTime();ApplyBotSpellCooldownMods(info,cooldown);
                // A successful use locks both versions, even if the other toggle is disabled.
                SetSpellCooldown(WDN5D::Allcure,cooldown);
                SetSpellCooldown(WDN5D::MassAllcure,cooldown);return;
            }
            // Arm only on successful spell-go; failed attempts leave the damage rotation available.
            if(IsScheduledUtility(info->Id))utilityDelay=4000;
            if(WDN3A::Defensive(info->Id))
            {
                uint32 cooldown=info->GetRecoveryTime();ApplyBotSpellCooldownMods(info,cooldown);
                SetSpellCooldown(info->Id,cooldown);survival.Begin(me,info->Id);return;
            }
            // Explicit private rank families need a stable cooldown key even on
            // databases without the optional spell_chain rows for these ranks.
            if(uint32 brewingBase=WDN2P::Base(info->Id))
            {uint32 cooldown=info->GetRecoveryTime();ApplyBotSpellCooldownMods(info,cooldown);SetSpellCooldown(brewingBase,cooldown);return;}
            uint32 base=WDN1::Base(info->Id);
            if(!base)base=WDN2::Base(info->Id);
            if(info->Id==WDN2O::SpellId||info->Id==WDN1C::Healing||info->Id==Vigil||info->Id==WDN2D::Serene||info->Id==WDN2D::Swift||info->Id==WDN2E::Cursed||info->Id==WDN2E::Graven||info->Id==WDN2E::Hex||info->Id==WDN2E::SpellId||info->Id==WDN2D::SpellId||info->Id==WDN2B::SpellId||info->Id==WDN2C::SpellId)base=info->Id;
            if(base==WDN2O::SpellId||base==WDN1C::Healing||base==Vigil||base==WDN2D::Serene||base==WDN2D::Swift||base==WDN2E::Cursed||base==WDN2E::Graven||base==WDN2E::Hex||base==WDN2E::SpellId||base==WDN2D::SpellId||base==WDN5D::Hexbreak||base==Reclaim||base==Wrath||base==Brew||base==Arrow||base==Reclamation||base==Eclipse||base==Glaive||base==WDN2::Hex||base==WDN2::Lethargy||base==WDN2::Shrinking||base==WDN2B::SpellId||base==WDN2C::SpellId)
            {
                uint32 cooldown=info->GetRecoveryTime();
                ApplyBotSpellCooldownMods(info,cooldown);
                SetSpellCooldown(base,cooldown);
            }
        }
        // Mirror the native Hunter/Shaman response, without enabling healer damage or breaking escape.
        void DamageTaken(Unit* attacker,uint32& damage,DamageEffectType,SpellSchoolMask) override
        {
            if(!WDN1::Actor(me)||!attacker||attacker==me||!attacker->IsAlive()||!attacker->IsInWorld()||
                !me->IsInMap(attacker)||!me->InSamePhase(attacker)||!me->IsValidAttackTarget(attacker))return;
            if(damage)recentHostileDamage=4000;
            if(HasRole(NPC_BOT_ROLE_DPS)&&WDN1::Safe(me,attacker))OnOwnerDamagedBy(attacker);
        }
        void OwnerAttackedBy(Unit* attacker) override
        {
            if(HasRole(NPC_BOT_ROLE_DPS)&&WDN1::Safe(me,attacker))OnOwnerDamagedBy(attacker);
        }
        int32 DefenseStatus(uint32 spell,uint32 diff)
        {
            if(!WDN3A::Known(me,spell))return -1;
            if(!IsSpellReady(spell,diff))return -2;
            return int32(CheckBotCast(me,spell));
        }
        void TraceSurvival(char const* gate,uint32 spell=0,int32 result=0)
        {
            if(survivalLogDelay||!WDN1::Actor(me)||!me->IsInCombat()||me->GetHealthPct()>40.f)return;
            survivalLogDelay=3000;
            LOG_ERROR("server", "[WDN5A] entry={} owner={} gate={} hp={} recentDamageMs={} roles={} commands={} casting={} attackers={} hold={} death={} slither={} mirage={} spell={} result={} defenseStatus(D/S/M)={}/{}/{} mana={}/{}",
                me->GetEntry(),GetBotOwnerGuid(),gate,me->GetHealthPct(),recentHostileDamage,GetBotRoles(),GetBotCommandState(),IsCasting(),me->getAttackers().size(),survival.spell,
                me->HasAura(WDN3A::Death,me->GetGUID()),me->HasAura(WDN3A::Slither,me->GetGUID()),me->HasAura(WDN3A::Mirage,me->GetGUID()),spell,result,DefenseStatus(WDN3A::Death,0),DefenseStatus(WDN3A::Slither,0),DefenseStatus(WDN3A::Mirage,0),me->GetPower(POWER_MANA),me->GetMaxPower(POWER_MANA));
        }
        bool TrySurvival(uint32 diff)
        {
            if(JumpingOrFalling()||IsDuringTeleport()){TraceSurvival("movement");return false;}
            if(IsCasting()&&me->GetHealthPct()>25.f){TraceSurvival("casting");return false;}
            std::vector<uint32> attempted;
            for(uint32 attempt=0;attempt<3;++attempt)
            {
                uint32 rejectedSpell=0;int32 rejected=0;
                uint32 id=WDN3A::Choose(me,[&](uint32 spell){
                    if(std::find(attempted.begin(),attempted.end(),spell)!=attempted.end())return false;
                    rejectedSpell=spell;
                    rejected=DefenseStatus(spell,diff);return rejected==SPELL_CAST_OK;
                },recentHostileDamage!=0);
                if(!id){TraceSurvival("no-eligible-defense",rejectedSpell,rejected);return false;}
                // At critical health interrupt the current cast only after a defense is eligible.
                // Native GCD, spell costs, cooldowns and the final doCast checks remain in force.
                if(IsCasting())me->InterruptNonMeleeSpells(false);
                if(bot_ai::doCast(me,id)){TraceSurvival("defense-started",id);return true;}
                attempted.push_back(id);
            }
            TraceSurvival("all-defense-casts-rejected");return false;
        }
        void StopDisabledOffense()
        {
            if(HasRole(NPC_BOT_ROLE_DPS))return;
            // Cancel only this class's known offensive casts; preserve healing and defense casts.
            for(CurrentSpellTypes slot:{CURRENT_GENERIC_SPELL,CURRENT_CHANNELED_SPELL})
                if(Spell const* current=me->GetCurrentSpell(slot))
                    for(uint32 base:damageSpells)
                        if(GetSpell(base)&&current->GetSpellInfo()->Id==GetSpell(base))
                        {me->InterruptSpell(slot);break;}
        }
        void UpdateAI(uint32 diff) override
        {
            recentHostileDamage=recentHostileDamage>diff?recentHostileDamage-diff:0;
            pullMoveDelay=pullMoveDelay>diff?pullMoveDelay-diff:0;
            survivalLogDelay=survivalLogDelay>diff?survivalLogDelay-diff:0;
            utilityDelay=utilityDelay>diff?utilityDelay-diff:0;
            if(spiritOwner!=GetBotOwnerGuid()||spiritMap!=me->GetMapId()||spiritPhase!=me->GetPhaseMask()||spiritInstance!=me->GetInstanceId())
            {
                // Do not carry a previous combat target or escape into another context.
                if(spiritOwner){me->AttackStop();me->InterruptSpell(CURRENT_AUTOREPEAT_SPELL);opponent=nullptr;disttarget=nullptr;}
                survival.Clear(me);
                me->RemoveAurasDueToSpell(Vigil,me->GetGUID());me->RemoveAurasDueToSpell(WDN1::Spirit,me->GetGUID());
                WDN2Y::Clear(me);WDN2P::Clear(me);WDN2O::Clear(me);WDN1C::Clear(me);WDN2B::Clear(me);WDN2C::Clear(me);WDN2D::Clear(me);WDN2E::Clear(me);
                ClearLocalScheduling();spiritOwner=GetBotOwnerGuid();spiritMap=me->GetMapId();spiritPhase=me->GetPhaseMask();spiritInstance=me->GetInstanceId();
            }
            StopDisabledOffense();
            if(IsDuringTeleport())survival.Clear(me);
            // Before GlobalUpdate/CheckAttackTarget: both may move or acquire targets.
            // CommonTimers is driven by Creature::Update, so native cooldowns keep ticking during holds.
            if(survival.Hold(me,diff)){TraceSurvival("defensive-hold");opponent=nullptr;disttarget=nullptr;return;}
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
            cleanseRetry=cleanseRetry>diff?cleanseRetry-diff:0;
            rezRetry=rezRetry>diff?rezRetry-diff:0;
            healMoveDelay=healMoveDelay>diff?healMoveDelay-diff:0;
            healLogDelay=healLogDelay>diff?healLogDelay-diff:0;
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
            DiagnoseResurrection(diff);
            if(!GlobalUpdate(diff)){TraceSurvival("global-update");Trace("global-update");return;}
            if(IAmFree()||!WDN1::Actor(me))
            { me->InterruptSpell(CURRENT_AUTOREPEAT_SPELL);me->RemoveAurasDueToSpell(Vigil,me->GetGUID());me->RemoveAurasDueToSpell(WDN1::Spirit,me->GetGUID());return; }
            DoVehicleActions(diff);
            if(!CanBotAttackOnVehicle()){TraceSurvival("vehicle");return;}
            if(TrySurvival(diff))return;
            if(ProcessImmediateNonAttackTarget()){TraceSurvival("immediate-action");Trace("vehicle-or-immediate");return;}
            if(TryResurrection(diff))return;
            bool const reserveHealingMana=ReserveHealingMana();
            Unit* healTarget=HealingTarget();
            if((!healTarget||!WDN5A::Urgent(healTarget->GetHealthPct(),HealingTank(healTarget)))&&TryCleansing(diff))return;
            if(healTarget && TryPriorityHeal(healTarget,diff))return;
            if(healTarget && WDN5A::Urgent(healTarget->GetHealthPct(),HealingTank(healTarget)))
            {
                if(TryManaIdol(diff))return;
                if(TryHealingWard(diff))return;
                TraceHealing("urgent-wait",healTarget);return;
            }
            if(TryVoodoo(diff))return;
            if(TryVigil(diff))return;
            if(TrySelfHeal(diff))return;
            if(TryBrewing(diff))return;
            if(TryAllyBrew(diff))return;
            if(reserveHealingMana&&TryManaIdol(diff))return;
            if(TryHealingWard(diff))return;
            if(TryManaIdol(diff))return;
            if(!HasRole(NPC_BOT_ROLE_DPS))
            {
                if(TrySereneIdol(diff))return;
                if(TrySwiftIdol(diff))return;
                Trace("support-only");return;
            }
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
            bool pullInRange=pulling&&HasRole(NPC_BOT_ROLE_RANGED)&&opener&&WDN1::Safe(me,target)&&
                me->GetDistance(target)>opener->GetMinRange(false)&&
                me->GetDistance(target)<=CalcSpellMaxRange(GetSpell(Arrow));
            if(pullInRange)
            {
                // A pull needs one settled first shot, not a new random attack point each tick.
                if(!JumpingOrFalling()&&me->isMoving())me->BotStopMovement();
                if(me->GetVictim()!=target)me->Attack(target,!HasRole(NPC_BOT_ROLE_RANGED));
                pullMoveDelay=0;
            }
            else if(pulling)
            {
                // Force acquisition even when the current movement is following the owner.
                // Native GetInPosition still enforces STAY, CC and positioning permissions.
                if(!pullMoveDelay){GetInPosition(true,target);pullMoveDelay=750;}
            }
            else {pullMoveDelay=0;GetInPosition(false,target);} // Keep native STAY/positioning checks.
            if(!WDN1::Safe(me,target)){Trace("unsafe-target");return;}
            // A melee pull must reach contact: ranged casts stop the native chase before the first hit.
            if(pulling&&!HasRole(NPC_BOT_ROLE_RANGED)&&!me->IsWithinMeleeRange(target))return;
            // Native melee swing checks were missing for the non-ranged DPS branch.
            if(!HasRole(NPC_BOT_ROLE_RANGED))CheckAttackState();
            if(!me->IsAlive()||!target->IsAlive())return;
            // Native doCast handles movement/real cast time; do not suppress instant spells.
            KeepAutoShot(target);
            if(reserveHealingMana){Trace("healing-mana-reserve");return;}
            if(!pulling&&TryCursedEffigy(target,diff))return;
            if(!pulling&&TryHexingEffigy(target,diff))return;
            // Establish Hex/Jinx first; then favor actual combat summons over optional effigies.
            if(!pulling&&MaintainDebuffs(target,diff))return;
            if(!pulling&&TryMassWards(target,diff))return;
            if(!pulling&&!utilityDelay&&me->IsWithinDistInMap(target,28.0f)&&
               WDN1C::Known(me)&&!WDN1C::Current(me)&&IsSpellReady(WDN1C::SpellId,diff)&&
               CheckBotCast(me,WDN1C::SpellId)==SPELL_CAST_OK&&bot_ai::doCast(me,WDN1C::SpellId))return;
            if(!pulling&&TryMimic(target,diff))return;
            if(!pulling&&TryGravenEffigy(target,diff))return;
            if(!pulling&&TryShadowEffigy(target,diff))return;
            if(!pulling&&TrySereneIdol(diff))return;
            if(!pulling&&TrySwiftIdol(diff))return;
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
