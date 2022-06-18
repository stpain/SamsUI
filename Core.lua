--[[

]]

local name, sui = ...;

sui.loaded = false;

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
    -- ["Cooking"] = 185,
    -- ["First Aid"] = -1,
    -- ["Fishing"] = -1,

    --mining
    ["Smelting"] = -1,
}

---print a message to the chat frame
---@param msg string the message to print
function sui.print(msg)
    print(string.format("[|cffcc0000%s|r] %s", name, msg))
end


--a core frame to act as an event listener
sui.e = CreateFrame("FRAME");
sui.e:RegisterEvent("ADDON_LOADED");
sui.e:RegisterEvent("PLAYER_ENTERING_WORLD");
sui.e:RegisterEvent("PLAYER_LEAVING_WORLD");
sui.e:RegisterEvent("SKILL_LINES_CHANGED");
sui.e:RegisterEvent("PLAYER_MONEY");
sui.e:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE");
sui.e:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN");
sui.e:RegisterEvent("QUEST_TURNED_IN");
sui.e:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
sui.e:RegisterEvent("UNIT_AURA");
sui.e:RegisterEvent("MERCHANT_CLOSED");

function sui:ADDON_LOADED(...)

    self.e:UnregisterEvent("ADDON_LOADED");

    Mixin(sui, CallbackRegistryMixin)
    sui:GenerateCallbackEvents({
        "Database_OnDatabaseInitialized",
        "Database_OnCharacterRegistered",
    });
    CallbackRegistryMixin.OnLoad(sui);

    sui:RegisterCallback("Database_OnDatabaseInitialized", self.OnDatabaseInitialized, self);
    sui:RegisterCallback("Database_OnCharacterRegistered", self.OnCharacterRegistered, self);

    sui.db:Init();

end

function sui:PLAYER_ENTERING_WORLD(...)

    C_CVar.RegisterCVar("fstack_showhighlight", "1")

    self.e:UnregisterEvent("PLAYER_ENTERING_WORLD");

    local name, realm = UnitFullName("player");
    if realm == nil or realm == "" then
        realm = GetNormalizedRealmName();
    end
    local nameRealm = string.format("%s-%s", name, realm);

    local _, class = UnitClass("player");
    local _, race = UnitRace("player");
    local gender = UnitSex("player") == 2 and "Male" or "Female";

    sui.db:RegisterCharacter(nameRealm, class, race, gender);

    local initialLogin, reload = ...
    if initialLogin == true then

        local now = time();
        local gold = GetMoney();

        sui.db:InsertOrUpdateCharacterInfo(nameRealm, "initialLoginGold", gold)

        sui.db:InsertOrUpdateCharacterInfo(nameRealm, "initialLoginTime", now)

        sui.sessionInfo = {
            questsCompleted = {},
            mobsKilled = 0,
            mobXpReward = 0,
            initialLoginTime = now,
            profit = 0,
            debits = 0,
            credits = 0,
            balance = gold,
            reputations = {},
        }

        sui.db:InsertOrUpdateCharacterInfo(nameRealm, "sessionInfo", sui.sessionInfo)

    else

        sui.sessionInfo = sui.db:GetCharacterInfo(nameRealm, "sessionInfo")
    end

    sui.characterKey = nameRealm;

    self:ScanSpellbook()

    if not TradeSkillFrame then
        LoadAddOn("Blizzard_TradeSkillUI")
    end

end

function sui:PLAYER_LEAVING_WORLD()
    sui.db:InsertOrUpdateCharacterInfo(sui.characterKey, "sessionInfo", sui.sessionInfo)
end

function sui:SKILL_LINES_CHANGED()
    self:ScanCharacterSkills()
    self:ScanSpellbook()
end

function sui:PLAYER_MONEY()
    --skip vendoring until merchant closed fires due to multi vendoring addons
    if not MerchantFrame:IsVisible() then
        self:ScanCharacterGold()
    end
end

function sui:MERCHANT_CLOSED()
    self:ScanCharacterGold()
end

function sui:UPDATE_INVENTORY_DURABILITY()
    self:ScanCharacterDurability()
end

