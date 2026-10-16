// WD154: Mirage, Senjin Swiftness / Wisdom (authored choice627411).
namespace WD154
{
constexpr uint32 Mirage=9004110,Swift=9004111,Wisdom=9004112,Clone=9004113,Speed=9004114,Entry=900254;
constexpr char Key[]="RebornWD154.Mirage";
struct State:DataMap::Base {ObjectGuid clone;};
constexpr uint32 Cooldown(bool swift){return swift?120000u:180000u;}
constexpr uint32 Duration(bool wisdom){return wisdom?40000u:20000u;}
bool Owns(Player* p,uint32 id){return IsDoctor(p)&&p->IsAlive()&&p->HasSpell(id);}
void Clear(Player* p){auto* s=p->CustomData.Get<State>(Key);if(!s)return;ObjectGuid id=s->clone;s->clone.Clear();if(p->IsInWorld())if(Creature* c=ObjectAccessor::GetCreature(*p,id))if(c->GetEntry()==Entry&&c->GetOwnerGUID()==p->GetGUID())c->DespawnOrUnsummon();}
class modifiers:public GlobalScript
{
public:modifiers():GlobalScript("reborn_wd154_modifiers"){}
bool OnIsAffectedBySpellModCheck(SpellInfo const*,SpellInfo const* check,SpellModifier const* mod)override
{if(check&&mod&&(mod->spellId==Swift||mod->spellId==Wisdom))return !(check->Id==Mirage&&mod->op==(mod->spellId==Swift?SPELLMOD_COOLDOWN:SPELLMOD_DURATION));return true;}
};
class cast:public SpellScript
{
PrepareSpellScript(cast);
SpellCastResult Check(){Player* p=GetCaster()->ToPlayer();return Owns(p,Mirage)&&p->GetLevel()>=10?SPELL_CAST_OK:SPELL_FAILED_CASTER_AURASTATE;}
void Done(){Player* p=GetCaster()->ToPlayer();if(!Owns(p,Mirage))return;for(uint32 i=0;i<5;++i)p->CastSpell(p,WD87A::Spirit,true);WD87A::Sync(p);}
void Register()override{OnCheckCast+=SpellCheckCastFn(cast::Check);AfterCast+=SpellCastFn(cast::Done);}
};
class aura:public AuraScript
{
PrepareAuraScript(aura);
void Apply(AuraEffect const*,AuraEffectHandleModes){Player* p=GetTarget()->ToPlayer();if(!Owns(p,Mirage)||GetCasterGUID()!=p->GetGUID())return;
 if(!p->IsInWorld())return;
 p->CastSpell(p,Speed,true);if(Aura* speed=p->GetAura(Speed,p->GetGUID())){speed->SetMaxDuration(GetMaxDuration());speed->SetDuration(GetDuration());}
 if(TempSummon* c=p->SummonCreature(Entry,p->GetPosition(),TEMPSUMMON_TIMED_DESPAWN,std::max(1,GetDuration()))){Clear(p);p->CustomData.GetDefault<State>(Key)->clone=c->GetGUID();}
}
void Remove(AuraEffect const*,AuraEffectHandleModes){if(Unit* u=GetTarget())u->RemoveAurasDueToSpell(Speed,GetCasterGUID());}
void Tick(AuraEffect const*){PreventDefaultAction();Player* p=GetTarget()->ToPlayer();if(!Owns(p,Mirage)||GetCasterGUID()!=p->GetGUID())return;
 std::list<Unit*> units;Acore::AnyUnitInObjectRangeCheck check(p,100.0f);Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(p,units,check);Cell::VisitObjects(p,search,100.0f);
 for(Unit* u:units)if(u&&p->IsInMap(u)&&p->InSamePhase(u)&&u->CanHaveThreatList())u->GetThreatMgr().ModifyThreatByPercent(p,-20);
}
bool Check(ProcEventInfo& e){Player* p=GetTarget()->ToPlayer();auto* spell=e.GetProcSpell();auto* info=e.GetSpellInfo();
 if(!Owns(p,Mirage)||e.GetActor()!=p||GetCasterGUID()!=p->GetGUID()||(e.GetTypeMask()&PROC_FLAG_DONE_PERIODIC)|| (spell&&spell->IsTriggered())|| (info&&info->Id==WD87A::Spirit))return false;
 return (e.GetDamageInfo()&&e.GetDamageInfo()->GetDamage()>0)||(e.GetHealInfo()&&e.GetHealInfo()->GetEffectiveHeal()>0);
}
void Proc(ProcEventInfo&){PreventDefaultAction();GetTarget()->RemoveAurasDueToSpell(Mirage,GetCasterGUID());}
void Register()override{AfterEffectApply+=AuraEffectApplyFn(aura::Apply,EFFECT_0,SPELL_AURA_MOD_INVISIBILITY,AURA_EFFECT_HANDLE_REAL);AfterEffectRemove+=AuraEffectRemoveFn(aura::Remove,EFFECT_0,SPELL_AURA_MOD_INVISIBILITY,AURA_EFFECT_HANDLE_REAL);OnEffectPeriodic+=AuraEffectPeriodicFn(aura::Tick,EFFECT_1,SPELL_AURA_PERIODIC_DUMMY);DoCheckProc+=AuraCheckProcFn(aura::Check);OnProc+=AuraProcFn(aura::Proc);}
};
class npc:public CreatureScript
{
public:npc():CreatureScript("npc_reborn_wd154_mirage"){}
struct AI:ScriptedAI
{
ObjectGuid owner;explicit AI(Creature* c):ScriptedAI(c){me->SetReactState(REACT_PASSIVE);me->SetCombatMovement(false);}
void AttackStart(Unit*)override{}
void IsSummonedBy(WorldObject* summoner)override{Player* p=summoner?summoner->ToPlayer():nullptr;if(!Owns(p,Mirage)){me->DespawnOrUnsummon();return;}
 owner=p->GetGUID();me->SetOwnerGUID(owner);me->SetCreatorGUID(owner);me->SetFaction(p->GetFaction());me->SetLevel(p->GetLevel());me->SetMaxHealth(std::max(5u,uint32(p->GetLevel())*10));me->SetHealth(me->GetMaxHealth());
 me->SetUnitFlag(UNIT_FLAG_PLAYER_CONTROLLED);me->m_ControlledByPlayer=true;
 for(uint32 i=0;i<3;++i)me->SetVirtualItem(i,p->GetUInt32Value(PLAYER_VISIBLE_ITEM_1_ENTRYID+(EQUIPMENT_SLOT_MAINHAND+i)*2));
 me->SetByteValue(UNIT_FIELD_BYTES_2,0,p->GetByteValue(UNIT_FIELD_BYTES_2,0));me->SetByteValue(UNIT_FIELD_BYTES_2,1,p->GetByteValue(UNIT_FIELD_BYTES_2,1));
 me->SetDisplayId(p->GetDisplayId());p->CastSpell(me,Clone,true);me->SetWalk(false);Position pos=p->GetPosition();p->MovePositionToFirstCollision(pos,25.0f,0.f);me->GetMotionMaster()->MovePoint(1,pos);
}
void UpdateAI(uint32)override{Player* p=ObjectAccessor::GetPlayer(*me,owner);if(!Owns(p,Mirage)||!p->IsInMap(me)||!p->InSamePhase(me)||p->CustomData.GetDefault<State>(Key)->clone!=me->GetGUID())me->DespawnOrUnsummon();}
};
CreatureAI* GetAI(Creature* c)const override{return new AI(c);}
};
class lifecycle:public PlayerScript
{
public:lifecycle():PlayerScript("reborn_wd154_lifecycle"){}
void OnPlayerLogout(Player* p)override{if(IsDoctor(p)){p->RemoveAurasDueToSpell(Mirage,p->GetGUID());Clear(p);}}
void OnPlayerMapChanged(Player* p)override{if(IsDoctor(p)){p->RemoveAurasDueToSpell(Mirage,p->GetGUID());Clear(p);}}
void OnPlayerUpdate(Player* p,uint32)override{if(!IsDoctor(p))return;if(!Owns(p,Mirage)){p->RemoveAurasDueToSpell(Mirage,p->GetGUID());Clear(p);}if(!p->HasAura(Mirage,p->GetGUID()))p->RemoveAurasDueToSpell(Speed,p->GetGUID());}
};
class diagnostics:public CommandScript
{
public:diagnostics():CommandScript("reborn_wd154_diagnostics"){}
static bool Check(ChatHandler* h){Player* p=h->GetSession()->GetPlayer();if(!IsDoctor(p))return false;Aura* a=p->GetAura(Mirage,p->GetGUID());Aura* speed=p->GetAura(Speed,p->GetGUID());Creature* clone=nullptr;if(auto* s=p->CustomData.Get<State>(Key))clone=ObjectAccessor::GetCreature(*p,s->clone);
 h->PSendSysMessage("WD154 learned={} swift={} wisdom={} expected_cd_ms={} server_cd_remaining_ms={} expected_duration_ms={} aura_max_ms={} aura_remaining_ms={} speed_remaining_ms={} spirits={} clone={} clone_remaining_ms={}",p->HasSpell(Mirage)?1:0,p->HasAura(Swift,p->GetGUID())?1:0,p->HasAura(Wisdom,p->GetGUID())?1:0,Cooldown(p->HasAura(Swift,p->GetGUID())),p->GetSpellCooldownDelay(Mirage),Duration(p->HasAura(Wisdom,p->GetGUID())),a?a->GetMaxDuration():0,a?a->GetDuration():0,speed?speed->GetDuration():0,WD87A::Count(p),clone?1:0,clone&&clone->ToTempSummon()?clone->ToTempSummon()->GetTimer():0);return true;
}
Acore::ChatCommands::ChatCommandTable GetCommands()const override{using namespace Acore::ChatCommands;static ChatCommandTable commands={{"wd154check",Check,SEC_PLAYER,Console::No}};return commands;}
};
void Register(){new modifiers();new npc();new lifecycle();new diagnostics();RegisterSpellScript(WD154::cast);RegisterSpellScript(WD154::aura);}
}
namespace WD154Bridge
{
void Apply(Player* p,bool mirage,bool swift,bool wisdom){if(!IsDoctor(p))return;bool flags[]={mirage,swift,wisdom};uint32 ids[]={WD154::Mirage,WD154::Swift,WD154::Wisdom};
 for(uint32 i=0;i<3;++i)if(!flags[i]){p->RemoveAurasDueToSpell(ids[i],p->GetGUID());if(p->HasSpell(ids[i]))p->removeSpell(ids[i],3,false);}
 for(uint32 i=0;i<3;++i)if(flags[i]){if(!p->HasSpell(ids[i]))p->learnSpell(ids[i]);if(i&&!p->HasAura(ids[i],p->GetGUID()))p->CastSpell(p,ids[i],true);}
 if(!mirage)WD154::Clear(p);
}
}
