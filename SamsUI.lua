

--[[
    honorsystem-bar-frame
]]


local name, addon = ...

local Util = addon.Util;

local MAX_LOGOUT_TIMESTAMP = 5000000000;

local inventorySlots = {
    "HEADSLOT",
    "NECKSLOT",
    "SHOULDERSLOT",
    "BACKSLOT",
    "CHESTSLOT",
    "SHIRTSLOT",
    "TABARDSLOT",
    "WRISTSLOT",
    "MAINHANDSLOT",
    "RANGEDSLOT",
    "HANDSSLOT",
    "WAISTSLOT",
    "LEGSSLOT",
    "FEETSLOT",
    "FINGER0SLOT",
    "FINGER1SLOT",
    "TRINKET0SLOT",
    "TRINKET1SLOT",
    "MAINHANDSLOT",
    "SECONDARYHANDSLOT",
    "RANGEDSLOT",
}

local tradeskillNamesToIDs = {
    ["Alchemy"] = 171,
    ["Blacksmithing"] = 164,
    ["Enchanting"] = 333,
    ["Engineering"] = 202,
    ["Inscription"] = 773,
    ["Jewelcrafting"] = 755,
    ["Leatherworking"] = 165,
    ["Tailoring"] = 197,
    ["Mining"] = 186,

    --these are ignored when setting up the top bar
    ["Herbalism"] = 182,
    ["Skinning"] = 393,

    --added this as its useful and this enables it on the top bar
    --["Cooking"] = 185,

    --mining
    ["Smelting"] = -1,
}




--[[
    set up the mixins now so all accessible
]]
SamsUiConfigPanelMixin = CreateFromMixins(CallbackRegistryMixin)
SamsUiTopBarMixin = CreateFromMixins(CallbackRegistryMixin);
SamsUiPlayerBarMixin = CreateFromMixins(CallbackRegistryMixin);
SamsUiTargetBarMixin = CreateFromMixins(CallbackRegistryMixin);

SamsUiCharacterFrameMixin = CreateFromMixins(CallbackRegistryMixin);
SamsUiPartyFrameMixin = CreateFromMixins(CallbackRegistryMixin);

























--[[
    database mixin

    takes care of setting and getting info to/from saved variables
]]
local Database = CreateFromMixins(CallbackRegistryMixin)
Database:GenerateCallbackEvents({
    "OnConfigChanged",
    "OnInitialised",
    "OnCharacterRemoved",
});
Database.isInitialised = false; --if i want to add any callbacks i may need to check this value first before triggering them

function Database:Init()

    CallbackRegistryMixin.OnLoad(self)

    if not SamsUiConfig then
        SamsUiConfig = {};
    end

    if not SamsUiCharacters then
        SamsUiCharacters = {};
    end

    self:RegisterCallback("OnInitialised", SamsUiTopBar.OnDatabaseInitialised, SamsUiTopBar)
    self:RegisterCallback("OnInitialised", SamsUiPlayerBar.LoadConfigVariables, SamsUiPlayerBar)
    self:RegisterCallback("OnInitialised", SamsUiTargetBar.LoadConfigVariables, SamsUiTargetBar)
    self:RegisterCallback("OnInitialised", SamsUiConfigPanel.OnDatabaseInitialised, SamsUiConfigPanel)
    self:RegisterCallback("OnInitialised", SamsUiPartyFrame.OnDatabaseInitialised, SamsUiPartyFrame)

    self:RegisterCallback("OnConfigChanged", SamsUiPlayerBar.OnConfigChanged, SamsUiPlayerBar)
    self:RegisterCallback("OnConfigChanged", SamsUiTargetBar.OnConfigChanged, SamsUiTargetBar)
    self:RegisterCallback("OnConfigChanged", SamsUiPartyFrame.OnConfigChanged, SamsUiPartyFrame)

    self:RegisterCallback("OnCharacterRemoved", SamsUiConfigPanel.LoadDatabasePanel, SamsUiConfigPanel)

    self:TriggerEvent("OnInitialised")
    self.isInitialised = true;

end


function Database:AddNewCharacter(nameRealm)

    if not SamsUiCharacters then
        SamsUiCharacters = {};
    end

    if not SamsUiCharacters[nameRealm] then
        SamsUiCharacters[nameRealm] = {};
    end

end


function Database:RemoveCharacter(nameRealm)

    if not SamsUiCharacters then
        return;
    end

    local name, realm = UnitFullName("player")
    if nameRealm == string.format("%s-%s", name, realm) then
        print(string.format("unable to delete current character %s", nameRealm))
        return;
    end

    if SamsUiCharacters[nameRealm] then
        SamsUiCharacters[nameRealm] = nil;

        Database:TriggerEvent("OnCharacterRemoved")
    end
end

function Database:GetCharacter(nameRealm)

    if type(SamsUiCharacters) ~= "table" then
        return false;
    end

    if SamsUiCharacters[nameRealm] then
        return SamsUiCharacters[nameRealm];
    end
end


function Database:GetCharacters()

    if not SamsUiCharacters then
        SamsUiCharacters = {};
    end

    local i = 0;
    local keys = {}
    for k, v in pairs(SamsUiCharacters) do
        i = i + 1;
        keys[i] = k;
    end

    local k = 0;
    return function()
        k = k + 1;
        if k <= i then
            return keys[k], SamsUiCharacters[keys[k]];
        end
    end

end


function Database:CreateNewCharacterSession(nameRealm, session)

    if type(nameRealm) ~= "string" then
        return;
    end

    if not SamsUiCharacters then
        SamsUiCharacters = {};
    end

    if not SamsUiCharacters[nameRealm] then
        SamsUiCharacters[nameRealm] = {};
    end

    if not SamsUiCharacters[nameRealm].sessions then
        SamsUiCharacters[nameRealm].sessions = {};
    end

    --insert at index 1 so that sessions are naturally in reverse order
    table.insert(SamsUiCharacters[nameRealm].sessions, 1, session)

end


function Database:DeleteSessionFromCharacter(nameRealm, key)

    --print(nameRealm, key)

    if not SamsUiCharacters then
        return;
    end

    if not SamsUiCharacters[nameRealm] then
        return;
    end

    if not SamsUiCharacters[nameRealm].sessions then
        return;
    end

    table.remove(SamsUiCharacters[nameRealm].sessions, key)
    --print("removed", key, "from sessions")

end


function Database:UpdatePartyUnitConfig_MacroButtons(nameRealm, unit, profile, buttonID, icon, macro, spellID)

    if not SamsUiCharacters then
        return;
    end

    if not SamsUiCharacters[nameRealm] then
        return;
    end

    if not SamsUiCharacters[nameRealm].partyUnitConfig then
        SamsUiCharacters[nameRealm].partyUnitConfig = {}
    end

    if not SamsUiCharacters[nameRealm].partyUnitConfig[unit] then
        SamsUiCharacters[nameRealm].partyUnitConfig[unit] = {}
    end

    if not SamsUiCharacters[nameRealm].partyUnitConfig[unit][profile] then
        SamsUiCharacters[nameRealm].partyUnitConfig[unit][profile] = {}
    end

    SamsUiCharacters[nameRealm].partyUnitConfig[unit][profile][buttonID] = {
        icon = icon,
        macro = macro,
        spellID = spellID or false,
    };

end


function Database:GetPartyUnitFrameConfig_SpellButtons(nameRealm, unit)
    
    if not SamsUiCharacters then
        return;
    end

    if not SamsUiCharacters[nameRealm] then
        return;
    end

    if not SamsUiCharacters[nameRealm].partyUnitConfig then
        return;
    end

    if not SamsUiCharacters[nameRealm].partyUnitConfig[unit] then
        return;
    end

    if type(SamsUiCharacters[nameRealm].partyUnitConfig[unit]) == "table" then
        return SamsUiCharacters[nameRealm].partyUnitConfig[unit];
    end
end


function Database:InsertOrUpdateCharacterInfo(nameRealm, key, newValue)

    if type(nameRealm) ~= "string" then
        error(string.format("nameRealm value is nil - %s %s", key or "-", newValue or "-"))
        return;
    end

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
        print("SamsUiCharacter table doesnt exist")
        return false;
    end

    if not SamsUiCharacters[nameRealm] then
        print(string.format("SamsUiCharacter[%s] table doesnt exist", nameRealm))
        return false;
    end

    if SamsUiCharacters[nameRealm][key] then
        return SamsUiCharacters[nameRealm][key];
    else
        print(string.format("unable to find [%s] in SamsUiCharacter[%s] table", key, nameRealm))
        return false;
    end

    return false;
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

    if not SamsUiConfig[setting] then
        SamsUiConfig[setting] = val;
    end
    
end


function Database:GetConfigValue(setting)

    --DevTools_Dump({ SamsUiConfig })

    if type(SamsUiConfig) == "table" then
        
        if SamsUiConfig[setting] ~= nil then
            return SamsUiConfig[setting]

        else
            return nil;
        end
    end
end


























--[[
    config panel mixin

    this is the ui for adjusting settings
]]
SamsUiConfigPanelMixin:GenerateCallbackEvents({

});

