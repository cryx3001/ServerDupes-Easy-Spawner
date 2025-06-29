SrvDupeES.SQL = {}
SrvDupeES.SQL.Enums = {}

function SrvDupeES.SQL.CreateTables()
    sql.Query([[
		CREATE TABLE IF NOT EXISTS server_dupe_categories (
			id TEXT PRIMARY KEY,
			name TEXT NOT NULL
		);
	]])

    sql.Query([[
		CREATE TABLE IF NOT EXISTS server_dupe_items (
			id TEXT PRIMARY KEY,
			category_id TEXT NOT NULL,
			name TEXT NOT NULL,
			path TEXT NOT NULL,
			author TEXT,
			description TEXT,
			image TEXT,
			active INTEGER DEFAULT 1,
			added_by TEXT NOT NULL,
			FOREIGN KEY(category_id) REFERENCES server_dupe_categories(id)
		);
	]])

    sql.Query([[
        CREATE TABLE IF NOT EXISTS server_dupe_usergroup_global_limits (
            usergroup TEXT PRIMARY KEY,
            max_value INTEGER DEFAULT -1
        );
    ]]
    )

    sql.Query([[
        CREATE TABLE IF NOT EXISTS server_dupe_item_limits (
            id TEXT NOT NULL,
            usergroup TEXT NOT NULL,
            max_value INTEGER DEFAULT -1,
            UNIQUE(id, usergroup)
        );
    ]])

    sql.Query([[
        CREATE TABLE IF NOT EXISTS server_dupe_category_limits (
            id TEXT NOT NULL,
            usergroup TEXT NOT NULL,
            max_value INTEGER DEFAULT -1,
            UNIQUE(id, usergroup)
        );
    ]])
end

local function forgeSQLInsert(tblName, tblKeysValue)
    local keysStr = ""
    local valuesStr = ""
    for k, v in pairs(tblKeysValue) do
        keysStr = keysStr .. ", " .. sql.SQLStr(k, true)
        valuesStr = valuesStr .. ", " .. sql.SQLStr(v)
    end

    keysStr = string.TrimLeft(keysStr, ",")
    valuesStr = string.TrimLeft(valuesStr, ",")

    return "INSERT INTO " .. sql.SQLStr(tblName, true) .. " ( " .. keysStr .. " ) VALUES ( " .. valuesStr .. " )"
end

local function forgeSQLUpdate(tblName, tblKeysValue)
    local updatedKeysValues = ""
    for k, v in pairs(tblKeysValue) do
        updatedKeysValues = updatedKeysValues .. "," .. sql.SQLStr(k, true) .. " = " .. sql.SQLStr(v)
    end

    updatedKeysValues = string.TrimLeft(updatedKeysValues, ",")

    return "UPDATE " .. sql.SQLStr(tblName, true) .. " SET " .. updatedKeysValues
end

local function clearNullResults(tbl)
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            clearNullResults(v)
            continue
        end
        if v == "NULL" then
            tbl[k] = nil
        end
    end
    return tbl
end

local function setPrimaryKeyAsTblKey(tbl, primaryKey)
    local resTbl = {}
    for _, t in pairs(tbl) do
        resTbl[t[primaryKey]] = t
    end
    return resTbl
end

-- DUPES
function SrvDupeES.SQL.GetDupe(id)
    local result = sql.QueryRow("SELECT * FROM server_dupe_items WHERE id = " .. sql.SQLStr(id))
    return clearNullResults(result or {})
end

function SrvDupeES.SQL.GetAllDupes()
    local result = sql.Query("SELECT * FROM server_dupe_items")
    result = setPrimaryKeyAsTblKey(result or {}, "id")
    return clearNullResults(result)
end

function SrvDupeES.SQL.GetDupesOfCategory(category_id)
    local result = sql.Query("SELECT * FROM server_dupe_items WHERE category_id = " .. sql.SQLStr(category_id))
    return clearNullResults(result or {})
end

function SrvDupeES.SQL.SaveDupe(data)
    if not data or not data.id or not data.name or not data.category_id or not data.path then return end

    local selectedId = data.SELECTED_ID
    local tblKeysValue = {
        id = data.id,
        category_id = data.category_id,
        name = data.name,
        path = data.path,
        author = data.author,
        description = data.description,
        image = data.image,
        active = tonumber(data.active) or 1,
        added_by = data.added_by
    }

    local query
    if selectedId and selectedId ~= "" then
        query = forgeSQLUpdate("server_dupe_items", tblKeysValue) .. " WHERE id = " .. sql.SQLStr(selectedId)
    else
        query = forgeSQLInsert("server_dupe_items", tblKeysValue)
    end

    return sql.Query(query)
end

function SrvDupeES.SQL.DeleteDupe(id)
    if not id or id == "" then return end

    local query = "DELETE FROM server_dupe_items WHERE id = " .. sql.SQLStr(id)
    return sql.Query(query)
end

-- CATEGORIES
function SrvDupeES.SQL.GetCategory(id)
    local result = sql.QueryRow("SELECT * FROM server_dupe_categories WHERE id = " .. sql.SQLStr(id))
    return clearNullResults(result or {})
