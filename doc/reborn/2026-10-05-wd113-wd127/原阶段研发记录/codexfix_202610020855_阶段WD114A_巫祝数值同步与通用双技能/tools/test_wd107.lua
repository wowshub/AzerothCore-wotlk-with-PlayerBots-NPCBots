local locale='zhCN'
GetLocale=function()return locale end
UnitClass=function()return 'WD','WITCHDOCTOR',13 end
UnitLevel=function()return 80 end
GetTime=function()return 0 end
IsSpellKnown=function()return false end
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
local hooks={}
GameTooltip={HookScript=function(self,k,v)hooks[k]=v end,GetSpell=function()return 'Brew',9003138 end,GetName=function()return 'GameTooltip'end,NumLines=function()return 2 end,Show=function()end,SetSpellByID=function()end,SetAction=function()end,SetSpellBookItem=function()end}
hooksecurefunc=function()end
GetSpellBookItemInfo=function()return 'SPELL',9003138 end
GetActionInfo=function()return 'spell',9003138 end
local ranks={}
RebornWD8={loaded=true,modern=true,active=1,specs={0,1,3},aeMasks={'old','exact-high-mask',0},AERank=function(id,mask)assert(mask=='exact-high-mask');return ranks[id]or 0 end}
local file=arg[1];local A=assert(loadfile(file))();local count=0
local function eq(x,y)assert(x==y,x..' != '..y);count=count+1 end
for _,loc in ipairs({'zhCN','enUS'})do
 locale=loc;A=assert(loadfile(file))()
 for id,base in pairs(A.brewTimes)do
  for r=0,2 do
   ranks[29736]=r
   local expected=tostring(base-r*.25)
   assert(A.Display(id):find(expected,1,true),A.Display(id));count=count+1
  end
 end
 ranks[29736]=2
 RebornWD8.draftAE='draft-zero'
 assert(A.Display(9003138):find('2.5',1,true));count=count+1
 RebornWD8.specs[2]=0;assert(A.Display(9003138):find('3',1,true));count=count+1
 ranks[6058]=1;assert(A.Display(9003103):find('2',1,true));count=count+1
 RebornWD8.specs[2]=1
 RebornWD8.pending=true;assert(A.Display(9003138):find(loc=='zhCN' and '待同步' or 'pending',1,true));count=count+1
 RebornWD8.pending=nil
 local text=loc=='zhCN' and '3秒施法时间' or '3 sec cast'
 GameTooltipTextLeft2={GetText=function()return text end,SetText=function(self,s)text=s end}
 A.Refresh(GameTooltip);assert(text:find('2.5',1,true));count=count+1
 ranks[29736]=1;A.Refresh(GameTooltip);assert(text:find('2.75',1,true));count=count+1
 ranks[29736]=0;A.Refresh(GameTooltip);assert(not text:find('2.75',1,true));count=count+1
 text='持续20秒';A.Refresh(GameTooltip);eq(text,'持续20秒')
end
print('PASS '..count..' display assertions: ten ranks, 0/1/2 saved rank, active spec, ignored draft, exact mask, pending, bilingual header, live refresh and prose preservation')
