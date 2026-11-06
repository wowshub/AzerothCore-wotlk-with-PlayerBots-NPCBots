# 原文件与新文件对比

## CharacterCreate.lua

```diff
--- B_当前原文件
+++ C_新文件
@@ -6133,6 +6133,11 @@

 -- RACEUI1B: class button state is a result of the current selection, not click history.
 local function RaceUIFinishClassState()
+ -- RACEUI1C: this XML texture is a 256x96 character-list bar, not the circular class ring.
+ for i=1,MAX_CLASSES_PER_RACE do
+  local button=_G["CharCreateClassButton"..i]
+  if button and button.selection then button.selection:Hide() end
+ end
  if not RaceUISelected() or PAID_SERVICE_TYPE then return end
  local warrior=RaceUIWarrior()
  local classes={GetAvailableClasses()}
@@ -6151,7 +6156,7 @@
    if pushed then pushed:SetAlpha(allowed and 1 or .4);pushed:SetDesaturated(not allowed) end
    local cover=_G["CharCreateClassButton"..index.."DisableTexture"]
    if cover then if allowed then cover:Hide() else cover:Show() end end
-   if button.selection then if allowed and selected==index then button.selection:Show() else button.selection:Hide() end end
+   if button.selection then button.selection:Hide() end
    if button.nameFrame and button.nameFrame.text then
     button.nameFrame.text:SetText((allowed and "|cffffd100" or "|cff696969")..tostring(classes[offset]).."|r")
     button.nameFrame.text:SetAlpha(1)
@@ -6163,9 +6168,23 @@
   if button then
    button:Disable();button:SetChecked(false);SetButtonDesaturated(button,true)
    if button.selection then button.selection:Hide() end
+   if button.ascendNeutralRing then button.ascendNeutralRing:SetDesaturated(true);button.ascendNeutralRing:SetAlpha(.4) end
+   local normal=button:GetNormalTexture()
+   if normal then normal:SetAlpha(.4) end
+   if button.nameFrame and button.nameFrame.text then button.nameFrame.text:SetTextColor(.45,.45,.45);button.nameFrame.text:SetAlpha(.65) end
   end
  end
  CharCreate_EnableNextButton(warrior~=nil and selected==warrior)
+end
+-- RACEUI1C: restore styling before the original whitelist computes old-race availability.
+local function RaceUIResetDetachedStyles()
+ for _,button in pairs({CharCreateMonkButton,CharCreateWitchDoctorPreviewButton,CharCreateWitchHunterPreviewButton}) do
+  if button then
+   if button.ascendNeutralRing then button.ascendNeutralRing:SetAlpha(1);button.ascendNeutralRing:SetDesaturated(false) end
+   local normal=button:GetNormalTexture();if normal then normal:SetAlpha(1) end
+   if button.nameFrame and button.nameFrame.text then button.nameFrame.text:SetTextColor(1,.82,0);button.nameFrame.text:SetAlpha(1) end
+  end
+ end
 end
 do
  local enumerate=CharacterCreateEnumerateClasses
@@ -6181,6 +6200,7 @@
    local cover=_G["CharCreateClassButton"..i.."DisableTexture"]
    if cover then cover:Hide() end
   end
+  RaceUIResetDetachedStyles()
   enumerate(...)
   RaceUIFinishClassState()
  end
@@ -6200,3 +6220,14 @@
   RaceUIFinishClassState()
  end
 end
+
+-- RACEUI1C: public bridge for the actual custom race-button Open handler.
+function CharacterCreate_RefreshRaceClassState(raceIndex)
+ if PAID_SERVICE_TYPE then return end
+ if raceIndex~=GetSelectedRace() then return end
+ CharacterCreate.selectedRace=raceIndex
+ CharacterCreateEnumerateClasses(GetAvailableClasses())
+ local _,_,index=GetSelectedClass()
+ SetCharacterClass(index)
+ RaceUIFinishClassState()
+end

```

## RebornRacePreview.lua

```diff
--- B_当前原文件
+++ C_新文件
@@ -84,6 +84,11 @@
     if CharacterCreate and CharacterCreate.backgroundRaceByListId then CharacterCreate.backgroundRaceByListId[s] = scene end
     A, B = e, s
     SetSelectedRace(s) SetSelectedSex(sex or 0) SetCharacterRace(s) SetCharacterCreateFacing(-15)
+    -- RACEUI1C: this custom button bypasses CharacterRace_OnClick; refresh the real class UI here.
+    if type(CharacterCreate_RefreshRaceClassState) == "function" then
+        CharacterCreate_RefreshRaceClassState(s)
+    end
+
     if CharacterCreate_UpdateModel then CharacterCreate_UpdateModel(CharacterCreate) end
     if e.drac and CharacterCreate_SetDracthyrBackground then pcall(CharacterCreate_SetDracthyrBackground, 1) CharacterCreate.r27WheelZoomLevel = 1 end
     -- experimental per-race model offset (the preview camera cannot be set); other races go back to 0,0,0

```
