

local name, addon = ...;

local Util = addon.Util;

SamsUiCharacterFrameMixin = {};
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
SamsUiCharacterFrameMixin.inventorySlots = {
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

    self:RegisterEvent("ADDON_LOADED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("UNIT_INVENTORY_CHANGED")

end


function SamsUiCharacterFrameMixin:OnShow()

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


    for _, slot in pairs(self.inventorySlots) do

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
    for _, slot in pairs(self.inventorySlots) do

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

    for k, slot in pairs(self.inventorySlots) do
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
