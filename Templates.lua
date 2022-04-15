

local name, addon = ...


local Util = addon.Util;


--[[
    the buttons used in the main menu from the top bar
]]
SamsUiTopBarMainMenuButtonMixin = {}

function SamsUiTopBarMainMenuButtonMixin:SetText(text)
    self.text:SetText(text)
end

function SamsUiTopBarMainMenuButtonMixin:SetIconAtlas(atlas)
    self.icon:SetAtlas(atlas)
end

function SamsUiTopBarMainMenuButtonMixin:OnLoad()
    self:SetAlpha(0)
end

function SamsUiTopBarMainMenuButtonMixin:OnShow()
    self.anim:Play()
end

function SamsUiTopBarMainMenuButtonMixin:OnHide()
    self:SetAlpha(0)
end

function SamsUiTopBarMainMenuButtonMixin:OnMouseDown()
    if self.func then
        self.func()
    end
end









--[[
    an insecure button template used for dropdown menus where the player can use an item listed
]]
SamsUiTopBarSecureMacroContainerMenuButtonMixin = {}

function SamsUiTopBarSecureMacroContainerMenuButtonMixin:ClearItem()

    self.item = nil;
    self.items = nil;
    self.func = nil;

    self.link:SetText(" ")
    self.count:SetText(" ")
    self.icon:SetTexture(" ")

    self:SetAttribute("macrotext1", "/run print('no item set for button')")
    self:SetAttribute("macrotext2", "/run print('no item set for button')")

end


function SamsUiTopBarSecureMacroContainerMenuButtonMixin:SetText(text)

    self.link:SetText(text)
    self.count:SetText("")
    self.icon:SetTexture("")

end


function SamsUiTopBarSecureMacroContainerMenuButtonMixin:SetItem(item)

    self.item = item;

    self.link:SetText(item.link)
    self.count:SetText(item.count)
    self.icon:SetTexture(item.icon)

    local _, itemType, itemSubType, itemEquipLoc, icon, itemClassID, itemSubClassID = GetItemInfoInstant(item.link)

    --consumables
    if itemClassID == 0 then
        self:SetAttribute("macrotext1", string.format("/use %s", item.name))
        
    --equipment
    elseif itemClassID == 2 or itemClassID == 4 then
        self:SetAttribute("macrotext2", string.format("/equip %s", item.name))
        
    --recipes
    elseif itemClassID == 9 then
        self:SetAttribute("macrotext2", string.format("/use %s", item.name))
        
    --quest items
    elseif itemClassID == 12 then

        if itemEquipLoc:find("INVTYPE") then
            self:SetAttribute("macrotext2", string.format("/equip %s", item.name))

        else
            self:SetAttribute("macrotext2", string.format("/use %s", item.name))
            
        end
    end

    
end


function SamsUiTopBarSecureMacroContainerMenuButtonMixin:OnShow()
    self.anim:Play()
end

function SamsUiTopBarSecureMacroContainerMenuButtonMixin:OnHide()
    self:SetAlpha(0)
end

function SamsUiTopBarSecureMacroContainerMenuButtonMixin:OnEnter()

    if not self.tooltipAnchor then
        self.tooltipAnchor = "ANCHOR_TOP"
    end
    
    if self.itemLink then
        GameTooltip:SetOwner(self, self.tooltipAnchor)
        GameTooltip:SetHyperlink(self.itemLink)
        GameTooltip:Show()
    end

    if self.func then
        self.func()
    end
end

function SamsUiTopBarSecureMacroContainerMenuButtonMixin:OnLeave()
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
end

function SamsUiTopBarSecureMacroContainerMenuButtonMixin:OnLoad()
    --self:SetAlpha(0)
end

function SamsUiTopBarSecureMacroContainerMenuButtonMixin:OnMouseUp()

    if self.func then
        self.func()
    end

    self.count:SetText(self.item.count)
end








