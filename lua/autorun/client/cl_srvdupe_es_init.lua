SrvDupeES = {}

local function init()
    print("[SrvDupeES]\tServer Duplicator loaded, hello world!")

    include("config/sh_srvdupe_es_config.lua")
    include("easy_spawner/sh_srvdupe_es.lua")
    include("easy_spawner/client/cl_spawnmenu.lua")

    function SrvDupeES.Notify(msg,typ,dur)
        surface.PlaySound(typ == 1 and "buttons/button10.wav" or "ambient/water/drip1.wav")
        GAMEMODE:AddNotify(msg, typ or NOTIFY_GENERIC, dur or 5)
        if not game.SinglePlayer() then print("[SrvDupeES]\t"..msg) end
    end

    net.Receive("SrvDupeES_Notify", function()
        SrvDupeES.Notify(net.ReadString(), net.ReadUInt(8), net.ReadFloat())
    end)

    hook.Remove("SrvDupeES_Init")
end

timer.Simple(5, function()
    if not SrvDupe then
        error("[SrvDupeES]\tServer Duplicator addon not found!")
    end
end)

hook.Add("SrvDupe_PostInit", "SrvDupeES_Init", init)
