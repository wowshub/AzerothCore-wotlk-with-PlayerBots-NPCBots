// WD173: map-thread-only explicit provisioning; never called by combat ticks.
#pragma once
#include "RebornWitchDoctorNodeLayout.h"
class Player;
class Creature;
namespace WD173 {
struct Receipt {
 char const* status="unavailable";
 unsigned revision=0,slot=0,spec=3,level=0,ae=0,te=0,missing=0,spell=0,paid=0;
 bool committed=false,ready=false;
 WD139::Build build;
};
Receipt Preview(Player*,std::string_view profile);
Receipt Enroll(Player*,unsigned expectedRevision);
Receipt Bind(Player*,std::string_view profile,unsigned expectedRevision);
Receipt Apply(Player*,std::string_view profile,unsigned expectedRevision,unsigned expectedLevel,std::string_view expectedHex);
Receipt TrainOne(Player*,Creature*,unsigned maximumCopper);
Receipt ConfirmTraining(Player*,unsigned spell);
}
