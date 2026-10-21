// WD173 v1 test profiles: canonical server validator is the final authority.
#pragma once
#include "RebornWitchDoctorNodeLayout.h"
#include <vector>
namespace WD173 {
inline unsigned Spec(std::string_view name) {
 if(name=="wd173-voodoo")return 0;
 if(name=="wd173-brewing")return 1;
 if(name=="wd173-shadow")return 2;
 return 3;
}
inline unsigned Index(unsigned id){for(unsigned i=0;i<WD139::Count;++i)if(WD139::Nodes[i].id==id)return i;return WD139::Count;}
// Rank-by-rank and repeated dependency passes. Never remove stored ranks or add bonus points.
template<class Valid>bool Grow(WD139::Build const& saved,unsigned spec,unsigned level,Valid valid,WD139::Build& out) {
 if(spec>2||level<10||!saved.SpecValid(spec)||!saved.Valid()||!valid(saved))return false;
 out=saved;
 std::vector<unsigned> goals;
 if(spec==0)goals={4004,31154,31344,31340,7157,6058,30973,4533,6062,6046,6007,6053,6045,31347,31348,31343,6644,30889,31350,5333,6059,5332,31345,11532,4532,29121,31346,29768,7100,6057,30596,29929,31349,6055,11133};
 if(spec==1)goals={4005,12645,12646,7131,30884,29736,5055,7129,9311,4715,7948,31137,35065,35064,35068,29738,30888,35051,29303,6022,6021,6498,6015,4112,6016,7132,6009,4733,30823,29754,30333,6027,13133,6026,29740,7133};
 if(spec==2)goals={4006,12086,4505,1969,7779,7086,8574,30895,6010,6072,6074,4506,30892,6983,6063,6069,5253,29729,7031,6073,5164,6011,11330,4572,5235,6388,29978,6076,7781,11164,29981,7102,5303,4177,7103,4423,29977,12145};
 std::vector<unsigned> common={29744,29301,6054,6047,7092,29309,7088,6030,31118,6042,30891,6031,9347,30147,6051,12264,7033};
 goals.insert(goals.end(),common.begin(),common.end());
 // Bound by the finite layout; free nodes are attempted too, without spending a fake point.
 for(unsigned pass=0;pass<WD139::Capacity;++pass) {
  bool changed=false;
  for(unsigned id:goals) {
   unsigned i=Index(id);if(i==WD139::Count||out.ranks[i]>=WD139::Nodes[i].maximum)continue;
   auto next=out;++next.ranks[i];
   if(next.SpecValid(spec)&&valid(next)){out=next;changed=true;}
  }
  if(!changed)return true;
 }
 return false;
}
}
