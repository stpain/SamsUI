

local name, addon = ...;

local Util = addon.Util;

--[[
    target bar mixin

    hanldes the target bar
]]
SamsUiTargetBarMixin = {};
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

    local isEnabled = addon.db:GetConfigValue("targetBarEnabled")
    if isEnabled ~= nil then
        self:SetEnabled(isEnabled)
    end

    if addon.db:GetConfigValue("showTargetHealthText") then
        self.healthBar.text:SetShown(addon.db:GetConfigValue("showTargetHealthText"))
    end

    if addon.db:GetConfigValue("targetHealthTextFormat") then
        self.targetHealthTextFormat = addon.db:GetConfigValue("targetHealthTextFormat")
    end

    if addon.db:GetConfigValue("showTargetPowerText") then
        self.powerBar.text:SetShown(addon.db:GetConfigValue("showTargetPowerText"))
    end

    if addon.db:GetConfigValue("targetPowerTextFormat") then
        self.targetPowerTextFormat = addon.db:GetConfigValue("targetPowerTextFormat")
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
