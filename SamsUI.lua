

--[[
    honorsystem-bar-frame
]]


local name, addon = ...


SamsUiConfigPanelMixin = CreateFromMixins(CallbackRegistryMixin)
SamsUiTopBarMixin = CreateFromMixins(CallbackRegistryMixin);
SamsUiPlayerBarMixin = CreateFromMixins(CallbackRegistryMixin);
SamsUiTargetBarMixin = CreateFromMixins(CallbackRegistryMixin);

local Database = CreateFromMixins(CallbackRegistryMixin)
Database:GenerateCallbackEvents({
    "OnConfigChanged",
    "OnInitialised",
});

function Database:Init()

    CallbackRegistryMixin.OnLoad(self)

    if not SamsUiConfig then
        SamsUiConfig = {};
    end

    if not SamsUiCharacters then
        SamsUiCharacters = {};
    end

    self:RegisterCallback("OnInitialised", SamsUiConfigPanel.LoadConfigVariables, SamsUiConfigPanel)
    self:RegisterCallback("OnInitialised", SamsUiPlayerBar.LoadConfigVariables, SamsUiPlayerBar)
    self:RegisterCallback("OnInitialised", SamsUiTargetBar.LoadConfigVariables, SamsUiTargetBar)

    self:RegisterCallback("OnConfigChanged", SamsUiPlayerBar.OnConfigChanged, SamsUiPlayerBar)
    self:RegisterCallback("OnConfigChanged", SamsUiTargetBar.OnConfigChanged, SamsUiTargetBar)

    self:TriggerEvent("OnInitialised")

end


function Database:AddNewCharacter(nameRealm)

    if not SamsUiCharacters then
        SamsUiCharacters = {};
    end

    if not SamsUiCharacters[nameRealm] then
        SamsUiCharacters[nameRealm] = {};
    end

end


function Database:InsertOrUpdateCharacterInfo(nameRealm, key, newValue)

    if not SamsUiCharacters then
        SamsUiCharacters = {};
    end

    if not SamsUiCharacters[nameRealm] then
        SamsUiCharacters[nameRealm] = {};
    end

    SamsUiCharacters[nameRealm][key] = newValue;

end


function Database:GetCharacterInfo(nameRealm, key)

    if type(SamsUiCharacters) ~= "table" then
        error("SamsUiCharacter table doesnt exist")
    end

    if not SamsUiCharacters[nameRealm] then
        error(string.format("SamsUiCharacter[%s] table doesnt exist", nameRealm))
    end

    if SamsUiCharacters[nameRealm][key] then
        return SamsUiCharacters[nameRealm][key];
    else
        error(string.format("unable to find [%s] in SamsUiCharacter[%s] table", key, nameRealm))
    end

end


function Database:UpdateConfig(setting, newValue)

    if not SamsUiConfig then
        SamsUiConfig = {}
    end

    SamsUiConfig[setting] = newValue;

    self:TriggerEvent("OnConfigChanged", setting, newValue)

end


function Database:AddNewConfigOption(setting, val)

    if not SamsUiConfig then
        SamsUiConfig = {}
    end

    if SamsUiConfig[setting] == nil then
        SamsUiConfig[setting] = val;
    end
    
end


function Database:GetConfigValue(setting)

    --DevTools_Dump({ SamsUiConfig })

    if type(SamsUiConfig) == "table" then
        
        if SamsUiConfig[setting] ~= nil then
            return SamsUiConfig[setting]

        else
            error(string.format("config setting %s not found in SamsUiConfig table", setting))
        end
    end
end








local Util = {}
function Util:FormatStatsusBarTags(t, s, cur, _max, per)
    s = s:gsub("{cur}", cur)
    s = s:gsub("{max}", _max)
    s = s:gsub("{per}", per)
    t:SetText(s)
end














SamsUiConfigPanelMixin:GenerateCallbackEvents({

});

