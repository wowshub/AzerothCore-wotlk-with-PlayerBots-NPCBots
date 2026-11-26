-- RebornShipMovie v3 (SHIP2D V2, 2026-11-23, Claude)
-- The server (ShipCrash.lua) sends addon message "RBSHIP" with "MOVIE|<path>"; this plays the avi by path.
-- v2: when that movie ends (finished, or skipped with ESC / SPACE / ENTER) the addon tells the server "RBSHIP|DONE" so the
-- server can send the player to the island at once instead of waiting for its timer.
local ours = false

local function err(msg)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffff4040[RebornShipMovie] " .. tostring(msg) .. "|r") end
end

local function reportDone()
    if not ours then return end
    ours = false
    local ok, e = pcall(SendAddonMessage, "RBSHIP", "DONE", "WHISPER", UnitName("player"))
    if not ok then err(e) end
end

local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_ADDON")
f:SetScript("OnEvent", function(self, event, prefix, msg)
    if prefix ~= "RBSHIP" or type(msg) ~= "string" then return end
    local cmd, arg = strsplit("|", msg, 2)
    if cmd == "MOVIE" and arg and arg ~= "" then
        local ok, e = pcall(function()
            if MovieFrame_PlayMovie and MovieFrame then
                ours = true
                MovieFrame_PlayMovie(MovieFrame, arg, 100)
            else
                error("MovieFrame not available")
            end
        end)
        if not ok then
            ours = false
            err(e)
            pcall(SendAddonMessage, "RBSHIP", "DONE", "WHISPER", UnitName("player"))     -- cannot play: do not leave the player waiting
        end
    end
end)

-- every way a movie closes goes through MovieFrame:Hide() (natural end, ESC, SPACE, ENTER, failure to start)
if MovieFrame and MovieFrame.HookScript then
    MovieFrame:HookScript("OnHide", function() pcall(reportDone) end)
end
