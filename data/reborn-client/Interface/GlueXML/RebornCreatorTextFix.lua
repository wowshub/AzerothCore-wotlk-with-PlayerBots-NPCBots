-- RebornCreatorTextFix.lua (GLUEFONT1A V1, 2026-11-26, Claude) - candidate, NOT user-tested.
-- Symptom: on the character creation screen a Chinese label (e.g. the active step in the top bar) sometimes shows broken or shifted glyphs.
-- Likely cause: the client keeps drawn glyphs in a small cache per font and size; the creator puts almost all of its Chinese text into the same
-- font (ARKai_T), so when new text pushes old glyphs out, strings that were not re-set keep pointing at the wrong picture.
--   1. the top step labels get a font/size of their own, so the race and class lists cannot push their glyphs out;
--   2. every text on the creator is set again shortly after each redraw and then every few seconds, which rebuilds a broken string.
-- Separate file on purpose: RebornCreator.lua is not changed. Listed in GlueXML.toc.
do
    local C = RebornCreator
    if type(C) == 'table' and type(C.Render) == 'function' and CharacterCreate then
        local HEADER_FONT, HEADER_SIZE = 'Fonts\\ARKai_C.ttf', 16
        local PERIOD = 2.0
        local DELAYS = {0.05, 0.4}      -- after a redraw: once the new glyphs have been drawn, and once more after models/lists settle
        local pending = {}
        local sincePeriodic = 0
        local broken = false

        local function reset(fs)
            local t = fs:GetText()
            if t and t ~= '' then
                fs:SetText('')
                fs:SetText(t)
            end
        end

        local function walk(frame, depth)
            if depth > 8 then return end
            local regions = {frame:GetRegions()}
            for i = 1, #regions do
                if regions[i]:GetObjectType() == 'FontString' then reset(regions[i]) end
            end
            local children = {frame:GetChildren()}
            for i = 1, #children do walk(children[i], depth + 1) end
        end

        local function headerFont()
            if not C.steps then return end
            for _, b in ipairs(C.steps) do
                if b.label and not b.rebornOwnFont then
                    b.label:SetFont(HEADER_FONT, HEADER_SIZE, '')
                    b.rebornOwnFont = true
                end
            end
        end

        local function refresh()
            if broken or not C.active or not C.root or not C.root:IsShown() then return end
            local ok = pcall(function()
                headerFont()
                walk(C.root, 0)
            end)
            if not ok then broken = true end         -- never repeat an error every frame
        end

        local render = C.Render
        local function after(...)
            pcall(headerFont)
            for i, d in ipairs(DELAYS) do pending[i] = d end
            return ...
        end
        function C.Render(...)
            return after(render(...))
        end

        local timer = CreateFrame('Frame', nil, CharacterCreate)
        timer:SetScript('OnUpdate', function(self, elapsed)
            elapsed = elapsed or arg1 or 0
            for i = 1, #DELAYS do
                if pending[i] then
                    pending[i] = pending[i] - elapsed
                    if pending[i] <= 0 then
                        pending[i] = false
                        refresh()
                    end
                end
            end
            sincePeriodic = sincePeriodic + elapsed
            if sincePeriodic >= PERIOD then
                sincePeriodic = 0
                refresh()
            end
        end)
    end
end
