

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
    config panel mixin

    this is the ui for adjusting settings
]]
SamsUiConfigPanelMixin = {};

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
        {
            panelName = "Addons",
            func = function()
                self:ShowPanel("addons")
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
            CastingBarFrame:SetPoint("TOP", UIParent, "BOTTOM", 0, 390)
        end)

        PlayerFrame:ClearAllPoints()
        PlayerFrame:SetPoint('TOP', UIParent, 'BOTTOM', -240, 400)
        PlayerFrame:SetUserPlaced(true);
        PlayerFrame_SetLocked(true)

        TargetFrame:ClearAllPoints()
        TargetFrame:SetPoint('TOP', UIParent, 'BOTTOM', 240, 400)
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
    self:LoadAddonPanel()

end


function SamsUiConfigPanelMixin:LoadAddonPanel()

    -- self.contentFrame.addons:SetScript("OnShow", function()
    --     UpdateAddOnMemoryUsage()
    --     local totalMemoryKB = 0;
    
    --     self.addons = {}
    --     for i = 1, GetNumAddOns() do
    
    --         totalMemoryKB = totalMemoryKB + GetAddOnMemoryUsage(i)
    
    --         local fs = self:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    --         fs:SetPoint("TOPLEFT", 12, (i-1) * -24)
    
    --         self.addons[i] = {
    --             name = GetAddOnInfo(i),
    --             memory = GetAddOnMemoryUsage(i),
    --             displayInfo = fs,
    --         }
    
    --     end
    
    --     for k, addon in ipairs(self.addons) do
    --         addon.displayInfo:SetText(string.format("%s %.2f" , addon.name, addon.memory))
    --     end    
    -- end)


end


