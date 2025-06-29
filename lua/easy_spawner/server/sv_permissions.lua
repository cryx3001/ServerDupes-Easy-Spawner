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

local function checkLimits(ply, dupeId, categoryId)
    local dupeLimitTbl = SrvDupeES.SQL.GetPermissionsOfIdAndUsergroup(SrvDupeES.SQL.Enums.PermissionsTbl.DUPE, dupeId, ply:GetUserGroup())
    local categoryLimitTbl = SrvDupeES.SQL.GetPermissionsOfIdAndUsergroup(SrvDupeES.SQL.Enums.PermissionsTbl.CATEGORY, categoryId, ply:GetUserGroup())

    local dupeLimit = dupeLimitTbl and tonumber(dupeLimitTbl.max_value) or -1
    local categoryLimit = categoryLimitTbl and tonumber(categoryLimitTbl.max_value) or -1

    if dupeLimit == -1 then
        dupeLimit = math.huge
    end

    if categoryLimit == -1 then
        categoryLimit = math.huge
    end

    local dupeSpawned = ply:GetDupeCount(categoryId, dupeId)
    local categorySpawned = ply:GetDupeCountByCategory(categoryId)

    if categorySpawned >= categoryLimit then
        return false, "You have reached the limit of dupes you can spawn in this category!"
    end

    if dupeSpawned >= dupeLimit then
        return false, "You have reached the limit of this dupe you can spawn!"
    end

    return true
end

function PLY:CanSpawnDupe(categoryId, dupeId)
    local allowedRolesSpawn = SrvDupeES.Config.AllowedRolesToSpawn or {}
    local allowSteamIDSpawn = SrvDupeES.Config.AllowedSteamIDToSpawn or {}

    if not table.HasValue(allowedRolesSpawn, self:GetUserGroup()) and not table.HasValue(allowSteamIDSpawn, self:SteamID()) then
        return false, "You do not have permission to spawn dupes!"
    end

    local maxDupesPerPlayer = GetConVar("srvdupe_es_max_dupes_per_player"):GetInt() or 50
    if maxDupesPerPlayer < 0 then
        maxDupesPerPlayer = math.huge
    end

    if self:GetDupeCount(categoryId, dupeId) >= maxDupesPerPlayer then
        return false, "You have reached the limit of dupes you can spawn!"
    end

    return checkLimits(self, dupeId, categoryId)
end



local possibleTypesItem = {
    CATEGORY_LIMITS = true,
    DUPE_LIMITS = true,
    USERGROUP_GLOBAL_LIMITS = false,
}

local function addLimit(ply, data)
    if not data or not data.type or not data.usergroup or not data.maxValue then return false end
    if possibleTypesItem[data.type] == nil or (possibleTypesItem[data.type] == true and not data.idItem) then
        return false
    end

    if data.type == "DUPE_LIMITS" or data.type == "CATEGORY_LIMITS" then
        local dataQuery = {
            id = data.idItem,
            usergroup = data.usergroup,
            max_value = data.maxValue
        }
        return SrvDupeES.SQL.SavePermission(SrvDupeES.SQL.Enums.PermissionsTbl[data.type], dataQuery)
    else
        return SrvDupeES.SQL.SaveUserGroupLimit(data.usergroup, data.maxValue)
    end
end

local function editLimit(ply, data)
    if not data or not data.type or not data.usergroup or not data.maxValue then return end
    if possibleTypesItem[data.type] == nil or (possibleTypesItem[data.type] == true and not data.idItem) then
        return false
    end

    if data.type == "DUPE_LIMITS" or data.type == "CATEGORY_LIMITS" then
        local dataQuery = {
            id = data.idItem,
            usergroup = data.usergroup,
            max_value = data.maxValue,
            SELECTED_ID = data.idItem
        }
        return SrvDupeES.SQL.SavePermission(SrvDupeES.SQL.Enums.PermissionsTbl[data.type], dataQuery)
    else
        return SrvDupeES.SQL.SaveUserGroupLimit(data.usergroup, data.maxValue)
    end
end

local function deleteLimit(ply, data)
    if not data or not data.type or not data.usergroup then return end
    if possibleTypesItem[data.type] == nil or (possibleTypesItem[data.type] == true and not data.idItem) then
        return false
    end

    if data.type == "DUPE_LIMITS" or data.type == "CATEGORY_LIMITS" then
        return SrvDupeES.SQL.DeletePermissionItem(SrvDupeES.SQL.Enums.PermissionsTbl[data.type], data.idItem, data.usergroup)
    else
        return SrvDupeES.SQL.DeletePermissionGlobalLimit(SrvDupeES.SQL.Enums.PermissionsTbl[data.type], data.usergroup)
    end
end

local possibleTypesOp = {
    add = addLimit,
    edit = editLimit,
    delete = deleteLimit
}
function SrvDupeES.HandleLimitsCommand(ply, args)
    if not SrvDupeES.CheckPlyWritePermissions(ply) then
        SrvDupeES.Notify("You do not have permission to modify limits.", 1, 5, ply, true)
        return
    end

    if #args < 3 then
        return
    end

    local typeOp = args[1]
    local funcTypeOp = possibleTypesOp[typeOp]
    if not funcTypeOp then
        return
    end
    local data = {
        type = args[2],
        usergroup = args[3],
        maxValue = tonumber(args[4]),
        idItem = args[5]
    }

    local res =funcTypeOp(ply, data) == nil
    SrvDupeES.SendDupesAndCategories()
    return res
end
