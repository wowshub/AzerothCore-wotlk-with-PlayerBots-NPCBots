// WD174 explicit provisioning API; map-thread-only, returned state is a value copy.
#pragma once
#include "RebornWitchDoctorBotJobPolicy174.h"
class Player;
namespace WD174 {
State Start(Player*,std::string_view profile,unsigned totalCopper,bool watchLevels);
State Status(Player*);
State Cancel(Player*,std::string_view reason="cancelled");
void Tick(Player*,unsigned diff);
void Forget(Player*);
}
