SrvDupeES = {}

local function spawnDupe(ply, dupeId)
    if not dupeId or not ply then return end

    local dupe = SrvDupeES.SQL.GetDupe(dupeId)

    if table.IsEmpty(dupe) then
        -- TODO: Give error
        return
    end

    local startPos = ply:EyePos()
    local trace = util.TraceLine({
        start = startPos,
        endpos = startPos + ply:GetAimVector() * 4096,
        filter = ply
    })

    SrvDupe.LoadAndPaste(dupe.path, trace.HitPos, angle_zero, ply)
end

local function init()
    print("[SrvDupeES]\tServer Duplicator loaded, hello world!")

    AddCSLuaFile("config/sh_srvdupe_es_config.lua")
    AddCSLuaFile("easy_spawner/sh_srvdupe_es.lua")
    AddCSLuaFile("easy_spawner/client/cl_spawnmenu.lua")

    include("config/sh_srvdupe_es_config.lua")
    include("easy_spawner/sh_srvdupe_es.lua")
    include("easy_spawner/server/sv_db.lua")
    include("easy_spawner/server/sv_net.lua")

    function SrvDupeES.Notify(msg, typ, dur, ply, showsrv)
        net.Start("SrvDupeES_Notify")
        net.WriteString(msg)
        net.WriteUInt(typ or 0, 8)
        net.WriteFloat(dur or 5)
        net.Send(ply)

        if(showsrv==true)then
            print("[SrvDupeES]\t"..ply:Nick()..": "..msg)
        end
    end

    concommand.Add("srvdupe_es_spawn", function (ply, cmd, args, argStr)
        spawnDupe(ply, args[1])
    end)

    hook.Remove("SrvDupeES_Init")
end

timer.Simple(5, function()
    if not SrvDupe then
        error("[SrvDupeES]\tServer Duplicator addon not found!")
    end
end)

hook.Add("SrvDupe_PostInit", "SrvDupeES_Init", init)