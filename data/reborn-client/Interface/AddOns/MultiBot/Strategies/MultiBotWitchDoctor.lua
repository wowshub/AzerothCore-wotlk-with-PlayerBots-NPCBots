-- MBWD1A: Reborn native Witch Doctor strategy adapter (WoW 3.3.5).
-- Roles come from WD168's active plan, not generic +heal/+tank strategies.
local function tip(title, body)
    return "|cffffd100" .. title .. "|r\n" .. body
end
function MultiBot.WDHasStrategy(text, strategy)
    for token in string.gmatch(text or "", "[^,]+") do
        if string.match(token, "^%s*(.-)%s*$") == strategy then return true end
    end
    return false
end
local function roster(name)
    local bar = MultiBot.frames and MultiBot.frames.MultiBar
    local units = bar and bar.frames and bar.frames.Units
    return units and units.buttons and units.buttons[name]
end
local pending = {}
local function request(button, command)
    local name = button.getName()
    local unit = roster(name)
    if not unit then return end
    local now = GetTime()
    if pending[name] and now - pending[name] < 3 then return end
    -- Never replace an inventory/spell/detail response currently being awaited.
    if unit.waitFor and unit.waitFor ~= "" then return end
    pending[name] = now
    unit.waitFor = "CO"
    -- CO reply -> existing handler queries NC -> rebuilds from both replies.
    -- No optimistic setEnable: a rejected command must not light an icon.
    MultiBot.ActionToTarget(command, name)
end
local function info(button)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(button.tip) end
end
function MultiBot.addWitchDoctor(frame, combat, normal)
    pending[frame.name] = nil
    local function toggle(key, x, icon, title, body, strategy, snapshot, commandOn, commandOff)
        local active = MultiBot.WDHasStrategy(snapshot, strategy)
        local state = active and "已启用 / Enabled" or "未启用 / Disabled"
        local b = frame.addButton(key, x, 0, icon, tip(title, body .. "\n" .. state ..
            "\n左键切换，等待服务器确认 / Click to toggle; wait for server confirmation."))
        b.setDisable()
        if active then b.setEnable() end
        b.doLeft = function(btn) request(btn, active and commandOff or commandOn) end
        return b
    end
    toggle("WDCombat", 0, "spell_shadow_demonbreath", "巫医战斗 / Witch Doctor combat",
        "运行巫医原生技能逻辑。输出或治疗由当前天赋方案决定。\nNative rotation; active talent plan determines DPS or healing.\n关闭它也会停止战斗中的原生治疗。/ Disabling also stops native combat healing.",
        "wd169 combat", combat, "co +wd169 combat,?", "co -wd169 combat,?")

    -- Support is a separate non-combat engine. The trailing CO query enters the
    -- established CO/NC refresh chain; NC modification itself requests no reply.
    local support = MultiBot.WDHasStrategy(normal, "wd169 support")
    local s = frame.addButton("WDSupport", -30, 0, "inv_potion_54", tip("脱战支援 / Out-of-combat support",
        "控制脱战后的原生支援，不是战斗治疗开关。\nControls native support outside combat, not combat healing.\n" ..
        (support and "已启用 / Enabled" or "未启用 / Disabled") .. "\n左键切换 / Click to toggle."))
    s.setDisable(); if support then s.setEnable() end
    s.doLeft = function(btn)
        local name=btn.getName(); local unit=roster(name)
        if not unit or (unit.waitFor and unit.waitFor~="") then return end
        if pending[name] and GetTime()-pending[name]<3 then return end
        MultiBot.ActionToTarget(support and "nc -wd169 support" or "nc +wd169 support", name)
        request(btn, "co ?")
    end
    toggle("WDDpsAssist", -60, "ability_hunter_aimedshot", "输出辅助 / DPS assist",
        "启用通用输出选怪策略；不改变天赋，也不强制酿造变成输出。\nEnables DPS target selection; does not change your talent plan.",
        "dps assist", combat, "co -tank assist,-dps aoe,+dps assist,?", "co -dps assist,?")
    toggle("WDTankAssist", -90, "ability_warrior_shieldmastery", "坦克辅助 / Tank assist",
        "通用坦克选怪策略，和输出辅助互斥。不是主坦克职责或嘲讽开关。\nTank target-selection strategy, exclusive with DPS assist. Not a tank role or taunt toggle.\n巫医没有独立主坦克轮转。/ No native main-tank rotation.",
        "tank assist", combat, "co -dps assist,-dps aoe,+tank assist,?", "co -tank assist,?")
    local book=frame.addFrame("WDGuide",-122,30);book:Hide()
    frame.addButton("WDPlaybook",-120,0,"inv_misc_book_06",tip("巫医策略手册 / Witch Doctor guide",
        "左键展开职业图标与说明 / Click for role and ability guidance.")).doLeft=function() MultiBot.ShowHideSwitch(book) end
    local entries={
        {"DPS","ability_hunter_rapidkilling","输出 / DPS","暗影狩猎：远程输出；巫毒：法术输出。\nShadowhunting: ranged DPS; Voodoo: spell DPS.\n需使用相应天赋方案，本按钮仅说明。/ Requires the matching active plan; information only."},
        {"Heal","spell_nature_healingwavegreater","治疗 / Healing","酿造方案优先治疗，战斗按钮必须开启；脱战支援单独控制。\nBrewing prioritizes healing; combat must be enabled. Out-of-combat support is separate.\n本按钮不切换天赋。/ This button does not switch talents."},
        {"Tank","inv_shield_06","坦克 / Tank","巫医尚无独立主坦克轮转，不能照搬德鲁伊熊形态策略。\nNo native main-tank rotation; druid bear strategies do not apply.\n坦克辅助仅影响选怪。/ Tank assist only affects target selection."},
        {"Summons","spell_nature_guardianward","守卫与召唤 / Wards and summons","由巫医原生逻辑按已学技能、冷却、蓝量与战况选择。\nNative logic checks learned spells, cooldowns, mana and combat conditions.\n不是萨满图腾开关。/ Not the shaman totems toggle."},
        {"Cure","spell_nature_nullifypoison","治疗与净化 / Healing and cleansing","由原生逻辑判断；通用 cure 不等于巫医净化总开关。\nHandled by native logic; generic cure is not a WD cleansing master switch."},
    }
    for i,e in ipairs(entries) do
        local b=book.addButton(e[1],0,(i-1)*30,e[2],tip(e[3],e[4]))
        b.doLeft=info -- explicit information cards, never fake enabled strategies
    end
    frame.addButton("WDRefresh",-150,0,"inv_misc_pocketwatch_01",tip("刷新策略 / Refresh strategies",
        "重新读取服务器战斗与脱战策略。\nRead combat and non-combat strategies from the server.")).doLeft=function(b) request(b,"co ?") end
end
