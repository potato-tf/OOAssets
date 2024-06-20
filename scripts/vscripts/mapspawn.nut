// Script is executed by the game every map spawn.
::__potato <- {
    // Seconds to delay formatting the mission display name.
    FormatNameDelay = 1.0

    objective_resource = null
    mapname = GetMapName()
    len_mapname = GetMapName().len()
    // True if the mission has been completed.
    InVictory = false
    // True if the server is running the sigsegv-mvm extension.
    IsSigmod = Convars.GetInt("sig_color_console") != null ? true : false

    // Mapping for difficulty phrases to respective display name.
    difficultyMap = {
        "nor": "(nor) "
        "int": "(int) "
        "adv": "(adv) "
        "exp": "(exp) "
    }
    // Phrases to ignore when formatting mission display name.
    toStrip = [
        "rev",
        "reverse"
    ]

    /**
     * Detects the recommended mission name setting method and sets the mission display name
     * using that method.
     *
     * @param str newname
     */
    function SetMissionName(newname) {
        if (this.IsSigmod == true) {
            // This is done because the Potato plugin that serves the mission name to the 
            // website retrieves the popfile name directly from this NetProp, causing the website
            // to display incorrectly if it is modified. Plugin authors should consider using a 
            // method like this instead:
            // https://github.com/mtxfellen/tf2-plugins/blob/3a83742/addons/sourcemod/scripting/include/tfmvm_stocks.inc#L21
            EntFireByHandle(__potato.objective_resource, "$SetClientProp$m_iszMvMPopfileName", newname, -1, null, null)
            return
        }
        NetProps.SetPropString(__potato.objective_resource, "m_iszMvMPopfileName", newname)
    }

    /**
     * Formats the current mission display name according to Potato.tf standard formatting,
     * if the mission name is otherwise unchanged.
     * Standard format is "(Difficulty) Mission Name".
     *
     * @param str popname   Mission name to format.
     * @param bool end      Set to true to use end card formatting (no difficulty).
     */
    function FormatMissionName(popname, end = false) {
        // Split:
        //  "scripts/population/mvm_condemned_b3_adv_unholy_undead.pop"
        // To:
        //  ["adv", "unholy", "undead"]
        local strings = split(popname.slice(20 + __potato.len_mapname, -4), "_")

        local name = ""  // Mission display name
        local difficulty = ""   // Mission display difficulty tag
        for(local i = 0; i <= strings.len() - 2; ++i) {
            // Don't include "rev" or "reverse" in formatted version
            if (strings[i] in this.toStrip) continue
            // Test for mission difficulty tag
            //  No way to access a key without potentially throwing an exception,
            //   and exceptions aren't typed so have to do this (or use arrays instead
            //   of a table for __potato.difficultyMap)
            if (strings[i] in this.difficultyMap) {
                difficulty = this.difficultyMap[strings[i]]
                continue
            }
            // Join strings to form mission name with space separator
            name += strings[i] + " "
        }
        // Add mission difficulty to the start if it exists.
        //  Don't add if on the victory screen since map name will also be squashed in.
        // Also append the last word of the mission name, done outside the loop to avoid
        //  a trailing space.
        if (end == false) {
            return difficulty + name + strings.top()
        } else {
            return name + strings.top()
        }
    }

    /**
     * Applies the map fixes specified for the current map.
     */
    function ApplyMapFixes() {
        switch (__potato.mapname) {
            // Oilrig
            case "mvm_oilrig_rc5a":
                // Rain particles fix - replace missing rain particles with sawmill rain.
                // Kill broken rain particles
                for (local particlesystem; particlesystem = Entities.FindByClassname(particlesystem, "info_particle_system");) {
                    if (particlesystem.GetName() == "end_pit_destroy_particle") continue
                    // Kill() and Destroy() methods will cause this to iterate ~300 times,
                    //  so must EntFire() instead
                    EntFireByHandle(particlesystem, "Kill", "", 0, null, null)
                }

                // Spawn replacement rain; looks bad if we just use the position of the old particle systems
                local rain2 = [Vector(-508, -2608, 1800), Vector(789, -2290, 1800), Vector(-324, -2694, 1800), Vector(-320, -3360, 1800)]
                local rain = [Vector(-2848, 384, 8810), Vector(-1200, 1924, 3620),
                    Vector(282, 1924, 3620), Vector(882, 1924, 3620), Vector(-366, -608, 3620), Vector(528, -608, 4100),
                    Vector(1849, -291, 3420), Vector(0, -1000, 1600), Vector(1024, -1632, 4100), Vector(-1024, -1632, 4100),
                    Vector(1562, -2210, 3620), Vector(-864, -3936, 3620), Vector(160, -4096, 4200), Vector(320, -4960, 4300),
                    Vector(-704, -4960, 4300), Vector(1242, -4256, 3620), Vector(-1146, -4702, 3620)]
                foreach(vec in rain2) {
                    SpawnEntityFromTable("info_particle_system", {
                        origin = vec
                        effect_name = "env_rain_002_256"
                        start_active = 1
                        flag_as_weather = 1
                    })
                }
                foreach(vec in rain) {
                    SpawnEntityFromTable("info_particle_system", {
                        origin = vec
                        effect_name = "env_rain_001"
                        start_active = 1
                        flag_as_weather = 1
                    })
                }

                // Tank spawn fixes
                // Add missing func_respawnroom to tank spawn.
                local tankspawn = SpawnEntityFromTable("func_respawnroom", {
                    origin = Vector(-520, -5450, 1063)
                    TeamNum = Constants.ETFTeam.TF_TEAM_BLUE
                })
                // Some properties are reset when spawn is dispatched, so they must be set
                //  post-spawn.
                tankspawn.SetSize(Vector(), Vector(400, 410, 200))
                tankspawn.SetSolid(Constants.ESolidType.SOLID_BBOX)
                // Mark tank spawn nav to properly provide bot uber.
                local tanknav = NavMesh.GetNavAreaByID(27)
                tanknav.SetAttributeTF(Constants.FTFNavAttributeType.TF_NAV_SPAWN_ROOM_BLUE)
                tanknav.ClearAttributeTF(Constants.FTFNavAttributeType.TF_NAV_BOMB_CAN_DROP_HERE)

                // Collect dropped cash in tank spawn.
                local tankcollect = SpawnEntityFromTable("trigger_hurt", {
                    origin = Vector(-520, -5450, 1063)
                })
                tankcollect.SetSize(Vector(), Vector(400, 410, 200))
                tankcollect.SetSolid(Constants.ESolidType.SOLID_BBOX)
                break

            // Rottenburg
            case "mvm_rottenburg":
                // Fix tank barricade turning invisible
                EntFire("Barricade", "SetParent", "Tank_Barricade_Particle")
                // Fix bad collision on tank barricade
                EntFire("Barricade", "DisableCollision")
                break
        }
    }

    Events = {
        // Event is fired every wave init (on mission change, wave jump or post wave fail).
        function OnGameEvent_teamplay_round_start(_) {
            __potato.InVictory = false
            __potato.ApplyMapFixes()

            // tf_objective_resource is made by tf_gamerules after map init, so we can't fetch it on map spawn.
            __potato.objective_resource = Entities.FindByClassname(null, "tf_objective_resource")

            // We want to delay setting the mission display name so that mission makers may
            //  set their own as desired.
            EntFire("worldspawn", "RunScriptCode", @"
                local popname = NetProps.GetPropString(__potato.objective_resource, `m_iszMvMPopfileName`)
                if (startswith(popname, `scripts/population/mvm_`) && endswith(popname, `.pop`))
                    __potato.SetMissionName(__potato.FormatMissionName(popname))
                "
            , __potato.FormatNameDelay)
        }
        // Event is fired at mission victory (all waves complete).
        function OnGameEvent_mvm_mission_complete(params) {
            __potato.InVictory = true
            // Set mission name without difficulty for the victory panel
            EntFire("worldspawn", "RunScriptCode", format(@"
                if (__potato.InVictory == true)
                    __potato.SetMissionName(`%s`)", __potato.FormatMissionName(params.mission, true))
            , 1)

            // Set back to regular formatted name once panel has been displayed
            EntFire("worldspawn", "RunScriptCode", format(@"
                if (__potato.InVictory == true)
                    __potato.SetMissionName(`%s`)", __potato.FormatMissionName(params.mission))
            , 3)

            // Reset mission name before the popfile is reloaded.
            //  This is done because the Potato plugin that intercepts the default mission
            //  cycle behaviour retrieves the popfile name directly from this NetProp,
            //  which causes the plugin to fail if we have overwritten the default string
            //  name. Plugin authors should consider using a method like this instead:
            //  https://github.com/mtxfellen/tf2-plugins/blob/3a83742/addons/sourcemod/scripting/include/tfmvm_stocks.inc#L21
            EntFire("worldspawn", "RunScriptCode", format(@"
                if (__potato.InVictory == true)
                    NetProps.SetPropString(__potato.objective_resource, `m_iszMvMPopfileName`, `%s`)", params.mission)
            , 9.5)
        }
    }
}

__CollectGameEventCallbacks(__potato.Events)