function SamsUiConfigPanelMixin:OnLoad()

    self:RegisterForDrag("LeftButton")

    self:RegisterEvent("ADDON_LOADED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")

    SLASH_SAMSUI1 = "/sui"
    SlashCmdList.SAMSUI = function(msg)

        if SamsUiConfigPanel then
            SamsUiConfigPanel:SetShown(not SamsUiConfigPanel:IsVisible())
        end

    end

    --player frame
    self.playerHealthTextCheckButton:SetScript("OnClick", function()
        Database:UpdateConfig("showPlayerHealthText", self.playerHealthTextCheckButton:GetChecked())
    end)

    self.playerHealthTextFormatEditBox:SetScript("OnTextChanged", function()
        Database:UpdateConfig("playerHealthTextFormat", self.playerHealthTextFormatEditBox:GetText())
    end)

    self.playerPowerTextCheckButton:SetScript("OnClick", function()
        Database:UpdateConfig("showPlayerPowerText", self.playerPowerTextCheckButton:GetChecked())
    end)

    self.playerPowerTextFormatEditBox:SetScript("OnTextChanged", function()
        Database:UpdateConfig("playerPowerTextFormat", self.playerPowerTextFormatEditBox:GetText())
    end)


    --target frame
    self.targetHealthTextCheckButton:SetScript("OnClick", function()
        Database:UpdateConfig("showTargetHealthText", self.targetHealthTextCheckButton:GetChecked())
    end)

    self.targetHealthTextFormatEditBox:SetScript("OnTextChanged", function()
        Database:UpdateConfig("targetHealthTextFormat", self.targetHealthTextFormatEditBox:GetText())
    end)

    self.targetPowerTextCheckButton:SetScript("OnClick", function()
        Database:UpdateConfig("showTargetPowerText", self.targetPowerTextCheckButton:GetChecked())
    end)

    self.targetPowerTextFormatEditBox:SetScript("OnTextChanged", function()
        Database:UpdateConfig("targetPowerTextFormat", self.targetPowerTextFormatEditBox:GetText())
    end)





    -- this should go else where at some point there are probably more frames to move about though
    UIWidgetTopCenterContainerFrame:ClearAllPoints()
    UIWidgetTopCenterContainerFrame:SetPoint("TOP", MinimapCluster, "BOTTOM", 9, -10)

    DurabilityFrame:ClearAllPoints()
    DurabilityFrame:SetPoint("RIGHT", UIWidgetTopCenterContainerFrame, "LEFT", -10, 0)

    MirrorTimer1:ClearAllPoints()
    MirrorTimer1:SetPoint("TOP", MinimapCluster, "BOTTOM", 9, -5)

   
end



function SamsUiConfigPanelMixin:LoadConfigVariables()

    --DevTools_Dump({ SamsUiConfig })

    --player frame
    if Database:GetConfigValue("showPlayerHealthText") then
        self.playerHealthTextCheckButton:SetChecked(Database:GetConfigValue("showPlayerHealthText"))
    end

    if Database:GetConfigValue("playerHealthTextFormat") then
        self.playerHealthTextFormatEditBox:SetText(Database:GetConfigValue("playerHealthTextFormat"))
    end

    if Database:GetConfigValue("showPlayerPowerText") then
        self.playerPowerTextCheckButton:SetChecked(Database:GetConfigValue("showPlayerPowerText"))
    end

    if Database:GetConfigValue("playerPowerTextFormat") then
        self.playerPowerTextFormatEditBox:SetText(Database:GetConfigValue("playerPowerTextFormat"))
    end


    --target frame
    if Database:GetConfigValue("showTargetHealthText") then
        self.targetHealthTextCheckButton:SetChecked(Database:GetConfigValue("showTargetHealthText"))
    end

    if Database:GetConfigValue("targetHealthTextFormat") then
        self.targetHealthTextFormatEditBox:SetText(Database:GetConfigValue("targetHealthTextFormat"))
    end

    if Database:GetConfigValue("showTargetPowerText") then
        self.targetPowerTextCheckButton:SetChecked(Database:GetConfigValue("showTargetPowerText"))
    end

    if Database:GetConfigValue("targetPowerTextFormat") then
        self.targetPowerTextFormatEditBox:SetText(Database:GetConfigValue("targetPowerTextFormat"))
    end

end


function SamsUiConfigPanelMixin:Init()

    SetPortraitToTexture(self:GetName().."Portrait", 626006)

    self:SetUpMiniMap()

    self:SetUpBuffFrame()
