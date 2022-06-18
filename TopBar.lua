

local name, sui = ...;

local Util = sui.Util;
local L = sui.locales;

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



SamsUiTopBarMixin = {};

---show the avatar chat bubble
---@param msg string the message to display
function SamsUiTopBarMixin:ShowAvatarChat(msg)

    self.avatarChat:SetAlpha(1)
    self.avatarChat:ClearAllPoints()
    self.avatarChat:SetPoint("LEFT", 70, -60)
    self.avatarChat.String:SetText(msg)
    local strWidth = self.avatarChat.String:GetStringWidth()
    local strHeight = self.avatarChat.String:GetStringHeight()
    self.avatarChat:SetSize(strWidth + 32, strHeight + 32)
    --self.avatarChat:Show()

    C_Timer.After(3, function()
        self.avatarChat.anim:Play()
    end)

end

function SamsUiTopBarMixin:Init()

    sui:RegisterCallback("Database_OnCharacterRegistered", self.OnCharacterRegistered, self);
    sui:RegisterCallback("Database_OnDatabaseInitialized", self.OnDatabaseInitialized, self);

    self.systemTray.reloadUI:SetScript("OnEnter", function()
        GameTooltip:SetOwner(self.systemTray.reloadUI, "ANCHOR_BOTTOMLEFT")
        GameTooltip:AddLine(L["RELOAD_UI"])
        GameTooltip:Show()
    end)

    self.systemTray.sessionInfo.UpdateTooltip = function()
        GameTooltip:SetOwner(self.systemTray.sessionInfo, 'ANCHOR_BOTTOMLEFT')
        GameTooltip:AddLine("Session info")
        GameTooltip:AddLine(" ")

        if sui.sessionInfo and sui.sessionInfo.initialLoginTime then
            GameTooltip:AddDoubleLine("Play time", date("%H:%M:%S", time() - sui.sessionInfo.initialLoginTime))
            GameTooltip:AddLine(" ")
        end

        GameTooltip:AddDoubleLine("|cff76D65BCredits|r", string.format("|cffffffff%s", GetCoinTextureString(sui.sessionInfo.credits)))
        GameTooltip:AddDoubleLine("|cffF6685EDebits|r", string.format("|cffffffff%s", GetCoinTextureString(sui.sessionInfo.debits)))

        local profit = GetMoney() - (sui.db:GetCharacterInfo(sui.characterKey, "initialLoginGold") or 0)
        if profit > 0 then
            profit = string.format("|cff76D65B%s", GetCoinTextureString(profit));
        elseif profit == 0 then
            profit = string.format("|cffFffffff%s", GetCoinTextureString(profit));
        else
            profit = string.format("|cffF6685E-%s", GetCoinTextureString(profit*-1));
        end
        GameTooltip:AddDoubleLine("|cffffffffBalance|r", profit)
        GameTooltip:AddLine(" ")

        local questsTurnedIn = 0;
        local questXp = 0;
        if sui.sessionInfo.questsCompleted then
            questsTurnedIn = #sui.sessionInfo.questsCompleted or 0;
            questXp = 0;
            for k, quest in ipairs(sui.sessionInfo.questsCompleted) do
                questXp = questXp + (quest.xpReward or 0);
            end
        end

        GameTooltip:AddDoubleLine("|cff5979B9Quests turned in:", questsTurnedIn)
        GameTooltip:AddDoubleLine("|cff5979B9Quest XP:", questXp)
        GameTooltip:AddLine(" ")

        GameTooltip:AddDoubleLine("|cffffffffMobs killed:", sui.sessionInfo.mobsKilled)
        GameTooltip:AddDoubleLine("|cffffffffMob XP:", sui.sessionInfo.mobXpReward)
        GameTooltip:AddLine(" ")

        if sui.sessionInfo.reputations and next(sui.sessionInfo.reputations) then
            GameTooltip:AddLine("Reputation gains:")
            for faction, gain in pairs(sui.sessionInfo.reputations) do
                GameTooltip:AddDoubleLine(string.format("|cffffffff%s|r", faction), gain)
            end
        end
        GameTooltip:Show()
    end
    self.systemTray.sessionInfo:SetScript("OnEnter", function()
        if not sui.sessionInfo then
            return;
        end
        self.systemTray.sessionInfo.UpdateTooltip()
    end)

    self.systemTray.xp:SetScript("OnEnter", function()
        GameTooltip:SetOwner(self.systemTray.xp, "ANCHOR_BOTTOMLEFT")
        local xp = UnitXP("player")
        local xpMax = UnitXPMax("player")
        local restedXp = GetXPExhaustion() or 0;
        local requiredXp = xpMax - xp;

        local requiredPer = tonumber(string.format("%.1f", (requiredXp/xpMax)*100))
        local restedPer = tonumber(string.format("%.1f", (restedXp/xpMax)*100))

        if xp == 0 then
            GameTooltip:AddDoubleLine("XP", "-")
        else
            GameTooltip:AddDoubleLine("XP", string.format("%.1f", (xpMax/xp) * 100))
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("|cffffffffThis level", xp.." / "..xpMax)
        GameTooltip:AddDoubleLine("|cffffffffRequired", string.format("%s [%s%%]", xpMax - xp, requiredPer))
        GameTooltip:AddDoubleLine("|cffffffffRested", string.format("%s [%s%%]", restedXp, restedPer))
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cff8F2E71Rested XP will be consumed \nat double rate per kill, \nif you have 1000 rested XP you'll \nget double for the first 500 XP earned")

        GameTooltip:Show()
    end)

    self.systemTray.macroUI:SetScript("OnEnter", function()
        GameTooltip:SetOwner(self.systemTray.reloadUI, "ANCHOR_BOTTOMLEFT")
        GameTooltip:AddLine(L["MACRO_UI"])
        GameTooltip:Show()
    end)

    self.systemTray.volume:SetScript("OnEnter", function()
        GameTooltip:SetOwner(self.systemTray.reloadUI, "ANCHOR_BOTTOMLEFT")
        GameTooltip:AddLine(L["VOLUME_CONTROL"])
        GameTooltip:Show()
    end)

    self.systemTray.volume:SetScript("OnClick", function()
        self.systemTray.volumeControls:SetShown(not self.systemTray.volumeControls:IsVisible())
    end)

    for k, text in ipairs({"Text", "Low", "High"}) do
        _G[self.systemTray.volumeControls.master:GetName()..text]:SetText()
        _G[self.systemTray.volumeControls.sound:GetName()..text]:SetText()
        _G[self.systemTray.volumeControls.music:GetName()..text]:SetText()
        _G[self.systemTray.volumeControls.ambience:GetName()..text]:SetText()
        _G[self.systemTray.volumeControls.dialog:GetName()..text]:SetText()
    end

    local volumeSliders = {
        ["master"] = AudioOptionsSoundPanelMasterVolume,
        ["sound"] = AudioOptionsSoundPanelSoundVolume,
        ["music"] = AudioOptionsSoundPanelMusicVolume,
        ["ambience"] = AudioOptionsSoundPanelAmbienceVolume,
        ["dialog"] = AudioOptionsSoundPanelDialogVolume,
    }

    for k, slider in pairs(volumeSliders) do
        local currentValue = slider:GetValue()
        self.systemTray.volumeControls[k]:SetValue(currentValue)
        self.systemTray.volumeControls[k]:SetScript("OnShow", function()
            self.systemTray.volumeControls[k]:SetValue((slider:GetValue() - 1) * -1)
        end)
        self.systemTray.volumeControls[k]:SetScript("OnValueChanged", function()
            local thisVal = self.systemTray.volumeControls[k]:GetValue()
            slider:SetValue(1 - thisVal)
        end)
        self.systemTray.volumeControls[k]:SetScript("OnMouseWheel", function(_, delta)
            local thisVal = self.systemTray.volumeControls[k]:GetValue()
            self.systemTray.volumeControls[k]:SetValue(thisVal - (delta / 50))
        end)
    end


end


function SamsUiTopBarMixin:OnDatabaseInitialized()

    --self.startButton.anim:Play()
    self.startButton:SetScript("OnMouseDown", function() 
        GameMenuFrame:SetShown(not GameMenuFrame:IsVisible())
    end)

    local systemTrayConfig = sui.db:GetConfigValue("systemTray")

    --DevTools_Dump({systemTrayConfig})

    self.systemTrayContextMenu = {}
    local numSystemTrayButtons = 0;
    
    for k, button in ipairs(self.systemTray.buttons) do

        button:ClearAllPoints()
        button:Hide()

        local isVisible;
        if systemTrayConfig and (systemTrayConfig[k] ~= nil) then
            isVisible = systemTrayConfig[k];
        else
            isVisible = true;
        end
        button.isVisible = isVisible;

        if button.isVisible == true then

            button:SetPoint("LEFT", (numSystemTrayButtons * 22) + (2 * numSystemTrayButtons) + 2, 0)
            button:Show()

            numSystemTrayButtons = numSystemTrayButtons + 1;

        end

        table.insert(self.systemTrayContextMenu, {
            text = button.menuName,
            checked = button.isVisible,
            isNotRadio = true,
            func = function()
                button.isVisible = not button.isVisible;
                self:UpdateSystemTrayButtons()
            end
        })
    end
    self.systemTray:SetWidth(4 + (numSystemTrayButtons * 22) + (numSystemTrayButtons * 2) + 70)
    self.systemTray:SetScript("OnMouseDown", function(_, button)
        if button == "RightButton" then
            EasyMenu(self.systemTrayContextMenu, self.dropdown, "cursor", -10, -10, "MENU", 2.0)
        end
    end)
end