function SamsUiConfigPanelMixin:OnLoad()

    self:RegisterForDrag("LeftButton")

    self:RegisterEvent("ADDON_LOADED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("CHAT_MSG_SYSTEM")

    SLASH_SAMSUI1 = "/sui"
    SlashCmdList.SAMSUI = function(msg)

        if SamsUiConfigPanel then
            SamsUiConfigPanel:SetShown(not SamsUiConfigPanel:IsVisible())
        end

    end

    local menu = {
        {
            panelName = "General",
            func = function()
                self:ShowPanel("generalConfig")
            end
        },
        {
            panelName = "Player Bar",
            func = function()
                self:ShowPanel("playerBarConfig")
            end
        },
        {
            panelName = "Target Bar",
            func = function()
                self:ShowPanel("targetBarConfig")
            end
        },
        {
            panelName = "Party",
            func = function()
                self:ShowPanel("partyConfig")
            end
        },
        {
            panelName = "Minimap",
            func = function()
                self:ShowPanel("minimapConfig")
            end
        },
        {
            panelName = "Sessions",
            func = function()
                self:ShowPanel("sessions")
            end
        },
        {
            panelName = "Database",
            func = function()
                self:ShowPanel("databaseControl")
            end
        },
    }
    self.menuListview.DataProvider:InsertTable(menu)

    -- this should go else where at some point there are probably more frames to move about though

    self:SetUpMiniMap()

    self:SetUpBuffFrame()

    self:SetupMerchantFrame()


    C_Timer.After(5, function()
        CastingBarFrame:SetSize(230, 24)
        CastingBarFrame.Border:SetTexture(nil)
        CastingBarFrame.BorderShield:SetTexture(nil)
        CastingBarFrame.Flash:SetTexture(nil)
        CastingBarFrame.Text:ClearAllPoints()
        CastingBarFrame.Text:SetPoint("CENTER", 0, 0)
        CastingBarFrame.SamsUiBorder = CastingBarFrame:CreateTexture("SamsUiCastingBarFrameBorder", "BACKGROUND")
        CastingBarFrame.SamsUiBorder:SetPoint("TOPLEFT", -2, 2)
        CastingBarFrame.SamsUiBorder:SetPoint("BOTTOMRIGHT", 2, -2)
        CastingBarFrame.SamsUiBorder:SetColorTexture(0,0,0,0.7)

        CastingBarFrame:HookScript("OnUpdate", function()
            CastingBarFrame:ClearAllPoints()
            CastingBarFrame:SetPoint("TOP", UIParent, "BOTTOM", 0, 470)
        end)

        PlayerFrame:ClearAllPoints()
        PlayerFrame:SetPoint('TOP', UIParent, 'BOTTOM', -240, 490)
        PlayerFrame:SetUserPlaced(true);
        PlayerFrame_SetLocked(true)

        TargetFrame:ClearAllPoints()
        TargetFrame:SetPoint('TOP', UIParent, 'BOTTOM', 240, 490)
        TargetFrame:SetUserPlaced(true);
        TargetFrame_SetLocked(true)

        --DevTools_Dump({CastingBarFrame})
    end)



    UIWidgetTopCenterContainerFrame:ClearAllPoints()
    UIWidgetTopCenterContainerFrame:SetPoint("TOP", MinimapCluster, "BOTTOM", 9, -10)

    -- DurabilityFrame:ClearAllPoints()
    -- DurabilityFrame:SetPoint("RIGHT", SamsUiPlayerBar.portrait, "LEFT", -10, 0)
    -- DurabilityFrame:Show()

    MirrorTimer1:ClearAllPoints()
    MirrorTimer1:SetPoint("TOP", MinimapCluster, "BOTTOM", 9, -5)

    UIErrorsFrame:ClearAllPoints()
    UIErrorsFrame:SetPoint("TOP", MinimapCluster, "BOTTOM", 9, -15)

    local x, y = _G[self:GetName().."Portrait"]:GetSize()
    _G[self:GetName().."Portrait"]:ClearAllPoints()
    _G[self:GetName().."Portrait"]:SetPoint("TOPLEFT", self, "TOPLEFT", -5, 5)
    _G[self:GetName().."Portrait"]:SetSize(x-5, y-5)
    _G[self:GetName().."Portrait"]:SetAtlas("mobile-enginnering")

    local portraitBackground = self:CreateTexture(nil, "BACKGROUND")
    portraitBackground:SetAtlas("AdventureMapQuest-PortraitBG")
    portraitBackground:SetPoint("TOPLEFT", self, "TOPLEFT", -5, 5)
    portraitBackground:SetSize(x-5, y-5)

   
end


function SamsUiConfigPanelMixin:OnShow()

end


function SamsUiConfigPanelMixin:ShowPanel(panel)

    for k, frame in ipairs(self.contentFrame.frames) do
        frame:Hide()
    end

    self.contentFrame[panel]:Show()
end


function SamsUiConfigPanelMixin:OnDatabaseInitialised()

    self:LoadPlayerBarPanel()
    self:LoadTargetBarPanel()
    self:LoadMinimapPanel()
    self:LoadDatabasePanel()
    self:LoadGeneralPanel()
    self:LoadPartyConfigPanel()

end


function SamsUiConfigPanelMixin:LoadGeneralPanel()

    local panel = self.contentFrame.generalConfig;

    if Database:GetConfigValue("welcomeGuildMembersOnLogin") then
        panel.welcomeGuildMembersOnLoginCheckButton:SetChecked("welcomeGuildMembersOnLogin")
    end

    if Database:GetConfigValue("welcomeGuildMembersOnLoginMessageArray") then
        panel.welcomeGuildMembersOnLoginMessageArrayEditBox:SetText(Database:GetConfigValue("welcomeGuildMembersOnLoginMessageArray"))
    end

    panel.welcomeGuildMembersOnLoginMessageArrayEditBox:SetScript("OnTextChanged", function()
        Database:UpdateConfig("welcomeGuildMembersOnLoginMessageArray", panel.welcomeGuildMembersOnLoginMessageArrayEditBox:GetText())
    end)


    --add a set of options for th8is sdtuff in time
    C_Timer.After(1, function()
        SetCVar("autoLootDefault", 1)
        SetCVar("alwaysShowActionBars", 1)
        SetCVar("instantQuestText", 1)

        if InterfaceOptionsActionBarsPanelBottomLeft:GetChecked() == false then
            InterfaceOptionsActionBarsPanelBottomLeft:Click()
        end

        if InterfaceOptionsActionBarsPanelBottomRight:GetChecked() == false then
            InterfaceOptionsActionBarsPanelBottomRight:Click()
        end

        if InterfaceOptionsActionBarsPanelRight:GetChecked() == false then
            InterfaceOptionsActionBarsPanelRight:Click()
        end

        if InterfaceOptionsActionBarsPanelRightTwo:GetChecked() == false then
            InterfaceOptionsActionBarsPanelRightTwo:Click()
        end

    end)
end


function SamsUiConfigPanelMixin:LoadDatabasePanel()

    self.contentFrame.databaseControl.listview.DataProvider:Flush()
    self.contentFrame.sessions.listview.DataProvider:Flush()

    for name, character in Database:GetCharacters() do
        self.contentFrame.databaseControl.listview.DataProvider:Insert({
            character = character,
            name = name,
            deleteFunc = Database.RemoveCharacter,
        })


        if type(character.sessions) == "table" then
            for k, session in ipairs(character.sessions) do
                local info = {
                    character = character,
                    name = name,
                    session = session,
                    deleteFunc = function()
                        Database:DeleteSessionFromCharacter(name, k)
                        self:LoadDatabasePanel()
                    end,
                }
                self.contentFrame.sessions.listview.DataProvider:Insert(info)
            end
        end
    end


end


function SamsUiConfigPanelMixin:LoadMinimapPanel()
    
    local panel = self.contentFrame.minimapConfig;

    _G[panel.numberIconsPerRow:GetName().."Low"]:SetText("1")
    _G[panel.numberIconsPerRow:GetName().."High"]:SetText("10")

    _G[panel.numberIconsPerRow:GetName().."Text"]:SetText(Database:GetConfigValue("numberMinimapIconsPerRow") or 6)
    panel.numberIconsPerRow:SetValue(Database:GetConfigValue("numberMinimapIconsPerRow") or 6)


    panel.numberIconsPerRow:SetScript("OnValueChanged", function()
        _G[panel.numberIconsPerRow:GetName().."Text"]:SetText(string.format("%.0f", panel.numberIconsPerRow:GetValue()))
        Database:UpdateConfig("numberMinimapIconsPerRow", tonumber(string.format("%.0f", panel.numberIconsPerRow:GetValue())))
    end)

end


function SamsUiConfigPanelMixin:LoadPlayerBarPanel()

    local panel = self.contentFrame.playerBarConfig;

    panel.playerBarSetEnabled:SetScript("OnClick", function()
        Database:UpdateConfig("playerBarEnabled", panel.playerBarSetEnabled:GetChecked())
    end)

    panel.playerHealthTextCheckButton:SetScript("OnClick", function()
        Database:UpdateConfig("showPlayerHealthText", panel.playerHealthTextCheckButton:GetChecked())
    end)

    panel.playerHealthTextFormatEditBox:SetScript("OnTextChanged", function()
        Database:UpdateConfig("playerHealthTextFormat", panel.playerHealthTextFormatEditBox:GetText())
    end)

    panel.playerPowerTextCheckButton:SetScript("OnClick", function()
        Database:UpdateConfig("showPlayerPowerText", panel.playerPowerTextCheckButton:GetChecked())
    end)

    panel.playerPowerTextFormatEditBox:SetScript("OnTextChanged", function()
        Database:UpdateConfig("playerPowerTextFormat", panel.playerPowerTextFormatEditBox:GetText())
    end)


    --player frame
    local isEnabled = Database:GetConfigValue("playerBarEnabled")
    if isEnabled ~= nil then
        panel.playerBarSetEnabled:SetChecked(isEnabled)
    end

    if Database:GetConfigValue("showPlayerHealthText") then
        panel.playerHealthTextCheckButton:SetChecked(Database:GetConfigValue("showPlayerHealthText"))
    end

    if Database:GetConfigValue("playerHealthTextFormat") then
        panel.playerHealthTextFormatEditBox:SetText(Database:GetConfigValue("playerHealthTextFormat"))
    end

    if Database:GetConfigValue("showPlayerPowerText") then
        panel.playerPowerTextCheckButton:SetChecked(Database:GetConfigValue("showPlayerPowerText"))
    end

    if Database:GetConfigValue("playerPowerTextFormat") then
        panel.playerPowerTextFormatEditBox:SetText(Database:GetConfigValue("playerPowerTextFormat"))
    end

end

function SamsUiConfigPanelMixin:LoadTargetBarPanel()

    local panel = self.contentFrame.targetBarConfig;

    panel.targetBarSetEnabled:SetScript("OnClick", function()
        Database:UpdateConfig("targetBarEnabled", panel.targetBarSetEnabled:GetChecked())
    end)

    --set the widget scripts
    panel.targetHealthTextCheckButton:SetScript("OnClick", function()
        Database:UpdateConfig("showTargetHealthText", panel.targetHealthTextCheckButton:GetChecked())
    end)

    panel.targetHealthTextFormatEditBox:SetScript("OnTextChanged", function()
        Database:UpdateConfig("targetHealthTextFormat", panel.targetHealthTextFormatEditBox:GetText())
    end)

    panel.targetPowerTextCheckButton:SetScript("OnClick", function()
        Database:UpdateConfig("showTargetPowerText", panel.targetPowerTextCheckButton:GetChecked())
    end)

    panel.targetPowerTextFormatEditBox:SetScript("OnTextChanged", function()
        Database:UpdateConfig("targetPowerTextFormat", panel.targetPowerTextFormatEditBox:GetText())
    end)


    --target frame
    local isEnabled = Database:GetConfigValue("targetBarEnabled")
    if isEnabled ~= nil then
        panel.targetBarSetEnabled:SetChecked(isEnabled)
    end

    if Database:GetConfigValue("showTargetHealthText") then
        panel.targetHealthTextCheckButton:SetChecked(Database:GetConfigValue("showTargetHealthText"))
    end

    if Database:GetConfigValue("targetHealthTextFormat") then
        panel.targetHealthTextFormatEditBox:SetText(Database:GetConfigValue("targetHealthTextFormat"))
    end

    if Database:GetConfigValue("showTargetPowerText") then
        panel.targetPowerTextCheckButton:SetChecked(Database:GetConfigValue("showTargetPowerText"))
    end

    if Database:GetConfigValue("targetPowerTextFormat") then
        panel.targetPowerTextFormatEditBox:SetText(Database:GetConfigValue("targetPowerTextFormat"))
    end

end



function SamsUiConfigPanelMixin:LoadPartyConfigPanel()

    local panel = self.contentFrame.partyConfig;

    panel.enablePartyFrames:SetScript("OnClick", function()
        Database:UpdateConfig("partyFramesEnabled", panel.enablePartyFrames:GetChecked())
    end)
    local isEnabled = Database:GetConfigValue("partyFramesEnabled")
    if isEnabled ~= nil then
        panel.enablePartyFrames:SetChecked(isEnabled)
    end

    panel.unitFramesCopyPlayer:SetScript("OnClick", function()
        Database:UpdateConfig("unitFramesCopyPlayer", panel.unitFramesCopyPlayer:GetChecked())
    end)
    local unitframesCopyplayer = Database:GetConfigValue("unitFramesCopyPlayer")
    if unitframesCopyplayer ~= nil then
        panel.unitFramesCopyPlayer:SetChecked(unitframesCopyplayer)
    end

    panel.unitFramesVerticalLayout:SetScript("OnClick", function()
        Database:UpdateConfig("unitFramesVerticalLayout", panel.unitFramesVerticalLayout:GetChecked())
    end)

    _G[panel.partyUnitFrameWidth:GetName().."Low"]:SetText("20")
    _G[panel.partyUnitFrameWidth:GetName().."High"]:SetText("300")

    _G[panel.partyUnitFrameWidth:GetName().."Text"]:SetText(Database:GetConfigValue("partyUnitFrameWidth") or 100)
    panel.partyUnitFrameWidth:SetValue(Database:GetConfigValue("partyUnitFrameWidth") or 100)

    panel.partyUnitFrameWidth:SetScript("OnMouseWheel", function(self, delta)
        self:SetValue(self:GetValue() + (delta * 2))
    end)
    panel.partyUnitFrameWidth:SetScript("OnValueChanged", function()
        _G[panel.partyUnitFrameWidth:GetName().."Text"]:SetText(string.format("%.0f", panel.partyUnitFrameWidth:GetValue()))
        Database:UpdateConfig("partyUnitFrameWidth", tonumber(string.format("%.0f", panel.partyUnitFrameWidth:GetValue())))
    end)


    _G[panel.partyUnitFramesNumSpellButtons:GetName().."Low"]:SetText("1")
    _G[panel.partyUnitFramesNumSpellButtons:GetName().."High"]:SetText("12")

    _G[panel.partyUnitFramesNumSpellButtons:GetName().."Text"]:SetText(Database:GetConfigValue("partyUnitFramesNumSpellButtons") or 4)
    panel.partyUnitFramesNumSpellButtons:SetValue(Database:GetConfigValue("partyUnitFramesNumSpellButtons") or 4)

    panel.partyUnitFramesNumSpellButtons:SetScript("OnMouseWheel", function(self, delta)
        self:SetValue(self:GetValue() + delta)
    end)
    panel.partyUnitFramesNumSpellButtons:SetScript("OnValueChanged", function()
        _G[panel.partyUnitFramesNumSpellButtons:GetName().."Text"]:SetText(string.format("%.0f", panel.partyUnitFramesNumSpellButtons:GetValue()))
        Database:UpdateConfig("partyUnitFramesNumSpellButtons", tonumber(string.format("%.0f", panel.partyUnitFramesNumSpellButtons:GetValue())))
    end)


    -- _G[panel.partyUnitFramesNumSpellButtonsPerRow:GetName().."Low"]:SetText("1")
    -- _G[panel.partyUnitFramesNumSpellButtonsPerRow:GetName().."High"]:SetText("12")

    -- _G[panel.partyUnitFramesNumSpellButtonsPerRow:GetName().."Text"]:SetText(Database:GetConfigValue("partyUnitFramesNumSpellButtonsPerRow") or 4)
    -- panel.partyUnitFramesNumSpellButtonsPerRow:SetValue(Database:GetConfigValue("partyUnitFramesNumSpellButtonsPerRow") or 4)

    -- panel.partyUnitFramesNumSpellButtonsPerRow:SetScript("OnMouseWheel", function(self, delta)
    --     self:SetValue(self:GetValue() + (delta * 2))
    -- end)
    -- panel.partyUnitFramesNumSpellButtonsPerRow:SetScript("OnValueChanged", function()
    --     _G[panel.partyUnitFramesNumSpellButtonsPerRow:GetName().."Text"]:SetText(string.format("%.0f", panel.partyUnitFramesNumSpellButtonsPerRow:GetValue()))
    --     Database:UpdateConfig("partyUnitFramesNumSpellButtonsPerRow", tonumber(string.format("%.0f", panel.partyUnitFramesNumSpellButtonsPerRow:GetValue())))
    -- end)



end



function SamsUiConfigPanelMixin:SetUpBuffFrame()

    BuffFrame:ClearAllPoints()
    BuffFrame:SetPoint("TOPRIGHT", SamsUiTopBar, "BOTTOMRIGHT", -10, -10)

end


function SamsUiConfigPanelMixin:SetupMerchantFrame()

    MerchantFrame:SetWidth(650)
    MerchantPageText:ClearAllPoints()
    MerchantPageText:SetPoint("BOTTOM", -155, 86)

    local textureDivider = MerchantFrameInset:CreateTexture(nil, "OVERLAY")
    textureDivider:SetPoint("TOP", 7, -2)
    textureDivider:SetPoint("BOTTOM", 7, 2)
    textureDivider:SetWidth(10)
    textureDivider:SetAtlas("!ForgeBorder-Right")

    local characterItemsListview = CreateFrame("FRAME", "SamsUiMerchantFrameCharacterItemsListview", MerchantFrameInset, "SamsUiListviewTemplateNoMixin")
    characterItemsListview:SetPoint("BOTTOMRIGHT", -4, 4)
    characterItemsListview:SetPoint("TOPRIGHT", -4, -60)
    characterItemsListview:SetWidth(305)

    characterItemsListview.background = characterItemsListview:CreateTexture(nil, "BACKGROUND")
    characterItemsListview.background:SetAllPoints()
    characterItemsListview.background:SetAtlas("Forge-Background")
    characterItemsListview.background:SetAtlas("ClassHall_InfoBoxMission-BackgroundTile")

    characterItemsListview.topBorder = characterItemsListview:CreateTexture(nil, "OVERLAY")
    characterItemsListview.topBorder:SetPoint("TOPLEFT", 0, 6)
    characterItemsListview.topBorder:SetPoint("TOPRIGHT", 0, 6)
    characterItemsListview.topBorder:SetHeight(8)
    characterItemsListview.topBorder:SetAtlas("_GeneralFrame-HorizontalBar")

    --need to code this in lua

    characterItemsListview.DataProvider = CreateDataProvider();
    characterItemsListview.scrollView = CreateScrollBoxListLinearView();
    characterItemsListview.scrollView:SetDataProvider(characterItemsListview.DataProvider);

    characterItemsListview.scrollView:SetElementExtent(24)
    characterItemsListview.scrollView:SetElementInitializer("BUTTON", "SamsUiMerchantFrameCharacterItemsListviewItemTemplate", function(element, elementData, isNew)
    
        if isNew then
            element:OnLoad();
        end
    
        element:SetDataBinding(elementData, 24);

    end);
    characterItemsListview.scrollView:SetElementResetter(function(element)
        element:ResetDataBinding()
    end);

    characterItemsListview.scrollView:SetPadding(2, 0, 0, 2, 0);

    ScrollUtil.InitScrollBoxListWithScrollBar(characterItemsListview.scrollBox, characterItemsListview.scrollBar, characterItemsListview.scrollView);

    local anchorsWithBar = {
        CreateAnchor("TOPLEFT", characterItemsListview, "TOPLEFT", 4, -4),
        CreateAnchor("BOTTOMRIGHT", characterItemsListview.scrollBar, "BOTTOMLEFT", 0, 4),
    };
    local anchorsWithoutBar = {
        CreateAnchor("TOPLEFT", characterItemsListview, "TOPLEFT", 4, -4),
        CreateAnchor("BOTTOMRIGHT", characterItemsListview, "BOTTOMRIGHT", -4, 4),
    };
    ScrollUtil.AddManagedScrollBarVisibilityBehavior(characterItemsListview.scrollBox, characterItemsListview.scrollBar, anchorsWithBar, anchorsWithoutBar);

    characterItemsListview.backButton = CreateFrame("BUTTON", "SamsUiMerchantFrameListviewBackButton", MerchantFrameInset)
    characterItemsListview.backButton:Hide()

    local function loadCharacterItems()
        characterItemsListview.DataProvider:Flush()
        characterItemsListview.backButton:Hide()

        SamsUiTopBar:ScanPlayerBags()

        local bagItems = {}
        for itemClassID, items in pairs(SamsUiTopBar.characterBagItems) do
            
            table.sort(items, function(a, b)
                if a.subClassID == b.subClassID then
                    return a.rarity > b.rarity;
                else
                    return a.subClassID < b.subClassID;
                end

            end)

            local button = {
                itemType = GetItemClassInfo(itemClassID),
                items = items,
                listview = characterItemsListview,
            }

            characterItemsListview.DataProvider:Insert(button)
            --characterItemsListview.DataProvider:InsertTable(items)
        end
    end

    characterItemsListview.backButton:SetNormalAtlas("glueannouncementpopup-arrow")
    --characterItemsListview.backButton:SetNormalAtlas("NPE_ArrowLeft")
    characterItemsListview.backButton:SetHighlightAtlas("UI-CharacterCreate-LargeButton-Blue-Highlight")
    characterItemsListview.backButton:GetNormalTexture():SetTexCoord(1, 0, 0, 1)
    characterItemsListview.backButton:SetPoint("BOTTOMLEFT", characterItemsListview, "TOPLEFT", 0, 8)
    characterItemsListview.backButton:SetSize(32, 23)
    characterItemsListview.backButton:SetScript("OnClick", loadCharacterItems)


    local vendorJunkButton = CreateFrame("BUTTON", "SamsUiMerchantFrameVendorJunkButton", MerchantFrameInset, "UIPanelButtonTemplate")
    vendorJunkButton:SetPoint("TOPRIGHT", -4, -4)
    vendorJunkButton:SetSize(100, 20)
    vendorJunkButton:SetText("Vendor junk")
    vendorJunkButton:SetScript("OnClick", function()
    
        local junk = {}
        local junkValue = 0;
        for bag = 0, 4 do
            for slot = 1, GetContainerNumSlots(bag) do
                local icon, itemCount, _, _, _, _, itemLink = GetContainerItemInfo(bag, slot)
                if itemLink then
                    local itemName, _, itemQuality, _, _, _, _, _, _, _, sellPrice = GetItemInfo(itemLink)
                    if itemQuality == 0 then
                        junkValue = junkValue + (itemCount * sellPrice)
                        table.insert(junk, {
                            itemLink = itemLink,
                            bagID = bag,
                            slotID = slot,
                        })
                    end
                end
            end
        end

        if #junk > 0 then

            vendorJunkButton:SetText(string.format("Slot 0 of %s", #junk))

            local i = 0;
            C_Timer.NewTicker(0.5, function()
                i = i + 1;
                vendorJunkButton:SetText(string.format("Slot %s of %s", i, #junk))
                UseContainerItem(junk[i].bagID, junk[i].slotID)
                if i == #junk then
                    loadCharacterItems()
                    print(string.format("sold junk worth %s", GetCoinTextureString(junkValue)))
                    C_Timer.After(0.5, function()
                        vendorJunkButton:SetText("Vendor junk")
                    end)
                end
            end, #junk)
        end
    end)


    MerchantFrameInset:SetScript("OnShow", loadCharacterItems)

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


function SamsUiConfigPanelMixin:OnChatMessageSystem(...)

    local msg = ...

    --was this a login message
    local loggedIn = ERR_FRIEND_ONLINE_SS:gsub("%%s", ".+"):gsub('%[','%%%1')
    if msg:find(loggedIn:sub(6)) then
        local name = strsplit(" ", msg)
        local s, e = name:find("%["), name:find("%]")
        local characterName = name:sub(s+1, e-1)

        if Database:GetConfigValue("welcomeGuildMembersOnLogin") == true then
            
            if type(Database:GetConfigValue("welcomeGuildMembersOnLoginMessageArray")) == "string" then
                local array = Database:GetConfigValue("welcomeGuildMembersOnLoginMessageArray")
                local welcomeOptions = {strsplit(",", array)}

                -- DevTools_Dump({welcomeOptions})
                -- print(#welcomeOptions)

                local random = math.random(1, #welcomeOptions)

                print(welcomeOptions[random])

            end
        end

    end

end



function SamsUiConfigPanelMixin:OnEvent(event, ...)

    if event == "CHAT_MSG_SYSTEM" then
        self:OnChatMessageSystem(...)
    end

end


























--[[
    top bar mixin

    the main ui feature of the addon

    provides menus and info about the players character
]]
SamsUiTopBarMixin:GenerateCallbackEvents({
    "OnPlayerBagsScanned",
});
SamsUiTopBarMixin.minimapButtonsMoved = false;
SamsUiTopBarMixin.dropdownMenuCloseDelay = 1.5;
SamsUiTopBarMixin.playerBagMenuTypeWidth = 150;
SamsUiTopBarMixin.playerBagMenuItemWidth = 280;
SamsUiTopBarMixin.sessionInfo = {
    questsCompleted = {}, --[questID] = xpReward
    mobsKilled = 0,
    mobXpReward = 0,
}

function SamsUiTopBarMixin:OnLoad()
    
    CallbackRegistryMixin.OnLoad(self)

    --to add or remove menu buttons comment or uncomment this list
    self.mainMenuContainer.keys = {
        "Options",
        "Reload UI",
        --"Hearthstone",
        "Log out",
        "Exit",
    }

    self.mainMenuContainer.menu = {
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
        ["Hearthstone"] = {
            atlas = "innkeeper",
            macro = "/cast Hearthstone",
        },
        ["Log out"] = {
            atlas = "mageportalalliance",
            macro = "/logout",
        },
        ["Exit"] = {
            atlas = "poi-door-left",
            macro = "/quit",
        },
    }

    self.minimapZoneText:SetText(GetMinimapZoneText())

    self.addonsInstalled = {}
    for i = 1, GetNumAddOns() do
        local name, title, notes, loadable, reason, security, newVersion = GetAddOnInfo(i)
        table.insert(self.addonsInstalled, {
            name = name,
            title = title,
            notes = notes,
            loaded = false,
        })
    end

    self.mainMenuContainer.buttons = {}

    self.openMainMenuButton.icon:SetTexture(136243)
    self.openMainMenuButton:SetScript("OnClick", function()

        if self.openMainMenuButton.tooltipText then
            GameTooltip:SetOwner(self.openMainMenuButton, "LEFT")
            GameTooltip:AddLine(self.openMainMenuButton.tooltipText)
            GameTooltip:Show()
        end

        self:CloseDropdownMenus()
        self:OpenMainMenu()
    end)

    self.openMinimapButtonsButton.icon:SetTexture(134391)
    self.openMinimapButtonsButton:SetScript("OnClick", function()

        if self.openMinimapButtonsButton.tooltipText then
            GameTooltip:SetOwner(self.openMinimapButtonsButton, "LEFT")
            GameTooltip:AddLine(self.openMinimapButtonsButton.tooltipText)
            GameTooltip:Show()
        end

        if self.minimapButtonsContainer:IsVisible() then
            return;
        end

        self:CloseDropdownMenus()
        self:OpenMinimapButtonsMenu()
    end)

    self.minimapButtonsContainer:SetScript("OnHide", function()
        self.minimapButtonsContainer:SetAlpha(0)
        self.minimapButtonsContainer:SetPoint("TOP", self.openMinimapButtonsButton, "BOTTOM", 0, 35)
    end)

    self.minimapButtonsContainer.anim.translate:SetScript("OnFinished", function()
        self.minimapButtonsContainer:SetPoint("TOP", self.openMinimapButtonsButton, "BOTTOM", 0, -15)
    end)


    self:UpdateCurrency()
    self.openCurrencyButton:SetScript("OnEnter", function()        
        GameTooltip:SetOwner(self.openCurrencyButton, 'ANCHOR_BOTTOM')
        GameTooltip:AddLine("Gold")
        GameTooltip:AddLine(" ")

        local profit = GetMoney() - (Database:GetCharacterInfo(self.nameRealm, "initialLoginGold") or 0)
        if profit > 0 then
            GameTooltip:AddLine(string.format("|cff00cc00Profit|r %s", GetCoinTextureString(profit), 1,1,1))
        elseif profit == 0 then
            GameTooltip:AddLine(string.format("|cffB6CAB8Profit|r %s", GetCoinTextureString(profit), 1,1,1))
        else
            GameTooltip:AddLine(string.format("|cffcc0000Deficit|r %s", GetCoinTextureString(profit*-1), 1,1,1))
        end
        GameTooltip:AddLine(" ")
        local totalGold = 0;

        local characters = {}
        for name, character in Database:GetCharacters() do
            table.insert(characters, {
                name = name,
                class = character.class,
                gold = character.gold,
            })
        end
        table.sort(characters, function(a,b)
            return a.gold > b.gold;
        end)
        for k, character in ipairs(characters) do
            local r, g, b, argbHex = GetClassColor(character.class)
            GameTooltip:AddDoubleLine(character.name, GetCoinTextureString(character.gold), r, g, b, 1, 1, 1)

            totalGold = totalGold + character.gold
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Total", GetCoinTextureString(totalGold), 1, 1, 1, 1, 1, 1)

        GameTooltip:Show()
    end)


    self.openDurabilityButton:SetScript("OnClick", function()
        CharacterFrame:Show()
        CharacterFrameTab1:Click()
    end)

    self.openDurabilityButton:SetScript("OnEnter", function()        
        GameTooltip:SetOwner(self.openDurabilityButton, 'ANCHOR_BOTTOM')

        self:UpdateDurability()

        GameTooltip:AddLine("Durability")
        GameTooltip:AddLine(" ")

        for k, item in ipairs(self.durabilityInfo) do
            
            local percent = math.floor((item.currentDurability/item.maximumDurability)*100)

            local r = (percent > 50 and 1 - 2 * (percent - 50) / 100.0 or 1.0);
            local g = (percent > 50 and 1.0 or 2 * percent / 100.0);
            local b = 0.0;

            if item.itemLink ~= "-" then
                --GameTooltip:AddDoubleLine(item.itemLink, string.format("|cffffffff[%s|cffffffff]", CreateColor(r, g, b):WrapTextInColorCode(item.currentDurability.."/"..item.maximumDurability.." - "..percent)))
                GameTooltip:AddDoubleLine(CreateAtlasMarkup(item.atlas, 20, 20, 0, -2)..item.itemLink, string.format("|cffffffff[%s|cffffffff]", CreateColor(r, g, b):WrapTextInColorCode(percent.."%")))
            end

        end

        GameTooltip:Show()
    end)


    self.openXpButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(self.openXpButton, 'ANCHOR_BOTTOM')

        local xp = UnitXP("player")
        local xpMax = UnitXPMax("player")
        local restedXp = GetXPExhaustion() or 0;
        local requiredXp = xpMax - xp;

        local requiredPer = tonumber(string.format("%.1f", (requiredXp/xpMax)*100))
        local restedPer = tonumber(string.format("%.1f", (restedXp/xpMax)*100))

        GameTooltip:AddLine("XP info")
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("|cffffffffCurrent", xp)
        GameTooltip:AddDoubleLine("|cffffffffThis level", xpMax)
        GameTooltip:AddDoubleLine("|cffffffffRequired", string.format("%s [%s%%]", xpMax - xp, requiredPer))
        GameTooltip:AddDoubleLine("|cffffffffRested", string.format("%s [%s%%]", restedXp, restedPer))
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cff8F2E71Rested XP will be consumed \nat double rate per kill, \nif you have 1000 rested XP you'll \nget double for the first 500 XP earned")

        GameTooltip:Show()
    end)


    --self.openSessionButton.text:ClearAllPoints()
    --self.openSessionButton.text:SetPoint("LEFT", 5, 0)
    self.openSessionButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(self.openSessionButton, 'ANCHOR_BOTTOM')

        GameTooltip:AddLine("Session info")
        GameTooltip:AddLine(" ")

        local questsTurnedIn = #self.sessionInfo.questsCompleted
        local questXp = 0;
        for k, quest in ipairs(self.sessionInfo.questsCompleted) do
            questXp = questXp + (quest.xpReward or 0);
        end

        GameTooltip:AddDoubleLine("|cff5979B9Quests turned in:", questsTurnedIn)
        GameTooltip:AddDoubleLine("|cff5979B9Quest XP:", questXp)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("|cffffffffMobs killed:", self.sessionInfo.mobsKilled)
        GameTooltip:AddDoubleLine("|cffffffffMob XP:", self.sessionInfo.mobXpReward)

        GameTooltip:Show()
    end)



    self.openNetStatsButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(self.openNetStatsButton, 'ANCHOR_BOTTOM')

        GameTooltip:AddLine("Network info")

        local bandwidthIn, bandwidthOut, latencyHome, latencyWorld = GetNetStats()

        GameTooltip:AddDoubleLine("|cffffffffHome|r", latencyHome)
        GameTooltip:AddDoubleLine("|cffffffffWorld|r", latencyWorld)
        GameTooltip:AddDoubleLine("|cffffffffDownload|r", string.format("%.2f", bandwidthIn))
        GameTooltip:AddDoubleLine("|cffffffffUpload|r", string.format("%.2f", bandwidthOut))

        GameTooltip:Show()
    end)



    self.openPlayerBagsButton:SetScript("OnEnter", function()
        if not InCombatLockdown() then
            self:CloseDropdownMenus()
            self:OpenPlayerBagsMenu()
        end
    end)


    -- self.openFoodAndDrinkButton.icon:SetTexture(135999)
    -- self.openFoodAndDrinkButton:SetScript("OnEnter", function()

    --     if self.openFoodAndDrinkButton.tooltipText then
    --         GameTooltip:SetOwner(self.openFoodAndDrinkButton, "LEFT")
    --         GameTooltip:AddLine(self.openFoodAndDrinkButton.tooltipText)
    --         GameTooltip:Show()
    --     end

    --     self:CloseDropdownMenus()
    --     self:OpenFoodAndDrinkMenu()
    -- end)


    -- self.openConsumablesButton.icon:SetTexture(134823)
    -- self.openConsumablesButton:SetScript("OnEnter", function()

    --     if self.openConsumablesButton.tooltipText then
    --         GameTooltip:SetOwner(self.openConsumablesButton, "LEFT")
    --         GameTooltip:AddLine(self.openConsumablesButton.tooltipText)
    --         GameTooltip:Show()
    --     end

    --     self:CloseDropdownMenus()
    --     self:OpenConsumablesMenu()
    -- end)


    self.openQuestLogButton.icon:SetAtlas("worldquest-tracker-questmarker")
    self.openQuestLogButton:SetScript("OnClick", function(self)

        if self.tooltipText then
            GameTooltip:SetOwner(self, "LEFT")
            GameTooltip:AddLine(self.tooltipText)
            GameTooltip:Show()
        end

        ShowUIPanel(QuestLogFrame)
    end)


    SetPortraitTexture(self.openCharacterFrameButton.icon, "player")
    self.openCharacterFrameButton:SetScript("OnClick", function(self, button)

        if self.tooltipText then
            GameTooltip:SetOwner(self, "LEFT")
            GameTooltip:AddLine(self.tooltipText)
            GameTooltip:Show()
        end

        if button == "LeftButton" then
            ShowUIPanel(CharacterFrame)
        else
            SamsUiCharacterFrame:Show()
        end
    end)


    self.openLFGFrameButton.icon:SetAtlas("dungeon")
    self.openLFGFrameButton:SetScript("OnClick", function()

        if self.openLFGFrameButton.tooltipText then
            GameTooltip:SetOwner(self.openLFGFrameButton, "LEFT")
            GameTooltip:AddLine(self.openLFGFrameButton.tooltipText)
            GameTooltip:Show()
        end

        --LFGFrame:Show()
        if not LFGFrame then
            LoadAddOn("Blizzard_LookingForGroupUI")
        end
        ShowUIPanel(LFGParentFrame)
    end)


    self.openMacroFrameButton.icon:SetAtlas("NPE_Icon")
    self.openMacroFrameButton:SetScript("OnClick", function()

        if self.openMacroFrameButton.tooltipText then
            GameTooltip:SetOwner(self.openMacroFrameButton, "LEFT")
            GameTooltip:AddLine(self.openMacroFrameButton.tooltipText)
            GameTooltip:Show()
        end

        --MacroFrame:Show()
        if not MacroFrame then
            LoadAddOn("Blizzard_MacroUI")
        end
        ShowUIPanel(MacroFrame)
    end)


    self.openSpellBookFrameButton.icon:SetAtlas("minortalents-icon-book")
    self.openSpellBookFrameButton:SetScript("OnClick", function()

        if self.openSpellBookFrameButton.tooltipText then
            GameTooltip:SetOwner(self.openSpellBookFrameButton, "LEFT")
            GameTooltip:AddLine(self.openSpellBookFrameButton.tooltipText)
            GameTooltip:Show()
        end

        ShowUIPanel(SpellBookFrame)
    end)


    self.hearthstoneButton.icon:SetAtlas("innkeeper")
    self.hearthstoneButton:SetAttribute("macrotext1", "/cast Hearthstone")
    self.hearthstoneButton:SetScript("OnEnter", function()
    
        GameTooltip:SetOwner(self.hearthstoneButton, "LEFT")
        GameTooltip:AddLine(GetBindLocation())
        GameTooltip:Show()

    end)


    self.openCookingButton.icon:SetAtlas("Mobile-Cooking")
    self.openCookingButton:SetAttribute("macrotext1", "/cast Cooking")
    self.openCookingButton:SetScript("OnEnter", function()
    
        GameTooltip:SetOwner(self.openCookingButton, "LEFT")
        GameTooltip:AddLine("Cooking")
        GameTooltip:Show()

    end)

    --questartifactturnin

    self:RegisterEvent("ADDON_LOADED")
    self:RegisterEvent("PLAYER_MONEY")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
    self:RegisterEvent("SKILL_LINES_CHANGED")
    self:RegisterEvent("ZONE_CHANGED")
    self:RegisterEvent("BAG_UPDATE_DELAYED")
    self:RegisterEvent("PLAYER_LOGOUT")
    self:RegisterEvent("PLAYER_XP_UPDATE")
    self:RegisterEvent("UNIT_PORTRAIT_UPDATE")
    self:RegisterEvent("QUEST_TURNED_IN")
    self:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
    self:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE")
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:RegisterEvent("UNIT_AURA")

    --MultiBarBottomLeftButton1
    --MultiBarBottomRightButton1

    -- local actionBarSetup = {
    --     --MainMenuBar,
    --     MultiBarBottomLeft = {
    --         anchor = "BOTTOM",
    --         relativeTo = UIParent,
    --         relativePoint = "BOTTOM",
    --         xPos = 0,
    --         yPos = 190,
    --     },
    --     MultiBarBottomRight = {
    --         anchor = "BOTTOM",
    --         relativeTo = UIParent,
    --         relativePoint = "BOTTOM",
    --         xPos = 0,
    --         yPos = 100,
    --     },
    --     MultiBarLeft = {
    --         anchor = "RIGHT",
    --         relativeTo = UIParent,
    --         relativePoint = "RIGHT",
    --         xPos = -60,
    --         yPos = 0,
    --     },
    --     MultiBarRight = {
    --         anchor = "RIGHT",
    --         relativeTo = UIParent,
    --         relativePoint = "RIGHT",
    --         xPos = -10,
    --         yPos = 0,
    --     },
    --     PetActionBarFrame = {
    --         anchor = "BOTTOM",
    --         relativeTo = UIParent,
    --         relativePoint = "BOTTOM",
    --         xPos = 0,
    --         yPos = 220,
    --     },
    -- }


    -- C_Timer.After(5, function()
    --     for barName, position in pairs(actionBarSetup) do
    --         local bar = _G[barName]
    --         if bar then
    --             bar:ClearAllPoints()
    --             bar:SetParent(UIParent)
    --             bar:SetPoint(position.anchor, position.relativeTo, position.relativePoint, position.xPos, position.yPos)
    --             Util:MakeFrameMoveable(bar)
    --         end
    --     end

    --     local x, y = ActionButton1:GetSize()

    --     local mainActionBar = CreateFrame("FRAME", nil, UIParent)
    --     mainActionBar:SetPoint("BOTTOM", MultiBarBottomRight, "TOP", 0, 6)
    --     mainActionBar:SetSize(((x + 6) * 12), ((y + 6) * 3))
    
    --     for i = 1, 12 do
    --         local button = _G["ActionButton"..i]
    --         button:ClearAllPoints()
    --         button:SetParent(mainActionBar)
    
    --         if i == 1 then
    --             button:SetPoint("LEFT", 3, 0)
    --         else
    --             button:SetPoint("LEFT", _G["ActionButton"..i-1], "RIGHT", 6, 0)
    --         end
    
    --     end

    --     Util:MakeFrameMoveable(mainActionBar)
    -- end)




    -- MainMenuBarLeftEndCap:Hide()
    -- MainMenuBarRightEndCap:Hide()
    -- MainMenuBarArtFrame:Hide()

    -- MainMenuBarPerformanceBar:Hide()

    -- MainMenuBarMaxLevelBar:Hide()

    -- MainMenuBar:SetSize(1,1)

end


function SamsUiTopBarMixin:OnUpdate()
    self.openNetStatsButton:SetText(string.format("fps %.1f",GetFramerate()))
end


function SamsUiTopBarMixin:OnEvent(event, ...)

    if event == "ADDON_LOADED" then
        
        C_Timer.After(1, function()
            self:MoveAllLibMinimapIcons()
        end)


        if ... == "Blizzard_TimeManager" then
            
            --TimeManagerClockButton:SetSize(80, 40)

        end

    end

    if event == "UNIT_AURA" then
        BuffFrame:ClearAllPoints()
        BuffFrame:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", -10, -10)
    end

    if event == "UNIT_PORTRAIT_UPDATE" then
        SetPortraitTexture(self.openCharacterFrameButton.icon, "player")
    end

    if event == "PLAYER_LOGOUT" then
        self.sessionInfo.logoutTime = time();
    end

    if event == "BAG_UPDATE_DELAYED" then
        self:ScanPlayerBags()
    end

    if event == "ZONE_CHANGED" then
        self.minimapZoneText:SetText(GetMinimapZoneText())
    end

    if event == "PLAYER_ENTERING_WORLD" then

        local name, realm = UnitFullName("player")
        self.nameRealm = string.format("%s-%s", name, realm)

        --these Database function will work fine even though we havent called Init() on the Database object
        --the Init function will register the callbacks and fire a trigger but becaue InsertOrUpdateCharacterInfo 
        --doesnt trigger any callbacks its not a problem
        local initialLogin, reload = ...
        if initialLogin == true then

            local now = time();
            local gold = GetMoney();

            Database:InsertOrUpdateCharacterInfo(self.nameRealm, "initialLoginGold", gold)

            Database:InsertOrUpdateCharacterInfo(self.nameRealm, "initialLoginTime", now)

            --as this is the fresh login we need to add a new session
            --local sessions = Database:GetCharacterInfo(self.nameRealm, "sessions")
            Database:CreateNewCharacterSession(self.nameRealm, {
                questsCompleted = {},
                mobsKilled = 0,
                mobXpReward = 0,
                initialLoginTime = now,
                logoutTime = 0,
                profit = 0,
            })
            print("db init > new session")

        else


        end

        Database:Init()
    end

    if event == "PLAYER_MONEY" then
        self:UpdateCurrency()
    end

    if event == "UPDATE_INVENTORY_DURABILITY" then
        self:UpdateDurability()
    end

    if event == "SKILL_LINES_CHANGED" then
        self:ScanSpellbook()
    end

    if event == "PLAYER_XP_UPDATE" then
        self:UpdateXp()
    end

    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        
        local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName = CombatLogGetCurrentEventInfo()

        if subevent == "UNIT_DIED" then
            C_Timer.After(0.5, function()
                
                if CanLootUnit(destGUID) then
                    self.sessionInfo.mobsKilled = self.sessionInfo.mobsKilled + 1;
                end
            end)
        end
    
    end

    if event == "CHAT_MSG_COMBAT_XP_GAIN" then
        local text = ...

        if text:find("dies") then

            --if a mob dies and gives xp then we must have tagged it so grab the xp value and update the session info
            self.sessionInfo.mobsKilled = self.sessionInfo.mobsKilled + 1;

            --nasty but there are a lot of global strings for the various messages so just attempt to strip the number characters out using a guess on fixed position
            local start = text:find("you gain ")
            local finish = text:find(" experience")
            local xp = text:sub(start+9, finish)
            if tonumber(xp) then
                self.sessionInfo.mobXpReward = self.sessionInfo.mobXpReward + xp;
            end
        end
    end

    if event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then

        local info = ...
        local rep = FACTION_STANDING_INCREASED:gsub("%%s", "(.+)"):gsub("%%d", "(.+)")
        local faction, gain = string.match(info, rep)
        


    end

    if event == "QUEST_TURNED_IN" then
        local questID, xpReward = ...

        table.insert(self.sessionInfo.questsCompleted, {
            questID = questID,
            xpReward = xpReward or 0,
        })
    end

end


function SamsUiTopBarMixin:UpdateSessionRep(faction, gain)

    if not self.sessionInfo.reputations then
        self.sessionInfo.reputations = {}
    end
end


function SamsUiTopBarMixin:CloseDropdownMenus()
    
    for k, menu in ipairs(self.dropdownMenus) do
        menu:Hide()
    end
end


function SamsUiTopBarMixin:OnDatabaseInitialised()

    local function updateSessionTimerText()
        local initialLogin = Database:GetCharacterInfo(self.nameRealm, "initialLoginTime") or time()
        if type(initialLogin) == "number" then
            local now = time()
            self.openSessionButton:SetText(string.format("%s %s", CreateAtlasMarkup("glueannouncementpopup-icon-info", 20, 20), SecondsToClock(now - initialLogin)))
        end
    end

    self.sessionTimer = C_Timer.NewTicker(1, updateSessionTimerText)

    --if there is a session info table then grab a ref to it to continue using (for ui reload situations)
    local sessions = Database:GetCharacterInfo(self.nameRealm, "sessions")
    if type(sessions) == "table" then
        if #sessions > 0 then
            self.sessionInfo = sessions[1]; --sessions are inserted at index 1 so they naturally list in reverse order - index 1 will be the most recent session
            --print("using session 1")
        else
            local now = time()
            table.insert(sessions, {
                questsCompleted = {},
                mobsKilled = 0,
                mobXpReward = 0,
                initialLoginTime = now,
                logoutTime = 0,
            })
            self.sessionInfo = sessions[1];
            --print("created new session 1")
        end
    end

    self:UpdateCurrency()

    self:UpdateDurability()

    self:ScanSpellbook()

    self:UpdateXp()

    self:ScanPlayerBags()

    local _, class = UnitClass("player")
    Database:InsertOrUpdateCharacterInfo(self.nameRealm, "class", class)

    local level = UnitLevel("player")
    Database:InsertOrUpdateCharacterInfo(self.nameRealm, "level", level)

    local _, englishRace = UnitRace("player")
    Database:InsertOrUpdateCharacterInfo(self.nameRealm, "englishRace", englishRace)


    self:SetupClass(class)


end


function SamsUiTopBarMixin:SetupClass(class)

    if class == "SHAMAN" then

        self.hearthstoneButton:SetAttribute("macrotext2", "/cast Astral Recall")
        self.hearthstoneButton:SetScript("OnEnter", function()
    
            GameTooltip:SetOwner(self.hearthstoneButton, "LEFT")
            GameTooltip:AddLine(GetBindLocation())
            local start, duration, enabled, modRate = GetSpellCooldown(8690)
            local hearthstoneCooldown = (start + duration) - GetTime()
            GameTooltip:AddDoubleLine(string.format("Left click |cffffffff%s|r", GetSpellInfo(8690)), SecondsToTime(hearthstoneCooldown))

            local start, duration, enabled, modRate = GetSpellCooldown(556)
            local astralRecallCooldown = (start + duration) - GetTime()
            GameTooltip:AddDoubleLine(string.format("Right click |cffffffff%s|r", GetSpellInfo(556)), SecondsToTime(astralRecallCooldown))
            GameTooltip:Show()
    
        end)
    end
end


function SamsUiTopBarMixin:GetCharacterXpInfo(character)

    if not character then
        character = Database:GetCharacter(self.nameRealm)
    end

    if type(character) ~= "table" then
        return;
    end

	local rate = 0
	local multiplier = 1.5
	
	if character.englishRace == "Pandaren" then
		multiplier = 3
	end
	
	local savedXP = 0
	local savedRate = 0
	local maxXP = character.XPMax * multiplier
	if character.RestXP then
		rate = character.RestXP / (maxXP / 100)
		savedXP = character.RestXP
		savedRate = rate
	end
	
	local xpEarnedResting = 0
	local rateEarnedResting = 0
	local isFullyRested = false
	local timeUntilFullyRested = 0
	local now = time()
	
	if character.lastLogoutTimestamp ~= MAX_LOGOUT_TIMESTAMP then	
		local oneXPBubble = character.XPMax / 20
		local elapsed = (now - character.lastLogoutTimestamp)
		local numXPBubbles = elapsed / 28800
		
		xpEarnedResting = numXPBubbles * oneXPBubble
		
		if not character.isResting then
			xpEarnedResting = xpEarnedResting / 4
		end

		if (xpEarnedResting + savedXP) > maxXP then
			xpEarnedResting = xpEarnedResting - ((xpEarnedResting + savedXP) - maxXP)
		end

		if xpEarnedResting < 0 then xpEarnedResting = 0 end
		
		rateEarnedResting = xpEarnedResting / (maxXP / 100)
		
		if (savedXP + xpEarnedResting) >= maxXP then
			isFullyRested = true
			rate = 100
		else
			local xpUntilFullyRested = maxXP - (savedXP + xpEarnedResting)
			timeUntilFullyRested = math.floor((xpUntilFullyRested / oneXPBubble) * 28800)
			
			rate = rate + rateEarnedResting
		end
	end
	
	return rate, savedXP, savedRate, rateEarnedResting, xpEarnedResting, maxXP, isFullyRested, timeUntilFullyRested
end


function SamsUiTopBarMixin:UpdateXp()

    local xp, xpMax = UnitXP("player"), UnitXPMax("player")
    local xpPer = tonumber(string.format("%.1f", (xp/xpMax)*100))
    local xpRested = GetXPExhaustion()
    self.openXpButton:SetText(string.format("%s %s %%", CreateAtlasMarkup("GarrMission_CurrencyIcon-Xp", 32, 32), xpPer))

    Database:InsertOrUpdateCharacterInfo(self.nameRealm, "xp", xp)
    Database:InsertOrUpdateCharacterInfo(self.nameRealm, "xpMax", xpMax)
    Database:InsertOrUpdateCharacterInfo(self.nameRealm, "xpRested", xpRested)
end


---open a sub menu for the player bags for the items of a sub type class id
---@param parent frame the button to anchor the menu to
---@param items table list of items for this sub class
function SamsUiTopBarMixin:OpenPlayersBagsSubClassItems(parent, items)

    self.playerBagsSubClassItemsContainer:ClearAllPoints()
    self.playerBagsSubClassItemsContainer:SetPoint("TOPLEFT", parent, "TOPRIGHT", 2, 0)

    if not self.playerBagsSubClassItemsMenuButtons then
        self.playerBagsSubClassItemsMenuButtons = {}
    end

    if self.playerBagsSubClassItemsTicker then
        self.playerBagsSubClassItemsTicker:Cancel()
    end

    for k, button in pairs(self.playerBagsSubClassItemsMenuButtons) do
        button:ClearItem()
        button:Hide()
    end

    for k, item in ipairs(items) do
        
        if not self.playerBagsSubClassItemsMenuButtons[k] then
            
            local button = CreateFrame("BUTTON", nil, self.playerBagsSubClassItemsContainer, "SamsUiTopBarSecureMacroContainerMenuButton")

            button:SetPoint("TOP", 0, (k-1) * -31)
            button:SetSize(self.playerBagMenuItemWidth, 32)

            button.tooltipAnchor = "ANCHOR_RIGHT"

            self.playerBagsSubClassItemsMenuButtons[k] = button;
        end

        local button = self.playerBagsSubClassItemsMenuButtons[k]

        button.itemLink = item.link;
        button:SetItem(item)

        button:Show()

        self.playerBagsSubClassItemsContainer:SetSize(self.playerBagMenuItemWidth, 31*k)
        self.playerBagsSubClassItemsContainer:Show()

    end

    self.playerBagsSubClassItemsTicker = C_Timer.NewTicker(self.dropdownMenuCloseDelay, function()
        if self.playerBagsSubClassItemsContainer:IsMouseOver() == false and self.playerBagsContainer:IsMouseOver() == false then
            local isHovered = false;
            for k, button in ipairs(self.playerBagsSubClassItemsMenuButtons) do
                if button:IsMouseOver() == true then
                    isHovered = true;
                end
            end
            --check the sub menu buttons
            if self.playerBagsSubClassMenuButtons then
                for k, button in ipairs(self.playerBagsSubClassMenuButtons) do
                    if button:IsMouseOver() == true then
                        isHovered = true;
                    end
                end
            end
            if isHovered == false then
                self.playerBagsSubClassItemsContainer:Hide()
                self.playerBagsSubClassItemsTicker:Cancel()
            end
        end
    end)

end


---open a sub menu for a player bags class id
---@param parent frame the button that the sub menu should anchor to
---@param itemClassID number the parent button class id - used to get sub class info
---@param subClassItems table a list of items for this class id
function SamsUiTopBarMixin:OpenPlayerBagsSubClassMenu(parent, itemClassID, subClassItems)

    self.playerBagsSubClassItemsContainer:Hide()

    self.playerBagsSubClassContainer:ClearAllPoints()
    self.playerBagsSubClassContainer:SetPoint("TOPLEFT", parent, "TOPRIGHT", 2, 0)

    if self.playerBagsSubClassMenuTicker then
        self.playerBagsSubClassMenuTicker:Cancel()
    end

    if not self.playerBagsSubClassMenuButtons then
        self.playerBagsSubClassMenuButtons = {}
    end

    for k, button in pairs(self.playerBagsSubClassMenuButtons) do
        button:ClearItem()
        button:Hide()
    end

    if self.playerBagsSubClassItemsMenuButtons then
        for k, button in pairs(self.playerBagsSubClassItemsMenuButtons) do
            button:ClearItem()
            button:Hide()
        end
    end

    local subClassIDs = {}
    for k, item in ipairs(subClassItems) do
        
        if not subClassIDs[item.subClassID] then
            subClassIDs[item.subClassID] = {}
        end

        table.insert(subClassIDs[item.subClassID], item)

    end

    local i = 0;
    for itemSubClassID, items in pairs(subClassIDs) do
        
        i = i + 1;

        local itemSubTypeInfo, isArmorType = GetItemSubClassInfo(itemClassID, itemSubClassID)

        if not self.playerBagsSubClassMenuButtons[i] then
            
            local button = CreateFrame("BUTTON", nil, self.playerBagsSubClassContainer, "SamsUiTopBarSecureMacroContainerMenuButton")

            button:SetPoint("TOP", 0, (i-1) * -31)
            button:SetSize(self.playerBagMenuTypeWidth, 32)

            self.playerBagsSubClassMenuButtons[i] = button;

        end

        local button = self.playerBagsSubClassMenuButtons[i]

        button:SetPoint("TOP", 0, (i-1) * -31)
        button:SetText(itemSubTypeInfo)

        --button.items = items;
        button.func = function()
            self:OpenPlayersBagsSubClassItems(button, items)
        end

        button:Show()

        self.playerBagsSubClassContainer:SetSize(self.playerBagMenuTypeWidth, 31*i)
        self.playerBagsSubClassContainer:Show()

    end

    self.playerBagsSubClassMenuTicker = C_Timer.NewTicker(self.dropdownMenuCloseDelay, function()

        --check if we are hovering over either the top level class di menu or the sub menu for the class id sub classes
        if self.playerBagsContainer:IsMouseOver() == false and self.playerBagsSubClassContainer:IsMouseOver() == false then
            local isHovered = false;

            --check the top level buttons
            for k, button in ipairs(self.playerBagsMenuButtons) do
                if button:IsMouseOver() == true then
                    isHovered = true;
                end
            end

            --check the sub menu buttons
            if self.playerBagsSubClassMenuButtons then
                for k, button in ipairs(self.playerBagsSubClassMenuButtons) do
                    if button:IsMouseOver() == true then
                        isHovered = true;
                    end
                end
            end
            if self.playerBagsSubClassItemsMenuButtons then
                for k, button in ipairs(self.playerBagsSubClassItemsMenuButtons) do
                    if button:IsMouseOver() == true then
                        isHovered = true;
                    end
                end
            end
            if isHovered == false then
                self.playerBagsContainer:Hide()
                self.playerBagsSubClassContainer:Hide()
                self.playerBagsSubClassMenuTicker:Cancel()
            end
        end
    end)

end


---open the player bag menu - this will show a list of item type class id names
function SamsUiTopBarMixin:OpenPlayerBagsMenu()

    if self.playerBagsContainer:IsVisible() then
        return;
    end

    if self.playerBagsMenuTicker then
        self.playerBagsMenuTicker:Cancel()
    end

    self:ScanPlayerBags()

    if not self.playerBagsMenuButtons then
        self.playerBagsMenuButtons = {}
    end

    for k, button in ipairs(self.playerBagsMenuButtons) do
        button:ClearItem()
        button:Hide()
    end

    if self.playerBagsSubClassMenuButtons then
        for k, button in ipairs(self.playerBagsSubClassMenuButtons) do
            button:ClearItem()
            button:Hide()
        end
    end

    if self.playerBagsSubClassItemsMenuButtons then
        for k, button in ipairs(self.playerBagsSubClassItemsMenuButtons) do
            button:ClearItem()
            button:Hide()
        end
    end


    local i = 0;
    for itemType, items in pairs(self.characterBagItems) do

        local itemTypeInfo = GetItemClassInfo(itemType)
        i = i + 1;

        if not self.playerBagsMenuButtons[i] then
            
            local button = CreateFrame("BUTTON", nil, self.playerBagsContainer, "SamsUiTopBarSecureMacroContainerMenuButton")

            button:SetPoint("TOP", 0, (i-1) * -31)
            button:SetSize(self.playerBagMenuTypeWidth, 32)

            self.playerBagsMenuButtons[i] = button;

        end

        local button = self.playerBagsMenuButtons[i]

        button:SetPoint("TOP", 0, (i-1) * -31)
        button:SetText(itemTypeInfo)

        button.func = function()
            self:OpenPlayerBagsSubClassMenu(button, itemType, items)
        end

        button:Show()


        self.playerBagsContainer:SetSize(self.playerBagMenuTypeWidth, 31*i)
        self.playerBagsContainer:Show()
    end

    self.playerBagsMenuTicker = C_Timer.NewTicker(self.dropdownMenuCloseDelay, function()
        if self.playerBagsContainer:IsMouseOver() == false and self.openPlayerBagsButton:IsMouseOver() == false and self.playerBagsSubClassContainer:IsMouseOver() == false then
            local isHovered = false;
            for k, button in ipairs(self.playerBagsMenuButtons) do
                if button:IsMouseOver() == true then
                    isHovered = true;
                end
            end
            if self.playerBagsSubClassMenuButtons then
                for k, button in ipairs(self.playerBagsSubClassMenuButtons) do
                    if button:IsMouseOver() == true then
                        isHovered = true;
                    end
                end
            end
            if self.playerBagsSubClassItemsMenuButtons then
                for k, button in ipairs(self.playerBagsSubClassItemsMenuButtons) do
                    if button:IsMouseOver() == true then
                        isHovered = true;
                    end
                end
            end
            if isHovered == false then
                self.playerBagsContainer:Hide()
                self.playerBagsSubClassItemsContainer:Hide()
                self.playerBagsMenuTicker:Cancel()
            end
        end
    end)

end


function SamsUiTopBarMixin:OpenConsumablesMenu()

    if self.consumablesMenuContainer:IsVisible() then
        return;
    end

    if self.consumablesMenuTicker then
        self.consumablesMenuTicker:Cancel()
    end

    self:ScanPlayerBags()

    if not self.consumablesMenuButtons then
        self.consumablesMenuButtons = {}
    end

    local consumablesTypesDisplayed = {
        [1] = true, --potion
        [2] = true, --elixir
        [3] = true, --scroll
        [6] = true, --bandages ?
        [8] = true, --bandages ?
    }

    local i = 0;
    for k, item in ipairs(self.characterBagItems[0]) do

        if consumablesTypesDisplayed[item.subClassID] then

            i = i + 1;

            if not self.consumablesMenuButtons[i] then
                
                local button = CreateFrame("BUTTON", nil, self.consumablesMenuContainer, "SamsUiTopBarSecureMacroContainerMenuButton")

                button:SetPoint("TOP", 0, (i-1) * -31)
                button:SetSize(250, 32)

                button.itemLink = item.link;
                button:SetItem(item)
                button.tooltipAnchor = "ANCHOR_LEFT"

                button:Show()

                self.consumablesMenuButtons[i] = button;

            else

                local button = self.consumablesMenuButtons[i]

                button.itemLink = item.link;
                button:SetItem(item)

                button:Show()

            end

        end

        self.consumablesMenuContainer:SetSize(250, 31*i)
        self.consumablesMenuContainer:Show()
    end

    self.consumablesMenuTicker = C_Timer.NewTicker(self.dropdownMenuCloseDelay, function()
        if self.consumablesMenuContainer:IsMouseOver() == false and self.openConsumablesButton:IsMouseOver() == false then
            local isHovered = false;
            for k, button in ipairs(self.consumablesMenuButtons) do
                if button:IsMouseOver() == true then
                    isHovered = true;
                end
            end
            if isHovered == false then
                self.consumablesMenuContainer:Hide()
                self.consumablesMenuTicker:Cancel()
            end
        end
    end)

end


function SamsUiTopBarMixin:OpenFoodAndDrinkMenu()

    if self.foodAndDrinkMenuContainer:IsVisible() then
        return;
    end

    if self.closeFoodAndDrinkMenuTicker then
        self.closeFoodAndDrinkMenuTicker:Cancel()
    end

    self:ScanPlayerBags()

    if not self.foodAndDrinkMenuButtons then
        self.foodAndDrinkMenuButtons = {}
    end

    for k, button in ipairs(self.foodAndDrinkMenuButtons) do
        button:Hide()
    end

    --DevTools_Dump({self.foodAndDrink})

    self.foodAndDrinkMenuContainer:SetSize(250, 0)

    local i = 0;
    for k, item in ipairs(self.characterBagItems[0]) do

        if item.subClassID == 5 then
            
            i = i + 1;
        
            if not self.foodAndDrinkMenuButtons[i] then
                
                local button = CreateFrame("BUTTON", nil, self.foodAndDrinkMenuContainer, "SamsUiTopBarSecureMacroContainerMenuButton")

                button:SetPoint("TOP", 0, (i-1) * -31)
                button:SetSize(250, 32)

                button.itemLink = item.link;
                button:SetItem(item)
                button.tooltipAnchor = "ANCHOR_LEFT"

                --button.anim.fadeIn:SetStartDelay(i/40)

                button:Show()

                self.foodAndDrinkMenuButtons[i] = button;

            else

                local button = self.foodAndDrinkMenuButtons[i]

                button.itemLink = item.link;
                button:SetItem(item)

                button:Show()

            end

        end
        self.foodAndDrinkMenuContainer:SetSize(250, 31*i)
        self.foodAndDrinkMenuContainer:Show()
    end


    self.closeFoodAndDrinkMenuTicker = C_Timer.NewTicker(self.dropdownMenuCloseDelay, function()
        if self.foodAndDrinkMenuContainer:IsMouseOver() == false and self.openFoodAndDrinkButton:IsMouseOver() == false then
            local isHovered = false;
            for k, button in ipairs(self.foodAndDrinkMenuButtons) do
                if button:IsMouseOver() == true then
                    isHovered = true;
                end
            end
            if isHovered == false then
                self.foodAndDrinkMenuContainer:Hide()
                self.closeFoodAndDrinkMenuTicker:Cancel()
            end
        end
    end)

end


function SamsUiTopBarMixin:ScanPlayerBags()

    self.characterBagItems = nil;
    self.characterBagItems = {}
    self.characterBagSlots = nil
    self.characterBagSlots = {}
    local bagItemsAdded = {}
    local bagItemIDsSeen = {}

    self.totalBagSlots = 0;
    self.bagSlotsUsed = 0;

    for bag = 0, 4 do

        local bagSlots = GetContainerNumSlots(bag)
        self.totalBagSlots = self.totalBagSlots + bagSlots;

        local slotID = 0;
        for slot = bagSlots, 1, -1 do

            slotID = slotID + 1;

            --local slotFrame = string.format("ContainerFrame%dItem%d", bag+1, slotID)

            local icon, itemCount, _, _, _, _, itemLink, _, _, itemID = GetContainerItemInfo(bag, slot)
            --local itemLink = GetContainerItemLink(bag, slot)
            if itemID then

                self.bagSlotsUsed = self.bagSlotsUsed + 1;

                bagItemIDsSeen[itemID] = true;

                local _, _, _, itemEquipLoc, _, itemClassID, itemSubClassID = GetItemInfoInstant(itemID)
                local itemName, _, itemQuality, itemLevel, _, _, _, _, _, _, sellPrice = GetItemInfo(itemID)

                
                -- table.insert(self.characterBagSlots, {
                --     slotFrame = slotFrame,
                --     itemID = itemID,
                --     icon = icon,
                --     link = itemLink,
                --     count = itemCount,
                --     classID = itemClassID,
                --     subClassID = itemSubClassID,
                --     name = itemName,
                --     ilvl = itemLevel or -1,
                -- })

                --add the classID check tables
                if not self.characterBagItems[itemClassID] then
                    self.characterBagItems[itemClassID] = {}
                end
                if not bagItemsAdded[itemClassID] then
                    bagItemsAdded[itemClassID] = {}
                end

                -- weapons and armour are best checked using links due to gems/enchants which an itemID would miss
                if itemClassID == 4 or itemClassID == 2 then
                    if not bagItemsAdded[itemClassID][itemLink] then
                        table.insert(self.characterBagItems[itemClassID], {
                            itemID = itemID,
                            icon = icon,
                            link = itemLink,
                            count = itemCount,
                            sellPrice = sellPrice,
                            rarity = itemQuality,
                            subClassID = itemSubClassID,
                            name = itemName,
                            ilvl = itemLevel or -1,
                        })
                        bagItemsAdded[itemClassID][itemLink] = true;
                    else
                        --print(string.format("updatign count for %s", itemLink))
                        for k, item in ipairs(self.characterBagItems[itemClassID]) do
                            if item.link == itemLink then
                                item.count = item.count + 1;
                            end
                        end
                    end

                --other items check by itemID
                else
                    if not bagItemsAdded[itemClassID][itemID] then
                        table.insert(self.characterBagItems[itemClassID], {
                            itemID = itemID,
                            icon = icon,
                            link = itemLink,
                            count = itemCount,
                            sellPrice = sellPrice,
                            rarity = itemQuality,
                            subClassID = itemSubClassID,
                            name = itemName,
                            ilvl = itemLevel or -1,
                        })
                        bagItemsAdded[itemClassID][itemID] = true
                    else
                        --print(string.format("updatign count for %s", itemLink))
                        for k, item in ipairs(self.characterBagItems[itemClassID]) do
                            if item.itemID == itemID then
                                item.count = item.count + itemCount;
                            end
                        end
                    end
                end

            end
        end
    end

    for itemClassID, items in pairs(self.characterBagItems) do

        local keysToRemove = {}
        
        for k, item in ipairs(items) do
            
            if not bagItemIDsSeen[item.itemID] then
                table.insert(keysToRemove, k)
            end

        end

        for _, key in ipairs(keysToRemove) do
            items[key] = nil;
        end

    end

    --table.sort(self.characterBagItems)
   
    for itemClassID, items in pairs(self.characterBagItems) do

        table.sort(items, function(a,b)

            if a.subClassID == b.subClassID then
                
                if a.ilvl == b.ilvl then
                    
                    if a.count == b.count then
                        
                        return a.name < b.name
                    else

                        return a.count > b.count
                    end

                else

                    return a.ilvl > b.ilvl
                end

            else

                return a.subClassID > b.subClassID
            end
        end)
    end

    self.openPlayerBagsButton:SetText(string.format("%s %s/%s", CreateAtlasMarkup("ShipMissionIcon-Treasure-Mission", 32, 32), self.bagSlotsUsed, self.totalBagSlots))

    self:TriggerEvent("OnPlayerBagsScanned")

end


function SamsUiTopBarMixin:ScanSpellbook()

     if not self.nameRealm then
         return;
     end

     
     local ignore = {
        ["Skinning"] = true,
        ["Herbalism"] = true,
    }

    local prof1, prof2 = false, false;
    local _, _, offset, numSlots = GetSpellTabInfo(1)
    for j = offset+1, offset+numSlots do
        
        local _, spellID = GetSpellBookItemInfo(j, BOOKTYPE_SPELL)
        local spellName = GetSpellInfo(spellID)

        if spellID == 2383 then --find herbs
            spellName = "Herbalism" --change this to add to db, will be ignored for top bar buttons
        end

        if spellID == 2656 then --smelting
            spellName = "Mining" --change this to add to db, will be ignored for top bar buttons
        end

        if tradeskillNamesToIDs[spellName] then

            --print(spellName)

            if prof1 == false then

                --update the db
                Database:InsertOrUpdateCharacterInfo(self.nameRealm, "profession1", spellName)

                --if the prof isnt somethign with a ui then ignore it
                if ignore[spellName] then
                    return;
                end

                --set the icon
                self.openProf1Button.icon:SetAtlas(string.format("Mobile-%s", (spellName ~= "Engineering" and spellName or "Enginnering")))

                --if its mining then swap the spell to cast smelting
                if spellName == "Mining" then
                    spellName = "Smelting"
                end

                --set the button macro
                self.openProf1Button:SetAttribute("macrotext1", string.format("/cast %s", spellName))
                self.openProf1Button.tooltipText = spellName;
                self.openProf1Button:Show()
                
                prof1 = true;

            else
                if prof2 == false then

                    Database:InsertOrUpdateCharacterInfo(self.nameRealm, "profession2", spellName)

                    if ignore[spellName] then
                        return;
                    end

                    self.openProf2Button.icon:SetAtlas(string.format("Mobile-%s", (spellName ~= "Engineering" and spellName or "Enginnering")))

                    if spellName == "Mining" then
                        spellName = "Smelting"
                    end

                    self.openProf2Button:SetAttribute("macrotext1", string.format("/cast %s", spellName))
                    self.openProf2Button.tooltipText = spellName;
                    self.openProf2Button:Show()

                    prof2 = true;
                end
            end 

        end
    end

    --if no data found then set to false
    if prof1 == false then
        Database:InsertOrUpdateCharacterInfo(self.nameRealm, "profession1", false)
    end
    if prof2 == false then
        Database:InsertOrUpdateCharacterInfo(self.nameRealm, "profession2", false)
    end

end


function SamsUiTopBarMixin:UpdateDurability()

    self.durabilityInfo = {};

    local currentDurability, maximumDurability = 0, 0;
    for i = 1, 19 do
        local slotId = GetInventorySlotInfo(inventorySlots[i])
        local itemLink = GetInventoryItemLink("player", slotId)
        if itemLink then
            local current, maximum = GetInventoryItemDurability(i)
            local percent = 100;
            if type(current) == "number" and type(maximum) == "number" then
                percent = tonumber(string.format("%.1f", (current / maximum) * 100));
            end
            local atlas = string.format("transmog-nav-slot-%s", inventorySlots[i]:sub(1, (#inventorySlots[i]-4)))
            self.durabilityInfo[i] = {
                atlas = atlas,
                itemLink = itemLink,
                currentDurability = current or 1,
                maximumDurability = maximum or 1,
                percentDurability = percent or 1,
            }
            currentDurability = currentDurability + (current or 0);
            maximumDurability = maximumDurability + (maximum or 0);
        else
            self.durabilityInfo[i] = {
                itemLink = "-",
                currentDurability = 1,
                maximumDurability = 1,
                percentDurability = 1,
            }
        end
    end

    table.sort(self.durabilityInfo, function(a,b)
        return a.percentDurability > b.percentDurability;
    end)

    local durability = tonumber(string.format("%.1f", (currentDurability / maximumDurability) * 100));

    self.openDurabilityButton:SetText(string.format("%s %s %%", CreateAtlasMarkup("vehicle-hammergold-3", 18, 18), durability))

end


function SamsUiTopBarMixin:UpdateCurrency()

    if type(self.nameRealm) ~= "string" then
        return;
    end

    local gold = GetMoney();

    self.sessionInfo.profit = GetMoney() - (Database:GetCharacterInfo(self.nameRealm, "initialLoginGold") or 0);

    self.openCurrencyButton:SetText(GetCoinTextureString(gold))

    Database:InsertOrUpdateCharacterInfo(self.nameRealm, "gold", gold)

end


function SamsUiTopBarMixin:OpenMinimapButtonsMenu()

    self:MoveAllLibMinimapIcons()

    if self.minimapButtonsContainer:IsVisible() then
        return;
    end

    if self.minimapButtonsCloseDelayTicker then
        self.minimapButtonsCloseDelayTicker:Cancel()
    end

    self.minimapButtonsContainer:Show()
    self.minimapButtonsContainer.anim:Play()

    self.minimapButtonsCloseDelayTicker = C_Timer.NewTicker(self.dropdownMenuCloseDelay, function()
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


function SamsUiTopBarMixin:SetupSpellBook()

    --SpellBook:Set
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

    local NUM_ICONS_PER_ROWS = Database:GetConfigValue("numberMinimapIconsPerRow") or 6;
    local rowsRequired = math.ceil(#buttons / NUM_ICONS_PER_ROWS)
    local k = 1;
    local xPos, yPos = 0, 0;
    local maxButtonHeight = 0;

    for rowIndex = 1, rowsRequired do

        local newRow = true;

        for i = 1, NUM_ICONS_PER_ROWS do
            local buttonIndex = i + ((rowIndex - 1) * NUM_ICONS_PER_ROWS)
            if buttons[buttonIndex] then
                local button = buttons[buttonIndex]
                
                button:ClearAllPoints()
                button:SetParent(self.minimapButtonsContainer)
                button:Show()

                if button:GetHeight() > maxButtonHeight then
                    maxButtonHeight = button:GetHeight()
                end

                xPos = xPos + maxButtonHeight;

                button:SetPoint("CENTER", self.minimapButtonsContainer, "TOPLEFT", xPos, -yPos)

                
                if newRow == true then
                    button:SetPoint("TOPLEFT", self.minimapButtonsContainer, "TOPLEFT", 0, -yPos)
                    newRow = false;
                else
                    button:SetPoint("LEFT", self.minimapButtons[k-1], "RIGHT", 4, 0)
                end


                if buttonNames[k] then
                    lib:Lock(buttonNames[k])
                else
                    button:SetScript("OnDragStart", nil)
                    button:SetScript("OnDragStop", nil)
                    button:SetMovable(false)
                end
                self.minimapButtons[k] = button

                self.minimapButtonsContainer:SetWidth(xPos)

                k = k + 1;
            end
        end

        yPos = yPos + maxButtonHeight;
        xPos = 0;

        self.minimapButtonsContainer:SetHeight(yPos)
    end

    self.minimapButtonsContainer:SetWidth(maxButtonHeight * NUM_ICONS_PER_ROWS)


end



function SamsUiTopBarMixin:OpenMainMenu()

    if self.mainMenuContainerCloseDelayTicker then
        self.mainMenuContainerCloseDelayTicker:Cancel()
    end

    for k, item in ipairs(self.mainMenuContainer.keys) do

        if not self.mainMenuContainer.buttons[k] then
            local button = CreateFrame("BUTTON", nil, self.mainMenuContainer, "SamsUiTopBarMainMenuButton")
            button:SetPoint("TOP", 0, (k-1)*-41)
            button:SetSize(200, 40)
            button:SetText(item)

            -- if item == "Hearthstone" then
            --     button:SetScript("OnShow", function()
            --         local hsl = GetBindLocation()
            --         button:SetText(hsl)
            --         button.anim:Play()
            --     end)
            -- end

            if self.mainMenuContainer.menu[item].macro then
                button:SetAttribute("type1", "macro")
                button:SetAttribute("macrotext1", string.format([[%s]], self.mainMenuContainer.menu[item].macro))
                button.func = nil;
            else
                button.func = self.mainMenuContainer.menu[item].func;

            end

            button:SetIconAtlas(self.mainMenuContainer.menu[item].atlas)
            
            button.anim.fadeIn:SetStartDelay(k/25)

            self.mainMenuContainer.buttons[k] = button;

            self.mainMenuContainer:SetSize(200, k*28)

        end
    end

    for _, button in ipairs(self.mainMenuContainer.buttons) do
        button:Show()
    end

    self.mainMenuContainer:Show()

    self.mainMenuContainerCloseDelayTicker = C_Timer.NewTicker(self.dropdownMenuCloseDelay, function()
        if self.mainMenuContainer:IsMouseOver() == false and self.openMainMenuButton:IsMouseOver() == false then
            self.mainMenuContainer:Hide()
            self.mainMenuContainerCloseDelayTicker:Cancel()
        end
    end)
end


























--[[
    player bar mixin

    handles the player bar ui
]]
SamsUiPlayerBarMixin:GenerateCallbackEvents({

});
SamsUiPlayerBarMixin.playerHealthTextFormat = "{per} %"; -- set a default string to use on first load before getting db values
SamsUiPlayerBarMixin.playerPowerTextFormat = "{per} %";

function SamsUiPlayerBarMixin:OnLoad()

    self:RegisterEvent("UNIT_AURA")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    self:RegisterEvent("UNIT_PORTRAIT_UPDATE")
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    
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


    self:LoadClassUI(playerClass)

    --Util:MakeFrameMoveable(self)

end


function SamsUiPlayerBarMixin:LoadConfigVariables()

    local isEnabled = Database:GetConfigValue("playerBarEnabled")
    if isEnabled ~= nil then
        self:SetEnabled(isEnabled)
    end

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

    if setting == "playerBarEnabled" then
        self:SetEnabled(newValue)
    end

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


function SamsUiPlayerBarMixin:SetEnabled(enabled)

    if enabled == true then
        self:RegisterEvent("UNIT_AURA")
        self:RegisterEvent("PLAYER_TARGET_CHANGED")
        self:RegisterEvent("UNIT_PORTRAIT_UPDATE")
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        self:Show()
    else
        self:UnregisterAllEvents()
        self:Hide()
    end

end


function SamsUiPlayerBarMixin:OnEvent(event, ...)

    if event == "PLAYER_ENTERING_WORLD" then
        self:Init()

    elseif event == "UNIT_PORTRAIT_UPDATE" then
        SetPortraitTexture(self.portrait, "player")

    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        
        local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName = CombatLogGetCurrentEventInfo()

        if subevent:find("DAMAGE") and destGUID == UnitGUID("player") then
            self.splashAnim:Play()
        end
        
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


    --buffs and auras
    self.shieldAuraIcon:Hide()
    if self.shieldAuraIcon.spellIds then

        for i = 1, 40 do
            local name, icon, count, dispelType, duration, expirationTime, _, _, _, spellId = UnitAura("player", i)

            if self.shieldAuraIcon.spellIds[spellId] then

                self.shieldAuraIcon.icon:SetTexture(icon)
                self.shieldAuraIcon.spinner:SetAtlas(self.shieldAuraIcon.spellIds[spellId])

                self.shieldAuraIcon:Show()
            end

        end
    end

end



function SamsUiPlayerBarMixin:LoadClassUI(class)

    local ui = {
        SHAMAN = function()
            self.shieldAuraIcon.background:SetAtlas(string.format("Artifacts-%s-KnowledgeRank", class:sub(1):upper()..class:sub(2):lower()))

            self.shieldAuraIcon.icon:SetTexture(136051)

            self.shieldAuraIcon.anim:Play()

            self.shieldAuraIcon.spellIds = {

                --lightning shield
                [324] = "Relic-Water-TraitGlow",
                [325] = "Relic-Water-TraitGlow",
                [905] = "Relic-Water-TraitGlow",
                [945] = "Relic-Water-TraitGlow",
                [8134] = "Relic-Water-TraitGlow",
                [10431] = "Relic-Water-TraitGlow",
                [10432] = "Relic-Water-TraitGlow",
                [25472] = "Relic-Water-TraitGlow",

                --water shield
                [24398] = "Relic-Frost-TraitGlow",
                [33736] = "Relic-Frost-TraitGlow",

                --earth shield

            }
        end,
    }
    
    if ui[class] then
        ui[class]()
    end
end


























--[[
    target bar mixin

    hanldes the target bar
]]
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

    --Util:MakeFrameMoveable(self)
    
end


function SamsUiTargetBarMixin:LoadConfigVariables()

    local isEnabled = Database:GetConfigValue("targetBarEnabled")
    if isEnabled ~= nil then
        self:SetEnabled(isEnabled)
    end

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

    if setting == "targetBarEnabled" then
        self:SetEnabled(newValue)
    end

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


function SamsUiTargetBarMixin:SetEnabled(enabled)

    if enabled == true then
        -- self:RegisterEvent("UNIT_AURA")
        self:RegisterEvent("PLAYER_TARGET_CHANGED")
        -- self:RegisterEvent("UNIT_PORTRAIT_UPDATE")
        -- self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        self:Show()
    else
        self:UnregisterAllEvents()
        self:Hide()
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

    local targetClassification = UnitClassification("target")

    if targetClassification == "elite" then
        self.classificationIcon:Show()

    else
        self.classificationIcon:Hide()
    end

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
    self.classificationIcon:Hide()

end


function SamsUiTargetBarMixin:OnUpdate()

    if UnitExists("target") == false then
        return;
    end

    local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellId = UnitCastingInfo("target")
    if name then
        --print(name, spellId)
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

























SamsUiCharacterFrameMixin:GenerateCallbackEvents({
    "InventoryChanged",
})
SamsUiCharacterFrameMixin.StatIDs = {
    [1] = 'Strength',
    [2] = 'Agility',
    [3] = 'Stamina',
    [4] = 'Intellect',
    [5] = 'Spirit',
}
SamsUiCharacterFrameMixin.SpellSchools = {
    [2] = 'Holy',
    [3] = 'Fire',
    [4] = 'Nature',
    [5] = 'Frost',
    [6] = 'Shadow',
    [7] = 'Arcane',
}
SamsUiCharacterFrameMixin.characterStats = {
    ["attributes"] = {
        { key = "Strength", display = true, },
        { key = "Agility", display = true, },
        { key = "Stamina", display = true, },
        { key = "Intellect", display = true, },
        { key = "Spirit", display = true, },
    },
    ["defence"] = {
        { key = "Armor", display = true, },
        { key = "Defence", display = true, },
        { key = "Dodge", display = true, },
        { key = "Parry", display = true, },
        { key = "Block", display = true, },
    },
    ["melee"] = {
        { key = "Expertise", display = true, },
        { key = "MeleeHit", display = true, },
        { key = "MeleeCrit", display = true, },
        { key = "MeleeDmgMH", display = true, },
        { key = "MeleeDpsMH", display = true, },
        { key = "MeleeDmgOH", display = true, },
        { key = "MeleeDpsOH", display = true, },
    },
    ["ranged"] = {
        { key = "RangedHit", display = true, },
        { key = "RangedCrit", display = true, },
        { key = "RangedDmg", display = true, },
        { key = "RangedDps", display = true, },
    },
    ["spells"] = {
        { key = "Haste", display = true, },
        { key = "ManaRegen", display = true, },
        { key = "ManaRegenCasting", display = true, },
        { key = "SpellHit", display = true, },
        { key = "SpellCrit", display = true, },
        { key = "HealingBonus", display = true, },
        { key = "SpellDmgHoly", display = true, },
        { key = "SpellDmgFrost", display = true, },
        { key = "SpellDmgShadow", display = true, },
        { key = "SpellDmgArcane", display = true, },
        { key = "SpellDmgFire", display = true, },
        { key = "SpellDmgNature", display = true, },
    }
}
SamsUiCharacterFrameMixin.characterEnhancements = {
    --melee
    { key = "MeleeCrit", display = false, label = "Critical strike %", },
    { key = "MeleeHit", display = false, label = "Hit %", },
    { key = "Expertise", display = false, label = "Expertise", },

    --casters
    { key = "HealingBonus", display = true, label = "Healing power", },
    { key = "SpellDmgNature", display = true, label = "Spell power", },
    { key = "Haste", display = true, label = "Haste", },
    { key = "SpellHit", display = true, label = "Hit %", },
    { key = "SpellCrit", display = true, label = "Critical strike %", },
    { key = "ManaRegen", display = true, label = "Mana regeneration", },
    { key = "ManaRegenCasting", display = true, label = "Mana regeneration (casting)", },

    --ranged aka hunter
    { key = "RangedHit", display = false, label = "Hit %", },
    { key = "RangedCrit", display = false, label = "Critical strike %", },
}


function SamsUiCharacterFrameMixin:OnLoad()

    CallbackRegistryMixin.OnLoad(self)

    self:RegisterEvent("ADDON_LOADED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("UNIT_INVENTORY_CHANGED")

    self:RegisterCallback("InventoryChanged", self.OnInventoryChanged, self)

end


function SamsUiCharacterFrameMixin:OnShow()
    self:TriggerEvent("InventoryChanged", self.OnInventoryChanged, self)
end


function SamsUiCharacterFrameMixin:Init()

    self:RegisterForDrag("LeftButton")

    PanelTemplates_SetNumTabs(self, 2);
    PanelTemplates_SetTab(self, 1);

    self:SetupPaperdollFrame()

end


function SamsUiCharacterFrameMixin:TabButton_Clicked(tabID, panel)

    for k, panel in ipairs(self.panels) do
        panel:Hide()
    end

    self[panel]:Show()

    PanelTemplates_SetTab(self, tabID);
end


function SamsUiCharacterFrameMixin:SetupPaperdollFrame()

    local _, class = UnitClass("player")

    local paperdoll = self.paperdoll;
    
    paperdoll.background:SetAtlas(string.format("legionmission-complete-background-%s", class:lower()))
    paperdoll.background:SetAtlas(string.format("dressingroom-background-%s", class:lower()))
    paperdoll.backgroundRight:SetAtlas(string.format("UI-Character-Info-%s-BG", Util:CapitaliseString(class)))

    _G[self:GetName().."Portrait"]:SetAtlas(string.format("Artifacts-%s-FinalIcon", Util:CapitaliseString(class)))

    paperdoll.portraitMask = self:CreateMaskTexture()
    paperdoll.portraitMask:SetSize(64,64)
    paperdoll.portraitMask:SetPoint("TOPLEFT", -10, 10)
    paperdoll.portraitMask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    _G[self:GetName().."Portrait"]:AddMaskTexture(paperdoll.portraitMask)


    paperdoll.playerModel:SetUnit("player")
    paperdoll.playerModel:SetPosition(0.0, 0.0, 0.05)
    paperdoll.playerModel.portraitZoom = 0.15
    paperdoll.playerModel:SetPortraitZoom(paperdoll.playerModel.portraitZoom)
    paperdoll.playerModel.rotation = 0.0
    paperdoll.playerModel:SetRotation(0.0)

    paperdoll.playerModel:SetScript('OnMouseDown', function(self, button)
        if ( not button or button == "LeftButton" ) then
            self.mouseDown = true;
            self.rotationCursorStart = GetCursorPosition();
        end
    end)
    paperdoll.playerModel:SetScript('OnMouseUp', function(self, button)
        if ( not button or button == "LeftButton" ) then
            self.mouseDown = false;
        end
    end)
    paperdoll.playerModel:SetScript('OnMouseWheel', function(self, delta)
        self.portraitZoom = self.portraitZoom + (delta/10)
        self:SetPortraitZoom(self.portraitZoom)
        --f:SetPosition(0.0, 0.0, (-0.1 + (delta/10)))
    end)

    paperdoll.playerModel:SetScript('OnShow', function(self)
        self:SetUnit("player")
    end)

    paperdoll.playerModel:SetScript('OnUpdate', function(self)
        if (self.mouseDown) then
            if ( self.rotationCursorStart ) then
                local x = GetCursorPosition();
                local diff = (x - self.rotationCursorStart) * 0.05;
                self.rotationCursorStart = GetCursorPosition();
                self.rotation = self.rotation + diff;
                if ( self.rotation < 0 ) then
                    self.rotation = self.rotation + (2 * PI);
                end
                if ( self.rotation > (2 * PI) ) then
                    self.rotation = self.rotation - (2 * PI);
                end
                self:SetRotation(self.rotation, false);
            end
        end
    end)


    for _, slot in pairs(inventorySlots) do

        local itemLink = GetInventoryItemLink("player", GetInventorySlotInfo(slot))
        if itemLink then
            paperdoll[slot]:SetItem(nil, itemLink)

        else
            paperdoll[slot]:ClearItem()
        end
    end

    local ilvl = self:GetCurrentIlvl()
    self.paperdoll.stats.ilvlLabel:SetText(Util:FormatNumberForCharacterStats(ilvl))

    -- move this into its own function to call when stuff changes etc
    local stats = self:GetPaperDollStats()

    --attributes panel
    self.paperdoll.stats.attributePanel = CreateFrame("FRAME", nil, self.paperdoll.stats, "SamsUiCharacterFramePaperdollInfoPanelTemplate")
    self.paperdoll.stats.attributePanel.titleLabel:SetText("Attributes")
    self.paperdoll.stats.attributePanel:SetPoint("TOP", self.paperdoll.stats.ilvlLabel, "BOTTOM", 0, 0)
    for k, stat in ipairs(self.characterStats.attributes) do

        local fsLeft = self.paperdoll.stats.attributePanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fsLeft:SetJustifyH("LEFT")
        fsLeft:SetPoint("TOPLEFT", 0, ((k-1) * -18) - 40)
        fsLeft:SetSize(100, 19)
        fsLeft:SetTextColor(1,1,1,1)
        fsLeft:SetText(stat.key)

        local fsRight = self.paperdoll.stats.attributePanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fsRight:SetJustifyH("RIGHT")
        fsRight:SetPoint("TOPRIGHT", 0, ((k-1) * -18) - 40)
        fsRight:SetSize(100, 19)
        fsRight:SetTextColor(1,1,1,1)
        fsRight:SetText(stats[stat.key])

        self.paperdoll.stats.attributePanel[stat.key] = fsRight;

        if k % 2 == 0 then
            local t = self.paperdoll.stats.attributePanel:CreateTexture(nil, "ARTWORK")
            t:SetPoint("TOP", 0, ((k-1) * -18) - 40)
            t:SetSize(200, 21)
            t:SetAlpha(0.3)
            t:SetAtlas("UI-Character-Info-Line-Bounce")
        end
    end
    self.paperdoll.stats.attributePanel:SetSize(200, 40 + (#self.characterStats.attributes * 19))

    --re position the enhancement panel title
    self.paperdoll.stats.enhancementTitleBackground:ClearAllPoints()
    self.paperdoll.stats.enhancementTitleBackground:SetPoint("TOP", self.paperdoll.stats.attributePanel, "BOTTOM", 0, -10)

    self:UpdatePaperdollStats()
end



function SamsUiCharacterFrameMixin:UpdatePaperdollStats()

    if not self.paperdoll.stats.attributePanel then
        return;
    end

    local stats = self:GetPaperDollStats()

    for k, stat in ipairs(self.characterStats.attributes) do
        self.paperdoll.stats.attributePanel[stat.key]:SetText(stats[stat.key])
    end

    --enhancements panel    
    local rows = 0;
    self.paperdoll.stats.enhancementsListview.DataProvider:Flush()
    for k, stat in ipairs(self.characterEnhancements) do

        if stat.display == true then

            rows = rows + 1;

            if rows % 2 == 0 then

                self.paperdoll.stats.enhancementsListview.DataProvider:Insert({
                    stat = stat.label,
                    val = stats[stat.key],
                    hasHighlight = true,
                })
            else

                self.paperdoll.stats.enhancementsListview.DataProvider:Insert({
                    stat = stat.label,
                    val = stats[stat.key],
                    hasHighlight = false,
                })
            end

        end
    end
end



function SamsUiCharacterFrameMixin:GetCurrentIlvl()
    local ilvl = 0;
    local iCount = 0;
    for _, slot in pairs(inventorySlots) do

        local itemLink = GetInventoryItemLink("player", GetInventorySlotInfo(slot))
        if itemLink then
            local itemName, _, itemQuality, itemLevel = GetItemInfo(itemLink)
            if itemLevel then
                ilvl = ilvl + itemLevel;
                iCount = iCount + 1;
            end
        end
    end
    return ilvl / iCount;
end



function SamsUiCharacterFrameMixin:GetPaperDollStats()

    local stats = {};

    ---go through getting each stat value
    local numSkills = GetNumSkillLines();
    local skillIndex = 0;
    local currentHeader = nil;

    for i = 1, numSkills do
        local skillName = select(1, GetSkillLineInfo(i));
        local isHeader = select(2, GetSkillLineInfo(i));

        if isHeader ~= nil and isHeader then
            currentHeader = skillName;
        else
            if (currentHeader == "Weapon Skills" and skillName == 'Defense') then
                skillIndex = i;
                break;
            end
        end
    end

    local baseDef, modDef;
    if (skillIndex > 0) then
        baseDef = select(4, GetSkillLineInfo(skillIndex));
        modDef = select(6, GetSkillLineInfo(skillIndex));
    else
        baseDef, modDef = UnitDefense('player')
    end

    local posBuff = 0;
    local negBuff = 0;
    if ( modDef > 0 ) then
        posBuff = modDef;
    elseif ( modDef < 0 ) then
        negBuff = modDef;
    end
    stats.Defence = {
        Base = Util:FormatNumberForCharacterStats(baseDef),
        Mod = Util:FormatNumberForCharacterStats(modDef),
    }

    local baseArmor, effectiveArmor, armr, posBuff, negBuff = UnitArmor('player');
    stats.Armor = Util:FormatNumberForCharacterStats(baseArmor)
    stats.Block = Util:FormatNumberForCharacterStats(GetBlockChance());
    stats.Parry = Util:FormatNumberForCharacterStats(GetParryChance());
    stats.ShieldBlock = Util:FormatNumberForCharacterStats(GetShieldBlock());
    stats.Dodge = Util:FormatNumberForCharacterStats(GetDodgeChance());

    --local expertise, offhandExpertise, rangedExpertise = GetExpertise();
    stats.Expertise = Util:FormatNumberForCharacterStats(GetExpertise()); --will display mainhand expertise but it stores offhand expertise as well, need to find a way to access it
    --local base, casting = GetManaRegen();

    --to work with all versions we have to adjust the values we get
    if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
        stats.SpellHit = Util:FormatNumberForCharacterStats(GetSpellHitModifier());
        stats.MeleeHit = Util:FormatNumberForCharacterStats(GetHitModifier());
        stats.RangedHit = Util:FormatNumberForCharacterStats(GetHitModifier());
        
    elseif WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
        stats.SpellHit = Util:FormatNumberForCharacterStats(GetCombatRatingBonus(CR_HIT_SPELL)) -- + GetSpellHitModifier());
        stats.MeleeHit = Util:FormatNumberForCharacterStats(GetCombatRatingBonus(CR_HIT_MELEE)) -- + GetHitModifier());
        stats.RangedHit = Util:FormatNumberForCharacterStats(GetCombatRatingBonus(CR_HIT_RANGED));

    else
    
    end

    stats.RangedCrit = Util:FormatNumberForCharacterStats(GetRangedCritChance());
    stats.MeleeCrit = Util:FormatNumberForCharacterStats(GetCritChance());

    stats.Haste = Util:FormatNumberForCharacterStats(GetHaste());
    local base, casting = GetManaRegen()
    stats.ManaRegen = base and Util:FormatNumberForCharacterStats(base * 5) or 0;
    stats.ManaRegenCasting = casting and Util:FormatNumberForCharacterStats(casting * 5) or 0;

    local minCrit = 100
    for id, school in pairs(self.SpellSchools) do
        if GetSpellCritChance(id) < minCrit then
            minCrit = GetSpellCritChance(id)
        end
        stats['SpellDmg'..school] = Util:FormatNumberForCharacterStats(GetSpellBonusDamage(id));
        stats['SpellCrit'..school] = Util:FormatNumberForCharacterStats(GetSpellCritChance(id));
    end
    stats.SpellCrit = Util:FormatNumberForCharacterStats(minCrit)

    stats.HealingBonus = Util:FormatNumberForCharacterStats(GetSpellBonusHealing());

    local lowDmg, hiDmg, offlowDmg, offhiDmg, posBuff, negBuff, percentmod = UnitDamage("player");
    local mainSpeed, offSpeed = UnitAttackSpeed("player");
    local mlow = (lowDmg + posBuff + negBuff) * percentmod
    local mhigh = (hiDmg + posBuff + negBuff) * percentmod
    local olow = (offlowDmg + posBuff + negBuff) * percentmod
    local ohigh = (offhiDmg + posBuff + negBuff) * percentmod
    if mainSpeed < 1 then mainSpeed = 1 end
    if mlow < 1 then mlow = 1 end
    if mhigh < 1 then mhigh = 1 end
    if olow < 1 then olow = 1 end
    if ohigh < 1 then ohigh = 1 end

    if offSpeed then
        if offSpeed < 1 then 
            offSpeed = 1
        end
        stats.MeleeDmgOH = Util:FormatNumberForCharacterStats((olow + ohigh) / 2.0)
        stats.MeleeDpsOH = Util:FormatNumberForCharacterStats(((olow + ohigh) / 2.0) / offSpeed)
    else
        --offSpeed = 1
        stats.MeleeDmgOH = Util:FormatNumberForCharacterStats(0)
        stats.MeleeDpsOH = Util:FormatNumberForCharacterStats(0)
    end
    stats.MeleeDmgMH = Util:FormatNumberForCharacterStats((mlow + mhigh) / 2.0)
    stats.MeleeDpsMH = Util:FormatNumberForCharacterStats(((mlow + mhigh) / 2.0) / mainSpeed)

    local speed, lowDmg, hiDmg, posBuff, negBuff, percent = UnitRangedDamage("player");
    local low = (lowDmg + posBuff + negBuff) * percent
    local high = (hiDmg + posBuff + negBuff) * percent
    if speed < 1 then speed = 1 end
    if low < 1 then low = 1 end
    if high < 1 then high = 1 end
    local dmg = (low + high) / 2.0
    stats.RangedDmg = Util:FormatNumberForCharacterStats(dmg)
    stats.RangedDps = Util:FormatNumberForCharacterStats(dmg/speed)

    local base, posBuff, negBuff = UnitAttackPower('player')
    stats.AttackPower = Util:FormatNumberForCharacterStats(base + posBuff + negBuff)

    for k, stat in pairs(self.StatIDs) do
        local a, b, c, d = UnitStat("player", k);
        stats[stat] = Util:FormatNumberForCharacterStats(b)
    end

    return stats;
end


function SamsUiCharacterFrameMixin:OnInventoryChanged()

    for k, slot in pairs(inventorySlots) do
        self.paperdoll.playerModel:UndressSlot(k)
        local itemLink = GetInventoryItemLink("player", GetInventorySlotInfo(slot))
        if itemLink then
            self.paperdoll[slot]:SetItem(nil, itemLink)
            self.paperdoll.playerModel:TryOn(itemLink)
        else
            self.paperdoll[slot]:ClearItem()
        end
    end

    local ilvl = self:GetCurrentIlvl()
    self.paperdoll.stats.ilvlLabel:SetText(Util:FormatNumberForCharacterStats(ilvl))

    self:UpdatePaperdollStats()

end


function SamsUiCharacterFrameMixin:OnEvent(event, ...)

    if event == "PLAYER_ENTERING_WORLD" then
        self:Init()
    end


    if event == "UNIT_INVENTORY_CHANGED" then
        C_Timer.After(0.5, function()
            self:TriggerEvent("InventoryChanged")
        end)
    end
end

























--[[
    party frame
]]
SamsUiPartyFrameMixin:GenerateCallbackEvents({

})
SamsUiPartyFrameMixin.numSpellButtons = 4;
SamsUiPartyFrameMixin.numSpellButtonsPerRow = 4;
SamsUiPartyFrameMixin.verticalLayout = false;
function SamsUiPartyFrameMixin:OnLoad()

    CallbackRegistryMixin.OnLoad(self)

    Util:MakeFrameMoveable(self)

    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:SetScript("OnEvent", function(self, event, ...)

        if event == "GROUP_ROSTER_UPDATE" then

            if IsInGroup() and Database:GetConfigValue("partyFramesEnabled") then
                self:Show()

            else
                self:Hide()
            end
        end
    end)

    for k, frame in ipairs(self.unitFrames) do

        frame:SetAttribute("unit", frame.unit)
        RegisterUnitWatch(frame)

        frame.buttons = {}

    end
end


function SamsUiPartyFrameMixin:SetEnabled(isEnabled)

    if isEnabled == true then
        self:Show()

    else
        self:Hide()

    end
end


function SamsUiPartyFrameMixin:UpdateUnitFrameButtons(copyPlayer)

    if not copyPlayer then
        copyPlayer = Database:GetConfigValue("unitFramesCopyPlayer")
    end

    for k, frame in ipairs(self.unitFrames) do

        if UnitExists(frame.unit) then

            frame:HideSpellButtons()

            local unitFrameConfig = Database:GetPartyUnitFrameConfig_SpellButtons(self.nameRealm, (copyPlayer == true and "player" or frame.unit))

            for i = 1, self.numSpellButtons do
                local button = frame.buttons[i]

                if button then

                    if type(unitFrameConfig) == "table" then
                        
                        if unitFrameConfig["default"][i] then
                            button.icon:SetTexture(unitFrameConfig["default"][i].icon)
                            local macro = unitFrameConfig["default"][i].macro;
                            if copyPlayer == true then
                                macro = macro:gsub("player", frame.unit)
                            end
                            button:SetAttribute("macrotext1", macro)

                            if unitFrameConfig["default"][i].spellID then
                                button:SetScript("OnEnter", function()
                                    GameTooltip:SetOwner(button, "ANCHOR_BOTTOM")
                                    GameTooltip:SetHyperlink("spell:"..unitFrameConfig["default"][i].spellID)
                                    GameTooltip:Show()
                                end)
                            end

                        else
                            button.icon:SetAtlas("search-iconframe-large")
                            button:SetAttribute("macrotext1", "")
                            button:SetScript("OnEnter", nil)
                        end

                    end

                button:Show()
                end
            end

        else
            frame:Hide()

        end
    end
end


function SamsUiPartyFrameMixin:UnitFrameSpellButtons_OnChanged(numButtons)

    self.numSpellButtons = numButtons;

    --loop the unit frames and setup the spell buttons
    for k, frame in ipairs(self.unitFrames) do

        if UnitExists(frame.unit) then

            local spellButtonWidth = frame:GetWidth() / self.numSpellButtons;

            frame:HideSpellButtons()

            local buttonIndex = 0;
            for i = 1, self.numSpellButtons do
                buttonIndex = buttonIndex + 1;

                local button = frame.buttons[buttonIndex]
                if button then
                    button:ClearAllPoints()
                    button:SetPoint("BOTTOMLEFT", (i-1) * spellButtonWidth, 0)
                    button:SetSize(spellButtonWidth - 1, spellButtonWidth - 1)
                    button:Show()

                else
                    frame:CreateSpellButton(buttonIndex, spellButtonWidth, i, 0, nil, Database, self)
                end
            end

        else
            frame:Hide()

        end

        frame:UpdateLayout(self.verticalLayout)
    end

    self:UnitFrameSize_OnChanged()
end



function SamsUiPartyFrameMixin:UnitFrames_OnOrientationChanged(verticalLayout)

    self.verticalLayout = verticalLayout;

    for k, frame in ipairs(self.unitFrames) do
        frame:ClearAllPoints()
    end

    local unitFrameWidth, unitFrameHeight = self.unitFrames[1]:GetSize()

    if verticalLayout == true then
        
        for k, frame in ipairs(self.unitFrames) do
            frame:SetPoint("TOP", 0, (k - 1) * -unitFrameHeight)
            frame:UpdateLayout(verticalLayout)
        end

        self:SetSize(unitFrameWidth, unitFrameHeight * #self.unitFrames)
    else

        for k, frame in ipairs(self.unitFrames) do
            frame:SetPoint("LEFT", (k - 1) * unitFrameWidth, 0)
            frame:UpdateLayout(verticalLayout)
        end

        self:SetSize(unitFrameWidth * #self.unitFrames, unitFrameHeight)
    end
end


function SamsUiPartyFrameMixin:UnitFrameSize_OnChanged(width)

    if not width then
        width = self.unitFrameWidth;
    end

    --loop the unit frames and setup the spell buttons
    for k, frame in ipairs(self.unitFrames) do

        if UnitExists(frame.unit) then

            frame:SetWidth(width)
            local spellButtonWidth = frame:GetWidth() / self.numSpellButtons

            frame:HideSpellButtons()

            local buttonIndex = 0;
            for i = 1, self.numSpellButtons do
                buttonIndex = buttonIndex + 1;

                if buttonIndex > self.numSpellButtons then
                    return
                end

                local button = frame.buttons[buttonIndex]
                if button then
                    button:ClearAllPoints()
                    button:SetPoint("BOTTOMLEFT", (i-1) * spellButtonWidth, 0)
                    button:SetSize(spellButtonWidth - 1, spellButtonWidth - 1)
                    button:Show()

                else
                    frame:CreateSpellButton(buttonIndex, spellButtonWidth, i, 0, nil, Database, self)
                end
            end

        else
            frame:Hide()
        end

        frame:UpdateLayout(self.verticalLayout)
    end

    self:UnitFrames_OnOrientationChanged(self.verticalLayout)
end


function SamsUiPartyFrameMixin:OnDatabaseInitialised()

    local isEnabled = Database:GetConfigValue("partyFramesEnabled")
    self:SetEnabled(isEnabled)

    local name, realm = UnitFullName("player")
    self.nameRealm = string.format("%s-%s", name, realm)

    --loop the unit frames and setup the spell buttons
    for k, frame in ipairs(self.unitFrames) do

            if UnitExists(frame.unit) then

            local unitFrameConfig = Database:GetPartyUnitFrameConfig_SpellButtons(self.nameRealm, frame.unit)

            for i = 1, self.numSpellButtons do
                local button = frame.buttons[i]

                if button then

                    if type(unitFrameConfig) == "table" then
                        
                        if unitFrameConfig["default"][i] then
                            button.icon:SetTexture(unitFrameConfig["default"][i].icon)
                            button:SetAttribute("macrotext1", unitFrameConfig["default"][i].macro)

                            if unitFrameConfig["default"][i].spellID then
                                button:SetScript("OnEnter", function()
                                    GameTooltip:SetOwner(button, "ANCHOR_BOTTOM")
                                    GameTooltip:SetHyperlink("spell:"..unitFrameConfig["default"][i].spellID)
                                    GameTooltip:Show()
                                end)

                            else

                            end
                        end

                    end

                end

            end

        else
            frame:Hide()
        end

        frame:UpdateLayout(Database:GetConfigValue("unitFramesVerticalLayout"))
    end

    self.unitFrameWidth = Database:GetConfigValue("partyUnitFrameWidth")
    self.verticalLayout = Database:GetConfigValue("unitFramesVerticalLayout")
    self.numSpellButtons = Database:GetConfigValue("partyUnitFramesNumSpellButtons")
    self.numSpellButtonsPerRow = Database:GetConfigValue("partyUnitFramesNumSpellButtons") --this is correct

    self:UnitFrameSize_OnChanged(self.unitFrameWidth)
    self:UnitFrames_OnOrientationChanged(self.verticalLayout)
    self:UnitFrameSpellButtons_OnChanged(self.numSpellButtons)

end



function SamsUiPartyFrameMixin:OnConfigChanged(setting, newValue)

    if setting == "partyFramesEnabled" then
        self:SetEnabled(newValue)
    end

    if setting == "unitFramesCopyPlayer" then
        self:UpdateUnitFrameButtons(newValue)
    end

    if setting == "partyUnitFrameWidth" then
        self:UnitFrameSize_OnChanged(newValue)
    end

    if setting == "partyUnitFramesNumSpellButtons" then
        self:UnitFrameSpellButtons_OnChanged(newValue)
    end

    if setting == "unitFramesVerticalLayout" then
        self:UnitFrames_OnOrientationChanged(newValue)
    end
end



function SamsUiPartyFrameMixin:SetButtonAttributeForAllPartyUnitFrames(spellButtonID, cursorType, cursorTypeID)

    for k, frame in ipairs(self.unitFrames) do

        local button = frame.buttons[spellButtonID];

        if cursorType == "spell" then

            local name, rank, icon, castTime, minRange, maxRange, spellID = GetSpellInfo(cursorTypeID)
            local rankID = GetSpellSubtext(cursorTypeID)
            if name then
                button.icon:SetTexture(icon)
                button:SetAttribute("macrotext1", string.format([[/cast [@%s] %s(%s)]], frame.unit, name, rankID))

                button:SetScript("OnEnter", function()
                    GameTooltip:SetOwner(button, "ANCHOR_BOTTOM")
                    GameTooltip:SetHyperlink("spell:"..cursorTypeID)
                    GameTooltip:Show()
                end)
            end

        elseif cursorType == "macro" then

            local name, icon, body, isLocal = GetMacroInfo(cursorTypeID)
            button.icon:SetTexture(icon)
            button:SetAttribute("macrotext1", body)

            button:SetScript("OnEnter", function()
                GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
                GameTooltip:AddLine(body)
                GameTooltip:Show()
            end)

        end
    end
end

















------------------------------
-- pet food frame
------------------------------
-- local pffWidth = 225;
-- local pff = false;
-- function SHA:SetupPetFoodUI()
--     local backdrop = {
--         bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
--         edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
--         tile = true, tileSize = 32, edgeSize = 32,
--         insets = { left = 8, right = 8, top = 8, bottom = 8 }
--     }
--     pff = CreateFrame("FRAME", nil, UIParent, "BasicFrameTemplateWithInset") --, "BackdropTemplate")
--     pff:SetSize(pffWidth, 50)
--     pff:SetPoint("CENTER", 0, 0)
--     pff:SetMovable(true)
--     pff:EnableMouse(true)
--     pff:RegisterForDrag("LeftButton")
--     pff:SetScript("OnDragStart", pff.StartMoving)
--     pff:SetScript("OnDragStop", pff.StopMovingOrSizing)

--     pff.title = pff:CreateFontString(nil, "OVERLAY", "GameFontNormal")
--     pff.title:SetPoint("TOP", 0, -6)
--     pff.title:SetText("Food & Drink")

--     pff.buttons = {}
-- end

-- local function updatePetFood(foods)
--     if not pff then
--         return
--     end
--     if pff.buttons and #pff.buttons > 0 then
--         for k, v in ipairs(pff.buttons) do
--             v:Hide()
--             v.food = nil;
--             v.icon:SetTexture(nil)
--             v.link:SetText("")
--             v.count:SetText("")
--         end
--     end
--     local point, relativeTo, relativePoint, xOfs, yOfs = pff:GetPoint()
--     if foods and #foods > 0 then
--         for k, food in ipairs(foods) do
--             if not pff.buttons[k] then
--                 local f = CreateFrame("BUTTON", nil, pff, "SecureActionButtonTemplate")
--                 f:SetPoint("TOPLEFT", 5, (k * -22) - 6)
--                 f:SetPoint("TOPRIGHT", -5, (k * -22) - 6)
--                 f:SetHeight(22)
--                 f:RegisterForClicks("AnyUp")

--                 f:SetAttribute("type1", "macro")
--                 f:SetAttribute("type2", "macro")
--                 f.food = food

--                 f.highlight = f:CreateTexture(nil, "HIGHLIGHT")
--                 f.highlight:SetAtlas("search-highlight-large")
--                 f.highlight:SetAllPoints()

--                 f.icon = f:CreateTexture(nil, "ARTWORK")
--                 f.icon:SetSize(18,18)
--                 f.icon:SetPoint("LEFT", 4, 0)
--                 f.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

--                 f.link = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
--                 f.link:SetPoint("LEFT", 26, 0)

--                 f.count = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
--                 f.count:SetPoint("RIGHT", -6, 0)
--                 f.count:SetTextColor(1,1,1,1)

--                 f:SetScript("OnEnter", function(self)
--                     if self.food.link then
--                         GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
--                         GameTooltip:SetHyperlink(self.food.link)
--                         GameTooltip:Show() 
--                     end
--                 end)
--                 f:SetScript("OnLeave", function(self)
--                     GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
--                 end)

--                 pff.buttons[k] = f
--             end

--             pff.buttons[k].food = food;
--             pff.buttons[k].icon:SetTexture(food.icon)
--             pff.buttons[k].link:SetText(food.link)
--             pff.buttons[k].count:SetText(food.count)

--             local feedPlayerMacro = "/use "..food.name
--             pff.buttons[k]:SetAttribute("macrotext1", feedPlayerMacro)

--             local feedPetMacro = tostring([[
-- /cast Feed pet
-- /use ]]..food.name )
--             pff.buttons[k]:SetAttribute("macrotext2", feedPetMacro)
--             pff.buttons[k]:Show()
--         end

--         pff:SetSize(pffWidth, (#foods * 22) + 34)
--         pff:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs)
--     end
-- end