end



function SamsUiConfigPanelMixin:SetUpBuffFrame()

    BuffFrame:ClearAllPoints()
    BuffFrame:SetPoint("TOPRIGHT", SamsUiPlayerBar, "BOTTOMRIGHT", -10, -10)

end


function SamsUiConfigPanelMixin:SetUpMiniMap()

    MinimapCluster:ClearAllPoints()
    MinimapCluster:SetPoint("TOP", -9, 20)
    MinimapCluster:SetFrameStrata("MEDIUM")

    MinimapBorderTop:Hide()
    MinimapToggleButton:Hide()
    MinimapZoneTextButton:Hide()

    MiniMapTracking:Hide()

    GameTimeFrame:Hide()

    MinimapZoomIn:Hide()
    MinimapZoomOut:Hide()

    MiniMapWorldMapButton:Hide()
    MiniMapWorldMapButton:SetScript("OnShow", function()
        MiniMapWorldMapButton:Hide()
    end)

end


function SamsUiConfigPanelMixin:OnEvent(event, ...)

    if event == "ADDON_LOADED" then
        
        if ... == "Blizzard_TimeManager" then
            -- TimeManagerClockButton:ClearAllPoints()
            -- TimeManagerClockButton:SetPoint("LEFT", SamsUiTopBar, "LEFT", 16, 0)
        end

        Database:Init()

    elseif event == "PLAYER_ENTERING_WORLD" then

        self:Init()

    end
end










SamsUiTopBarMixin:GenerateCallbackEvents({

});
SamsUiTopBarMixin.minimapButtonsMoved = false;

function SamsUiTopBarMixin:OnLoad()

    self.mainMenu.keys = {
        "Options",
        "Reload UI",
        "Character",
    }

    self.mainMenu.menu = {
        ["Options"] = {
            atlas = "services-icon-processing",
            func = function()
                SamsUiConfigPanel:Show()
            end,
        },
        ["Reload UI"] = {
            atlas = "characterundelete-RestoreButton",
            func = function()
                ReloadUI()
            end,
        },
        ["Character"] = {
            atlas = string.format("raceicon-%s-%s", UnitRace("player"):lower(), (UnitSex("player") == 2 and "male" or "female")),
            func = function()
                CharacterFrame:Show()
            end,
        },
    }

    self.addonsInstalled = {}
    for i = 1, GetNumAddOns() do
        local name, title, notes, loadable, reason, security, newVersion = GetAddOnInfo(i)
        table.insert(self.addonsInstalled, {
            name = name,
            title = title,
            notes = notes,
        })
    end

    self.mainMenu.buttons = {}

    self.openMainMenuButton:SetScript("OnClick", function()
        self.mainMenu:SetShown(not self.mainMenu:IsVisible())
    end)

    -- self.mainMenu:SetScript("OnHide", function()
    --     for _, button in ipairs(self.mainMenu.buttons) do
    --         --button:Hide()
    --     end
    -- end)
    self.mainMenu:SetScript("OnShow", function()
        self:OpenMainMenu()
    end)

    self.openMinimapButtonsButton:SetScript("OnClick", function()
        self:OpenMinimapButtonsMenu()
    end)

    self.minimapButtonsContainer:SetScript("OnHide", function()
        self.minimapButtonsContainer:SetAlpha(0)
        self.minimapButtonsContainer:SetPoint("TOPRIGHT", -150, -9)
    end)

    self.minimapButtonsContainer.anim.translate:SetScript("OnFinished", function()
        self.minimapButtonsContainer:SetPoint("TOPRIGHT", -150, -49)
    end)

end


