local ADDON_NAME = ...
local frame = CreateFrame("Frame", "DromsInstanceTimerFrame", UIParent)

-- Config
local MAX_INSTANCES = 50
local ROLLING_WINDOW = 3600 -- seconds

-- State
-- SavedVariables
DromsInstanceTimerDB = DromsInstanceTimerDB or {}
DromsInstanceTimerOptions = DromsInstanceTimerOptions or {}

local instanceEntries = {}

-- UI setup
frame:SetSize(200, 24)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

-- Options table
local options = {
    mode = "bar", -- "bar" or "square"
    strata = "MEDIUM",
}

local bg = frame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetTexture(0, 0, 0, 0.5)

-- Header above the bar
local header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
header:SetPoint("BOTTOM", frame, "TOP", 0, 2)
header:SetText("Drom's Instance Timer")

local bar = CreateFrame("StatusBar", nil, frame)
bar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
bar:SetMinMaxValues(0, MAX_INSTANCES)
bar:SetPoint("TOPLEFT", 2, -2)
bar:SetPoint("BOTTOMRIGHT", -2, 2)
bar:SetStatusBarColor(0.2, 0.8, 0.2, 1)

local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text:SetPoint("CENTER", frame, "CENTER")
text:SetText("0 / 50")

-- Square mode fontstring
local squareText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
squareText:SetPoint("CENTER", frame, "CENTER")
squareText:SetText("0")
squareText:Hide()

frame:SetFrameStrata(options.strata)
frame:SetSize(200, 24)
frame:Hide()

-- Helper: Cleanup expired entries
table.sort = table.sort -- ensure sort is available
local function cleanup()
    local now = time()
    local newEntries = {}
    for _, t in ipairs(instanceEntries) do
        t = tonumber(t) -- ensure t is a number
        if t and now - t < ROLLING_WINDOW then
            table.insert(newEntries, t)
        end
    end
    wipe(instanceEntries)
    for _, t in ipairs(newEntries) do
        table.insert(instanceEntries, t)
    end
end

-- Helper: Update UI
local function updateUI()
    cleanup()
    local count = #instanceEntries
    -- Display mode
    if options.mode == "bar" then
        bar:Show()
        text:Show()
        squareText:Hide()
        bar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
        frame:SetSize(200, 24)
        bar:SetMinMaxValues(0, MAX_INSTANCES)
        bar:SetValue(count)
        text:SetText(count .. " / " .. MAX_INSTANCES)
    else
        bar:Hide()
        text:Hide()
        squareText:Show()
        frame:SetSize(24, 24)
        squareText:SetText(count)
    end
    frame:SetFrameStrata(options.strata)
    -- Always leave frame visibility to user control
    -- Color change if near limit
    if count >= MAX_INSTANCES * 0.9 then
        bar:SetStatusBarColor(0.8, 0.2, 0.2, 1)
    else
        bar:SetStatusBarColor(0.2, 0.8, 0.2, 1)
    end
end

-- Event: Detect instance entry
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGOUT")

local wasInInstance = IsInInstance()

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == ADDON_NAME then
        -- Load DB
        if DromsInstanceTimerDB and type(DromsInstanceTimerDB) == "table" then
            instanceEntries = DromsInstanceTimerDB
        end
        if DromsInstanceTimerOptions and type(DromsInstanceTimerOptions) == "table" then
            for k,v in pairs(DromsInstanceTimerOptions) do
                options[k] = v
            end
        end
        cleanup()
        updateUI()
    elseif event == "PLAYER_LOGOUT" then
        -- Save DB
        cleanup()
        DromsInstanceTimerDB = instanceEntries
        DromsInstanceTimerOptions = options
    else
        local inInstance, instanceType = IsInInstance()
        if inInstance and not wasInInstance then
            -- Entered a new instance
            table.insert(instanceEntries, time())
            updateUI()
        end
        wasInInstance = inInstance
        cleanup()
        updateUI()
    end
end)

