Config = {}

Config.command = "steamreward" -- Command to claim steam reward
Config.serverName = "Leaf" -- Server name or what you want to have in their steam name

Config.framework = "esx" -- Framework (esx, qbcore)

-- DAILY - Player can claim reward every 24 hours
-- WEEKLY - Player can claim reward every 7 days
-- MONTHLY - Player can claim reward every 30 days
-- RESTART - Player can claim reward every server restart
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
}

Config.Notify = function (src, msg)
    TriggerClientEvent("chat:addMessage", src, {
        color = {0, 163, 108},
        multiline = true,
        args = {"[Leaf Steam Rewards]", msg}
    })
end