function SamsUiTopBarMixin:OpenMinimapButtonsMenu()

    if self.minimapButtonsMoved == false then
        self:MoveAllLibMinimapIcons()
    end

    if self.minimapButtonsContainer:IsVisible() then
        return;
    end

    if self.minimapButtonsCloseDelayTicker then
        self.minimapButtonsCloseDelayTicker:Cancel()
    end

    self.minimapButtonsContainer:Show()
    self.minimapButtonsContainer.anim:Play()

    self.minimapButtonsCloseDelayTicker = C_Timer.NewTicker(2.5, function()
        if self.openMinimapButtonsButton:IsMouseOver() == false and self.minimapButtonsContainer:IsMouseOver() == false then
            local isHovered = false;
            for k, button in ipairs(self.minimapButtons) do
                if button and button:IsMouseOver() then
                    isHovered = true;
                end
            end
            if isHovered == true then
                return;
            end
            self.minimapButtonsContainer:Hide()
            self.minimapButtonsCloseDelayTicker:Cancel()
        end
    end)

end



function SamsUiTopBarMixin:MoveAllLibMinimapIcons()

    self.minimapButtons = {}

    local lib = LibStub("LibDBIcon-1.0")

    local buttonList = lib:GetButtonList()
    
    local buttons = {}
    local buttonNames = {}

    for k, name in ipairs(buttonList) do
        buttons[k] = lib:GetMinimapButton(name)
        buttonNames[k] = name;
    end

    if _G["ATT-Classic-Minimap"] then
        table.insert(buttons, _G["ATT-Classic-Minimap"])
    end

    for k, addon in ipairs(self.addonsInstalled) do
        if _G["Lib_GPI_Minimap_"..addon.name] then
            table.insert(buttons, _G["Lib_GPI_Minimap_"..addon.name])
        end
    end

    local yPos = 0;
    local NUM_ICONS_PER_ROWS = 5;
    for k, button in ipairs(buttons) do
        button:ClearAllPoints()
        button:SetParent(self.minimapButtonsContainer)
        button:Show()
        --if button:IsVisible() then
            button:SetPoint("LEFT", self.minimapButtonsContainer, "LEFT", yPos, 0)
            yPos = yPos + button:GetWidth()
        --end
        lib:Lock(buttonNames[k])
        self.minimapButtons[k] = button
    end

    self.minimapButtonsContainer:SetWidth(yPos)

    self.minimapButtonsMoved = true;

end



function SamsUiTopBarMixin:OpenMainMenu()

    if self.mainMenuCloseDelayTicker then
        self.mainMenuCloseDelayTicker:Cancel()
    end

    for k, item in ipairs(self.mainMenu.keys) do

        if not self.mainMenu.buttons[k] then
            local button = CreateFrame("BUTTON", nil, self.mainMenu, "SamsUiTopBarMainMenuButton")
            button:SetPoint("TOP", 0, (k-1)*-31)
            button:SetSize(200, 30)
            button:SetText(item)
            button:SetIconAtlas(self.mainMenu.menu[item].atlas)

            button.func = self.mainMenu.menu[item].func;
            
            button.anim.fadeIn:SetStartDelay(k/25)

            self.mainMenu.buttons[k] = button;

            self.mainMenu:SetSize(200, k*28)

        end
    end

    for _, button in ipairs(self.mainMenu.buttons) do
        button:Show()
    end

    self.mainMenuCloseDelayTicker = C_Timer.NewTicker(2.5, function()
        if self.mainMenu:IsMouseOver() == false and self.openMainMenuButton:IsMouseOver() == false then
            self.mainMenu:Hide()
            self.mainMenuCloseDelayTicker:Cancel()
        end
    end)
end






SamsUiPlayerBarMixin:GenerateCallbackEvents({

});
SamsUiPlayerBarMixin.playerHealthTextFormat = "{per} %"; -- set a default string to use on first load before getting db values
SamsUiPlayerBarMixin.playerPowerTextFormat = "{per} %";

function SamsUiPlayerBarMixin:OnLoad()

    self:RegisterEvent("UNIT_AURA")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    self:RegisterEvent("UNIT_PORTRAIT_UPDATE")
    
end


function SamsUiPlayerBarMixin:Init()

    self.playerPowerType, self.playerPowerToken = UnitPowerType("player")

    self.playerPowerRGB = PowerBarColor[self.playerPowerToken]
    self.powerBar:SetStatusBarColor(self.playerPowerRGB.r, self.playerPowerRGB.g, self.playerPowerRGB.b)

    local _, playerClass = UnitClass("player")
    local r, g, b, argbHex = GetClassColor(playerClass)
    self.portraitRing:SetVertexColor(r, g, b)

    SetPortraitTexture(self.portrait, "player")

    self:UnregisterEvent("PLAYER_ENTERING_WORLD")