--[[
    button used for the top bar for dropdown menus ???
]]
SamsUiTopBarGoldRingButtonMixin = {}

function SamsUiTopBarGoldRingButtonMixin:OnLoad()

end

function SamsUiTopBarGoldRingButtonMixin:OnShow()

end

function SamsUiTopBarGoldRingButtonMixin:OnEnter()

    if self.tooltipText then
        GameTooltip:SetOwner(self, "LEFT")
        GameTooltip:AddLine(self.tooltipText)
        GameTooltip:Show()
    end
end

function SamsUiTopBarGoldRingButtonMixin:OnLeave()
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
end

function SamsUiTopBarGoldRingButtonMixin:SetText(text)
    self.text:SetText(text)
end








--[[
    mixin for an inset style button used to show info
]]
SamsUiTopBarInsetButtonMixin = {}

function SamsUiTopBarInsetButtonMixin:OnLoad()

end

function SamsUiTopBarInsetButtonMixin:OnShow()

end

function SamsUiTopBarInsetButtonMixin:OnLeave()
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
end

function SamsUiTopBarInsetButtonMixin:SetText(text)
    self.text:SetText(text)
end








--[[
    the menu buttons for the config panel menu
]]
SamsUiConfigPanelMenuButtonMixin = {}
function SamsUiConfigPanelMenuButtonMixin:OnLoad()

end


function SamsUiConfigPanelMenuButtonMixin:OnClick()

    if self.func then
        self.func()
    end
end


function SamsUiConfigPanelMenuButtonMixin:SetDataBinding(binding, height)

    self:SetHeight(height)

    if binding.panelName then
        self.text:SetText(binding.panelName)
    end

    self.func = binding.func;
end


function SamsUiConfigPanelMenuButtonMixin:ResetDataBinding()

end






---this is the listview template mixin
SamsUiListviewMixin = CreateFromMixins(CallbackRegistryMixin);
SamsUiListviewMixin:GenerateCallbackEvents(
    {
        "OnSelectionChanged",
    }
);

function SamsUiListviewMixin:OnLoad()

    ---these values are set in the xml frames KeyValues, it allows us to reuse code by setting listview item values in xml
    -- if type(self.itemTemplate) ~= "string" then
    --     error("self.itemTemplate name not set or not of type string")
    --     return;
    -- end
    -- if type(self.frameType) ~= "string" then
    --     error("self.frameType not set or not of type string")
    --     return;
    -- end
    -- if type(self.elementHeight) ~= "number" then
    --     error("self.elementHeight not set or not of type number")
    --     return;
    -- end

    CallbackRegistryMixin.OnLoad(self)

    self.DataProvider = CreateDataProvider();
    self.scrollView = CreateScrollBoxListLinearView();
    self.scrollView:SetDataProvider(self.DataProvider);

    ---height is defined in the xml keyValues
    if type(self.elementHeight) == "number" then
        local height = self.elementHeight;
        self.scrollView:SetElementExtent(height);

    else
        self.scrollView:SetElementExtent(24);
    end

    self.scrollView:SetElementInitializer(self.frameType, self.itemTemplate, GenerateClosure(self.OnElementInitialize, self));
    self.scrollView:SetElementResetter(GenerateClosure(self.OnElementReset, self));

    self.selectionBehavior = ScrollUtil.AddSelectionBehavior(self.scrollView);
    self.selectionBehavior:RegisterCallback("OnSelectionChanged", self.OnElementSelectionChanged, self);

    self.scrollView:SetPadding(5, 5, 5, 5, 1);

    ScrollUtil.InitScrollBoxListWithScrollBar(self.scrollBox, self.scrollBar, self.scrollView);

    local anchorsWithBar = {
        CreateAnchor("TOPLEFT", self, "TOPLEFT", 4, -4),
        CreateAnchor("BOTTOMRIGHT", self.scrollBar, "BOTTOMLEFT", 0, 4),
    };
    local anchorsWithoutBar = {
        CreateAnchor("TOPLEFT", self, "TOPLEFT", 4, -4),
        CreateAnchor("BOTTOMRIGHT", self, "BOTTOMRIGHT", -4, 4),
    };
    ScrollUtil.AddManagedScrollBarVisibilityBehavior(self.scrollBox, self.scrollBar, anchorsWithBar, anchorsWithoutBar);
