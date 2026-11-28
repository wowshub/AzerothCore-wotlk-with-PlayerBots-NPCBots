#ifndef REBORN_NEUTRAL_ORIGIN_WIRE_H
#define REBORN_NEUTRAL_ORIGIN_WIRE_H
#include <cstdint>
#include <cstddef>
namespace RebornNeutralOrigin {
inline constexpr uint32_t Magic=0x314F4E52; // RNO1, creation only
inline constexpr size_t Size=12;
struct Choice { uint8_t race=0, playerClass=0, sex=0, team=2, zone=0; };
inline constexpr bool IsRace(unsigned r) {
 switch(r) {case 56:case 73:case 76:case 83:case 89:case 90:case 93:case 96:case 97:case 98:case 103:case 106:case 112:case 114:case 115:case 116:return true;default:return false;}
}
inline constexpr bool IsClass(unsigned c){return (c>=1&&c<=9)||c==11;}
inline constexpr bool IsSex(unsigned r,unsigned s){
 if(!IsRace(r)||s>1)return false;
 if(r==56||r==90)return s==1;
 if(r==73||r==76||r==89||r==93)return true;
 return s==0;
}
inline constexpr uint8_t Donor(unsigned team,unsigned c){
 constexpr uint8_t a[]={0,1,1,3,1,1,1,11,1,1,0,4};
 constexpr uint8_t h[]={0,2,10,2,2,5,2,2,5,2,0,6};
 return team<2&&IsClass(c)?(team?h[c]:a[c]):0;
}
inline constexpr bool Zone(unsigned team,unsigned c,unsigned z){
 if(team>1||!IsClass(c))return false;
 if(z>=129 && z<=141)return true; // faction starting-zone slots 1–13
 if(c==6)return z==0; // Acherus: preserve the class's required initial quest/phase chain.
 return team==0?(z==1||z==3||z==4||z==11):(z==2||z==5||z==6||z==10);
}
inline constexpr bool Valid(Choice v){return IsSex(v.race,v.sex)&&IsClass(v.playerClass)&&Zone(v.team,v.playerClass,v.zone);}
inline constexpr bool ValidCreate(Choice v){
 // The four duplicate-body identities retain old records, but expose one creation slot.
 return Valid(v) && ((v.race!=73 && v.race!=76 && v.race!=89 && v.race!=93) || v.sex==0);
}
inline bool Write(uint8_t* p,Choice v){
 if(!p||!ValidCreate(v))return false;
 p[0]=v.race;p[1]=v.playerClass;p[2]=v.sex;p[3]=v.team;p[4]=v.zone;p[5]=1;p[6]=p[7]=0;
 for(unsigned i=0;i<4;i++)p[8+i]=uint8_t(Magic>>(i*8));return true;
}
inline bool Read(uint8_t const*p,size_t n,Choice& out){
 if(!p||n!=Size||p[5]!=1||p[6]||p[7])return false;
 uint32_t magic=0;for(unsigned i=0;i<4;i++)magic|=uint32_t(p[8+i])<<(i*8);if(magic!=Magic)return false;
 Choice v{p[0],p[1],p[2],p[3],p[4]};if(!ValidCreate(v))return false;out=v;return true;
}
template<class Packet> bool ReadTail(Packet& packet,bool& present,Choice& out){
 present=false;auto r=packet.rpos(),n=packet.size();if(r>n)return false;if(n-r<4)return true;
 auto p=packet.contents()+n-4;uint32_t magic=0;for(unsigned i=0;i<4;i++)magic|=uint32_t(p[i])<<(i*8);
 if(magic!=Magic)return true;if(n-r<Size)return false;
 Choice value;if(!Read(packet.contents()+n-Size,Size,value))return false;
 packet.resize(n-Size);packet.rpos(r);present=true;out=value;return true;
}
}

#endif
