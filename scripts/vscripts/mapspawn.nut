local objRes = Entities.FindByClassname(null, "tf_objective_resource")
local delay = 1 //delay the popfile name switch incase the mission itself changes it first

local diffKeywords = {
    int = "(Int)" //was gonna format these in, but it's better to just use the pivot
    adv = "(Adv)"
    exp = "(Exp)"
}

local pivotKeywords = {
    rev = null
    reverse = null
    final = null
}


::__NameFormat <- {

    function IsSigmod() { return Convars.GetStr("sig_color_console") != null ? true : false }

    function Format()
    {
        local popname = NetProps.GetPropString(objRes, "m_iszMvMPopfileName")
        local str = ""
        local s = []
        local pivot = -1

        if (startswith(popname, "scripts/population/") && endswith(popname, ".pop")) //probably an unmodified name
            s = split(split(popname, "/")[2], "_")

        local len = s.len() - 1

        //first clean up the array
        for (local i = len; i >= 0; i--)
        {
            local name = s[i]

            //remove "mvm" and remove rev if there's already a difficulty keyword
            if (name == "mvm" || (name == "rev" && (s[i - 1] in diffKeywords || s[i + 1] in diffKeywords)))
            {
                s.remove(i)
                continue
            }

            //remove .pop suffix
            if (i == len)
            {
                s[i] = split(name, ".")[0]
                continue
            }
        }

        //find a pivot keyword to separate map and mission name.
        foreach(i, name in s)
        {
            local namelen = name.len()
            if (name in diffKeywords || name in pivotKeywords || (startswith(name, "rc") && namelen < 5) || (startswith(name, "b") && namelen < 4) || (startswith(name, "a") && namelen < 4))
                pivot = i+1
        }

        if (pivot == -1) return

        str += format("(%s) ", s[pivot - 1])

        for (local i = pivot; i < s.len(); i++)
            str += format("%s ", s[i])

        //setting this netprop directly will break the map rotation for rafmod/sigmod servers, use ClientProp instead to fake it
        this.IsSigmod() ? EntFireByHandle(objRes, "$SetClientProp$m_iszMvMPopfileName", format("%s", str), delay, null, null) : EntFireByHandle(objRes, "RunScriptCode", format("NetProps.SetPropString(self, `m_iszMvMPopfileName`, `%s`)", str), delay, null, null)
    }
    Events = {
        function OnGameEvent_teamplay_round_start(_) {
            this.Format()
        }
    }
}
__CollectGameEventCallbacks(__NameFormat.Events)