end

function SamsUiListviewMixin:OnElementInitialize(element, elementData, isNew)
    if isNew then
        element:OnLoad();
    end

    local height = self.elementHeight;

    element:SetDataBinding(elementData, height);
    --element:RegisterCallback("OnMouseDown", self.OnElementClicked, self);

end

function SamsUiListviewMixin:OnElementReset(element)
    --element:UnregisterCallback("OnMouseDown", self);

    element:ResetDataBinding()
end

function SamsUiListviewMixin:OnElementClicked(element)
    self.selectionBehavior:Select(element);
end


function SamsUiListviewMixin:OnElementSelectionChanged(elementData, selected)
    --DevTools_Dump({ self.selectionBehavior:GetSelectedElementData() })

    local element = self.scrollView:FindFrame(elementData);

    if element then
        element:SetSelected(selected);
    end

    if selected then
        self:TriggerEvent("OnSelectionChanged", elementData, selected);
    end
end







--[[
    the database view row template used in the config panel 
]]
SamsUiConfigPanelDatabaseControlListviewItemTemplateMixin = {}
function SamsUiConfigPanelDatabaseControlListviewItemTemplateMixin:OnLoad()

end


function SamsUiConfigPanelDatabaseControlListviewItemTemplateMixin:SetDataBinding(binding, height)

    self:SetHeight(height)

    local character = binding.character;

    self.name:SetText(RAID_CLASS_COLORS[character.class]:WrapTextInColorCode(binding.name))
    self.class:SetText(character.class)
    self.level:SetText(character.level)

    if type(character.xp) == "number" and type(character.xpMax) == "number" and type(character.xpRested) == "number" then
        
        local curentLevelXp = tonumber(string.format("%.1f", (character.xp / character.xpMax) * 100))
        local currentRestedXp = tonumber(string.format("%.1f", (character.xpRested / character.xpMax) * 100))
        self.xp:SetText(string.format("%s%% [%s%%]", curentLevelXp, currentRestedXp))

    else
        self.xp:SetText("-")
    end

    local tradeskillInfo = "";
    if character.profession1 then
        if character.profession1 == "Engineering" then
            tradeskillInfo = CreateAtlasMarkup("Mobile-Enginnering", 20, 20)
        else
            tradeskillInfo = CreateAtlasMarkup(string.format("Mobile-%s", character.profession1), 20, 20)
        end
    end
    tradeskillInfo = tradeskillInfo.." "
    if character.profession2 then
        if character.profession2 == "Engineering" then
            tradeskillInfo = tradeskillInfo..CreateAtlasMarkup("Mobile-Enginnering", 20, 20)
        else
            tradeskillInfo = tradeskillInfo..CreateAtlasMarkup(string.format("Mobile-%s", character.profession2), 20, 20)
        end
    end
    self.tradeskills:SetText(tradeskillInfo)

    self.delete:SetScript("OnClick", function()
        binding.deleteFunc(nil, binding.name)
    end)
end


function SamsUiConfigPanelDatabaseControlListviewItemTemplateMixin:ResetDataBinding()

end








SamsUiMerchantFrameCharacterItemsListviewItemTemplateMixin = {}

function SamsUiMerchantFrameCharacterItemsListviewItemTemplateMixin:OnLoad()

end

function SamsUiMerchantFrameCharacterItemsListviewItemTemplateMixin:OnLeave()
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
end

function SamsUiMerchantFrameCharacterItemsListviewItemTemplateMixin:OnEnter()

    if self.itemLink then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(self.itemLink)
        GameTooltip:Show()
    end
