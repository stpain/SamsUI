

local name, addon = ...;

local Util = addon.Util;



--[[
    party frame
]]
SamsUiPartyFrameMixin = {};
SamsUiPartyFrameMixin.numSpellButtons = 4;
SamsUiPartyFrameMixin.numSpellButtonsPerRow = 4;
SamsUiPartyFrameMixin.verticalLayout = false;
function SamsUiPartyFrameMixin:OnLoad()

    

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