function SamsUiTopBarMixin:OnCharacterRegistered(character)

    local now = date("*t")
    local welcomeMessage = "Hello";
    if now.hour >= 12 then
        welcomeMessage = "Good afternoon";
    else
        welcomeMessage = "Good morning";
    end
    C_Timer.After(3, function()
        self:ShowAvatarChat(welcomeMessage);
    end)


    self.systemTray.gold:SetScript("OnEnter", function()
        GameTooltip:SetOwner(self.systemTray.gold, 'ANCHOR_BOTTOMLEFT')
        GameTooltip:AddLine("Gold")
        GameTooltip:AddLine(" ")

        local totalGold = 0;

        local characters = {}
        for name, character in sui.db:GetCharacters() do
            table.insert(characters, {
                name = name,
                class = character.class,
                gold = character.currentGold,
            })
        end
        if #characters > 1 then
            table.sort(characters, function(a,b)
                if a.gold and b.gold then
                    return a.gold > b.gold;
                end
            end)
        end
        for k, character in ipairs(characters) do
            local r, g, b, argbHex = GetClassColor(character.class)
            GameTooltip:AddDoubleLine(character.name, GetCoinTextureString(character.gold), r, g, b, 1, 1, 1)

            totalGold = totalGold + character.gold;
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Total", GetCoinTextureString(totalGold), 1, 1, 1, 1, 1, 1)

        GameTooltip:Show()
    end)

    self.systemTray.durability:SetScript("OnEnter", function()
        sui:ScanCharacterDurability()

        GameTooltip:SetOwner(self.systemTray.durability, "ANCHOR_BOTTOMLEFT")
        GameTooltip:AddLine("Durability")
        GameTooltip:AddLine(" ")

        for k, item in ipairs(sui.durabilityInfo) do
            
            local percent = math.floor((item.currentDurability/item.maximumDurability)*100)

            local r = (percent > 50 and 1 - 2 * (percent - 50) / 100.0 or 1.0);
            local g = (percent > 50 and 1.0 or 2 * percent / 100.0);
            local b = 0.0;

            if item.itemLink ~= "-" then
                --GameTooltip:AddDoubleLine(item.itemLink, string.format("|cffffffff[%s|cffffffff]", CreateColor(r, g, b):WrapTextInColorCode(item.currentDurability.."/"..item.maximumDurability.." - "..percent)))
                GameTooltip:AddDoubleLine(item.atlas.." "..item.itemLink, string.format("|cffffffff[%s|cffffffff]", CreateColor(r, g, b):WrapTextInColorCode(percent.."%")))
            end

        end

        GameTooltip:Show()
    end)

    if character.class then
        local r, g, b, argbHex = GetClassColor(character.class)

        self.systemTray.hearthstone:SetAttribute("macrotext1", "/cast [nomod] Hearthstone")
        if character.class == "SHAMAN" then
            self.systemTray.hearthstone:SetAttribute("macrotext2", "/cast Astral Recall")
        end
        if character.skills and character.skills.Professions then
            if (character.skills.Professions[1] and character.skills.Professions[1].name == "Inscription") or (character.skills.Professions[2] and character.skills.Professions[2].name == "Inscription") then
                self.systemTray.hearthstone:SetAttribute("macrotext1", "/cast [mod:shift] Scroll of Recall")
            end
        end

        self.systemTray.hearthstone.UpdateTooltip = function()
            GameTooltip:SetOwner(self.systemTray.hearthstone, "ANCHOR_BOTTOMLEFT")

            --basic hearthstone
            GameTooltip:AddLine(GetBindLocation())
            local start, duration, enabled, modRate = GetSpellCooldown(8690)
            local hearthstoneCooldown = (start + duration) - GetTime()
            GameTooltip:AddDoubleLine(string.format("Left click |cffffffff%s|r", GetSpellInfo(8690)), SecondsToTime(hearthstoneCooldown))

            --include shaman astra recall spell
            if character.class == "SHAMAN" then
                local start, duration, enabled, modRate = GetSpellCooldown(556)
                local astralRecallCooldown = (start + duration) - GetTime()
                GameTooltip:AddDoubleLine(string.format("Right click |cffffffff%s|r", GetSpellInfo(556)), SecondsToTime(astralRecallCooldown))
            end

            --check for inscription scrolls
            if character.skills and character.skills.Professions then
                
                if (character.skills.Professions[1] and character.skills.Professions[1].name == "Inscription") or (character.skills.Professions[2] and character.skills.Professions[2].name == "Inscription") then
                
                    local scrollCooldown;
                    local start, duration, enable = GetItemCooldown(37118)
                    if start then
                        scrollCooldown = (start + duration) - GetTime()
                    else
                        start, duration, enable = GetItemCooldown(44314)
                        if start then
                            scrollCooldown = (start + duration) - GetTime()
                        else
                            start, duration, enable = GetItemCooldown(44315)
                            if start then
                                scrollCooldown = (start + duration) - GetTime()
                            end
                        end
                    end
                    if scrollCooldown then
                        GameTooltip:AddDoubleLine(string.format("Shift left click |cffffffff%s|r", "Scroll of Recall", SecondsToTime(scrollCooldown)));
                    end

                end
            end

            GameTooltip:Show()
        end

        --set the heartstone button after we know the character has been registered
        self.systemTray.hearthstone:SetScript("OnEnter", function()
            self.systemTray.hearthstone.UpdateTooltip()
        end)
    end

end


function SamsUiTopBarMixin:OnUpdate()

    self.systemTray.clock:SetText(date("%H:%M:%S"))

    local posY, posX, posZ, instanceID = UnitPosition("player")

    --self.zoneText:SetText(GetZoneText())
    --self.minimapZoneText:SetText(string.format("%s [%s : %s]", GetMinimapZoneText(), posY, posX))
    --self.minimapZoneText:SetText(GetMinimapZoneText())

end


function SamsUiTopBarMixin:UpdateSystemTrayButtons()

    self.systemTrayContextMenu = {};
    local systemTrayConfig = {};

    local numSystemTrayButtons = 0;
    for k, button in ipairs(self.systemTray.buttons) do
        if button.isVisible == true then

            button:ClearAllPoints()
            button:SetPoint("LEFT", (numSystemTrayButtons * 22) + (2 * numSystemTrayButtons) + 2, 0)
            button:Show()
            
            numSystemTrayButtons = numSystemTrayButtons + 1;

        else
            button:Hide()
        end

        table.insert(self.systemTrayContextMenu, {
            text = button.menuName,
            checked = button.isVisible,
            isNotRadio = true,
            func = function()
                button.isVisible = not button.isVisible;
                self:UpdateSystemTrayButtons()
            end
        })

        systemTrayConfig[k] = button.isVisible;
    end
    self.systemTray:SetWidth(4 + (numSystemTrayButtons * 22) + (numSystemTrayButtons * 2) + 70)

    sui.db:SetConfigValue("systemTray", systemTrayConfig)
end






-- function SamsUiTopBarMixin:OnLoad()

--     if 1 == 1 then
--         return;
--     end
    

--     --to add or remove menu buttons comment or uncomment this list
--     self.mainMenuContainer.keys = {
--         "Options",
--         "Reload UI",
--         --"Hearthstone",
--         "Log out",
--         "Exit",
--     }

--     self.mainMenuContainer.menu = {
--         ["Options"] = {
--             atlas = "services-icon-processing",
--             func = function()
--                 SamsUiConfigPanel:Show()
--             end,
--         },
--         ["Reload UI"] = {
--             atlas = "characterundelete-RestoreButton",
--             func = function()
--                 ReloadUI()
--             end,
--         },
--         ["Hearthstone"] = {
--             atlas = "innkeeper",
--             macro = "/cast Hearthstone",
--         },
--         ["Log out"] = {
--             atlas = "mageportalalliance",
--             macro = "/logout",
--         },
--         ["Exit"] = {
--             atlas = "poi-door-left",
--             macro = "/quit",
--         },
--     }

--     self.minimapZoneText:SetText(GetMinimapZoneText())

--     self.suisInstalled = {}
--     for i = 1, GetNumAddOns() do
--         local name, title, notes, loadable, reason, security, newVersion = GetAddOnInfo(i)
--         table.insert(self.suisInstalled, {
--             name = name,
--             title = title,
--             notes = notes,
--             loaded = false,
--         })
--     end

--     self.mainMenuContainer.buttons = {}

--     self.openMainMenuButton.icon:SetTexture(136243)
--     self.openMainMenuButton:SetScript("OnClick", function()

--         if self.openMainMenuButton.tooltipText then
--             GameTooltip:SetOwner(self.openMainMenuButton, "LEFT")
--             GameTooltip:AddLine(self.openMainMenuButton.tooltipText)
--             GameTooltip:Show()
--         end

--         self:CloseDropdownMenus()
--         self:OpenMainMenu()
--     end)

--     self.openMinimapButtonsButton.icon:SetTexture(134391)
--     self.openMinimapButtonsButton:SetScript("OnClick", function()

--         if self.openMinimapButtonsButton.tooltipText then
--             GameTooltip:SetOwner(self.openMinimapButtonsButton, "LEFT")
--             GameTooltip:AddLine(self.openMinimapButtonsButton.tooltipText)
--             GameTooltip:Show()
--         end

--         if self.minimapButtonsContainer:IsVisible() then
--             return;
--         end

--         self:CloseDropdownMenus()
--         self:OpenMinimapButtonsMenu()
--     end)

--     self.minimapButtonsContainer:SetScript("OnHide", function()
--         self.minimapButtonsContainer:SetAlpha(0)
--         self.minimapButtonsContainer:SetPoint("TOP", self.openMinimapButtonsButton, "BOTTOM", 0, 35)
--     end)