function sui:CHAT_MSG_COMBAT_FACTION_CHANGE(...)

    local info = ...
    local rep = FACTION_STANDING_INCREASED:gsub("%%s", "(.+)"):gsub("%%d", "(.+)")
    local faction, gain = string.match(info, rep)
    
    gain = tonumber(gain);

    if not self.sessionInfo.reputations then
        self.sessionInfo.reputations = {}
    end

    if self.sessionInfo.reputations[faction] then
        self.sessionInfo.reputations[faction] = self.sessionInfo.reputations[faction] + gain;
    else
        self.sessionInfo.reputations[faction] = gain
    end

end

function sui:COMBAT_LOG_EVENT_UNFILTERED(...)
    
    local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName = CombatLogGetCurrentEventInfo()

    if subevent == "UNIT_DIED" then
        C_Timer.After(0.5, function()
            
            if CanLootUnit(destGUID) then
                if not self.sessionInfo then
                    self.sessionInfo = {
                        mobsKilled = 0,
                    }
                end
                self.sessionInfo.mobsKilled = self.sessionInfo.mobsKilled + 1;
            end
        end)
    end

end

function sui:QUEST_TURNED_IN(...)
    local questID, xpReward = ...

    if not self.sessionInfo then
        self.sessionInfo = {
            questsCompleted = {},
        }
    end

    table.insert(self.sessionInfo.questsCompleted, {
        questID = questID,
        xpReward = xpReward or 0,
    })
end

function sui:CHAT_MSG_COMBAT_XP_GAIN(...)
    local text = ...

    if text:find("dies") then

        if not self.sessionInfo then
            self.sessionInfo = {
                mobsKilled = 0,
                mobXpReward = 0,
            }
        end

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

function sui:UNIT_AURA()
    BuffFrame:ClearAllPoints()
    BuffFrame:SetPoint("TOPRIGHT", MinimapCluster, "LEFT", -10, 0)
end


sui.e:SetScript("OnEvent", function(self, event, ...)

    if event == "ADDON_LOADED" then
        if sui[event] then
            sui[event](sui, ...);
        end

    elseif event ~= "PLAYER_ENTERING_WORLD" then
        if sui[event] then
            sui[event](sui, ...);
        end

    else
        if sui.loaded == false then
            return;
        else
            if sui[event] then
                sui[event](sui, ...);
            end
        end
    end

end)



local factionLevels = {
    [0] = -21000,
    [1] = -36000, --hated
    [2] = -3000, --hostile
    [3] = -3000, --unfriendly
    [4] = 3000, --neutral
    [5] = 6000, --friendly
    [6] = 12000, --honoured
    [7] = 21000, --revered
    [8] = 1000, --exalted
}

function sui:OnDatabaseInitialized()
    self.loaded = true;

    SamsUiTopBar:Init();
    self:ModifyMinimap()
    self:ModifyGameMenu()

    for i = 1, 15 do
        local barName = "ReputationBar"..i

        _G[barName]:HookScript("OnLeave", function(self)
            GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
        end)
        _G[barName]:HookScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

            local faction = _G[barName.."FactionName"]:GetText()
            GameTooltip:AddLine(faction)

            for nameRealm, character in sui.db:GetCharacters() do
                if character.reputations and character.reputations[faction] then
                    local standingId = character.reputations[faction].standingId;
                    local totalRep = character.reputations[faction].totalRep;
                    local rep = totalRep;
                    if totalRep >= 0 then
                        for standing = (standingId - 1), 4, -1 do
                            rep = rep - factionLevels[standing]
                        end

                    else
                        for standing = 4, (standingId + 1), -1 do
                            rep = rep + factionLevels[standing]
                        end
                    end
                    GameTooltip:AddDoubleLine(nameRealm, string.format("|cffffffff%s/%s|r", rep, factionLevels[standingId]))
                end
            end

            GameTooltip:Show()
        end)
    end
end

function sui:OnCharacterRegistered()
    
    SkillFrame:HookScript("OnShow", function()
        sui:ScanCharacterSkills()
    end)
    
    
    ReputationFrame:HookScript("OnShow", function()
        sui:ScanCharacterReputations()
    end)

    sui.db:InsertOrUpdateCharacterInfo(sui.characterKey, "currentGold", GetMoney())

    self:ScanCharacterSkills()
    self:ScanCharacterReputations()

    C_Timer.After(1, function()
        sui.db:SetVDT()
    end)
