function SrvDupeES.CheckPlyWritePermissions(ply)
    local roles = SrvDupeES.Config.AllowedRolesWrite or {}
    local steamIDs = SrvDupeES.Config.AllowedSteamIDWrite or {}
    return table.HasValue(roles, ply:GetUserGroup()) or table.HasValue(steamIDs, ply:GetSteamID())
end