function SamsUiConfigPanelMixin:LoadGeneralPanel()

    local panel = self.contentFrame.generalConfig;

    if addon.db:GetConfigValue("welcomeGuildMembersOnLogin") then
        panel.welcomeGuildMembersOnLoginCheckButton:SetChecked("welcomeGuildMembersOnLogin")
    end

    if addon.db:GetConfigValue("welcomeGuildMembersOnLoginMessageArray") then
        panel.welcomeGuildMembersOnLoginMessageArrayEditBox:SetText(addon.db:GetConfigValue("welcomeGuildMembersOnLoginMessageArray"))
    end

    panel.welcomeGuildMembersOnLoginMessageArrayEditBox:SetScript("OnTextChanged", function()
        addon.db:UpdateConfig("welcomeGuildMembersOnLoginMessageArray", panel.welcomeGuildMembersOnLoginMessageArrayEditBox:GetText())
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

    for name, character in addon.db:GetCharacters() do
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
                        addon.db:DeleteSessionFromCharacter(name, k)
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

    _G[panel.numberIconsPerRow:GetName().."Text"]:SetText(addon.db:GetConfigValue("numberMinimapIconsPerRow") or 6)
    panel.numberIconsPerRow:SetValue(addon.db:GetConfigValue("numberMinimapIconsPerRow") or 6)


    panel.numberIconsPerRow:SetScript("OnValueChanged", function()
        _G[panel.numberIconsPerRow:GetName().."Text"]:SetText(string.format("%.0f", panel.numberIconsPerRow:GetValue()))
        addon.db:UpdateConfig("numberMinimapIconsPerRow", tonumber(string.format("%.0f", panel.numberIconsPerRow:GetValue())))
    end)

end


function SamsUiConfigPanelMixin:LoadPlayerBarPanel()

    local panel = self.contentFrame.playerBarConfig;

    panel.playerBarSetEnabled:SetScript("OnClick", function()
        addon.db:UpdateConfig("playerBarEnabled", panel.playerBarSetEnabled:GetChecked())
    end)

    panel.playerHealthTextCheckButton:SetScript("OnClick", function()
        addon.db:UpdateConfig("showPlayerHealthText", panel.playerHealthTextCheckButton:GetChecked())
    end)

    panel.playerHealthTextFormatEditBox:SetScript("OnTextChanged", function()
        addon.db:UpdateConfig("playerHealthTextFormat", panel.playerHealthTextFormatEditBox:GetText())
    end)

    panel.playerPowerTextCheckButton:SetScript("OnClick", function()
        addon.db:UpdateConfig("showPlayerPowerText", panel.playerPowerTextCheckButton:GetChecked())
    end)

    panel.playerPowerTextFormatEditBox:SetScript("OnTextChanged", function()
        addon.db:UpdateConfig("playerPowerTextFormat", panel.playerPowerTextFormatEditBox:GetText())
    end)


    --player frame
    local isEnabled = addon.db:GetConfigValue("playerBarEnabled")
    if isEnabled ~= nil then
        panel.playerBarSetEnabled:SetChecked(isEnabled)
    end

    if addon.db:GetConfigValue("showPlayerHealthText") then
        panel.playerHealthTextCheckButton:SetChecked(addon.db:GetConfigValue("showPlayerHealthText"))
    end

    if addon.db:GetConfigValue("playerHealthTextFormat") then
        panel.playerHealthTextFormatEditBox:SetText(addon.db:GetConfigValue("playerHealthTextFormat"))
    end

    if addon.db:GetConfigValue("showPlayerPowerText") then
        panel.playerPowerTextCheckButton:SetChecked(addon.db:GetConfigValue("showPlayerPowerText"))
    end

    if addon.db:GetConfigValue("playerPowerTextFormat") then
        panel.playerPowerTextFormatEditBox:SetText(addon.db:GetConfigValue("playerPowerTextFormat"))
    end

end

function SamsUiConfigPanelMixin:LoadTargetBarPanel()

    local panel = self.contentFrame.targetBarConfig;

    panel.targetBarSetEnabled:SetScript("OnClick", function()
        addon.db:UpdateConfig("targetBarEnabled", panel.targetBarSetEnabled:GetChecked())
    end)

    --set the widget scripts
    panel.targetHealthTextCheckButton:SetScript("OnClick", function()
        addon.db:UpdateConfig("showTargetHealthText", panel.targetHealthTextCheckButton:GetChecked())
    end)

    panel.targetHealthTextFormatEditBox:SetScript("OnTextChanged", function()
        addon.db:UpdateConfig("targetHealthTextFormat", panel.targetHealthTextFormatEditBox:GetText())
    end)

    panel.targetPowerTextCheckButton:SetScript("OnClick", function()
        addon.db:UpdateConfig("showTargetPowerText", panel.targetPowerTextCheckButton:GetChecked())
    end)

    panel.targetPowerTextFormatEditBox:SetScript("OnTextChanged", function()
        addon.db:UpdateConfig("targetPowerTextFormat", panel.targetPowerTextFormatEditBox:GetText())
    end)


    --target frame
    local isEnabled = addon.db:GetConfigValue("targetBarEnabled")
    if isEnabled ~= nil then
        panel.targetBarSetEnabled:SetChecked(isEnabled)
    end

    if addon.db:GetConfigValue("showTargetHealthText") then
        panel.targetHealthTextCheckButton:SetChecked(addon.db:GetConfigValue("showTargetHealthText"))
    end

    if addon.db:GetConfigValue("targetHealthTextFormat") then
        panel.targetHealthTextFormatEditBox:SetText(addon.db:GetConfigValue("targetHealthTextFormat"))
    end

    if addon.db:GetConfigValue("showTargetPowerText") then
        panel.targetPowerTextCheckButton:SetChecked(addon.db:GetConfigValue("showTargetPowerText"))
    end

    if addon.db:GetConfigValue("targetPowerTextFormat") then
        panel.targetPowerTextFormatEditBox:SetText(addon.db:GetConfigValue("targetPowerTextFormat"))
    end

end



function SamsUiConfigPanelMixin:LoadPartyConfigPanel()

    local panel = self.contentFrame.partyConfig;

    panel.enablePartyFrames:SetScript("OnClick", function()
        addon.db:UpdateConfig("partyFramesEnabled", panel.enablePartyFrames:GetChecked())
    end)
    local isEnabled = addon.db:GetConfigValue("partyFramesEnabled")
    if isEnabled ~= nil then
        panel.enablePartyFrames:SetChecked(isEnabled)
    end

    panel.unitFramesCopyPlayer:SetScript("OnClick", function()
        addon.db:UpdateConfig("unitFramesCopyPlayer", panel.unitFramesCopyPlayer:GetChecked())
    end)
    local unitframesCopyplayer = addon.db:GetConfigValue("unitFramesCopyPlayer")
    if unitframesCopyplayer ~= nil then
        panel.unitFramesCopyPlayer:SetChecked(unitframesCopyplayer)
    end

    panel.unitFramesVerticalLayout:SetScript("OnClick", function()
        addon.db:UpdateConfig("unitFramesVerticalLayout", panel.unitFramesVerticalLayout:GetChecked())
    end)

    _G[panel.partyUnitFrameWidth:GetName().."Low"]:SetText("20")
    _G[panel.partyUnitFrameWidth:GetName().."High"]:SetText("300")

    _G[panel.partyUnitFrameWidth:GetName().."Text"]:SetText(addon.db:GetConfigValue("partyUnitFrameWidth") or 100)
    panel.partyUnitFrameWidth:SetValue(addon.db:GetConfigValue("partyUnitFrameWidth") or 100)

    panel.partyUnitFrameWidth:SetScript("OnMouseWheel", function(self, delta)
        self:SetValue(self:GetValue() + (delta * 2))
    end)
    panel.partyUnitFrameWidth:SetScript("OnValueChanged", function()
        _G[panel.partyUnitFrameWidth:GetName().."Text"]:SetText(string.format("%.0f", panel.partyUnitFrameWidth:GetValue()))
        addon.db:UpdateConfig("partyUnitFrameWidth", tonumber(string.format("%.0f", panel.partyUnitFrameWidth:GetValue())))
    end)


    _G[panel.partyUnitFramesNumSpellButtons:GetName().."Low"]:SetText("1")
    _G[panel.partyUnitFramesNumSpellButtons:GetName().."High"]:SetText("12")

    _G[panel.partyUnitFramesNumSpellButtons:GetName().."Text"]:SetText(addon.db:GetConfigValue("partyUnitFramesNumSpellButtons") or 4)
    panel.partyUnitFramesNumSpellButtons:SetValue(addon.db:GetConfigValue("partyUnitFramesNumSpellButtons") or 4)

    panel.partyUnitFramesNumSpellButtons:SetScript("OnMouseWheel", function(self, delta)
        self:SetValue(self:GetValue() + delta)
    end)
    panel.partyUnitFramesNumSpellButtons:SetScript("OnValueChanged", function()
        _G[panel.partyUnitFramesNumSpellButtons:GetName().."Text"]:SetText(string.format("%.0f", panel.partyUnitFramesNumSpellButtons:GetValue()))
        addon.db:UpdateConfig("partyUnitFramesNumSpellButtons", tonumber(string.format("%.0f", panel.partyUnitFramesNumSpellButtons:GetValue())))
    end)


    -- _G[panel.partyUnitFramesNumSpellButtonsPerRow:GetName().."Low"]:SetText("1")
    -- _G[panel.partyUnitFramesNumSpellButtonsPerRow:GetName().."High"]:SetText("12")

    -- _G[panel.partyUnitFramesNumSpellButtonsPerRow:GetName().."Text"]:SetText(addon.db:GetConfigValue("partyUnitFramesNumSpellButtonsPerRow") or 4)
    -- panel.partyUnitFramesNumSpellButtonsPerRow:SetValue(addon.db:GetConfigValue("partyUnitFramesNumSpellButtonsPerRow") or 4)

    -- panel.partyUnitFramesNumSpellButtonsPerRow:SetScript("OnMouseWheel", function(self, delta)
    --     self:SetValue(self:GetValue() + (delta * 2))
    -- end)
    -- panel.partyUnitFramesNumSpellButtonsPerRow:SetScript("OnValueChanged", function()
    --     _G[panel.partyUnitFramesNumSpellButtonsPerRow:GetName().."Text"]:SetText(string.format("%.0f", panel.partyUnitFramesNumSpellButtonsPerRow:GetValue()))
    --     addon.db:UpdateConfig("partyUnitFramesNumSpellButtonsPerRow", tonumber(string.format("%.0f", panel.partyUnitFramesNumSpellButtonsPerRow:GetValue())))
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

        if addon.db:GetConfigValue("welcomeGuildMembersOnLogin") == true then
            
            if type(addon.db:GetConfigValue("welcomeGuildMembersOnLoginMessageArray")) == "string" then
                local array = addon.db:GetConfigValue("welcomeGuildMembersOnLoginMessageArray")
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

    if event == "ADDON_LOADED" then
        
        self:UnregisterEvent("ADDON_LOADED");

        Mixin(addon, CallbackRegistryMixin)
        addon:GenerateCallbackEvents({
            "Database_OnInitialised",
        });
        CallbackRegistryMixin.OnLoad(addon);

        addon:RegisterCallback("Database_OnInitialised", self.OnDatabaseInitialized, self);

        addon.db:Init();

    end

    if event == "PLAYER_ENTERING_WORLD" then

        local name, realm = UnitFullName("player");
        if realm == nil or realm == "" then
            realm = GetNormalizedRealmName();
        end
        local nameRealm = string.format("%s-%s", name, realm);

        self:UnregisterEvent("PLAYER_ENTERING_WORLD");

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