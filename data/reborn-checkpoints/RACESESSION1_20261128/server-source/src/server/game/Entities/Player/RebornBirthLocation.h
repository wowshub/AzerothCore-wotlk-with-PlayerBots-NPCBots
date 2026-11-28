#pragma once
#include "DatabaseEnv.h"
#include "Log.h"
#include "MapMgr.h"
#include "Player.h"
#include "ObjectMgr.h"
#include "DBCStores.h"
#include "RebornNeutralOrigin.h"
inline uint8 RebornStartZone(uint8 team,uint8 zone) {
 if(team<2&&zone>=129&&zone<=141)return zone;
 constexpr uint8 a[]={0,129,130,131,132,0,0,0,0};
 constexpr uint8 h[]={0,0,0,0,0,129,131,130,132};
 return team<2&&zone<9?(team==0?a[zone]:h[zone]):0;
}
inline bool ValidRebornStartZone(uint8 team,uint8 zone) { return zone && RebornStartZone(team,zone)!=0; }
inline uint32 RebornBirthCinematic(uint8 team,uint8 zone) {
 if(team>1||!zone)return 0; // DK0 and old defaults retain their original cinematic.
 if(zone<129) {
  if(auto* race=sChrRacesStore.LookupEntry(zone))return race->CinematicSequence;
  return 0;
 }
 if(zone>140)return 0;
 constexpr uint32 base[2][4]={{81,41,61,163},{21,2,141,162}};
 const unsigned slot=zone-129;
 return slot<4?base[team][slot]:50000u+unsigned(team)*100u+slot+1;
}
inline bool RebornBirthRoutesReady() {
 static const bool ready=[] {
  QueryResult schema=CharacterDatabase.Query("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='character_reborn_birth_route'");
  if(!schema||schema->Fetch()[0].Get<uint32>()!=1)return false;
  for(uint8 team=0;team<2;++team)for(uint8 zone=129;zone<=140;++zone)
   if(!sCinematicSequencesStore.LookupEntry(RebornBirthCinematic(team,zone)))return false;
  return true;
 }();
 return ready;
}
struct RebornBirthLocation {
 uint32 mapId=0,areaId=0;float positionX=0,positionY=0,positionZ=0,orientation=0;
};
inline bool ResolveRebornBirth(uint8 team,uint8 playerClass,uint8 zone,RebornBirthLocation& out) {
 const bool tableRoute = zone >= 129 && zone <= 141;
 if (tableRoute ? (team > 1 || !sChrClassesStore.LookupEntry(playerClass))
                : !RebornNeutralOrigin::Zone(team,playerClass,zone))
  return false;
 if (tableRoute) {
  out.areaId=0;
  QueryResult result=WorldDatabase.Query("SELECT map_id,position_x,position_y,position_z,orientation FROM spelldraft_starting_zone WHERE team={} AND slot={} AND enabled=1",team,uint32(zone-128));
  if(!result) {
   LOG_ERROR("entities.player", "STARTFIX1B birth rejected: missing enabled WORLD route team={} slot={} zone={} class={}", uint32(team), uint32(zone-128), uint32(zone), uint32(playerClass));
   return false;
  }
  Field* f=result->Fetch();
  out.mapId=f[0].Get<uint32>();out.positionX=f[1].Get<float>();out.positionY=f[2].Get<float>();out.positionZ=f[3].Get<float>();out.orientation=f[4].Get<float>();
 } else {
  // Keep all previously saved1/2/3/4/5/6/10/11 origins and DK0 stable.
  uint8 source=playerClass==6 && zone==0?RebornNeutralOrigin::Donor(team,6):zone;
  PlayerInfo const* info=sObjectMgr->GetPlayerInfo(source,playerClass==6&&zone==0?6:1);
  if(!info)return false;out.mapId=info->mapId;out.areaId=info->areaId;
  out.positionX=info->positionX;out.positionY=info->positionY;out.positionZ=info->positionZ;out.orientation=info->orientation;
 }
 MapEntry const* entry=sMapStore.LookupEntry(out.mapId);
 const bool valid = entry && !entry->Instanceable() && MapMgr::IsValidMapCoord(out.mapId,out.positionX,out.positionY,out.positionZ,out.orientation);
 if (zone==141) LOG_INFO("entities.player", "STARTFIX1B birth resolve: team={} map={} x={} y={} z={} orientation={} mapDBC={} instance={} valid={}", uint32(team), out.mapId, out.positionX,out.positionY,out.positionZ,out.orientation, bool(entry), entry?entry->Instanceable():false, valid);
 return valid;
}
