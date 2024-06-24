::PYROTHRESHOLD <- 60
::ENEMYCOUNTMODIFIER <- 26

local triggerHurty = SpawnEntityFromTable("trigger_hurt",
{
	targetname = "triggerHurty"
	damage = 999999,
	damagetype = 0,
	spawnflags = 1
})

::PyroCallbacks <- 
{	
	activePyroDeadCount = 0
	activePyroSpawnCount = 0
	objRes = Entities.FindByClassname(null, "tf_objective_resource")
	
	Cleanup = function()
    {
        //activePyroDeadCount = 0
		//activePyroSpawnCount = 0
		delete ::PyroCallbacks
    }
    
    // mandatory events
    OnGameEvent_recalculate_holidays = function(_) {
		if (GetRoundState() == 3) {
			Cleanup()
		} 
		
	}
    OnGameEvent_mvm_wave_complete = function(_) { Cleanup() }
    
    OnGameEvent_player_spawn = function(params) {
		local player = GetPlayerFromUserID(params.userid)
		
		if(!IsPlayerABot(player)) {
			return
		}

		if(player.GetTeam() != 3) {
			return
		}
		NetProps.SetPropInt(objRes, "m_nMannVsMachineWaveEnemyCount", PYROTHRESHOLD + ENEMYCOUNTMODIFIER)
		NetProps.SetPropIntArray(objRes, "m_nMannVsMachineWaveClassCounts", PYROTHRESHOLD - activePyroDeadCount, 0)
		if(activePyroSpawnCount <= PYROTHRESHOLD) {
			EntFireByHandle(player, "RunScriptCode", "PyroCallbacks.checkIfBotIsAliveThenAddTags(activator)", 0.8, player, null)
		}
		//delay to allow properties to update
	}

	OnGameEvent_player_death = function(params) {
		local player = GetPlayerFromUserID(params.userid)
		if(!IsPlayerABot(player)) {
			return
		}
		
		if(!player.HasBotTag("activePyro")) {
			return
		}

		activePyroDeadCount++
		//ClientPrint(null, 3, "Pyro ded. Count: " + activePyroDeadCount)
		// ClientPrint(null, 3, "Current Wavebar: " + currentCounter)
		if(PYROTHRESHOLD - activePyroDeadCount >= 0) NetProps.SetPropIntArray(objRes, "m_nMannVsMachineWaveClassCounts", PYROTHRESHOLD - activePyroDeadCount, 0)
		if(activePyroDeadCount >= PYROTHRESHOLD) {
			// ClientPrint(null, 3, "Ded counter over 60")
			EntFire("spawnbot_placeholder4", "Enable")
		}
	}

	checkIfBotIsAliveThenAddTags = function(player) {
		//ClientPrint(null, 3, "Poopy joe 2")
		if(NetProps.GetPropInt(player, "m_lifeState") != 0) {
			return
		}

		if(!player.HasBotTag("placeholder_teleport_b1")) {
			return
		}
		activePyroSpawnCount++
		//ClientPrint(null, 3, "Pyro spawned, spawn count: " + activePyroSpawnCount)
		// local objRes = Entities.FindByClassname(null, "tf_objective_resource")
		// // ClientPrint(null, 3, "Current Wavebar: " + currentCounter)
		// NetProps.SetPropIntArray(objRes, "m_nMannVsMachineWaveClassCounts", 60 - activePyroDeadCount, 0)
		if(activePyroSpawnCount > PYROTHRESHOLD) {
            // ClientPrint(null, 3, "Spawn counter over 60")
            EntFire("placeholder_relay_teleporter_b_disable_all", "Trigger")
            EntFire("placeholder_relay_killer_enable_all", "Trigger")
            
            if(activePyroSpawnCount >= PYROTHRESHOLD) {
				//ClientPrint(null, 3, "Pyro spawned above threshold, owning...")
                player.TakeDamageEx(triggerHurty, player, null, Vector(0, 0,0), Vector(0, 0,0), 300, 0) //DMG_GENERIC
            }
        }
        else {
            player.AddBotTag("activePyro")
        }
	}
}

local objRes = Entities.FindByClassname(null, "tf_objective_resource")
// local maxEnemyCount = NetProps.GetPropInt(objRes2, "m_nMannVsMachineWaveEnemyCount")
NetProps.SetPropInt(objRes, "m_nMannVsMachineWaveEnemyCount", PYROTHRESHOLD + ENEMYCOUNTMODIFIER)
NetProps.SetPropIntArray(objRes, "m_nMannVsMachineWaveClassCounts", PYROTHRESHOLD, 0)
// NetProps.SetPropIntArray(objRes, "m_nMannVsMachineWaveClassCounts2", 60, 0)

__CollectGameEventCallbacks(PyroCallbacks)