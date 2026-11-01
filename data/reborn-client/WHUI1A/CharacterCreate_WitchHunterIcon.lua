-- WHUI1A: icon-only entry. It never selects or creates a native class.
function CharacterCreate_PositionWitchHunterIcon()
    local button = CharCreateWitchHunterPreviewButton;
    if not button or not CharCreateClassFrame then return; end
    button:SetParent(CharCreateClassFrame);
    CharacterCreate_StyleAscendClassButton(button);
    button:ClearAllPoints();
    button:SetPoint("BOTTOM", "CharCreateClassFrame", "TOP", CharacterCreate_AscendClassSlotX(2), MONK_CLASS_BUTTON_Y);
    button:SetFrameStrata("HIGH");
    button:SetFrameLevel(CharCreateClassFrame:GetFrameLevel() + 30);
    button:SetChecked(0);
    button:Enable();
    if button.nameFrame and button.nameFrame.text then
        button.nameFrame.text:SetText("猎巫者");
    end
    button.tooltip = "|cffffffff猎巫者 / Witch Hunter|r|n|n|cffffd200CoA 新职业|r|n|n|cffffffff移植开发中，暂未开放创建。|r";
    if PAID_SERVICE_TYPE then button:Hide(); else button:Show(); end
end
-- WHUI1A end.
