SrvDupeES = {}

local function init()
    print("[SrvDupeES]\tServer Duplicator loaded, hello world!")

    include("config/sh_config.lua")
    include("easy_spawner/sh_srvdupe_es.lua")
    include("easy_spawner/client/cl_spawnmenu.lua")

    hook.Remove("SrvDupeES_Init")
end

timer.Simple(5, function()
    if not SrvDupe then
        error("[SrvDupeES]\tServer Duplicator addon not found!")
    end
end)

hook.Add("SrvDupe_PostInit", "SrvDupeES_Init", init)