end

function SamsUiMerchantFrameCharacterItemsListviewItemTemplateMixin:SetDataBinding(binding, height)

    self:SetHeight(height)

    if binding.disabled == true then
        self:SetAlpha(0.5)
        self:EnableMouse(false)
    else
        self:SetAlpha(1)
        self:EnableMouse(true)
    end


    if binding.link then
        self.itemLink = binding.link;
        self.icon:SetTexture(binding.icon)
        self.icon:SetSize(18, 18)
        self.icon:ClearAllPoints()
        self.icon:SetPoint("LEFT", 4, 0)
        self.link:SetText(binding.link)

        self.value:SetText(GetCoinTextureString(binding.sellPrice * binding.count))

        self:SetScript("OnClick", function(self, button)
           
            if button == "RightButton" then
                for bag = 0, 4 do
                    for slot = 0, GetContainerNumSlots(bag) do

                        local itemLink = GetContainerItemLink(bag, slot)

                        if itemLink == binding.link then
                            UseContainerItem(bag, slot)

                            self:SetAlpha(0.5)
                            self:EnableMouse(false)

                            --set this binding table so the button gets the disbaled state when its re initialised
                            binding.disabled = true;
                        end
                    end
                end
            end
        end)

    else

        --self.icon:SetAtlas("Garr_Building-AddFollowerPlus")
        --self.icon:SetAtlas("bags-icon-addslots")
        self.icon:SetTexture(130838)
        self.icon:SetSize(12, 12)
        self.icon:ClearAllPoints()
        self.icon:SetPoint("LEFT", 6, 0)
        self.link:SetText(binding.itemType)

        self.value:SetText(nil)

        self:SetScript("OnClick", function()
            
            binding.listview.DataProvider:Flush()
            binding.listview.DataProvider:InsertTable(binding.items)
            binding.listview.backButton:Show()
        end)
    end


end

function SamsUiMerchantFrameCharacterItemsListviewItemTemplateMixin:ResetDataBinding()

    self.itemLink = nil;

    --self.binding.disabled = false;

    self.icon:SetTexture(nil)
    self.link:SetText(nil)

    self.value:SetText(nil)

end






SamsUiItemIconRingMixin = {}
SamsUiItemIconRingMixin.itemQualityToRingColours = {
    [0] = "auctionhouse-itemicon-border-gray",
    [1] = "auctionhouse-itemicon-border-white",
    [2] = "auctionhouse-itemicon-border-green",
    [3] = "auctionhouse-itemicon-border-blue",
    [4] = "auctionhouse-itemicon-border-purple",
    [5] = "auctionhouse-itemicon-border-orange",
    [6] = "auctionhouse-itemicon-border-artifact",
    [7] = "auctionhouse-itemicon-border-account",
}

function SamsUiItemIconRingMixin:OnLoad()

end

function SamsUiItemIconRingMixin:SetItem(itemId, itemLink)

    if itemLink then
        local itemName, _, itemQuality, itemLevel, _, _, _, _, _, icon, sellPrice, itemClassID, itemSubClassID = GetItemInfo(itemLink)
        self.ring:SetAtlas(self.itemQualityToRingColours[itemQuality])
        self.icon:SetTexture(icon)

        self.itemLink = itemLink;
    end
end

function SamsUiItemIconRingMixin:ClearItem()
    self.ring:SetAtlas(self.itemQualityToRingColours[0])
    self.icon:SetTexture(nil)

    self.itemLink = nil;
end

function SamsUiItemIconRingMixin:OnEnter()
    if self.itemLink then
        GameTooltip:SetOwner(self, self.tooltipAnchor)
        GameTooltip:SetHyperlink(self.itemLink)
        GameTooltip:Show()
    end
end

function SamsUiItemIconRingMixin:OnLeave()
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
end







SamsUiConfigPanelSessionsListviewItemTemplateMixin = {}