--     self.minimapButtonsContainer.anim.translate:SetScript("OnFinished", function()
--         self.minimapButtonsContainer:SetPoint("TOP", self.openMinimapButtonsButton, "BOTTOM", 0, -15)
--     end)


--     self:UpdateCurrency()
--     self.openCurrencyButton:SetScript("OnEnter", function()        
--         GameTooltip:SetOwner(self.openCurrencyButton, 'ANCHOR_BOTTOM')
--         GameTooltip:AddLine("Gold")
--         GameTooltip:AddLine(" ")

--         local profit = GetMoney() - (sui.db:GetCharacterInfo(self.nameRealm, "initialLoginGold") or 0)
--         if profit > 0 then
--             GameTooltip:AddLine(string.format("|cff00cc00Profit|r %s", GetCoinTextureString(profit), 1,1,1))
--         elseif profit == 0 then
--             GameTooltip:AddLine(string.format("|cffB6CAB8Profit|r %s", GetCoinTextureString(profit), 1,1,1))
--         else
--             GameTooltip:AddLine(string.format("|cffcc0000Deficit|r %s", GetCoinTextureString(profit*-1), 1,1,1))
--         end
--         GameTooltip:AddLine(" ")
--         local totalGold = 0;

--         local characters = {}
--         for name, character in sui.db:GetCharacters() do
--             table.insert(characters, {
--                 name = name,
--                 class = character.class,
--                 gold = character.gold,
--             })
--         end
--         table.sort(characters, function(a,b)
--             return a.gold > b.gold;
--         end)
--         for k, character in ipairs(characters) do
--             local r, g, b, argbHex = GetClassColor(character.class)
--             GameTooltip:AddDoubleLine(character.name, GetCoinTextureString(character.gold), r, g, b, 1, 1, 1)

--             totalGold = totalGold + character.gold
--         end

--         GameTooltip:AddLine(" ")
--         GameTooltip:AddDoubleLine("Total", GetCoinTextureString(totalGold), 1, 1, 1, 1, 1, 1)

--         GameTooltip:Show()
--     end)


--     self.openDurabilityButton:SetScript("OnClick", function()
--         CharacterFrame:Show()
--         CharacterFrameTab1:Click()
--     end)

--     self.openDurabilityButton:SetScript("OnEnter", function()        
--         GameTooltip:SetOwner(self.openDurabilityButton, 'ANCHOR_BOTTOM')

--         self:UpdateDurability()

--         GameTooltip:AddLine("Durability")
--         GameTooltip:AddLine(" ")

--         for k, item in ipairs(self.durabilityInfo) do
            
--             local percent = math.floor((item.currentDurability/item.maximumDurability)*100)

--             local r = (percent > 50 and 1 - 2 * (percent - 50) / 100.0 or 1.0);
--             local g = (percent > 50 and 1.0 or 2 * percent / 100.0);
--             local b = 0.0;

--             if item.itemLink ~= "-" then
--                 --GameTooltip:AddDoubleLine(item.itemLink, string.format("|cffffffff[%s|cffffffff]", CreateColor(r, g, b):WrapTextInColorCode(item.currentDurability.."/"..item.maximumDurability.." - "..percent)))
--                 GameTooltip:AddDoubleLine(CreateAtlasMarkup(item.atlas, 20, 20, 0, -2)..item.itemLink, string.format("|cffffffff[%s|cffffffff]", CreateColor(r, g, b):WrapTextInColorCode(percent.."%")))
--             end

--         end

--         GameTooltip:Show()
--     end)


--     self.openXpButton:SetScript("OnEnter", function()
--         GameTooltip:SetOwner(self.openXpButton, 'ANCHOR_BOTTOM')

--         local xp = UnitXP("player")
--         local xpMax = UnitXPMax("player")
--         local restedXp = GetXPExhaustion() or 0;
--         local requiredXp = xpMax - xp;

--         local requiredPer = tonumber(string.format("%.1f", (requiredXp/xpMax)*100))
--         local restedPer = tonumber(string.format("%.1f", (restedXp/xpMax)*100))

--         GameTooltip:AddLine("XP info")
--         GameTooltip:AddLine(" ")
--         GameTooltip:AddDoubleLine("|cffffffffCurrent", xp)
--         GameTooltip:AddDoubleLine("|cffffffffThis level", xpMax)
--         GameTooltip:AddDoubleLine("|cffffffffRequired", string.format("%s [%s%%]", xpMax - xp, requiredPer))
--         GameTooltip:AddDoubleLine("|cffffffffRested", string.format("%s [%s%%]", restedXp, restedPer))
--         GameTooltip:AddLine(" ")
--         GameTooltip:AddLine("|cff8F2E71Rested XP will be consumed \nat double rate per kill, \nif you have 1000 rested XP you'll \nget double for the first 500 XP earned")

--         GameTooltip:Show()
--     end)


--     --self.openSessionButton.text:ClearAllPoints()
--     --self.openSessionButton.text:SetPoint("LEFT", 5, 0)
--     self.openSessionButton:SetScript("OnEnter", function()
--         GameTooltip:SetOwner(self.openSessionButton, 'ANCHOR_BOTTOM')

--         GameTooltip:AddLine("Session info")
--         GameTooltip:AddLine(" ")

--         local questsTurnedIn = #self.sessionInfo.questsCompleted or 0;
--         local questXp = 0;
--         for k, quest in ipairs(self.sessionInfo.questsCompleted) do
--             questXp = questXp + (quest.xpReward or 0);
--         end

--         GameTooltip:AddDoubleLine("|cff5979B9Quests turned in:", questsTurnedIn)
--         GameTooltip:AddDoubleLine("|cff5979B9Quest XP:", questXp)
--         GameTooltip:AddLine(" ")

--         GameTooltip:AddDoubleLine("|cffffffffMobs killed:", self.sessionInfo.mobsKilled)
--         GameTooltip:AddDoubleLine("|cffffffffMob XP:", self.sessionInfo.mobXpReward)
--         GameTooltip:AddLine(" ")

--         if self.sessionInfo.reputations then
--             GameTooltip:AddLine("Reputation gains:")
--             for faction, gain in pairs(self.sessionInfo.reputations) do
--                 GameTooltip:AddDoubleLine(string.format("|cffffffff%s|r", faction), gain)
--             end
--         end

--         GameTooltip:Show()
--     end)



--     self.openNetStatsButton:SetScript("OnEnter", function()
--         GameTooltip:SetOwner(self.openNetStatsButton, 'ANCHOR_BOTTOM')

--         GameTooltip:AddLine("Network info")

--         local bandwidthIn, bandwidthOut, latencyHome, latencyWorld = GetNetStats()

--         GameTooltip:AddDoubleLine("|cffffffffHome|r", latencyHome)
--         GameTooltip:AddDoubleLine("|cffffffffWorld|r", latencyWorld)
--         GameTooltip:AddDoubleLine("|cffffffffDownload|r", string.format("%.2f", bandwidthIn))
--         GameTooltip:AddDoubleLine("|cffffffffUpload|r", string.format("%.2f", bandwidthOut))

--         GameTooltip:Show()
--     end)



--     self.openPlayerBagsButton:SetScript("OnEnter", function()
--         if not InCombatLockdown() then
--             self:CloseDropdownMenus()
--             self:OpenPlayerBagsMenu()
--         end
--     end)


--     self.openQuestLogButton.icon:SetAtlas("worldquest-tracker-questmarker")
--     self.openQuestLogButton:SetScript("OnClick", function(self)

--         if self.tooltipText then
--             GameTooltip:SetOwner(self, "LEFT")
--             GameTooltip:AddLine(self.tooltipText)
--             GameTooltip:Show()
--         end

--         ShowUIPanel(QuestLogFrame)
--     end)


--     SetPortraitTexture(self.openCharacterFrameButton.icon, "player")
--     self.openCharacterFrameButton:SetScript("OnClick", function(self, button)

--         if self.tooltipText then
--             GameTooltip:SetOwner(self, "LEFT")
--             GameTooltip:AddLine(self.tooltipText)
--             GameTooltip:Show()
--         end

--         if button == "LeftButton" then
--             ShowUIPanel(CharacterFrame)
--         else
--             SamsUiCharacterFrame:Show()
--         end
--     end)


--     self.openLFGFrameButton.icon:SetAtlas("dungeon")
--     self.openLFGFrameButton:SetScript("OnClick", function()

--         if self.openLFGFrameButton.tooltipText then
--             GameTooltip:SetOwner(self.openLFGFrameButton, "LEFT")
--             GameTooltip:AddLine(self.openLFGFrameButton.tooltipText)
--             GameTooltip:Show()
--         end

--         --LFGFrame:Show()
--         if not LFGFrame then
--             LoadAddOn("Blizzard_LookingForGroupUI")
--         end
--         ShowUIPanel(LFGParentFrame)
--     end)


--     self.openMacroFrameButton.icon:SetAtlas("NPE_Icon")
--     self.openMacroFrameButton:SetScript("OnClick", function()

--         if self.openMacroFrameButton.tooltipText then
--             GameTooltip:SetOwner(self.openMacroFrameButton, "LEFT")
--             GameTooltip:AddLine(self.openMacroFrameButton.tooltipText)
--             GameTooltip:Show()
--         end

--         --MacroFrame:Show()
--         if not MacroFrame then
--             LoadAddOn("Blizzard_MacroUI")
--         end
--         ShowUIPanel(MacroFrame)
--     end)