end

function sui:ScanCharacterGold()
    local newBalance = GetMoney();
    local transactionValue = newBalance - sui.sessionInfo.balance;
    if transactionValue > 0 then
        sui.sessionInfo.credits = sui.sessionInfo.credits + transactionValue
    elseif transactionValue < 0 then
        sui.sessionInfo.debits = sui.sessionInfo.debits - transactionValue
    end
    sui.sessionInfo.balance = newBalance;

    sui.db:InsertOrUpdateCharacterInfo(sui.characterKey, "currentGold", GetMoney())
end

function sui:ScanCharacterSkills()

    local skills = {};

    local name, isHeader, isExpanded, rank, maxRank, desc;
    local header;
    for i = 1, GetNumSkillLines() do
        
        name, isHeader, isExpanded, rank, _, _, maxRank, _, _, _, _, _, desc = GetSkillLineInfo(i);

        if name == "Professions" or name == "Secondary Skills" or name == "Weapon Skills" then
            if isHeader == 1 then
                header = name;

                if not skills[header] then
                    skills[header] = {};
                end
            end
        end

        if header == "Professions" or header == "Secondary Skills" or header == "Weapon Skills" then
            if header == "Professions" then
                if tradeskillNamesToIDs[name] then
                    skills[header][name] = {
                        rank = rank,
                        maxRank = maxRank,
                    }
                end
            else
                skills[header][name] = {
                    rank = rank,
                    maxRank = maxRank,
                }
            end
        end
    end

    sui.db:InsertOrUpdateCharacterInfo(sui.characterKey, "skills", skills)

end

function sui:ScanCharacterReputations()

    local factions = {};
    local reputations = {};

    local numFactions = GetNumFactions()
    local factionIndex = 1
    while (factionIndex <= numFactions) do
        local name, description, standingId, bottomValue, topValue, earnedValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canBeLFGBonus = GetFactionInfo(factionIndex)
        
        if not factions[name] then
            factions[name] = description;
        end
        
        if isHeader and isCollapsed then
            ExpandFactionHeader(factionIndex)
            numFactions = GetNumFactions()
        end
        if hasRep or not isHeader then
            reputations[name] = {
                standingId = standingId,
                totalRep = earnedValue,
            }
        end
        factionIndex = factionIndex + 1
    end

    sui.db:InsertGameInfo("factions", factions);
    sui.db:InsertOrUpdateCharacterInfo(sui.characterKey, "reputations", reputations)

end

