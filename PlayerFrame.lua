

local name, addon = ...;

local Util = addon.Util;


--[[
    player bar mixin

    handles the player bar ui
]]
SamsUiPlayerBarMixin = {};
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

    local isEnabled = addon.db:GetConfigValue("playerBarEnabled")
    if isEnabled ~= nil then
        self:SetEnabled(isEnabled)
    end

    if addon.db:GetConfigValue("showPlayerHealthText") then
        self.healthBar.text:SetShown(addon.db:GetConfigValue("showPlayerHealthText"))
    end

    if addon.db:GetConfigValue("playerHealthTextFormat") then
        self.playerHealthTextFormat = addon.db:GetConfigValue("playerHealthTextFormat")
    end

    if addon.db:GetConfigValue("showPlayerPowerText") then
        self.powerBar.text:SetShown(addon.db:GetConfigValue("showPlayerPowerText"))
    end

    if addon.db:GetConfigValue("playerPowerTextFormat") then
        self.playerPowerTextFormat = addon.db:GetConfigValue("playerPowerTextFormat")
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

        self:Init()
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