end

function SrvDupeES.SQL.GetAllCategories()
    local result = sql.Query("SELECT * FROM server_dupe_categories")
    result = setPrimaryKeyAsTblKey(result or {}, "id")
    return clearNullResults(result)
end

function SrvDupeES.SQL.SaveCategory(data)
    if not data or not data.id or not data.name then return end

    local selectedId = data.SELECTED_ID
    local tblKeysValue = {
        id = data.id,
        name = data.name
    }

    local query
    if selectedId and selectedId ~= "" then
        query = forgeSQLUpdate("server_dupe_categories", tblKeysValue) .. " WHERE id = " .. sql.SQLStr(selectedId)
    else
        query = forgeSQLInsert("server_dupe_categories", tblKeysValue)
    end

    return sql.Query(query)
end

function SrvDupeES.SQL.DeleteCategory(id)
    if not id or id == "" then return end

    local query = "DELETE FROM server_dupe_categories WHERE id = " .. sql.SQLStr(id)
    return sql.Query(query)
end

-- Permissions
SrvDupeES.SQL.Enums.PermissionsTbl = {
    USERGROUP_GLOBAL_LIMITS = "server_dupe_usergroup_global_limits",
    DUPE_LIMITS = "server_dupe_item_limits",
    CATEGORY_LIMITS = "server_dupe_category_limits",
}

function SrvDupeES.SQL.GetAllPermissions(nameTbl)
    if not nameTbl then return {} end

    local query = "SELECT * FROM " .. sql.SQLStr(nameTbl, true)
    local result = sql.Query(query)
    return clearNullResults(result or {})
end

function SrvDupeES.SQL.GetPermissionsOfId(nameTbl, id)
    if not nameTbl or not id then return {} end

    local query = "SELECT * FROM " .. sql.SQLStr(nameTbl, true) .. " WHERE id = " .. sql.SQLStr(id)
    local result = sql.Query(query)
    return clearNullResults(result or {})
end

function SrvDupeES.SQL.GetPermissionsOfUsergroup(nameTbl, usergroup)
    if not nameTbl or not usergroup then return {} end

    local query = "SELECT * FROM " .. sql.SQLStr(nameTbl, true) .. " WHERE usergroup = " .. sql.SQLStr(usergroup)
    local result = sql.Query(query)
    return clearNullResults(result or {})
end

function SrvDupeES.SQL.GetPermissionsOfIdAndUsergroup(nameTbl, id, usergroup)
    if not nameTbl or not id or not usergroup then return {} end

    local query = "SELECT * FROM " .. sql.SQLStr(nameTbl, true) .. " WHERE id = " .. sql.SQLStr(id) .. " AND usergroup = " .. sql.SQLStr(usergroup)
    local result = sql.QueryRow(query)
    return clearNullResults(result or {})
end

function SrvDupeES.SQL.DeletePermissionItem(nameTbl, id, usergroup)
    if not nameTbl or not id or not usergroup then return end

    local query = "DELETE FROM " .. sql.SQLStr(nameTbl, true) .. " WHERE id = " .. sql.SQLStr(id) .. " AND usergroup = " .. sql.SQLStr(usergroup)
    return sql.Query(query)
end

function SrvDupeES.SQL.DeletePermissionGlobalLimit(nameTbl, usergroup)
    if not nameTbl or not usergroup then return end

    local query = "DELETE FROM " .. sql.SQLStr(nameTbl, true) .. " WHERE usergroup = " .. sql.SQLStr(usergroup)
    return sql.Query(query)
end

function SrvDupeES.SQL.SavePermission(nameTbl, data)
    if not nameTbl or not data or not data.id or not data.usergroup then return end

    local selectedId = data.SELECTED_ID
    local tblKeysValue = {
        id = data.id,
        usergroup = data.usergroup,
        max_value = tonumber(data.max_value) or -1
    }

    local query
    if selectedId and selectedId ~= "" then
        query = forgeSQLUpdate(nameTbl, tblKeysValue) .. " WHERE id = " .. sql.SQLStr(selectedId) .. " AND usergroup = " .. sql.SQLStr(data.usergroup)
    else
        query = forgeSQLInsert(nameTbl, tblKeysValue)
    end

    return sql.Query(query)
end

function SrvDupeES.SQL.SaveUserGroupLimit(usergroup, maxValue)
    if not usergroup or not maxValue then return end

    local tblKeysValue = {
        usergroup = usergroup,
        max_value = tonumber(maxValue) or -1
    }

    local exists =  (SrvDupeES.SQL.GetPermissionsOfUsergroup(SrvDupeES.SQL.Enums.PermissionsTbl.USERGROUP_GLOBAL_LIMITS, usergroup) or {})[1]
    local query
    if exists then
        query = forgeSQLUpdate("server_dupe_usergroup_global_limits", tblKeysValue) .. " WHERE usergroup = " .. sql.SQLStr(usergroup)
    else
        query = forgeSQLInsert("server_dupe_usergroup_global_limits", tblKeysValue)
    end

    return sql.Query(query)
end

SrvDupeES.SQL.CreateTables()