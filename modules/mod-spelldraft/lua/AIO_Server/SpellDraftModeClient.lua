local AIO = AIO or require("AIO")
if AIO.AddAddon() then return end
-- RACECOMBO1E: full UI is an ordinary addon, loaded before entering the world.
if _G.RebornModeGateBuild ~= "RACECOMBO1E" then
    print("|cffff3333[RebornModeGate] Please install and enable RebornModeGate and AIO_Client.|r")
elseif type(_G.RebornModeGateRequest) == "function" then
    _G.RebornModeGateRequest()
end
