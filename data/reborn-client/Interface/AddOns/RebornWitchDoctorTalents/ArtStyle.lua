-- TG31B: presentation only. Defaults to the original CoA art.
local originalHome, originalTree = {}, {}
local keys = {'voodoo','brewing','shadowhunting'}
local root = 'Interface\\AddOns\\RebornTalentGuide\\Art\\'
for _,key in ipairs(keys) do
 originalHome[key]=RebornWDHomeArt['spec-thumbnail-witchdoctor-'..key]
 originalTree[key]=RebornWDArt['talents-background-witchdoctor-'..key]
end
function RebornWDApplyArtStyle()
 local modern=RebornWDArtStyle=='new'
 for i,key in ipairs(keys) do
  RebornWDHomeArt['spec-thumbnail-witchdoctor-'..key]=modern and {root..'WitchDoctorSpecCardsTG31A_blp',512,310,(i-1)*.25,i*.25,0,.60546875} or originalHome[key]
  RebornWDArt['talents-background-witchdoctor-'..key]=modern and {root..'WitchDoctorSpec'..i..'TG31A_blp',1612,774,0,.787109375,0,.755859375} or originalTree[key]
 end
end
RebornWDApplyArtStyle()
