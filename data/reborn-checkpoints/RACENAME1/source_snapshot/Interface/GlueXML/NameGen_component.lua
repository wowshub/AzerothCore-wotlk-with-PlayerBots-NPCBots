-- RACEUI1A: scope by the actual current ChrRaces tokens and enumeration indexes.
local function RaceUIKind(index)
 local races={GetAvailableRaces()}
 for i=1,#races,3 do
  if (i+2)/3==index then
   local token=type(races[i+1])=="string" and string.upper(races[i+1]) or ""
   if token=="REBORNSETHRAK" then return "SETHRAK" end
   if token=="REBORNOGRE" then return "OGRE" end
   return nil
  end
 end
end
local function RaceUIWarrior()
 local classes={GetAvailableClasses()}
 for i=1,#classes,3 do
  if type(classes[i+1])=="string" and string.upper(classes[i+1])=="WARRIOR" then return (i+2)/3 end
 end
end
local function RaceUISelected()
 return RaceUIKind(CharacterCreate and CharacterCreate.selectedRace or GetSelectedRace())
end
-- RACEUI1A: native NameGen has no rows for the two new tokens.
local RaceUINamePools={["SETHRAK0"]={"Agamand","Andromath","Antonidas","Fordred","Nielas","Arius","Arugal","Sten","Ballador","Barthilas","Aedelas","Conjurus","Rex","Danath","Saidin","Dalar","Alonsus","Tenn","Tirion","Taelan","Gavinrad","Granis","Genn","Nandis","Geros","Jorn","Khadgar","Landazar","Shal","Anduin","Doril","Marn","Malak","Manadar","Medivh","Arthas","Terenas","Morlune","Moroes","Daelin","Rhonin","Sage","Duncan","Manos","Peril","Aran","Thoras","Turalyon","Uther","Varien","Llane","Zann","Aimery","Alex","Alonso","Ander","Anselm","Apollo","Arlan","Benedict","Berenger","Bertren","Bruce","Carl","Carlin","Carter","Cedric","Clement","Clinton","Daniel","Darren","Derek","Eric","Errol","Everard","Garth","Geoff","Graham","Gregory","Guillaume"},["SETHRAK1"]={"Aegwynn","Taretha","Calia","Maevis","Alexis","Ariandra","Kassandra","Wilhelmina","Gloriana","Sarah","Samantha","Kitiara","April","Jorune","Brunhilde","Sithaya","Andra","Amora","Dierdre","Sandris","Adelaide","Alice","Amaria","Amelia","Avelina","Barbara","Beatrix","Betta","Brigit","Calli","Candis","Carolyn","Catherine","Catin","Christiana","Christine","Cicely","Constance","Cristina","Dagny","Danielle","Darcy","Desiree","Felicity","Florencia","Giliana","Gladys","Grace","Heloise","Honor","Hope","Jane","Joy","Kaisa","Kamilla","Kimberly","Lia","Lois","Lola","Lucille","Margery","Marilyn","Marlena","Meghan","Mercy","Mirabell","Naomi","Pamela","Peggy","Prudence","Reyna","Rhoda","Sabeline","Theda","Thelma","Theresa","Tiffany","Tina","Tracy","Verity"},["OGRE0"]={"Akinos","Arashicage","Baelgun","Bale","Blackhand","Kargath","Broxxigar","Chogall","Clawhand","Magis","Kazil","Daisho","Kilrogg","Dentarg","Orgrim","Doomroar","Naz","Drekthar","Durotan","Eitrigg","Fenrisar","Fenris","Foerend","Gathras","Gardal","Gorr","Guldan","Negal","Grom","Irontusk","Kajind","Kalthar","Kazragore","Kigami","Maim","Mazuru","Mikasa","Nazgrel","Nikoro","Zess","Rend","Rexxar","Samuro","Nekros","Tagar","Thrall","Thundrax","Tojara","Uglaz","Kag","Warmaul","Borr","Pand","Kagar","Wolfsong","Morg","Yozshura","Zuluhed","Zargil","Asato","Asuya","Azuma","Baku","Chuugo","Dahr","Dai","Daichi","Dugan","Dugrum","Emok","Engo","Fukashi","Fusao","Goragon","Gor-Ka","Gulmore","Gunga","Gyousei","Hakuba","Iku"},["OGRE1"]={"Draka","Garona","Nekra","Gara","Theg","Markas","Sendra","Sergra","Gaine","Dala","Morisha","Galvania","Titania","Jenka","Ragos","Mirsha","Misha","Korvis","Mandiss","Germana","Agata","Agna","Akana","Akheena","Anga","Asako","Atsuko","Aya","Boka","Chantu","Cora","Damah","Doba","Doska","Duka","Eghala","Elka","Eta","Garuka","Ghana","Gisa","Gruta","Hedda","Hilar","Iria","Junna","Kaia","Kama","Kasa","Kaya","Loka","Luka","Machiko","Magda","Maiko","Maja","Makha","Moka","Mugallah","Nagisa","Nanaka","Nayu","Nodoka","Onela","Palka","Rana","Rela","Roka","Saaya","Sana","Tabitha","Tamao","Tamsin","Tanya","Teruna","Tetsumi","Tokimi","Yatsumi","Yukari","Agasa"}}
local function RaceUIRandomName()
 local kind=RaceUISelected()
 local before=CharacterCreateNameEdit:GetText() or ""
 local candidate=GetRandomName()
 if kind and (type(candidate)~="string" or candidate=="" or candidate==before) then
  local sex=GetSelectedSex()==SEX_FEMALE and 1 or 0
  local names=RaceUINamePools[kind..sex]
  local start=math.random(1,#names)
  for i=0,#names-1 do
   local value=names[(start+i-1)%#names+1]
   if value~=before then candidate=value;break end
  end
 end
 if type(candidate)=="string" and candidate~="" then CharacterCreateNameEdit:SetText(candidate) end
end

function CharacterCreate_GenerateRandomName(button)
 RaceUIRandomName()
end
