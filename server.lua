-- Create database table if not exists
if not string.lower(Config.rewardTime) == 'restart' then
    MySQL.Async.execute('CREATE TABLE IF NOT EXISTS leafsteamrewards (id VARCHAR(255) PRIMARY KEY NOT NULL, datetimestamp INT)')
end

local claimed = {}

local FW = nil
local framework = string.lower(Config.framework)
if framework == 'esx' then
    FW = exports["es_extended"]:getSharedObject()
elseif framework == 'qbcore' then
    FW = exports['qb-core']:GetCoreObject()

else
    print("Leaf Steam Rewards: Framework is not set in config.lua!")
    return
end

if (string.lower(Config.logs) == "both" or string.lower(Config.logs) == "discord") and (not Config.discordWebhook or Config.discordWebhook == "YOUR_DISCORD_WEBHOOK") then
    print("Leaf Steam Rewards: Discord webhook is not set in config.lua, logs will not be sent to discord!")
end
if string.lower(Config.logs) == "both" or string.lower(Config.logs) == "leaflogs" then
    local loggerData = {
        name = "Steam Rewards",
        header = {"SteamName", "Source", "ID"}
    }
    
    if exports.LeafLogs then
        exports.LeafLogs:RegisterLogger(loggerData)
    end
    AddEventHandler('leaflogs:getLoggers', function()
        exports.LeafLogs:RegisterLogger(loggerData)
    end)
end

local function checkTime(diff, claimTime)
    if claimTime == 'daily' then
        if diff < 86400 then
            return false
        end
    elseif claimTime == 'weekly' then
        if diff < 604800 then
            return false
        end
    elseif claimTime == 'monthly' then
        if diff < 2592000 then
            return false
        end
    end
    return true
end

local function getID(src)
    if framework == "esx" then
        return FW.GetPlayerFromId(src).identifier
    elseif framework == "qbcore" then
        return FW.Functions.GetPlayer(src).PlayerData.steam
    end
end

