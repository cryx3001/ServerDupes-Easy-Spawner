local PLY = FindMetaTable("Player")

function PLY:GetDupeCount(categoryId, dupeId)
    if not self.SrvDupeES.OwnedDupes or not self.SrvDupeES.OwnedDupes[categoryId] then
        return 0
    end

    return self.SrvDupeES.OwnedDupes[categoryId][dupeId] or 0
end

function PLY:GetDupeCountByCategory(categoryId)
    if not self.SrvDupeES.OwnedDupes or not self.SrvDupeES.OwnedDupes[categoryId] then
        return 0
    end
    local count = 0
    for _, dupeCount in pairs(self.SrvDupeES.OwnedDupes[categoryId]) do
        count = count + dupeCount
    end
    return count
end

function PLY:GetAllDupesCount()
    if not self.SrvDupeES.OwnedDupes then
        return 0
    end

    local totalCount = 0
    for categoryId, dupes in pairs(self.SrvDupeES.OwnedDupes) do
        totalCount = totalCount + self:GetDupeCountByCategory(categoryId)
    end

    return totalCount
end

function PLY:IncrementDupeCount(categoryId, dupeId, count)
    if not self.SrvDupeES.OwnedDupes[categoryId] then
        self.SrvDupeES.OwnedDupes[categoryId] = {}
    end

    if not self.SrvDupeES.OwnedDupes[categoryId][dupeId] then
        self.SrvDupeES.OwnedDupes[categoryId][dupeId] = 0
    end

    self.SrvDupeES.OwnedDupes[categoryId][dupeId] = self.SrvDupeES.OwnedDupes[categoryId][dupeId] + (count or 1)
end

function PLY:CanSpawnDupe(categoryId, dupeId)
    -- TODO: temp
    local allowedRolesSpawn = SrvDupeES.Config.AllowedRolesToSpawn or {}
    local allowSteamIDSpawn = SrvDupeES.Config.AllowedSteamIDToSpawn or {}

    if not table.HasValue(allowedRolesSpawn, self:GetUserGroup()) and not table.HasValue(allowSteamIDSpawn, self:SteamID()) then
        return false, "You do not have permission to spawn dupes!"
    end

    if not self.SrvDupeES.OwnedDupes or not self.SrvDupeES.OwnedDupes[categoryId] then
        return true
    end

    -- TODO: temp solution, go db

    if self:GetDupeCount(categoryId, dupeId) >= (SrvDupeES.Config.MaxDupesPerPlayer) then
        return false, "You have reached the limit of dupes you can spawn!"
    end

    return true
end