function sui:ScanCharacterDurability()
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

    self.durabilityInfo = {};
    local itemLinksProcessed = {};

    local currentDurability, maximumDurability = 0, 0;
    local slotId, itemLink;
    for i = 1, 21 do
        slotId = GetInventorySlotInfo(inventorySlots[i])
        if slotId then
            itemLink = GetInventoryItemLink("player", slotId)
            if itemLink and not itemLinksProcessed[itemLink] then
                local current, maximum = GetInventoryItemDurability(i)
                local percent = 100;
                if type(current) == "number" and type(maximum) == "number" then
                    percent = tonumber(string.format("%.1f", (current / maximum) * 100));
                end
                local icon = GetItemIcon(GetItemInfoInstant(itemLink))
                local texStr = "";
                if icon then
                    texStr = string.format("|T%s:20|t", icon)
                end
                local atlas = string.format("transmog-nav-slot-%s", inventorySlots[i]:sub(1, (#inventorySlots[i]-4)))
                table.insert(self.durabilityInfo, {
                    atlas = texStr,
                    itemLink = itemLink,
                    currentDurability = current or 1,
                    maximumDurability = maximum or 1,
                    percentDurability = percent or 1,
                });
                itemLinksProcessed[itemLink] = true;
                currentDurability = currentDurability + (current or 0);
                maximumDurability = maximumDurability + (maximum or 0);
            else
                -- self.durabilityInfo[i] = {
                --     itemLink = "-",
                --     currentDurability = 1,
                --     maximumDurability = 1,
                --     percentDurability = 1,
                -- }
            end
        end
    end

    table.sort(self.durabilityInfo, function(a,b)
        if a.percentDurability == b.percentDurability then
            return a.itemLink < b.itemLink;
        else
            return a.percentDurability > b.percentDurability;
        end
    end)
end

function sui:GetCharacterXP()

    local xp, xpMax = UnitXP("player"), UnitXPMax("player")
    local xpPer = tonumber(string.format("%.1f", (xp/xpMax)*100))
    local xpRested = GetXPExhaustion()
    self.openXpButton:SetText(string.format("%s %s %%", CreateAtlasMarkup("GarrMission_CurrencyIcon-Xp", 32, 32), xpPer))

    sui.db:InsertOrUpdateCharacterInfo(self.nameRealm, "xp", xp)
    sui.db:InsertOrUpdateCharacterInfo(self.nameRealm, "xpMax", xpMax)
    sui.db:InsertOrUpdateCharacterInfo(self.nameRealm, "xpRested", xpRested)

    return xp, xpPer, xpMax, xpRested;
end

function sui:ScanSpellbook()

     if not self.characterKey then
         return;
     end

    local ignore = {
        ["Skinning"] = true,
        ["Herbalism"] = true,
    }

    local profSpecCooldowns = {
        ["Tailoring"] = {
            26751, -- mooncloth
        },
    };

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
                sui.db:InsertOrUpdateCharacterInfo(self.characterKey, "profession1", spellName)

                --if the prof isnt somethign with a ui then ignore it
                if ignore[spellName] then
                    return;
                end

                --set the icon
                --self.openProf1Button.icon:SetAtlas(string.format("Mobile-%s", (spellName ~= "Engineering" and spellName or "Enginnering")))

                --if its mining then swap the spell to cast smelting
                if spellName == "Mining" then
                    spellName = "Smelting"
                end

                --set the button macro
                --self.openProf1Button:SetAttribute("macrotext1", string.format("/cast %s", spellName))

                local profTooltip = spellName;
                if profSpecCooldowns[spellName] then
                    for k, spellID in ipairs(profSpecCooldowns[spellName]) do
                        local start, dur, ending = GetSpellCooldown(spellID)
                        if start > 0 and dur > 0 then
                            profTooltip = string.format("%s\n\n[|cffffffff%s|r] %s", spellName, GetSpellInfo(spellID), SecondsToTime(start + dur - GetTime()))
                        end
                    end
                end

                --self.openProf1Button.tooltipText = profTooltip;
                --self.openProf1Button:Show()
                
                prof1 = true;

            else
                if prof2 == false then

                    sui.db:InsertOrUpdateCharacterInfo(self.characterKey, "profession2", spellName)

                    if ignore[spellName] then
                        return;
                    end

                    --self.openProf2Button.icon:SetAtlas(string.format("Mobile-%s", (spellName ~= "Engineering" and spellName or "Enginnering")))

                    if spellName == "Mining" then
                        spellName = "Smelting"
                    end

                    --self.openProf2Button:SetAttribute("macrotext1", string.format("/cast %s", spellName))

                    local profTooltip = spellName;
                    if profSpecCooldowns[spellName] then
                        for k, spellID in ipairs(profSpecCooldowns[spellName]) do
                            local start, dur, ending = GetSpellCooldown(spellID)
                            if start > 0 and dur > 0 then
                                profTooltip = string.format("%s\n\n[|cffffffff%s|r] %s", spellName, GetSpellInfo(spellID), SecondsToTime(start + dur - GetTime()))
                            end
                        end
                    end

                    --self.openProf2Button.tooltipText = profTooltip;
                    --self.openProf2Button:Show()

                    prof2 = true;
                end
            end 

        end
    end

    --if no data found then set to false
    if prof1 == false then
        sui.db:InsertOrUpdateCharacterInfo(self.nameRealm, "profession1", false)
    end
    if prof2 == false then
        sui.db:InsertOrUpdateCharacterInfo(self.nameRealm, "profession2", false)
    end

end

function sui:ModifyMinimap()
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

    UIWidgetTopCenterContainerFrame:ClearAllPoints()
    UIWidgetTopCenterContainerFrame:SetPoint("TOP", MinimapCluster, "BOTTOM", 9, -10)

    UIWidgetBelowMinimapContainerFrame:SetPoint("TOP", UIWidgetTopCenterContainerFrame, "BOTTOM", 0, -10)

    BuffFrame:ClearAllPoints()
    BuffFrame:SetPoint("TOPRIGHT", MinimapCluster, "LEFT", -10, 0)
end


function sui:ModifyGameMenu()

    GameMenuFrameHeader:Hide()
    

    local f = GameMenuFrame;

    for i = 1, f:GetNumRegions() do
        local region = select(i, f:GetRegions())
        if (region:GetObjectType() == 'FontString')or (region:GetObjectType() == "Texture") then
            region:Hide()
        end
    end

    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", SamsUiTopBar, "BOTTOMLEFT", 1, 5)

    f:SetSize(600, 400)

    SamsUiStartMenu:SetParent(f)
    SamsUiStartMenu:SetAllPoints()

    local menuButtons = {
        "Help",
        "Options",
        "UIOptions",
        "Keybindings",
        "Macros",
        "Addons",
        "Logout",
        "Quit",
        "Continue",
    }

    for k, v in ipairs(menuButtons) do        
        local button = _G["GameMenuButton"..v]
        button:ClearAllPoints()
        button.Left:Hide()
        button.Right:Hide()
        button.Middle:Hide()
        button:SetHighlightTexture(nil)
        button:Hide()
    end


    SamsUiStartMenu.quickPane.exitGame:SetAttribute("macrotext1", [[/click GameMenuButtonQuit]])
    SamsUiStartMenu.quickPane.logout:SetAttribute("macrotext1", [[/click GameMenuButtonLogout]])
    SamsUiStartMenu.quickPane.continue:SetAttribute("macrotext1", [[/click GameMenuButtonContinue]])


    SamsUiStartMenu.menuList:SetScript("OnShow", function()

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
    
    
        local lib = LibStub("LibDBIcon-1.0")
    
        local buttonList = lib:GetButtonList()
        
        local buttons = {}
    
        for k, name in ipairs(buttonList) do
            buttons[k] = {
                button = lib:GetMinimapButton(name),
                name = name,
            }
            lib:Unlock(name)
            lib:Hide(name)
        end
    
        if _G["ATT-Classic-Minimap"] then
            table.insert(buttons, {
                button = _G["ATT-Classic-Minimap"],
                name = "ATT",
            })
        end
    
        for k, addon in ipairs(self.addonsInstalled) do
            if _G["Lib_GPI_Minimap_"..addon.name] then
                table.insert(buttons, {
                    button = _G["Lib_GPI_Minimap_"..addon.name],
                    name = addon.name,
                })
            end
        end

        local prof1 = sui.db:GetCharacterInfo(sui.characterKey, "profession1")
        if prof1 then
            table.insert(buttons, {
                name = prof1,
                iconAtlas = string.format("Mobile-%s", prof1),
                macrotext1 = string.format([[
/cast %s
/run GameMenuFrame:Hide()
]], prof1)
            })
        end

        local prof2 = sui.db:GetCharacterInfo(sui.characterKey, "profession2")
        if prof2 then
            table.insert(buttons, {
                name = prof2,
                iconAtlas = string.format("Mobile-%s", prof2),
                macrotext1 = string.format([[
/cast %s
/run GameMenuFrame:Hide()
]], prof2)
            })
        end

        local skills = sui.db:GetCharacterInfo(sui.characterKey, "skills")
        if skills and skills["Secondary Skills"] and skills["Secondary Skills"]["Cooking"] then
            table.insert(buttons, {
                name = "Cooking",
                iconAtlas = "Mobile-Cooking",
                macrotext1 = [[
/cast Cooking
/run GameMenuFrame:Hide()
]],
            })
        end
        if skills and skills["Secondary Skills"] and skills["Secondary Skills"]["First Aid"] then
            table.insert(buttons, {
                name = "First Aid",
                iconAtlas = "Mobile-FirstAid",
                macrotext1 = [[
/cast First Aid
/run GameMenuFrame:Hide()
]],
            })
        end
    
        table.sort(buttons, function(a, b)
            return a.name < b.name;
        end)
    
        SamsUiStartMenu.menuList.DataProvider:Flush()
        for k, addon in ipairs(buttons) do
            SamsUiStartMenu.menuList.DataProvider:Insert(addon)
        end

    end)


end