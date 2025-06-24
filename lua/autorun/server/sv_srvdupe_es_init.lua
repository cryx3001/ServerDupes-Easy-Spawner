SrvDupeES = {}

local function init()
    print("[SrvDupeES]\tServer Duplicator loaded, hello world!")

    AddCSLuaFile("config/sh_srvdupe_es_config.lua")
    AddCSLuaFile("easy_spawner/sh_srvdupe_es.lua")
    AddCSLuaFile("easy_spawner/client/cl_spawnmenu.lua")

    include("config/sh_srvdupe_es_config.lua")
    include("easy_spawner/sh_srvdupe_es.lua")
    include("easy_spawner/server/sv_db.lua")
    include("easy_spawner/server/sv_net.lua")

    hook.Remove("SrvDupeES_Init")
end

timer.Simple(5, function()
    if not SrvDupe then
        error("[SrvDupeES]\tServer Duplicator addon not found!")
    end
end)

hook.Add("SrvDupe_PostInit", "SrvDupeES_Init", init)