end


function SamsUiPlayerBarMixin:LoadConfigVariables()

    if Database:GetConfigValue("showPlayerHealthText") then
        self.healthBar.text:SetShown(Database:GetConfigValue("showPlayerHealthText"))
    end

    if Database:GetConfigValue("playerHealthTextFormat") then
        self.playerHealthTextFormat = Database:GetConfigValue("playerHealthTextFormat")
    end

    if Database:GetConfigValue("showPlayerPowerText") then
        self.powerBar.text:SetShown(Database:GetConfigValue("showPlayerPowerText"))
    end

    if Database:GetConfigValue("playerPowerTextFormat") then
        self.playerPowerTextFormat = Database:GetConfigValue("playerPowerTextFormat")
    end

end


function SamsUiPlayerBarMixin:OnConfigChanged(setting, newValue)

    if setting == "playerHealthTextFormat" then
        self.playerHealthTextFormat = newValue;
    end

    if setting == "showPlayerHealthText" then
        self.healthBar.text:SetShown(newValue)
    end

    if setting == "playerPowerTextFormat" then
        self.playerPowerTextFormat = newValue;
    end

    if setting == "showPlayerPowerText" then
        self.powerBar.text:SetShown(newValue)
    end

end


function SamsUiPlayerBarMixin:OnEvent(event, ...)

    if event == "UNIT_AURA" then
        BuffFrame:ClearAllPoints()
        BuffFrame:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", -10, -10)

    elseif event == "PLAYER_ENTERING_WORLD" then
        self:Init()

    elseif event == "UNIT_PORTRAIT_UPDATE" then
        SetPortraitTexture(self.portrait, "player")
        
    end

end





function SamsUiPlayerBarMixin:OnUpdate()

    local health, maxHealth = UnitHealth("player"), UnitHealthMax("player")
    if type(health) == "number" and type(maxHealth) == "number" and maxHealth > 0 then

        local percentHealth = string.format("%.2f", (health/maxHealth) * 100);

        self.healthBar:SetValue(percentHealth)

        Util:FormatStatsusBarTags(self.healthBar.text, self.playerHealthTextFormat, health, maxHealth, percentHealth)

    else
        self.healthBar:SetValue(0)

        Util:FormatStatsusBarTags(self.healthBar.text, self.playerHealthTextFormat, 0, 0, 0)
    end

    local power, maxPower = UnitPower("player", self.playerPowerType, true), UnitPowerMax("player", self.playerPowerType, true)
    if type(power) == "number" and type(maxPower) == "number" and maxPower > 0 then

        local percentPower = string.format("%.2f", (power/maxPower) * 100);

        self.powerBar:SetValue(percentPower)

        Util:FormatStatsusBarTags(self.powerBar.text, self.playerPowerTextFormat, power, maxPower, percentPower)

    else    
        self.powerBar:SetValue(0)

        Util:FormatStatsusBarTags(self.powerBar.text, self.playerPowerTextFormat, 0, 0, 0)
    end

end
















SamsUiTargetBarMixin:GenerateCallbackEvents({

});
SamsUiTargetBarMixin.targetHealthTextFormat = "{per} %"; -- set a default string to use on first load before getting db values
SamsUiTargetBarMixin.targetPowerTextFormat = "{per} %"; -- set a default string to use on first load before getting db values

function SamsUiTargetBarMixin:OnLoad()
    
    self:ClearTarget()

    -- self:RegisterEvent("UNIT_AURA")
    -- self:RegisterEvent("PLAYER_ENTERING_WORLD")
    -- self:RegisterEvent("UNIT_TARGET")
    self:RegisterEvent("PLAYER_TARGET_CHANGED")

    
end