--     self.openSpellBookFrameButton.icon:SetAtlas("minortalents-icon-book")
--     self.openSpellBookFrameButton:SetScript("OnClick", function()

--         if self.openSpellBookFrameButton.tooltipText then
--             GameTooltip:SetOwner(self.openSpellBookFrameButton, "LEFT")
--             GameTooltip:AddLine(self.openSpellBookFrameButton.tooltipText)
--             GameTooltip:Show()
--         end

--         ShowUIPanel(SpellBookFrame)
--     end)


--     self.hearthstoneButton.icon:SetAtlas("innkeeper")
--     self.hearthstoneButton:SetAttribute("macrotext1", "/cast Hearthstone")
--     self.hearthstoneButton:SetScript("OnEnter", function()
    
--         GameTooltip:SetOwner(self.hearthstoneButton, "LEFT")
--         GameTooltip:AddLine(GetBindLocation())
--         GameTooltip:Show()

--     end)


--     self.openCookingButton.icon:SetAtlas("Mobile-Cooking")
--     self.openCookingButton:SetAttribute("macrotext1", "/cast Cooking")
--     self.openCookingButton:SetScript("OnEnter", function()
    
--         GameTooltip:SetOwner(self.openCookingButton, "LEFT")
--         GameTooltip:AddLine("Cooking")
--         GameTooltip:Show()

--     end)

--     --questartifactturnin

--     self:RegisterEvent("ADDON_LOADED")
--     self:RegisterEvent("PLAYER_MONEY")
--     self:RegisterEvent("PLAYER_ENTERING_WORLD")
--     self:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
--     self:RegisterEvent("SKILL_LINES_CHANGED")
--     self:RegisterEvent("ZONE_CHANGED")
--     self:RegisterEvent("BAG_UPDATE_DELAYED")
--     self:RegisterEvent("PLAYER_LOGOUT")
--     self:RegisterEvent("PLAYER_XP_UPDATE")
--     self:RegisterEvent("UNIT_PORTRAIT_UPDATE")
--     self:RegisterEvent("QUEST_TURNED_IN")
--     self:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
--     self:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE")
--     self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
--     self:RegisterEvent("UNIT_AURA")

--     --MultiBarBottomLeftButton1
--     --MultiBarBottomRightButton1

--     -- local actionBarSetup = {
--     --     --MainMenuBar,
--     --     MultiBarBottomLeft = {
--     --         anchor = "BOTTOM",
--     --         relativeTo = UIParent,
--     --         relativePoint = "BOTTOM",
--     --         xPos = 0,
--     --         yPos = 190,
--     --     },
--     --     MultiBarBottomRight = {
--     --         anchor = "BOTTOM",
--     --         relativeTo = UIParent,
--     --         relativePoint = "BOTTOM",
--     --         xPos = 0,
--     --         yPos = 100,
--     --     },
--     --     MultiBarLeft = {
--     --         anchor = "RIGHT",
--     --         relativeTo = UIParent,
--     --         relativePoint = "RIGHT",
--     --         xPos = -60,
--     --         yPos = 0,
--     --     },
--     --     MultiBarRight = {
--     --         anchor = "RIGHT",
--     --         relativeTo = UIParent,
--     --         relativePoint = "RIGHT",
--     --         xPos = -10,
--     --         yPos = 0,
--     --     },
--     --     PetActionBarFrame = {
--     --         anchor = "BOTTOM",
--     --         relativeTo = UIParent,
--     --         relativePoint = "BOTTOM",
--     --         xPos = 0,
--     --         yPos = 220,
--     --     },
--     -- }


--     -- C_Timer.After(5, function()
--     --     for barName, position in pairs(actionBarSetup) do
--     --         local bar = _G[barName]
--     --         if bar then
--     --             bar:ClearAllPoints()
--     --             bar:SetParent(UIParent)
--     --             bar:SetPoint(position.anchor, position.relativeTo, position.relativePoint, position.xPos, position.yPos)
--     --             Util:MakeFrameMoveable(bar)
--     --         end
--     --     end

--     --     local x, y = ActionButton1:GetSize()

--     --     local mainActionBar = CreateFrame("FRAME", nil, UIParent)
--     --     mainActionBar:SetPoint("BOTTOM", MultiBarBottomRight, "TOP", 0, 6)
--     --     mainActionBar:SetSize(((x + 6) * 12), ((y + 6) * 3))
    
--     --     for i = 1, 12 do
--     --         local button = _G["ActionButton"..i]
--     --         button:ClearAllPoints()
--     --         button:SetParent(mainActionBar)
    
--     --         if i == 1 then
--     --             button:SetPoint("LEFT", 3, 0)
--     --         else
--     --             button:SetPoint("LEFT", _G["ActionButton"..i-1], "RIGHT", 6, 0)
--     --         end
    
--     --     end

--     --     Util:MakeFrameMoveable(mainActionBar)
--     -- end)




--     -- MainMenuBarLeftEndCap:Hide()
--     -- MainMenuBarRightEndCap:Hide()
--     -- MainMenuBarArtFrame:Hide()

--     -- MainMenuBarPerformanceBar:Hide()

--     -- MainMenuBarMaxLevelBar:Hide()

--     -- MainMenuBar:SetSize(1,1)

-- end


--function SamsUiTopBarMixin:OnUpdate()
    -- if 1 == 1 then
    --     return;
    -- end
    --self.openNetStatsButton:SetText(string.format("fps %.1f", GetFramerate()))

    -- local totalMemKB = self:GetCurrentAddonUsage()
    -- self.openAddonUsageButton:SetText(string.format("%.2f KB", totalMemKB))
--end


-- function SamsUiTopBarMixin:OnEvent(event, ...)
--     if 1 == 1 then
--         return;
--     end

--     if event == "ADDON_LOADED" then
        
--         C_Timer.After(1, function()
--             self:MoveAllLibMinimapIcons()
--         end)

--     end

--     if event == "UNIT_AURA" then
--         BuffFrame:ClearAllPoints()
--         BuffFrame:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", -10, -10)
--     end

--     if event == "UNIT_PORTRAIT_UPDATE" then
--         SetPortraitTexture(self.openCharacterFrameButton.icon, "player")
--     end

--     if event == "PLAYER_LOGOUT" then
--         self.sessionInfo.logoutTime = time();
--     end

--     if event == "BAG_UPDATE_DELAYED" then
--         self:ScanPlayerBags()
--     end

--     if event == "ZONE_CHANGED" then
--         self.minimapZoneText:SetText(GetMinimapZoneText())
--     end

--     if event == "PLAYER_ENTERING_WORLD" then

--         local name, realm = UnitFullName("player")
--         self.nameRealm = string.format("%s-%s", name, realm)

--         --these sui.db function will work fine even though we havent called Init() on the sui.db object
--         --the Init function will register the callbacks and fire a trigger but becaue InsertOrUpdateCharacterInfo 
--         --doesnt trigger any callbacks its not a problem
--         local initialLogin, reload = ...
--         if initialLogin == true then

--             local now = time();
--             local gold = GetMoney();

--             sui.db:InsertOrUpdateCharacterInfo(self.nameRealm, "initialLoginGold", gold)

--             sui.db:InsertOrUpdateCharacterInfo(self.nameRealm, "initialLoginTime", now)

--             --as this is the fresh login we need to add a new session
--             --local sessions = sui.db:GetCharacterInfo(self.nameRealm, "sessions")
--             sui.db:CreateNewCharacterSession(self.nameRealm, {
--                 questsCompleted = {},
--                 mobsKilled = 0,
--                 mobXpReward = 0,
--                 initialLoginTime = now,
--                 logoutTime = 0,
--                 profit = 0,
--             })
--             print("db init > new session")

--         else


--         end

--         sui.db:Init()
--     end

--     if event == "PLAYER_MONEY" then
--         self:UpdateCurrency()
--     end

--     if event == "UPDATE_INVENTORY_DURABILITY" then
--         self:UpdateDurability()
--     end

--     if event == "SKILL_LINES_CHANGED" then
--         self:ScanSpellbook()
--     end

--     if event == "PLAYER_XP_UPDATE" then
--         self:UpdateXp()
--     end

--     if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        
--         local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName = CombatLogGetCurrentEventInfo()

--         if subevent == "UNIT_DIED" then
--             C_Timer.After(0.5, function()
                
--                 if CanLootUnit(destGUID) then
--                     self.sessionInfo.mobsKilled = self.sessionInfo.mobsKilled + 1;
--                 end
--             end)
--         end
    
--     end

--     if event == "CHAT_MSG_COMBAT_XP_GAIN" then
--         local text = ...

--         if text:find("dies") then

--             --if a mob dies and gives xp then we must have tagged it so grab the xp value and update the session info
--             self.sessionInfo.mobsKilled = self.sessionInfo.mobsKilled + 1;

--             --nasty but there are a lot of global strings for the various messages so just attempt to strip the number characters out using a guess on fixed position
--             local start = text:find("you gain ")
--             local finish = text:find(" experience")
--             local xp = text:sub(start+9, finish)
--             if tonumber(xp) then
--                 self.sessionInfo.mobXpReward = self.sessionInfo.mobXpReward + xp;
--             end
--         end
--     end

--     if event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then

--         local info = ...
--         local rep = FACTION_STANDING_INCREASED:gsub("%%s", "(.+)"):gsub("%%d", "(.+)")
--         local faction, gain = string.match(info, rep)
        
--         self:UpdateSessionRep(faction, gain)

--     end

--     if event == "QUEST_TURNED_IN" then
--         local questID, xpReward = ...

--         table.insert(self.sessionInfo.questsCompleted, {
--             questID = questID,
--             xpReward = xpReward or 0,
--         })
--     end

-- end



-- function SamsUiTopBarMixin:UpdateSessionRep(faction, gain)

