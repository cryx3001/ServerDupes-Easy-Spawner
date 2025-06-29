util.AddNetworkString("SrvDupe_ES_RequestDupesAndCategories")
util.AddNetworkString("SrvDupe_ES_SendDupesAndCategories")
util.AddNetworkString("SrvDupeES_Notify")
util.AddNetworkString("SrvDupeES_SaveCategory")
util.AddNetworkString("SrvDupeES_SaveDupe")
util.AddNetworkString("SrvDupeES_DeleteCategory")
util.AddNetworkString("SrvDupeES_DeleteDupe")

function SrvDupeES.SendDupesAndCategories(ply)
    local dupes = SrvDupeES.SQL.GetAllDupes()
    local categories = SrvDupeES.SQL.GetAllCategories()

    local dupeLimits = SrvDupeES.SQL.GetAllPermissions(SrvDupeES.SQL.Enums.PermissionsTbl.DUPE_LIMITS)
    local categoryLimits = SrvDupeES.SQL.GetAllPermissions(SrvDupeES.SQL.Enums.PermissionsTbl.CATEGORY_LIMITS)
    local usergroupGlobalLimits = SrvDupeES.SQL.GetAllPermissions(SrvDupeES.SQL.Enums.PermissionsTbl.USERGROUP_GLOBAL_LIMITS)

    local permissions = {
        DUPE_LIMITS = dupeLimits,
        CATEGORY_LIMITS = categoryLimits,
        USERGROUP_GLOBAL_LIMITS = usergroupGlobalLimits
    }

    net.Start("SrvDupe_ES_SendDupesAndCategories")
        net.WriteTable(dupes)
        net.WriteTable(categories)
        net.WriteTable(permissions)
    if not ply then
        net.Broadcast()
    else
        net.Send(ply)
    end
end

net.Receive("SrvDupe_ES_RequestDupesAndCategories", function(_, ply)
    SrvDupeES.SendDupesAndCategories(ply)
end)

net.Receive("SrvDupeES_SaveCategory", function(_, ply)
    if not IsValid(ply) and not SrvDupeES.CheckPlyWritePermissions(ply) then
        SrvDupeES.Notify("You do not have permission to save categories.", 1, 5, ply, true)
        return
    end

    local data = net.ReadTable()

    if not data or not data.id then return end

    SrvDupeES.SQL.SaveCategory(data)

    SrvDupeES.SendDupesAndCategories()
end)

net.Receive("SrvDupeES_SaveDupe", function(_, ply)
    if not IsValid(ply) and not SrvDupeES.CheckPlyWritePermissions(ply) then
        SrvDupeES.Notify("You do not have permission to save dupes.", 1, 5, ply, true)
        return
    end

    local data = net.ReadTable()

    if not data or not data.id or not data.name or not data.category_id or not data.path then return end

    data.added_by = tostring(ply:SteamID())

    local success, _, _, _ = SrvDupe.LoadFile(data.path)
    if not success then
        SrvDupeES.Notify("Invalid file, could not open or decode the file.", 1, 5, ply, true)
        return
    end


    SrvDupeES.SQL.SaveDupe(data)

    SrvDupeES.SendDupesAndCategories()
end)

net.Receive("SrvDupeES_DeleteCategory", function(_, ply)
    if not IsValid(ply) and not SrvDupeES.CheckPlyWritePermissions(ply) then
        SrvDupeES.Notify("You do not have permission to delete categories.", 1, 5, ply, true)
        return
    end

    local id = net.ReadString()

    if not id or id == "" then return end

    SrvDupeES.SQL.DeleteCategory(id)

    SrvDupeES.SendDupesAndCategories()
end)

net.Receive("SrvDupeES_DeleteDupe", function(_, ply)
    if not IsValid(ply) and not SrvDupeES.CheckPlyWritePermissions(ply) then
        SrvDupeES.Notify("You do not have permission to delete dupes.", 1, 5, ply, true)
        return
    end

    local id = net.ReadString()

    if not id or id == "" then return end

    SrvDupeES.SQL.DeleteDupe(id)

    SrvDupeES.SendDupesAndCategories()
end)