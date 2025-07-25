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

    -- TODO: When the dupe id is updated, everything depending on it must be updated too

    local canSpawn, errMsg = ply:CanSpawnDupe(dupe.category_id, dupe.id)
    if not canSpawn then
        SrvDupeES.Notify(errMsg, 1, 5, ply, true)
        return
    end

    ply:IncrementDupeCount(dupe.category_id, dupe.id)
    local result, errMsg = SrvDupe.LoadAndPaste(dupe.path, trace.HitPos, angle_zero, ply, function()
        ply:IncrementDupeCount(dupe.category_id, dupe.id, -1)
    end)

    if not result then
        SrvDupeES.Notify(errMsg or "Failed to spawn the dupe!", 1, 5, ply, true)
        ply:IncrementDupeCount(dupe.category_id, dupe.id, -1)
        return
    end
end

local function init()
    print("[SrvDupeES]\tServerDupe Easy Spawner loaded, hello world!")

    AddCSLuaFile("config/sh_srvdupe_es_config.lua")
    AddCSLuaFile("easy_spawner/sh_cami.lua")
    AddCSLuaFile("easy_spawner/sh_srvdupe_es.lua")
    AddCSLuaFile("easy_spawner/client/cl_image.lua")
    AddCSLuaFile("easy_spawner/client/cl_spawnmenu.lua")
    AddCSLuaFile("easy_spawner/client/vgui/vgui_slider.lua")
    AddCSLuaFile("easy_spawner/client/vgui/vgui_cat_dupes_tab.lua")
    AddCSLuaFile("easy_spawner/client/vgui/vgui_permissions_tab.lua")

    include("config/sh_srvdupe_es_config.lua")
    include("easy_spawner/sh_cami.lua")
    include("easy_spawner/sh_srvdupe_es.lua")
    include("easy_spawner/server/sv_db.lua")
    include("easy_spawner/server/sv_net.lua")
    include("easy_spawner/server/sv_permissions.lua")

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

    concommand.Add("srvdupe_es_limits", function(ply, cmd, args, argStr)
        print("srvdupe_es_limits", argStr)
        if not SrvDupeES.CheckPlyWritePermissions(ply) then
            SrvDupeES.Notify("You do not have permission to modify limits.", 1, 5, ply, true)
            return
        end

        SrvDupeES.HandleLimitsCommand(ply, args)
    end)

    hook.Add("PlayerInitialSpawn","SrvDupeES_AddPlayerTable",function(ply)
        ply.SrvDupeES = ply.SrvDupeES or {}
        ply.SrvDupeES.OwnedDupes = ply.SrvDupeES.OwnedDupes or {}
    end)


    hook.Remove("SrvDupeES_Init")
end

timer.Simple(5, function()
    if not SrvDupe then
        error("[SrvDupeES]\tServer Duplicator addon not found!")
    end
end)

hook.Add("SrvDupe_PostInit", "SrvDupeES_Init", init)