--     gain = tonumber(gain);

--     if not self.sessionInfo.reputations then
--         self.sessionInfo.reputations = {}
--     end

--     if self.sessionInfo.reputations[faction] then
--         self.sessionInfo.reputations[faction] = self.sessionInfo.reputations[faction] + gain;
--     else
--         self.sessionInfo.reputations[faction] = gain
--     end

-- end


-- function SamsUiTopBarMixin:CloseDropdownMenus()
    
--     for k, menu in ipairs(self.dropdownMenus) do
--         menu:Hide()
--     end
-- end


-- function SamsUiTopBarMixin:OnDatabaseInitialized()

--     local function updateSessionTimerText()
--         local initialLogin = sui.db:GetCharacterInfo(self.nameRealm, "initialLoginTime") or time()
--         if type(initialLogin) == "number" then
--             local now = time()
--             self.openSessionButton:SetText(string.format("%s %s", CreateAtlasMarkup("glueannouncementpopup-icon-info", 20, 20), SecondsToClock(now - initialLogin)))
--         end
--     end

--     self.sessionTimer = C_Timer.NewTicker(1, updateSessionTimerText)

--     --if there is a session info table then grab a ref to it to continue using (for ui reload situations)
--     local sessions = sui.db:GetCharacterInfo(self.nameRealm, "sessions")
--     if type(sessions) == "table" then
--         if #sessions > 0 then
--             self.sessionInfo = sessions[1]; --sessions are inserted at index 1 so they naturally list in reverse order - index 1 will be the most recent session
--             --print("using session 1")
--         else
--             local now = time()
--             table.insert(sessions, {
--                 questsCompleted = {},
--                 mobsKilled = 0,
--                 mobXpReward = 0,
--                 initialLoginTime = now,
--                 logoutTime = 0,
--             })
--             self.sessionInfo = sessions[1];
--             --print("created new session 1")
--         end
--     end

--     self:UpdateCurrency()

--     self:UpdateDurability()

--     self:ScanSpellbook()

--     self:UpdateXp()

--     self:ScanPlayerBags()

--     local _, class = UnitClass("player")
--     sui.db:InsertOrUpdateCharacterInfo(self.nameRealm, "class", class)

--     local level = UnitLevel("player")
--     sui.db:InsertOrUpdateCharacterInfo(self.nameRealm, "level", level)

--     local _, englishRace = UnitRace("player")
--     sui.db:InsertOrUpdateCharacterInfo(self.nameRealm, "englishRace", englishRace)


--     self:SetupClass(class)


-- end


-- function SamsUiTopBarMixin:SetupClass(class)

--     if class == "SHAMAN" then

--         self.hearthstoneButton:SetAttribute("macrotext2", "/cast Astral Recall")
--         self.hearthstoneButton:SetScript("OnEnter", function()
    
--             GameTooltip:SetOwner(self.hearthstoneButton, "LEFT")
--             GameTooltip:AddLine(GetBindLocation())
--             local start, duration, enabled, modRate = GetSpellCooldown(8690)
--             local hearthstoneCooldown = (start + duration) - GetTime()
--             GameTooltip:AddDoubleLine(string.format("Left click |cffffffff%s|r", GetSpellInfo(8690)), SecondsToTime(hearthstoneCooldown))

--             local start, duration, enabled, modRate = GetSpellCooldown(556)
--             local astralRecallCooldown = (start + duration) - GetTime()
--             GameTooltip:AddDoubleLine(string.format("Right click |cffffffff%s|r", GetSpellInfo(556)), SecondsToTime(astralRecallCooldown))
--             GameTooltip:Show()
    
--         end)
--     end
-- end


-- function SamsUiTopBarMixin:GetCharacterXpInfo(character)

--     if not character then
--         character = sui.db:GetCharacter(self.nameRealm)
--     end

--     if type(character) ~= "table" then
--         return;
--     end

-- 	local rate = 0
-- 	local multiplier = 1.5
	
-- 	if character.englishRace == "Pandaren" then
-- 		multiplier = 3
-- 	end
	
-- 	local savedXP = 0
-- 	local savedRate = 0
-- 	local maxXP = character.XPMax * multiplier
-- 	if character.RestXP then
-- 		rate = character.RestXP / (maxXP / 100)
-- 		savedXP = character.RestXP
-- 		savedRate = rate
-- 	end
	
-- 	local xpEarnedResting = 0
-- 	local rateEarnedResting = 0
-- 	local isFullyRested = false
-- 	local timeUntilFullyRested = 0
-- 	local now = time()
	
-- 	if character.lastLogoutTimestamp ~= MAX_LOGOUT_TIMESTAMP then	
-- 		local oneXPBubble = character.XPMax / 20
-- 		local elapsed = (now - character.lastLogoutTimestamp)
-- 		local numXPBubbles = elapsed / 28800
		
-- 		xpEarnedResting = numXPBubbles * oneXPBubble
		
-- 		if not character.isResting then
-- 			xpEarnedResting = xpEarnedResting / 4
-- 		end

-- 		if (xpEarnedResting + savedXP) > maxXP then
-- 			xpEarnedResting = xpEarnedResting - ((xpEarnedResting + savedXP) - maxXP)
-- 		end

-- 		if xpEarnedResting < 0 then xpEarnedResting = 0 end
		
-- 		rateEarnedResting = xpEarnedResting / (maxXP / 100)
		
-- 		if (savedXP + xpEarnedResting) >= maxXP then
-- 			isFullyRested = true
-- 			rate = 100
-- 		else
-- 			local xpUntilFullyRested = maxXP - (savedXP + xpEarnedResting)
-- 			timeUntilFullyRested = math.floor((xpUntilFullyRested / oneXPBubble) * 28800)
			
-- 			rate = rate + rateEarnedResting
-- 		end
-- 	end
	
-- 	return rate, savedXP, savedRate, rateEarnedResting, xpEarnedResting, maxXP, isFullyRested, timeUntilFullyRested
-- end


-- function SamsUiTopBarMixin:UpdateXp()

--     local xp, xpMax = UnitXP("player"), UnitXPMax("player")
--     local xpPer = tonumber(string.format("%.1f", (xp/xpMax)*100))
--     local xpRested = GetXPExhaustion()
--     self.openXpButton:SetText(string.format("%s %s %%", CreateAtlasMarkup("GarrMission_CurrencyIcon-Xp", 32, 32), xpPer))

--     sui.db:InsertOrUpdateCharacterInfo(self.nameRealm, "xp", xp)
--     sui.db:InsertOrUpdateCharacterInfo(self.nameRealm, "xpMax", xpMax)
--     sui.db:InsertOrUpdateCharacterInfo(self.nameRealm, "xpRested", xpRested)
-- end


-- ---open a sub menu for the player bags for the items of a sub type class id
-- ---@param parent frame the button to anchor the menu to
-- ---@param items table list of items for this sub class
-- function SamsUiTopBarMixin:OpenPlayersBagsSubClassItems(parent, items)

--     self.playerBagsSubClassItemsContainer:ClearAllPoints()
--     self.playerBagsSubClassItemsContainer:SetPoint("TOPLEFT", parent, "TOPRIGHT", 2, 0)

--     if not self.playerBagsSubClassItemsMenuButtons then
--         self.playerBagsSubClassItemsMenuButtons = {}
--     end

--     if self.playerBagsSubClassItemsTicker then
--         self.playerBagsSubClassItemsTicker:Cancel()
--     end

--     for k, button in pairs(self.playerBagsSubClassItemsMenuButtons) do
--         button:ClearItem()
--         button:Hide()
--     end

--     for k, item in ipairs(items) do
        
--         if not self.playerBagsSubClassItemsMenuButtons[k] then
            
--             local button = CreateFrame("BUTTON", nil, self.playerBagsSubClassItemsContainer, "SamsUiTopBarSecureMacroContainerMenuButton")

--             button:SetPoint("TOP", 0, (k-1) * -31)
--             button:SetSize(self.playerBagMenuItemWidth, 32)

--             button.tooltipAnchor = "ANCHOR_RIGHT"

--             button.closeDropdownMenus = function()
--                 self:CloseDropdownMenus()
--             end

--             self.playerBagsSubClassItemsMenuButtons[k] = button;
--         end

--         local button = self.playerBagsSubClassItemsMenuButtons[k]

--         button.itemLink = item.link;
--         button:SetItem(item)

--         button:Show()

--         self.playerBagsSubClassItemsContainer:SetSize(self.playerBagMenuItemWidth, 31*k)
--         self.playerBagsSubClassItemsContainer:Show()

--     end

--     self.playerBagsSubClassItemsTicker = C_Timer.NewTicker(self.dropdownMenuCloseDelay, function()
--         if self.playerBagsSubClassItemsContainer:IsMouseOver() == false and self.playerBagsContainer:IsMouseOver() == false then
--             local isHovered = false;
--             for k, button in ipairs(self.playerBagsSubClassItemsMenuButtons) do
--                 if button:IsMouseOver() == true then
--                     isHovered = true;
--                 end
--             end
--             --check the sub menu buttons
--             if self.playerBagsSubClassMenuButtons then
--                 for k, button in ipairs(self.playerBagsSubClassMenuButtons) do
--                     if button:IsMouseOver() == true then
--                         isHovered = true;
--                     end
--                 end
--             end
--             if isHovered == false then
--                 self.playerBagsSubClassItemsContainer:Hide()
--                 self.playerBagsSubClassItemsTicker:Cancel()
--             end
--         end
--     end)

-- end


