
local function forbidden() error('Native mutation or render invocation from addon') end
local function frozen(t) return setmetatable({}, {__index=t,__newindex=forbidden,__pairs=function() return pairs(t) end,__ipairs=function() return ipairs(t) end}) end
BOOKTYPE_SPELL='spell'
SlashCmdList={}
function UnitClass() return '巫医','WITCHDOCTOR',13 end
function GetNumSpellTabs()return 2 end
function GetSpellTabInfo(i)if i==1 then return '综合',nil,0,1 else return '巫毒 / Voodoo',nil,1,1 end end
function GetSpellLink(i)return i==2 and 'spell:9003853' or 'spell:6603' end
function GetSpellInfo(id)return 'Test'..id end
function IsSpellKnown()return true end
local log={}
function print(s)log[#log+1]=s end
local events
function CreateFrame()events={RegisterEvent=function()end,SetScript=function(self,k,v)self[k]=v end};return events end
spellbookCustomRender=frozen({[2]=frozen({{spellID=9003853}})})
SpellBookFrame=frozen({bookType='spell'})
SPELLBOOK_PAGENUMBERS=frozen({[2]=1})
SpellBookFrame_UpdateSpellRender=forbidden
SpellButton_UpdateButton=forbidden
SpellBookSkillLineTab_OnClick=forbidden
hooksecurefunc=forbidden
CastSpellByID=forbidden
local before=SpellBookFrame_UpdateSpellRender
local M=assert(loadfile(arg[1]))()
SlashCmdList.REBORNWDBOOK('')
SlashCmdList.REBORNWDBOOK('假死')
SlashCmdList.REBORNWDBOOK('9003853')
assert(M.locate(9003853)==2)
assert(SpellBookFrame_UpdateSpellRender==before)
events.OnEvent(nil,'ADDON_ACTION_FORBIDDEN','DBM-Core','CastSpellByID()')
SlashCmdList.REBORNWDBOOK('假死')
assert(log[#log]:find('DBM-Core',1,true) and log[#log]:find('CastSpellByID',1,true))
io.write('PASS WD119B read-only book: native globals/tables/handlers untouched, diagnostics and blocked event preserved\n')
