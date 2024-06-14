::DisableSquad <-
{
    GLOBAL_CALLBACKS =
    {
        OnGameEvent_player_spawn = function(params)
        {
            local bot = GetPlayerFromUserID(params.userid);
            
            if (bot.IsFakeClient())
            {
                printl("Bot spawn detected! Checking tags...")
                EntFireByHandle(bot, "RunScriptCode", "DisableSquad.BotTagCheck(self)", -1.0, null, null)
            }
        }
    }

    BotTagCheck = function(bot)
    {
        if (bot.HasBotTag("disband_squad"))
        {
            bot.DisbandCurrentSquad()
            printl("Disbanding Squad...")
        }
    }
};
__CollectGameEventCallbacks(DisableSquad)
__CollectGameEventCallbacks(DisableSquad.GLOBAL_CALLBACKS)