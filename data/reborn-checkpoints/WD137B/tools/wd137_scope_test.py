# coding: utf-8
from pathlib import Path
import subprocess
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');P=Path(Path('wd137_path.txt').read_text().strip());SF=P/'01_覆盖到源代码根目录'
text=(SF/'modules/mod-reborn-witchdoctor/src/RebornWitchDoctor.cpp').read_text(encoding='utf8')
a=text.index('        if(mod->spellId==9003957)');b=text.index('        if(mod->spellId==9003914)',a);matching=text[a:b]
text=(SF/'src/server/game/Spells/Spell.cpp').read_text(encoding='utf8');a=text.index('    Player const* mixer=');b=text.index('    if(!info || !(info->Id==9003822',a);moving=text[a:b]
src=r'''#include <cassert>
#include <cstdint>
#include <cstdio>
using uint32=uint32_t;
enum { SPELLMOD_DAMAGE=0,SPELLMOD_DOT=22,SPELLMOD_ALL_EFFECTS=8 };
struct SpellInfo { uint32 Id; }; struct SpellModifier { uint32 spellId,op; };
struct Player { bool alive=true,known=true,aura=true;uint32 cls=13; bool IsAlive() const {return alive;}uint32 getClass() const{return cls;}bool HasSpell(uint32)const{return known;}bool HasAura(uint32,uint32)const{return aura;}uint32 GetGUID()const{return 1;} };
struct Unit {Player* player;Player const* ToPlayer()const{return player;}};
bool Unmatched(SpellInfo const* check,SpellModifier const* mod) {
'''+matching+'''return true;}
bool Moving(Unit const* caster,SpellInfo const* info) {
'''+moving+r'''return false;}
int main(){
 const uint32 util[]={9003902,9003903,9003904,9003906,9003907,9003908,9003916,9003917,9003918};
 unsigned checks=0;
 for(uint32 id=9003000;id<=9004000;++id) for(uint32 op=0;op<32;++op){
  bool expected=(id==9003866&&op==0)||((id==9003867||id==9003889)&&op==22);
  for(auto u:util) expected|=id==u&&op==8;
  SpellInfo info{id};SpellModifier mod{9003957,op};assert(!Unmatched(&info,&mod)==expected);++checks;
 }
 Player p;Unit u{&p};
 for(uint32 id=9003000;id<=9004000;++id){SpellInfo s{id};assert(Moving(&u,&s)==(id>=9003460&&id<=9003467));++checks;}
 SpellInfo bottle{9003460};p.aura=false;assert(!Moving(&u,&bottle));p.aura=true;p.known=false;assert(!Moving(&u,&bottle));p.known=true;p.alive=false;assert(!Moving(&u,&bottle));p.alive=true;p.cls=8;assert(!Moving(&u,&bottle));u.player=nullptr;assert(!Moving(&u,&bottle));assert(!Moving(nullptr,&bottle));assert(!Moving(&u,nullptr));
 std::printf("PASS %u exact source predicate combinations + seven ownership/null negatives\n",checks);
}
'''
t=P/'checks/scope';t.mkdir(parents=True,exist_ok=True);(t/'test.cpp').write_text(src,encoding='utf8')
cmd='@echo off\ncall "D:\\soft\\vs2022\\enterprise\\VC\\Auxiliary\\Build\\vcvars64.bat" >nul\ncl /nologo /std:c++20 /EHsc /utf-8 "'+str(t/'test.cpp')+'" /Fo"'+str(t/'test.obj')+'" /Fe"'+str(t/'test.exe')+'"\nif errorlevel 1 exit /b 1\n"'+str(t/'test.exe')+'"\n'
(P/'tools/scope.cmd').write_text(cmd,encoding='utf8');print(P/'tools/scope.cmd')