RegisterCommand(Config.command, function(source)
    local src = source

    -- Get id
    local id = getID(src)

    -- Check if steam is running
    if id == nil then
        Config.Notify(src, Config.lang["no_steam"])
        return
    end

    -- Check if user has claimed reward
    local claimTimestamp = claimed[id]
    if claimTimestamp then
        if string.lower(Config.rewardTime) == 'restart' then
            Config.Notify(src, Config.lang["already_claimed"])
            return
        end
        local time = os.time()
        local diff = time - claimTimestamp
        if not checkTime(diff, string.lower(Config.rewardTime)) then
            Config.Notify(src, Config.lang["already_claimed"])
            return
        end
    elseif not claimTimestamp and not string.lower(Config.rewardTime) == 'restart' then
        -- Check database if user has claimed reward
        MySQL.Async.fetchAll('SELECT * FROM leafsteamrewards WHERE id = @id', {
            ['@id'] = id
        }, function(result)
            if result[1] then
                if string.lower(Config.rewardTime) == 'restart' then
                    Config.Notify(src, Config.lang["already_claimed"])
                    return
                end
                local time = os.time()
                local diff = time - result[1].datetimestamp
                if not checkTime(diff, string.lower(Config.rewardTime)) then
                    Config.Notify(src, Config.lang["already_claimed"])
                    return
                end
            end
        end)
    end

    local steamName = GetPlayerName(src)
    if string.lower(Config.mode) == 'name' then
        -- Check if user has server name in steam name
        if not string.find(steamName, Config.serverName) then
            Config.Notify(src, string.format(Config.lang["no_steam_name"], Config.serverName))
            return
        end
    elseif string.lower(Config.mode) == 'group' then
        -- Check if user is in steam group
        local steamID = id
        if framework == 'esx' then
            for _, v in pairs(GetPlayerIdentifiers(src)) do
                if string.find(v, 'steam:') then
                    steamID = v
                    break
                end
            end
        end

        if not steamID then
            Config.Notify(src, Config.lang["no_steam"])
            return
        end

        steamID = tonumber(string.gsub(steamID, 'steam:', ''), 16)

        local steamAPIKey = GetConvar('steam_webApiKey', '')
        local url = string.format('https://api.steampowered.com/ISteamUser/GetUserGroupList/v1?key=%s&steamid=%s', steamAPIKey, steamID)

        local promise = promise.new()

        PerformHttpRequest(url, function (status, body, headers, errorData)
            if status ~= 200 then
                Config.Notify(src, Config.lang["error"])
                promise:resolve(false)
                return
            end
            
            local data = json.decode(body)
            if not data.response then
                Config.Notify(src, Config.lang["error"])
                promise:resolve(false)
                return
            end

            local groups = data.response.groups
            if not groups then
                Config.Notify(src, Config.lang["error"])
                promise:resolve(false)
                return
            end

            local found = false
            for _, v in pairs(groups) do
                if v.gid == Config.groupID then
                    found = true
                    break
                end
            end

            if not found then
                Config.Notify(src, string.format(Config.lang["no_group"], "https://steamcommunity.com/groups/" .. Config.groupID))
                promise:resolve(false)
                return
            end

            promise:resolve(true)
        end)

        local result = Citizen.Await(promise)
        if not result then
            return
        end
    end

    -- Give rewards
    local xPlayer = nil
    if framework == 'esx' then
        xPlayer = FW.GetPlayerFromId(src)
    elseif framework == 'qbcore' then
        xPlayer = FW.Functions.GetPlayer(src)
    end
    for _, v in pairs(Config.rewards) do
        if v.type == 'money' then
            if framework == 'esx' then
                xPlayer.addMoney(v.value)
            elseif framework == 'qbcore' then
                xPlayer.Functions.AddMoney('cash', v.value)
            end
        elseif v.type == 'item' then
            if framework == 'esx' then
                xPlayer.addInventoryItem(v.value, v.amount)
            elseif framework == 'qbcore' then
                xPlayer.Functions.AddItem(v.value, v.amount)
            end
        elseif v.type == 'weapon' then
            if framework == 'esx' then
                xPlayer.addWeapon(v.value, v.amount)
            elseif framework == 'qbcore' then
                xPlayer.Functions.AddItem(v.value, v.amount)
            end
        end
    end

    -- Send notification
    Config.Notify(src, Config.lang["success"])

    -- Add to claimed table
    claimed[id] = os.time()

    -- Add to database or update database
    if not string.lower(Config.rewardTime) == 'restart' then
        MySQL.Async.execute('INSERT INTO leafsteamrewards (id, datetimestamp) VALUES (@id, @datetimestamp) ON DUPLICATE KEY UPDATE datetimestamp = @datetimestamp', {
            ['@id'] = id,
            ['@datetimestamp'] = os.time()
        })
    end

    -- Send logs
    local logs = string.lower(Config.logs)
    if logs ~= "none" then
        if (logs == "discord" or logs == "both") and Config.discordWebhook then
            local embed = {
                {
                    ["color"] = 0x00A36C,
                    ["title"] = "Steam Reward Claimed",
                    ["description"] = string.format("**%s** has claimed their reward!", steamName),
                    ["fields"] = {
                        {
                            ["name"] = "Source",
                            ["value"] = src,
                            ["inline"] = true
                        },
                        {
                            ["name"] = "ID",
                            ["value"] = id,
                            ["inline"] = true
                        }
                    },
                    ["timestamp"] = os.date('!%Y-%m-%dT%H:%M:%S'),
                    ["footer"] = {
                        ["text"] = "Leaf Steam Rewards"
                    }
                }
            }
            PerformHttpRequest(Config.discordWebhook, function(err, text, headers) end, 'POST', json.encode({username = "Leaf Steam Rewards", embeds = embed}), { ['Content-Type'] = 'application/json' })
        end
        if (logs == "leaflogs" or logs == "both") and exports.LeafLogs and exports.LeafLogs:HasLogger("Steam Rewards") then
            exports.LeafLogs:AddData("Steam Rewards", {
                data = {
                    ["SteamName"] = steamName,
                    ["Source"] = src,
                    ["ID"] = id
                }
            })
        end
    end
end, false)