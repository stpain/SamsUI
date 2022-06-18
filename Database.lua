

local addonName, sui = ...;

local L = sui.locales;

local Database = {};

function Database:Init()

    if not SamsUiGameInfo then
        SamsUiGameInfo = {};
    end

    if not SamsUiConfig then
        SamsUiConfig = {};
    end

    if not SamsUiCharacters then
        SamsUiCharacters = {};
    end

    sui:TriggerEvent("Database_OnDatabaseInitialized")

end

function Database:SetVDT()
    ViragDevTool:AddData(SamsUiCharacters, "SamsUiCharacters")
    ViragDevTool:AddData(SamsUiConfig, "SamsUiConfig")
end

---register the character in the database, this is called during the game loading process
---@param nameRealm any
---@param class any
---@param race any
---@param gender any
function Database:RegisterCharacter(nameRealm, class, race, gender)

    if type(SamsUiCharacters) == "table" then
        
        if not SamsUiCharacters[nameRealm] then
            SamsUiCharacters[nameRealm] = {
                initialLoginGold = 0,
                initialLoginTime = 0,
                currentGold = 0,
                reputations = {},
                skills = {},
                containers = {},
                inventory = {},
                xp = 0,
                xpMax = 0,
                xpRested = 0,
                quests = {},
                mail = {},
                talents = {},
            };
        end

        SamsUiCharacters[nameRealm].class = class;
        SamsUiCharacters[nameRealm].race = race;
        SamsUiCharacters[nameRealm].gender = gender;

        sui.print(L["CHARACTER_REGISTERED_S"]:format(nameRealm))

        sui:TriggerEvent("Database_OnCharacterRegistered", SamsUiCharacters[nameRealm])
    end

end


function Database:InsertOrUpdateCharacterInfo(nameRealm, key, val)

    if type(nameRealm) == "string" and type(SamsUiCharacters) == "table" then
        
        if not SamsUiCharacters[nameRealm] then
            SamsUiCharacters[nameRealm] = {};
        end

        if key ~= nil then
            SamsUiCharacters[nameRealm][key] = val;
        end
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


function Database:GetCharacterInfo(nameRealm, key)

    if type(SamsUiCharacters) ~= "table" then
        return false;
    end

    if SamsUiCharacters[nameRealm] and SamsUiCharacters[nameRealm][key] then
        return SamsUiCharacters[nameRealm][key];
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


function Database:SetConfigValue(setting, newValue)

    if type(SamsUiConfig) == "table" then
        SamsUiConfig[setting] = newValue;
    end
end

function Database:GetConfigValue(setting)

    if type(SamsUiConfig) == "table" then
        if SamsUiConfig[setting] then
            return SamsUiConfig[setting];
        end
    end
end

function Database:InsertGameInfo(key, val)
    SamsUiGameInfo[key] = val;
end


sui.db = Database;