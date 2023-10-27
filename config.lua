Config = {}

Config.command = "steamreward" -- Command to claim steam reward
Config.serverName = "YOUR_SERVER_NAME" -- Server name or what you want to have in their steam name (Required if mode is set to name)
Config.groupID = "YOUR_GROUPID" -- Steam groupID to check for (Required if mode is set to group)
-- How to get groupID: https://steamcommunity.com/groups/<group url>/edit
-- The groupID is first field. The number out from ID

-- NAME - Player must have server name in their steam name
-- GROUP - Player must be in a specific steam group
-- BOTH - Player must have server name in their steam name and be in a specific steam group
Config.mode = "NAME"

Config.framework = "esx" -- Framework (esx, qbcore)

-- DAILY - Player can claim reward every 24 hours
-- WEEKLY - Player can claim reward every 7 days
-- MONTHLY - Player can claim reward every 30 days
-- RESTART - Player can claim reward every server restart
-- ONCE - Player can only claim reward once
Config.rewardTime = "restart"

-- DISCORD - Send logs to discord webhook
-- LEAFLOGS - Send logs to LeafLogs (Requires LeafLogs resource)
-- BOTH - Send logs to both discord and LeafLogs
-- NONE - Don't send logs anywhere
Config.logs = "both"
Config.discordWebhook = "YOUR_DISCORD_WEBHOOK" -- Discord webhook (Required if logs is set to discord or both)

Config.rewards = {
    {
        type = "money", -- Type of reward (money, item, weapon)
        value = 1000, -- Value of reward (money, item name, weapon name)
        amount = 1, -- Amount of reward (money, item, weapon)
    }
}

Config.lang = {
    ["success"] = "You have claimed your reward!",
    ["already_claimed"] = "You have already claimed your reward!",
    ["no_steam"] = "You must have steam running to claim your reward!",
    ["no_steam_name"] = "You must have %s in your steam name to claim your reward!",
    ["error"] = "Something went wrong, please try again later!",
    ["no_group"] = "You must be in the steam group to claim your reward!\nGroup: %s",
}

Config.Notify = function (src, msg)
    TriggerClientEvent("chat:addMessage", src, {
        color = {0, 163, 108},
        multiline = true,
        args = {"[Leaf Steam Rewards]", msg}
    })
end