-- Timer: Periodic cleanup
local elapsed = 0
frame:SetScript("OnUpdate", function(self, e)
    elapsed = elapsed + e
    if elapsed > 10 then -- every 10 seconds
        cleanup()
        updateUI()
        elapsed = 0
    end
end)

-- Slash command to show/hide and options
SLASH_DROMSINSTANCETIMER1 = "/dit"
SlashCmdList["DROMSINSTANCETIMER"] = function(msg)
    msg = msg and msg:lower() or ""
    if msg:find("mode") then
        local mode = msg:match("mode%s+(%w+)")
        if mode == "bar" or mode == "square" then
            options.mode = mode
            print("DromsInstanceTimer: Mode set to " .. mode)
        end
    elseif msg:find("strata") then
        local s = msg:match("strata%s+(%w+)")
        if s then
            options.strata = s:upper()
            print("DromsInstanceTimer: Strata set to " .. options.strata)
        end
    elseif msg == "show" then
        updateUI()
        frame:Show()
        -- Force show even if count is zero
        frame:Show()
    elseif msg == "hide" then
        frame:Hide()
    else
        print("DromsInstanceTimer options:")
        print("/dit show - Show frame")
        print("/dit hide - Hide frame")
        print("/dit mode bar|square - Display as bar or square")
        print("/dit strata <strata> - Set frame strata (e.g. BACKGROUND, LOW, MEDIUM, HIGH, DIALOG)")
    end
    updateUI()
end

-- Interface Options Panel
local panel = CreateFrame("Frame")
panel.name = "DromsInstanceTimer"

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Drom's Instance Timer Options")

local modeLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
modeLabel:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)
modeLabel:SetText("Display Mode:")

local modeBar = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
modeBar:SetPoint("LEFT", modeLabel, "RIGHT", 10, 0)
local modeBarLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
modeBarLabel:SetPoint("LEFT", modeBar, "RIGHT", 4, 0)
modeBarLabel:SetText("Bar")

local modeSquare = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
modeSquare:SetPoint("LEFT", modeBarLabel, "RIGHT", 40, 0)
local modeSquareLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
modeSquareLabel:SetPoint("LEFT", modeSquare, "RIGHT", 4, 0)
modeSquareLabel:SetText("Square")

local function updateModeChecks()
    modeBar:SetChecked(options.mode == "bar")
    modeSquare:SetChecked(options.mode == "square")
end
modeBar:SetScript("OnClick", function()
    options.mode = "bar"
    updateModeChecks()
    updateUI()
end)
modeSquare:SetScript("OnClick", function()
    options.mode = "square"
    updateModeChecks()
    updateUI()
end)

local strataLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
strataLabel:SetPoint("TOPLEFT", modeLabel, "BOTTOMLEFT", 0, -32)
strataLabel:SetText("Frame Strata:")

local strataLevels = {"BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG"}
local strataDisplay = {"Low", "Low+", "Medium", "High", "Dialog"}
local strataSlider = CreateFrame("Slider", "DromsInstanceTimerStrataSlider", panel, "OptionsSliderTemplate")
strataSlider:SetWidth(200)
strataSlider:SetHeight(16)
strataSlider:SetMinMaxValues(1, #strataLevels)
strataSlider:SetValueStep(1)
strataSlider:SetPoint("LEFT", strataLabel, "RIGHT", 10, 0)
getglobal(strataSlider:GetName() .. 'Low'):SetText("Low")
getglobal(strataSlider:GetName() .. 'High'):SetText("High")
getglobal(strataSlider:GetName() .. 'Text'):SetText(strataDisplay[3])

local function updateStrataSlider()
    for i, v in ipairs(strataLevels) do
        if options.strata == v then
            strataSlider:SetValue(i)
            getglobal(strataSlider:GetName() .. 'Text'):SetText(strataDisplay[i])
            break
        end
    end
end
strataSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)
    options.strata = strataLevels[value]
    frame:SetFrameStrata(options.strata)
    getglobal(self:GetName() .. 'Text'):SetText(strataDisplay[value])
end)

panel.refresh = function()
    updateModeChecks()
    updateStrataSlider()
end

InterfaceOptions_AddCategory(panel)
