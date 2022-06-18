

local name, addon = ...

local Util = {}


function Util.FormatStatsusBarTags(t, s, cur, _max, per)
    s = s:gsub("{cur}", cur)
    s = s:gsub("{max}", _max)
    s = s:gsub("{per}", per)
    t:SetText(s)
end

function Util.CapitaliseString(s)
    if type(s) == "string" then
        return s:sub(1,1):upper()..s:sub(2):lower()
    end
end


function Util.MakeFrameMoveable(frame)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
end


function Util.LockFramePosition(frame)
    frame:SetMovable(false)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", nil)
    frame:SetScript("OnDragStop", nil)
end


function Util.FormatNumberForCharacterStats(num)
    if type(num) == 'number' then
        local trimmed = string.format("%.2f", num)
        return tonumber(trimmed)
    else
        return 1.0;
    end
end


function Util.GetContainerItemsValue(classID, subClassID, itemID, itemLink)

    local value = 0;

    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local icon, itemCount, locked, quality, readable, lootable, link, isFiltered, noValue, itemId, isBound = GetContainerItemInfo(bag, slot)
            if link then
                local itemName, _, itemQuality, _, _, _, _, _, _, _, sellPrice, itemClassID, itemSubClassID = GetItemInfo(itemLink)

                if not itemID and not itemLink then

                    if classID and subClassID then
                        if itemClassID == classID and itemSubClassID == subClassID then
                            value = value + (itemCount * sellPrice)
                        end
                    end

                    if classID and not subClassID then
                        if itemClassID == classID then
                            value = value + (itemCount * sellPrice)
                        end
                    end

                end

                if itemID and not itemLink then
                    
                    if itemId == itemID then
                        value = value + (itemCount * sellPrice)
                    end
                    
                end

                if itemLink and not itemID then
                    
                    if link == itemLink then
                        value = value + (itemCount * sellPrice)
                    end

                end


            end
        end
    end
    return value;
end




addon.util = Util;