function SamsUiTargetBarMixin:LoadConfigVariables()

    if Database:GetConfigValue("showTargetHealthText") then
        self.healthBar.text:SetShown(Database:GetConfigValue("showTargetHealthText"))
    end

    if Database:GetConfigValue("targetHealthTextFormat") then
        self.targetHealthTextFormat = Database:GetConfigValue("targetHealthTextFormat")
    end

    if Database:GetConfigValue("showTargetPowerText") then
        self.powerBar.text:SetShown(Database:GetConfigValue("showTargetPowerText"))
    end

    if Database:GetConfigValue("targetPowerTextFormat") then
        self.targetPowerTextFormat = Database:GetConfigValue("targetPowerTextFormat")
    end

end


function SamsUiTargetBarMixin:OnConfigChanged(setting, newValue)

    if setting == "targetHealthTextFormat" then
        self.targetHealthTextFormat = newValue;
    end

    if setting == "showTargetHealthText" then
        self.healthBar.text:SetShown(newValue)
    end

    if setting == "targetPowerTextFormat" then
        self.targetPowerTextFormat = newValue;
    end

    if setting == "showTargetPowerText" then
        self.powerBar.text:SetShown(newValue)
    end

end


function SamsUiTargetBarMixin:OnEvent(event, ...)

    if event == "PLAYER_TARGET_CHANGED" then

        if UnitExists("target") then
            self:SetTarget()
        else
            self:ClearTarget()
        end

    end

end


function SamsUiTargetBarMixin:SetTarget()

    self.name:SetText(UnitName("target"))

    self.level:SetText(UnitLevel("target"))

    local _, targetClass = UnitClass("target")
    local r, g, b, argbHex = GetClassColor(targetClass)
    self.portraitRing:SetVertexColor(r, g, b)

    SetPortraitTexture(self.portrait, "target")

    self.targetPowerType, self.targetPowerToken = UnitPowerType("target")
    self.targetPowerRGB = PowerBarColor[self.targetPowerToken]

    self.powerBar:SetStatusBarColor(self.targetPowerRGB.r, self.targetPowerRGB.g, self.targetPowerRGB.b)

    self.targetFaction = UnitFactionGroup("target")

    if self.targetFaction == "Horde" then
        self.factionIcon:SetAtlas("honorsystem-portrait-horde")

    elseif self.targetFaction == "Alliance" then
        self.factionIcon:SetAtlas("honorsystem-portrait-alliance")

    else
        self.factionIcon:SetAtlas("honorsystem-portrait-neutral")
    end

end


function SamsUiTargetBarMixin:ClearTarget()

    self.healthBar:SetValue(0)
    self.healthBar.text:SetText("")
    self.powerBar:SetValue(0)
    self.powerBar.text:SetText("")
    self.portraitRing:SetVertexColor(1, 1, 1)
    self.portrait:SetTexture(136813)
    self.name:SetText("")
    self.level:SetText("")
    self.factionIcon:SetAtlas("honorsystem-portrait-neutral")

end


function SamsUiTargetBarMixin:OnUpdate()

    if UnitExists("target") == false then
        return;
    end

    local health, maxHealth = UnitHealth("target"), UnitHealthMax("target")
    if type(health) == "number" and type(maxHealth) == "number" and maxHealth > 0 then

        local percentHealth = string.format("%.2f", (health/maxHealth) * 100);

        self.healthBar:SetValue(percentHealth)

        Util:FormatStatsusBarTags(self.healthBar.text, self.targetHealthTextFormat, health, maxHealth, percentHealth)

    else
        self.healthBar:SetValue(0)

        Util:FormatStatsusBarTags(self.healthBar.text, self.targetHealthTextFormat, 0, 0, 0)
    end



    local powerType, powerToken = UnitPowerType("target")
    local power, maxPower = UnitPower("target", powerType, true), UnitPowerMax("target", powerType, true)
    if type(power) == "number" and type(maxPower) == "number" and maxPower > 0 then

        local percentPower = string.format("%.2f", (power/maxPower) * 100);

        self.powerBar:SetValue(percentPower)

        Util:FormatStatsusBarTags(self.powerBar.text, self.targetPowerTextFormat, power, maxPower, percentPower)

    else        
        self.powerBar:SetValue(0)

        Util:FormatStatsusBarTags(self.powerBar.text, self.targetPowerTextFormat, 0, 0, 0)
    end

end
