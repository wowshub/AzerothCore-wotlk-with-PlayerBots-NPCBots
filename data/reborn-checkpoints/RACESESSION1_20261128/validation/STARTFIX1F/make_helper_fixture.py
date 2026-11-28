from pathlib import Path
w=Path(r'D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261127/codexwork_STARTFIX1F');e=w.parent/'codexwork_STARTFIX1E'
s=(e/'fixture.cpp').read_text();start=s.index('static void FitDracthyrSheathedStaff(');end=s.index('\nint main()',start)
r=(w/'src/WoW/Common/ComponentCore/RetailRace.cpp').read_text();a=r.index('static void FitDracthyrSheathedStaff(');b=r.index('\nvoid RetailRaceEquipment',a)
s=s[:start]+r[a:b]+s[end:]
s=s.replace('struct Vec {','struct Vec {Vec()=default;Vec(float a,float b,float c):x(a),y(b),z(c){}')
s=s.replace('struct C44Matrix','using C3Vector=Vec;\nstruct C44Matrix',1)
s=s.replace('float scale=0;','float scale=0;Vec offset;')
s=s.replace('bool SetAttachmentFrame(unsigned b,Vec p,float s){','bool SetAttachmentFrame(unsigned b,Vec p,Vec sizes,float yaw,Vec move){float s=sizes.x;offset=move;')
s=s.replace('child.applied.z-2.65f','child.applied.z-3.f').replace('child.scale==1&&','child.scale==1&&std::abs(child.offset.z+.55f)<.00001f&&')
s=s.replace('absolute offset/no drift','actor-space offset/no drift')
(w/'helper-fixture.cpp').write_text(s)
