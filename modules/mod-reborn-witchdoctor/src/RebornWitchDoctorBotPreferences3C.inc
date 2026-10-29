// MBWD3C: called only on login, explicit preference requests and deletion.
// AI readiness/selection reads WDMB3::Read from memory and never queries SQL.
namespace WDMB3
{
bool PersistenceAvailable()
{
    auto q=CharacterDatabase.Query("SELECT "
        "(SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='reborn_mbwd_preferences' AND engine='InnoDB')=1 AND "
        "(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='reborn_mbwd_preferences')=3 AND "
        "(SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema=DATABASE() AND routine_type='PROCEDURE' AND routine_name IN('reborn_mbwd3c_state','reborn_mbwd3c_set'))=2");
    return q && q->Fetch()[0].Get<uint32>()==1;
}
inline bool DecodePreference(QueryResult const& q,Snapshot& value,std::string& status)
{
    if(!q || q->GetFieldCount()!=3)return false;
    auto* f=q->Fetch();status=f[0].Get<std::string>();
    value={f[1].Get<uint32>(),f[2].Get<uint32>()};
    return value.mask<=All && value.revision<=2000000000u &&
        (status=="ok" || status=="stale" || status=="invalid");
}
bool LoadPersistent(Player* player)
{
    if(!player)return false;
    auto* state=player->CustomData.GetDefault<State>(Key);
    state->persistent=false;
    if(!PersistenceAvailable())return false;
    auto q=CharacterDatabase.Query("CALL reborn_mbwd3c_state({})",player->GetGUID().GetCounter());
    Snapshot value;std::string status;
    if(!DecodePreference(q,value,status) || status!="ok")return false;
    state->value=value;state->persistent=true;return true;
}
Update SetPersistent(Player* player,uint32 expected,uint32 mask)
{
    if(!player)return {Read(player),Result::Database};
    auto* state=player->CustomData.GetDefault<State>(Key);
    if(!PersistenceAvailable()){state->persistent=false;return {state->value,Result::Database};}
    auto q=CharacterDatabase.Query("CALL reborn_mbwd3c_set({},{},{})",player->GetGUID().GetCounter(),expected,mask);
    Snapshot value;std::string status;
    if(!DecodePreference(q,value,status))
    {state->persistent=false;return {state->value,Result::Database};}
    state->value=value;state->persistent=true;
    return {value,status=="ok"?Result::Ok:status=="stale"?Result::Stale:Result::Invalid};
}
}