function SamsUiConfigPanelSessionsListviewItemTemplateMixin:OnLoad()

    --self.delete:SetText("Delete")

end

function SamsUiConfigPanelSessionsListviewItemTemplateMixin:SetDataBinding(binding, height)

    self.character = binding.character;

    self:SetHeight(height)
    local questXP = 0;
    for k, quest in ipairs(binding.session.questsCompleted) do
        questXP = questXP + quest.xpReward;
    end

    self.timeInfo:SetText(string.format("%s - %s [%s]", date("%X %a %d %b %Y", binding.session.initialLoginTime), date("%X %a %d %b %Y", binding.session.logoutTime or 0), SecondsToClock((binding.session.logoutTime or 0) - binding.session.initialLoginTime)))
    
    self.name:SetText(RAID_CLASS_COLORS[self.character.class]:WrapTextInColorCode(binding.name))

    self.classIcon:SetSize(height-4, height-4)
    self.classIcon:SetAtlas("GarrMission_ClassIcon-"..self.character.class)
    
    if binding.session.profit > 0 then
        self.moneyInfo:SetText(string.format("|cff00cc00Profit|r %s", GetCoinTextureString(binding.session.profit)))
    elseif binding.session.profit == 0 then
        self.moneyInfo:SetText(string.format("|cffB6CAB8Profit|r %s", GetCoinTextureString(binding.session.profit)))
    else
        self.moneyInfo:SetText(string.format("|cffcc0000Deficit|r %s", GetCoinTextureString(binding.session.profit*-1)))
    end
    
    self.questInfo:SetText(string.format("Quests turned in: %s Quest XP: %s", #binding.session.questsCompleted, questXP))
    self.mobInfo:SetText(string.format("Mobs killed: %s Mob XP: %s", binding.session.mobsKilled, binding.session.mobXpReward))
    self.delete:SetScript("OnClick", binding.deleteFunc)

end


function SamsUiConfigPanelSessionsListviewItemTemplateMixin:ResetDataBinding()
    self.character = nil;
    self.timeInfo:SetText(nil)
    self.name:SetText(nil)
    self.questInfo:SetText(nil)
    self.mobInfo:SetText(nil)
    self.delete:SetScript("OnClick", nil)
end





SamsUiCharacterFramePaperdollStatsInfoRowTemplateMixin = {}

function SamsUiCharacterFramePaperdollStatsInfoRowTemplateMixin:OnLoad()

end

function SamsUiCharacterFramePaperdollStatsInfoRowTemplateMixin:SetDataBinding(binding, height)

    self:SetHeight(height)

    self.label:SetText(binding.stat)
    self.value:SetText(binding.val)

    self.highlight:SetShown(binding.hasHighlight)
    
end

function SamsUiCharacterFramePaperdollStatsInfoRowTemplateMixin:ResetDataBinding()

    self.label:SetText("-")
    self.value:SetText("-")

end







SamsUiPartyUnitFrameMixin = {}

function SamsUiPartyUnitFrameMixin:OnLoad()

    self.target:SetSize(self:GetWidth(), 22)

    self:HookScript("OnShow", function()
        if UnitExists(self.unit) then
            self.name:SetText(UnitName(self.unit))
            local _, unitClass = UnitClass(self.unit)
            if unitClass then
                --self.background:SetAtlas("UnitFrame")
                self.background:SetAtlas(string.format("classicon-%s", unitClass:lower()))
                local r, g, b = RAID_CLASS_COLORS[unitClass]:GetRGB()
                self.healthBar:SetStatusBarColor(r, g, b)
            end
        end
    end)

    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:SetScript("OnEvent", function(self, event, ...)

        if event == "COMBAT_LOG_EVENT_UNFILTERED" then

            --this is to get spells so hardcoding spellID as 12th return
            local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
            if subevent:find("SPELL") and sourceName == self.name:GetText() then
                local name, text, texture, startTimeMS, endTimeMS, spellId;
                name, text, texture, startTimeMS, endTimeMS, _, _, _, spellId = UnitCastingInfo(self.unit)
                if not name then
                    name, text, texture, startTimeMS, endTimeMS, _, _, spellId = UnitChannelInfo(self.unit)
                end
                if name then
                    local duration = (endTimeMS - startTimeMS) / 1000;
                    self.target:Show()
                    self.target.castBar:SetMinMaxValues(0, duration)
                    self.target.castBar.start = startTimeMS
                    self.target.castBar.duration = duration
                    self.target.castBar.text:SetText(name)
                    self.target.castBar.icon:SetTexture(texture)
                    self.target.castBar.spellID = spellId;
                    self.target.name:SetText(UnitName(string.format("%starget", self.unit)) or "-")
                else
                    self.target.castBar:SetMinMaxValues(0,0)
                    self.target.castBar:SetValue(0)
                    self.target.castBar.text:SetText(nil)
                    self.target.castBar.spellID = nil;
                    self.target.name:SetText(nil)
                    self.target.castBar.icon:SetTexture(nil)
                    --self.target:Hide()
                end
            end
        end
    end)

end



function SamsUiPartyUnitFrameMixin:CreateSpellButton(buttonIndex, spellButtonWidth, x, y, unitFrameConfig, db, unitFrameContainer)


    local button = CreateFrame("BUTTON", nil, self, "SamsUiPartyFrameSpellButton")

    button:SetPoint("BOTTOMLEFT", (x-1) * spellButtonWidth, y)
    button:SetSize(spellButtonWidth - 1, spellButtonWidth - 1)

    if type(unitFrameConfig) == "table" then
        
        if unitFrameConfig["default"][buttonIndex] then
            button.icon:SetTexture(unitFrameConfig["default"][buttonIndex].icon)
            button:SetAttribute("macrotext1", unitFrameConfig["default"][buttonIndex].macro)
        end

    end

    --when we drag a something into the button we need to setup attributes
    button:SetScript('OnReceiveDrag', function()
        local info, macroID, _, spellID = GetCursorInfo()
        if info == "spell" then
            local name, rank, icon, castTime, minRange, maxRange, spellID = GetSpellInfo(spellID)
            local rankID = GetSpellSubtext(spellID)
            if name then
                button.icon:SetTexture(icon)
                local macro = string.format([[/cast [@%s] %s(%s)]], self.unit, name, rankID)
                button:SetAttribute("macrotext1", macro)

                db:UpdatePartyUnitConfig_MacroButtons(self.nameRealm, self.unit, "default", buttonIndex, icon, macro, spellID)

                button:SetScript("OnEnter", function()
                    GameTooltip:SetOwner(button, "ANCHOR_BOTTOM")
                    GameTooltip:SetHyperlink("spell:"..spellID)
                    GameTooltip:Show()
                end)

                if self.unit == "player" and self.copyPlayerButtons == true then
                    unitFrameContainer:SetButtonAttributeForAllPartyUnitFrames(buttonIndex, "spell", spellID)
                end
            end

        elseif info == "macro" then
            local name, icon, body, isLocal = GetMacroInfo(macroID)
            button.icon:SetTexture(icon)
            button:SetAttribute("macrotext1", body)
            button:SetAttribute("macrotext2", body)

            if self.unit == "player" and self.copyPlayerButtons == true then
                unitFrameContainer:SetButtonAttributeForAllPartyUnitFrames(buttonIndex, "macro", macroID)
            end

            button:SetScript("OnEnter", function()
                GameTooltip:SetOwner(button, "ANCHOR_BOTTOM")
                GameTooltip:AddLine(body)
                GameTooltip:Show()
            end)
        end
        ClearCursor()
    end)

    button:SetScript("OnMouseDown", function(self, bttn)
        if bttn == "RightButton" and IsAltKeyDown() then
            self.icon:SetAtlas("search-iconframe-large")
            self:SetAttribute("macrotext1", "")
            self:SetScript("OnEnter", nil)
        end
    end)

    button:SetScript("OnLeave", function()
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    end)
    
    if not self.buttons then
        self.buttons = {}
    end
    self.buttons[buttonIndex] = button;

    unitFrameContainer:UpdateUnitFrameButtons()
end


function SamsUiPartyUnitFrameMixin:UpdateLayout(isVertical)

    self:SetHeight(
        self.powerBar:GetHeight() +
        self.healthBar:GetHeight() +
        self.name:GetHeight()
    )
    if self.buttons and self.buttons[1] then
        self:SetHeight(self:GetHeight() + self.buttons[1]:GetHeight())
    end

    if isVertical == true then        
        self.target:ClearAllPoints()
        self.target:SetPoint("TOPLEFT", self.name, "TOPRIGHT", 2, 0)
        self.target:SetPoint("BOTTOMLEFT", self.name, "TOPRIGHT", 2, -22)
        self.target:SetSize(self:GetWidth(), 22)
    else
        self.target:ClearAllPoints()
        self.target:SetPoint("BOTTOMLEFT", self.name, "TOPLEFT", 0, 2)
        self.target:SetPoint("BOTTOMRIGHT", self.name, "TOPRIGHT", 0, 2)
        self.target:SetHeight(22)
    end

end



function SamsUiPartyUnitFrameMixin:ShowTarget(isShown)
    self.target:SetShown(isShown)
end



function SamsUiPartyUnitFrameMixin:HideSpellButtons()

    if self.buttons then
        for _, button in ipairs(self.buttons) do
            button:Hide()
        end
    end
end


function SamsUiPartyUnitFrameMixin:OnUpdate()

    if UnitExists(self.unit) then

        if UnitIsDeadOrGhost(self.unit) then
            self:SetAlpha(0.3)
            return;
        else
            self:SetAlpha(1.0)
        end

        if UnitExists(string.format("%starget", self.unit)) then
            self.target.name:SetText(UnitName(string.format("%starget", self.unit)) or "-")
            self.target:Show()
        else
            self.target:Hide()
        end
               
        local health, maxHealth = UnitHealth(self.unit), UnitHealthMax(self.unit)
        if type(health) == "number" and type(maxHealth) == "number" and maxHealth > 0 then
    
            self.healthBar.text:SetText(string.format("%.1f %%", (health/maxHealth) * 100));
    
            self.healthBar:SetValue((health/maxHealth) * 100)
        else
            self.healthBar:SetValue(0)
        end

        local powerType, powerToken = UnitPowerType(self.unit)
        local powerRGB = PowerBarColor[powerToken]
        self.powerBar:SetStatusBarColor(powerRGB.r, powerRGB.g, powerRGB.b)
        
        local power, maxPower = UnitPower(self.unit, powerType, true), UnitPowerMax(self.unit, powerType, true)
        if type(power) == "number" and type(maxPower) == "number" and maxPower > 0 then

            --self.powerBar.text:SetText(string.format("%.1f %%", (power/maxPower) * 100));

            self.powerBar:SetValue((power/maxPower) * 100)
        else
            self.powerBar:SetValue(0)
        end

        --buff bar#
        if self.target.castBar.spellID then
            local elapsed = (GetTime() * 1000) - self.target.castBar.start;
            if elapsed > 0 then
                self.target.castBar:SetValue(elapsed / 1000)
            end
            
            -- for i = 1, 40 do
            --     local name, icon, count, dispelType, duration, expirationTime, _, _, _, spellId = UnitAura(self.unit, i)

            --     if spellId == self.castBar.spellID then
            --         self.castBar:SetValue(((expirationTime - GetTime()) / duration) * 100)


            --     end
            -- end

        else
            self.target.castBar:SetValue(0)
        end

    end
end

function SamsUiPartyUnitFrameMixin:OnEnter()

end

function SamsUiPartyUnitFrameMixin:OnLeave()
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
end