-- ---open a sub menu for a player bags class id
-- ---@param parent frame the button that the sub menu should anchor to
-- ---@param itemClassID number the parent button class id - used to get sub class info
-- ---@param subClassItems table a list of items for this class id
-- function SamsUiTopBarMixin:OpenPlayerBagsSubClassMenu(parent, itemClassID, subClassItems)

--     self.playerBagsSubClassItemsContainer:Hide()

--     self.playerBagsSubClassContainer:ClearAllPoints()
--     self.playerBagsSubClassContainer:SetPoint("TOPLEFT", parent, "TOPRIGHT", 2, 0)

--     if self.playerBagsSubClassMenuTicker then
--         self.playerBagsSubClassMenuTicker:Cancel()
--     end

--     if not self.playerBagsSubClassMenuButtons then
--         self.playerBagsSubClassMenuButtons = {}
--     end

--     for k, button in pairs(self.playerBagsSubClassMenuButtons) do
--         button:ClearItem()
--         button:Hide()
--     end

--     if self.playerBagsSubClassItemsMenuButtons then
--         for k, button in pairs(self.playerBagsSubClassItemsMenuButtons) do
--             button:ClearItem()
--             button:Hide()
--         end
--     end

--     local subClassIDs = {}
--     for k, item in ipairs(subClassItems) do
        
--         if not subClassIDs[item.subClassID] then
--             subClassIDs[item.subClassID] = {}
--         end

--         table.insert(subClassIDs[item.subClassID], item)

--     end

--     local i = 0;
--     for itemSubClassID, items in pairs(subClassIDs) do
        
--         i = i + 1;

--         local itemSubTypeInfo, isArmorType = GetItemSubClassInfo(itemClassID, itemSubClassID)

--         if not self.playerBagsSubClassMenuButtons[i] then
            
--             local button = CreateFrame("BUTTON", nil, self.playerBagsSubClassContainer, "SamsUiTopBarSecureMacroContainerMenuButton")

--             button:SetPoint("TOP", 0, (i-1) * -31)
--             button:SetSize(self.playerBagMenuTypeWidth, 32)

--             self.playerBagsSubClassMenuButtons[i] = button;

--         end

--         local button = self.playerBagsSubClassMenuButtons[i]

--         button:SetPoint("TOP", 0, (i-1) * -31)
--         button:SetText(itemSubTypeInfo)

--         --button.items = items;
--         button.func = function()
--             self:OpenPlayersBagsSubClassItems(button, items)
--         end

--         button:Show()

--         self.playerBagsSubClassContainer:SetSize(self.playerBagMenuTypeWidth, 31*i)
--         self.playerBagsSubClassContainer:Show()

--     end

--     self.playerBagsSubClassMenuTicker = C_Timer.NewTicker(self.dropdownMenuCloseDelay, function()

--         --check if we are hovering over either the top level class di menu or the sub menu for the class id sub classes
--         if self.playerBagsContainer:IsMouseOver() == false and self.playerBagsSubClassContainer:IsMouseOver() == false then
--             local isHovered = false;

--             --check the top level buttons
--             for k, button in ipairs(self.playerBagsMenuButtons) do
--                 if button:IsMouseOver() == true then
--                     isHovered = true;
--                 end
--             end

--             --check the sub menu buttons
--             if self.playerBagsSubClassMenuButtons then
--                 for k, button in ipairs(self.playerBagsSubClassMenuButtons) do
--                     if button:IsMouseOver() == true then
--                         isHovered = true;
--                     end
--                 end
--             end
--             if self.playerBagsSubClassItemsMenuButtons then
--                 for k, button in ipairs(self.playerBagsSubClassItemsMenuButtons) do
--                     if button:IsMouseOver() == true then
--                         isHovered = true;
--                     end
--                 end
--             end
--             if isHovered == false then
--                 self.playerBagsContainer:Hide()
--                 self.playerBagsSubClassContainer:Hide()
--                 self.playerBagsSubClassMenuTicker:Cancel()
--             end
--         end
--     end)

-- end


-- ---open the player bag menu - this will show a list of item type class id names
-- function SamsUiTopBarMixin:OpenPlayerBagsMenu()

--     if self.playerBagsContainer:IsVisible() then
--         return;
--     end

--     if self.playerBagsMenuTicker then
--         self.playerBagsMenuTicker:Cancel()
--     end

--     self:ScanPlayerBags()

--     if not self.playerBagsMenuButtons then
--         self.playerBagsMenuButtons = {}
--     end

--     for k, button in ipairs(self.playerBagsMenuButtons) do
--         button:ClearItem()
--         button:Hide()
--     end

--     if self.playerBagsSubClassMenuButtons then
--         for k, button in ipairs(self.playerBagsSubClassMenuButtons) do
--             button:ClearItem()
--             button:Hide()
--         end
--     end

--     if self.playerBagsSubClassItemsMenuButtons then
--         for k, button in ipairs(self.playerBagsSubClassItemsMenuButtons) do
--             button:ClearItem()
--             button:Hide()
--         end
--     end


--     local i = 0;
--     for itemType, items in pairs(self.characterBagItems) do

--         local itemTypeInfo = GetItemClassInfo(itemType)
--         i = i + 1;

--         if not self.playerBagsMenuButtons[i] then
            
--             local button = CreateFrame("BUTTON", nil, self.playerBagsContainer, "SamsUiTopBarSecureMacroContainerMenuButton")

--             button:SetPoint("TOP", 0, (i-1) * -31)
--             button:SetSize(self.playerBagMenuTypeWidth, 32)

--             self.playerBagsMenuButtons[i] = button;

--         end

--         local button = self.playerBagsMenuButtons[i]

--         button:SetPoint("TOP", 0, (i-1) * -31)
--         button:SetText(itemTypeInfo)

--         button.func = function()
--             self:OpenPlayerBagsSubClassMenu(button, itemType, items)
--         end

--         button:Show()


--         self.playerBagsContainer:SetSize(self.playerBagMenuTypeWidth, 31*i)
--         self.playerBagsContainer:Show()
--     end

--     self.playerBagsMenuTicker = C_Timer.NewTicker(self.dropdownMenuCloseDelay, function()
--         if self.playerBagsContainer:IsMouseOver() == false and self.openPlayerBagsButton:IsMouseOver() == false and self.playerBagsSubClassContainer:IsMouseOver() == false then
--             local isHovered = false;
--             for k, button in ipairs(self.playerBagsMenuButtons) do
--                 if button:IsMouseOver() == true then
--                     isHovered = true;
--                 end
--             end
--             if self.playerBagsSubClassMenuButtons then
--                 for k, button in ipairs(self.playerBagsSubClassMenuButtons) do
--                     if button:IsMouseOver() == true then
--                         isHovered = true;
--                     end
--                 end
--             end
--             if self.playerBagsSubClassItemsMenuButtons then
--                 for k, button in ipairs(self.playerBagsSubClassItemsMenuButtons) do
--                     if button:IsMouseOver() == true then
--                         isHovered = true;
--                     end
--                 end
--             end
--             if isHovered == false then
--                 self.playerBagsContainer:Hide()
--                 self.playerBagsSubClassItemsContainer:Hide()
--                 self.playerBagsMenuTicker:Cancel()
--             end
--         end
--     end)

-- end


-- function SamsUiTopBarMixin:OpenConsumablesMenu()

--     if self.consumablesMenuContainer:IsVisible() then
--         return;
--     end

--     if self.consumablesMenuTicker then
--         self.consumablesMenuTicker:Cancel()
--     end

--     self:ScanPlayerBags()

--     if not self.consumablesMenuButtons then
--         self.consumablesMenuButtons = {}
--     end

--     local consumablesTypesDisplayed = {
--         [1] = true, --potion
--         [2] = true, --elixir
--         [3] = true, --scroll
--         [6] = true, --bandages ?
--         [8] = true, --bandages ?
--     }

--     local i = 0;
--     for k, item in ipairs(self.characterBagItems[0]) do

--         if consumablesTypesDisplayed[item.subClassID] then

--             i = i + 1;

--             if not self.consumablesMenuButtons[i] then
                
--                 local button = CreateFrame("BUTTON", nil, self.consumablesMenuContainer, "SamsUiTopBarSecureMacroContainerMenuButton")

--                 button:SetPoint("TOP", 0, (i-1) * -31)
--                 button:SetSize(250, 32)

--                 button.itemLink = item.link;
--                 button:SetItem(item)
--                 button.tooltipAnchor = "ANCHOR_LEFT"

--                 button:Show()

--                 self.consumablesMenuButtons[i] = button;

--             else

--                 local button = self.consumablesMenuButtons[i]

--                 button.itemLink = item.link;
--                 button:SetItem(item)

--                 button:Show()

--             end

--         end

--         self.consumablesMenuContainer:SetSize(250, 31*i)
--         self.consumablesMenuContainer:Show()
--     end

--     self.consumablesMenuTicker = C_Timer.NewTicker(self.dropdownMenuCloseDelay, function()
--         if self.consumablesMenuContainer:IsMouseOver() == false and self.openConsumablesButton:IsMouseOver() == false then
--             local isHovered = false;
--             for k, button in ipairs(self.consumablesMenuButtons) do
--                 if button:IsMouseOver() == true then
--                     isHovered = true;
--                 end
--             end
--             if isHovered == false then
--                 self.consumablesMenuContainer:Hide()
--                 self.consumablesMenuTicker:Cancel()
--             end
--         end
--     end)

-- end


-- function SamsUiTopBarMixin:OpenFoodAndDrinkMenu()

--     if self.foodAndDrinkMenuContainer:IsVisible() then
--         return;
--     end

--     if self.closeFoodAndDrinkMenuTicker then
--         self.closeFoodAndDrinkMenuTicker:Cancel()
--     end

--     self:ScanPlayerBags()

--     if not self.foodAndDrinkMenuButtons then
--         self.foodAndDrinkMenuButtons = {}
--     end

--     for k, button in ipairs(self.foodAndDrinkMenuButtons) do
--         button:Hide()
--     end

--     --DevTools_Dump({self.foodAndDrink})

--     self.foodAndDrinkMenuContainer:SetSize(250, 0)

--     local i = 0;
--     for k, item in ipairs(self.characterBagItems[0]) do

--         if item.subClassID == 5 then
            
--             i = i + 1;
        
--             if not self.foodAndDrinkMenuButtons[i] then
                
--                 local button = CreateFrame("BUTTON", nil, self.foodAndDrinkMenuContainer, "SamsUiTopBarSecureMacroContainerMenuButton")

--                 button:SetPoint("TOP", 0, (i-1) * -31)
--                 button:SetSize(250, 32)

--                 button.itemLink = item.link;
--                 button:SetItem(item)
--                 button.tooltipAnchor = "ANCHOR_LEFT"

--                 --button.anim.fadeIn:SetStartDelay(i/40)

--                 button:Show()

--                 self.foodAndDrinkMenuButtons[i] = button;

--             else

--                 local button = self.foodAndDrinkMenuButtons[i]

--                 button.itemLink = item.link;
--                 button:SetItem(item)

--                 button:Show()

--             end

--         end
--         self.foodAndDrinkMenuContainer:SetSize(250, 31*i)
--         self.foodAndDrinkMenuContainer:Show()
--     end


--     self.closeFoodAndDrinkMenuTicker = C_Timer.NewTicker(self.dropdownMenuCloseDelay, function()
--         if self.foodAndDrinkMenuContainer:IsMouseOver() == false and self.openFoodAndDrinkButton:IsMouseOver() == false then
--             local isHovered = false;
--             for k, button in ipairs(self.foodAndDrinkMenuButtons) do
--                 if button:IsMouseOver() == true then
--                     isHovered = true;
--                 end
--             end
--             if isHovered == false then
--                 self.foodAndDrinkMenuContainer:Hide()
--                 self.closeFoodAndDrinkMenuTicker:Cancel()
--             end
--         end
--     end)

-- end


-- function SamsUiTopBarMixin:ScanPlayerBags()

--     self.characterBagItems = nil;
--     self.characterBagItems = {}
--     self.characterBagSlots = nil
--     self.characterBagSlots = {}
--     local bagItemsAdded = {}
--     local bagItemIDsSeen = {}

--     self.totalBagSlots = 0;
--     self.bagSlotsUsed = 0;

--     for bag = 0, 4 do

--         local bagSlots = GetContainerNumSlots(bag)
--         self.totalBagSlots = self.totalBagSlots + bagSlots;

--         local slotID = 0;
--         for slot = bagSlots, 1, -1 do

--             slotID = slotID + 1;

--             --local slotFrame = string.format("ContainerFrame%dItem%d", bag+1, slotID)

--             local icon, itemCount, _, _, _, _, itemLink, _, _, itemID = GetContainerItemInfo(bag, slot)
--             --local itemLink = GetContainerItemLink(bag, slot)
--             if itemID then

--                 self.bagSlotsUsed = self.bagSlotsUsed + 1;

--                 bagItemIDsSeen[itemID] = true;

--                 local _, _, _, itemEquipLoc, _, itemClassID, itemSubClassID = GetItemInfoInstant(itemID)
--                 local itemName, _, itemQuality, itemLevel, _, _, _, _, _, _, sellPrice = GetItemInfo(itemID)

                
--                 -- table.insert(self.characterBagSlots, {
--                 --     slotFrame = slotFrame,
--                 --     itemID = itemID,
--                 --     icon = icon,
--                 --     link = itemLink,
--                 --     count = itemCount,
--                 --     classID = itemClassID,
--                 --     subClassID = itemSubClassID,
--                 --     name = itemName,
--                 --     ilvl = itemLevel or -1,
--                 -- })

--                 --add the classID check tables
--                 if not self.characterBagItems[itemClassID] then
--                     self.characterBagItems[itemClassID] = {}
--                 end
--                 if not bagItemsAdded[itemClassID] then
--                     bagItemsAdded[itemClassID] = {}
--                 end

--                 -- weapons and armour are best checked using links due to gems/enchants which an itemID would miss
--                 if itemClassID == 4 or itemClassID == 2 then
--                     if not bagItemsAdded[itemClassID][itemLink] then
--                         table.insert(self.characterBagItems[itemClassID], {
--                             itemID = itemID,
--                             icon = icon,
--                             link = itemLink,
--                             count = itemCount,
--                             sellPrice = sellPrice,
--                             rarity = itemQuality,
--                             subClassID = itemSubClassID,
--                             name = itemName,
--                             ilvl = itemLevel or -1,
--                         })
--                         bagItemsAdded[itemClassID][itemLink] = true;
--                     else
--                         --print(string.format("updatign count for %s", itemLink))
--                         for k, item in ipairs(self.characterBagItems[itemClassID]) do
--                             if item.link == itemLink then
--                                 item.count = item.count + 1;
--                             end
--                         end
--                     end

--                 --other items check by itemID
--                 else
--                     if not bagItemsAdded[itemClassID][itemID] then
--                         table.insert(self.characterBagItems[itemClassID], {
--                             itemID = itemID,
--                             icon = icon,
--                             link = itemLink,
--                             count = itemCount,
--                             sellPrice = sellPrice,
--                             rarity = itemQuality,
--                             subClassID = itemSubClassID,
--                             name = itemName,
--                             ilvl = itemLevel or -1,
--                         })
--                         bagItemsAdded[itemClassID][itemID] = true
--                     else
--                         --print(string.format("updatign count for %s", itemLink))
--                         for k, item in ipairs(self.characterBagItems[itemClassID]) do
--                             if item.itemID == itemID then
--                                 item.count = item.count + itemCount;
--                             end
--                         end
--                     end
--                 end

--             end
--         end
--     end

--     for itemClassID, items in pairs(self.characterBagItems) do

--         local keysToRemove = {}
        
--         for k, item in ipairs(items) do
            
--             if not bagItemIDsSeen[item.itemID] then
--                 table.insert(keysToRemove, k)
--             end

--         end

--         for _, key in ipairs(keysToRemove) do
--             items[key] = nil;
--         end

--     end

--     --table.sort(self.characterBagItems)
   
--     for itemClassID, items in pairs(self.characterBagItems) do

--         table.sort(items, function(a,b)

--             if a.subClassID == b.subClassID then
                
--                 if a.ilvl == b.ilvl then
                    
--                     if a.count == b.count then
                        
--                         return a.name < b.name
--                     else

--                         return a.count > b.count
--                     end

--                 else

--                     return a.ilvl > b.ilvl
--                 end

--             else

--                 return a.subClassID > b.subClassID
--             end
--         end)
--     end

--     self.openPlayerBagsButton:SetText(string.format("%s %s/%s", CreateAtlasMarkup("ShipMissionIcon-Treasure-Mission", 32, 32), self.bagSlotsUsed, self.totalBagSlots))

--     self:TriggerEvent("OnPlayerBagsScanned")

-- end


-- function SamsUiTopBarMixin:ScanSpellbook()

--      if not self.nameRealm then
--          return;
--      end

     
--      local ignore = {
--         ["Skinning"] = true,
--         ["Herbalism"] = true,
--     }

--     local profSpecCooldowns = {
--         ["Tailoring"] = {
--             26751, -- mooncloth
--         },
--     };

--     local prof1, prof2 = false, false;
--     local _, _, offset, numSlots = GetSpellTabInfo(1)
--     for j = offset+1, offset+numSlots do
        
--         local _, spellID = GetSpellBookItemInfo(j, BOOKTYPE_SPELL)
--         local spellName = GetSpellInfo(spellID)

--         if spellID == 2383 then --find herbs
--             spellName = "Herbalism" --change this to add to db, will be ignored for top bar buttons
--         end

--         if spellID == 2656 then --smelting
--             spellName = "Mining" --change this to add to db, will be ignored for top bar buttons
--         end

--         if tradeskillNamesToIDs[spellName] then

--             --print(spellName)

--             if prof1 == false then

--                 --update the db
--                 sui.db:InsertOrUpdateCharacterInfo(self.nameRealm, "profession1", spellName)

--                 --if the prof isnt somethign with a ui then ignore it
--                 if ignore[spellName] then
--                     return;
--                 end

--                 --set the icon
--                 self.openProf1Button.icon:SetAtlas(string.format("Mobile-%s", (spellName ~= "Engineering" and spellName or "Enginnering")))

--                 --if its mining then swap the spell to cast smelting
--                 if spellName == "Mining" then
--                     spellName = "Smelting"
--                 end

--                 --set the button macro
--                 self.openProf1Button:SetAttribute("macrotext1", string.format("/cast %s", spellName))

--                 local profTooltip = spellName;
--                 if profSpecCooldowns[spellName] then
--                     for k, spellID in ipairs(profSpecCooldowns[spellName]) do
--                         local start, dur, ending = GetSpellCooldown(spellID)
--                         if start > 0 and dur > 0 then
--                             profTooltip = string.format("%s\n\n[|cffffffff%s|r] %s", spellName, GetSpellInfo(spellID), SecondsToTime(start + dur - GetTime()))
--                         end
--                     end
--                 end

--                 self.openProf1Button.tooltipText = profTooltip;
--                 self.openProf1Button:Show()
                
--                 prof1 = true;

--             else
--                 if prof2 == false then

--                     sui.db:InsertOrUpdateCharacterInfo(self.nameRealm, "profession2", spellName)

--                     if ignore[spellName] then
--                         return;
--                     end

--                     self.openProf2Button.icon:SetAtlas(string.format("Mobile-%s", (spellName ~= "Engineering" and spellName or "Enginnering")))

--                     if spellName == "Mining" then
--                         spellName = "Smelting"
--                     end

--                     self.openProf2Button:SetAttribute("macrotext1", string.format("/cast %s", spellName))

--                     local profTooltip = spellName;
--                     if profSpecCooldowns[spellName] then
--                         for k, spellID in ipairs(profSpecCooldowns[spellName]) do
--                             local start, dur, ending = GetSpellCooldown(spellID)
--                             if start > 0 and dur > 0 then
--                                 profTooltip = string.format("%s\n\n[|cffffffff%s|r] %s", spellName, GetSpellInfo(spellID), SecondsToTime(start + dur - GetTime()))
--                             end
--                         end
--                     end

--                     self.openProf2Button.tooltipText = profTooltip;
--                     self.openProf2Button:Show()

--                     prof2 = true;
--                 end
--             end 

--         end
--     end

--     --if no data found then set to false
--     if prof1 == false then
--         sui.db:InsertOrUpdateCharacterInfo(self.nameRealm, "profession1", false)
--     end
--     if prof2 == false then
--         sui.db:InsertOrUpdateCharacterInfo(self.nameRealm, "profession2", false)
--     end

-- end


-- function SamsUiTopBarMixin:UpdateDurability()

--     self.durabilityInfo = {};

--     local currentDurability, maximumDurability = 0, 0;
--     for i = 1, 19 do
--         local slotId = GetInventorySlotInfo(inventorySlots[i])
--         local itemLink = GetInventoryItemLink("player", slotId)
--         if itemLink then
--             local current, maximum = GetInventoryItemDurability(i)
--             local percent = 100;
--             if type(current) == "number" and type(maximum) == "number" then
--                 percent = tonumber(string.format("%.1f", (current / maximum) * 100));
--             end
--             local atlas = string.format("transmog-nav-slot-%s", inventorySlots[i]:sub(1, (#inventorySlots[i]-4)))
--             self.durabilityInfo[i] = {
--                 atlas = atlas,
--                 itemLink = itemLink,
--                 currentDurability = current or 1,
--                 maximumDurability = maximum or 1,
--                 percentDurability = percent or 1,
--             }
--             currentDurability = currentDurability + (current or 0);
--             maximumDurability = maximumDurability + (maximum or 0);
--         else
--             self.durabilityInfo[i] = {
--                 itemLink = "-",
--                 currentDurability = 1,
--                 maximumDurability = 1,
--                 percentDurability = 1,
--             }
--         end
--     end

--     table.sort(self.durabilityInfo, function(a,b)
--         return a.percentDurability > b.percentDurability;
--     end)

--     local durability = tonumber(string.format("%.1f", (currentDurability / maximumDurability) * 100));

--     self.openDurabilityButton:SetText(string.format("%s %s %%", CreateAtlasMarkup("vehicle-hammergold-3", 18, 18), durability))

-- end


-- function SamsUiTopBarMixin:UpdateCurrency()

--     if type(self.nameRealm) ~= "string" then
--         return;
--     end

--     local gold = GetMoney();

--     self.sessionInfo.profit = GetMoney() - (sui.db:GetCharacterInfo(self.nameRealm, "initialLoginGold") or 0);

--     self.openCurrencyButton:SetText(GetCoinTextureString(gold))

--     sui.db:InsertOrUpdateCharacterInfo(self.nameRealm, "gold", gold)

-- end


-- function SamsUiTopBarMixin:OpenMinimapButtonsMenu()

--     self:MoveAllLibMinimapIcons()

--     if self.minimapButtonsContainer:IsVisible() then
--         return;
--     end

--     if self.minimapButtonsCloseDelayTicker then
--         self.minimapButtonsCloseDelayTicker:Cancel()
--     end

--     self.minimapButtonsContainer:Show()
--     self.minimapButtonsContainer.anim:Play()

--     self.minimapButtonsCloseDelayTicker = C_Timer.NewTicker(self.dropdownMenuCloseDelay, function()
--         if self.openMinimapButtonsButton:IsMouseOver() == false and self.minimapButtonsContainer:IsMouseOver() == false then
--             local isHovered = false;
--             for k, button in ipairs(self.minimapButtons) do
--                 if button and button:IsMouseOver() then
--                     isHovered = true;
--                 end
--             end
--             if isHovered == true then
--                 return;
--             end
--             self.minimapButtonsContainer:Hide()
--             self.minimapButtonsCloseDelayTicker:Cancel()
--         end
--     end)

-- end


-- function SamsUiTopBarMixin:SetupSpellBook()

--     --SpellBook:Set
-- end




-- function SamsUiTopBarMixin:MoveAllLibMinimapIcons()

--     self.minimapButtons = {}

--     local lib = LibStub("LibDBIcon-1.0")

--     local buttonList = lib:GetButtonList()
    
--     local buttons = {}
--     local buttonNames = {}

--     for k, name in ipairs(buttonList) do
--         buttons[k] = lib:GetMinimapButton(name)
--         buttonNames[k] = name;
--     end

--     if _G["ATT-Classic-Minimap"] then
--         table.insert(buttons, _G["ATT-Classic-Minimap"])
--     end

--     for k, sui in ipairs(self.suisInstalled) do
--         if _G["Lib_GPI_Minimap_"..sui.name] then
--             table.insert(buttons, _G["Lib_GPI_Minimap_"..sui.name])
--         end
--     end

--     local NUM_ICONS_PER_ROWS = sui.db:GetConfigValue("numberMinimapIconsPerRow") or 6;
--     local rowsRequired = math.ceil(#buttons / NUM_ICONS_PER_ROWS)
--     local k = 1;
--     local xPos, yPos = 0, 0;
--     local maxButtonHeight = 0;

--     for rowIndex = 1, rowsRequired do

--         local newRow = true;

--         for i = 1, NUM_ICONS_PER_ROWS do
--             local buttonIndex = i + ((rowIndex - 1) * NUM_ICONS_PER_ROWS)
--             if buttons[buttonIndex] then
--                 local button = buttons[buttonIndex]
                
--                 button:ClearAllPoints()
--                 button:SetParent(self.minimapButtonsContainer)
--                 button:Show()

--                 if button:GetHeight() > maxButtonHeight then
--                     maxButtonHeight = button:GetHeight()
--                 end

--                 xPos = xPos + maxButtonHeight;

--                 button:SetPoint("CENTER", self.minimapButtonsContainer, "TOPLEFT", xPos, -yPos)

                
--                 if newRow == true then
--                     button:SetPoint("TOPLEFT", self.minimapButtonsContainer, "TOPLEFT", 0, -yPos)
--                     newRow = false;
--                 else
--                     button:SetPoint("LEFT", self.minimapButtons[k-1], "RIGHT", 4, 0)
--                 end


--                 if buttonNames[k] then
--                     lib:Lock(buttonNames[k])
--                 else
--                     button:SetScript("OnDragStart", nil)
--                     button:SetScript("OnDragStop", nil)
--                     button:SetMovable(false)
--                 end
--                 self.minimapButtons[k] = button

--                 self.minimapButtonsContainer:SetWidth(xPos)

--                 k = k + 1;
--             end
--         end

--         yPos = yPos + maxButtonHeight;
--         xPos = 0;

--         self.minimapButtonsContainer:SetHeight(yPos)
--     end

--     self.minimapButtonsContainer:SetWidth(maxButtonHeight * NUM_ICONS_PER_ROWS)


-- end



-- function SamsUiTopBarMixin:OpenMainMenu()

--     if self.mainMenuContainerCloseDelayTicker then
--         self.mainMenuContainerCloseDelayTicker:Cancel()
--     end

--     for k, item in ipairs(self.mainMenuContainer.keys) do

--         if not self.mainMenuContainer.buttons[k] then
--             local button = CreateFrame("BUTTON", nil, self.mainMenuContainer, "SamsUiTopBarMainMenuButton")
--             button:SetPoint("TOP", 0, (k-1)*-41)
--             button:SetSize(200, 40)
--             button:SetText(item)

--             -- if item == "Hearthstone" then
--             --     button:SetScript("OnShow", function()
--             --         local hsl = GetBindLocation()
--             --         button:SetText(hsl)
--             --         button.anim:Play()
--             --     end)
--             -- end

--             if self.mainMenuContainer.menu[item].macro then
--                 button:SetAttribute("type1", "macro")
--                 button:SetAttribute("macrotext1", string.format([[%s]], self.mainMenuContainer.menu[item].macro))
--                 button.func = nil;
--             else
--                 button.func = self.mainMenuContainer.menu[item].func;

--             end

--             button:SetIconAtlas(self.mainMenuContainer.menu[item].atlas)
            
--             button.anim.fadeIn:SetStartDelay(k/25)

--             self.mainMenuContainer.buttons[k] = button;

--             self.mainMenuContainer:SetSize(200, k*28)

--         end
--     end

--     for _, button in ipairs(self.mainMenuContainer.buttons) do
--         button:Show()
--     end

--     self.mainMenuContainer:Show()

--     self.mainMenuContainerCloseDelayTicker = C_Timer.NewTicker(self.dropdownMenuCloseDelay, function()
--         if self.mainMenuContainer:IsMouseOver() == false and self.openMainMenuButton:IsMouseOver() == false then
--             self.mainMenuContainer:Hide()
--             self.mainMenuContainerCloseDelayTicker:Cancel()
--         end
--     end)
-- end
