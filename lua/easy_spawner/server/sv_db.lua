SrvDupeES.SQL = {}

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
			author TEXT NOT NULL,
			description TEXT,
			image TEXT,
			active INTEGER DEFAULT 1,
			created_by TEXT NOT NULL,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY(category_id) REFERENCES server_dupe_categories(id)
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

SrvDupeES.SQL.CreateTables()
print("-----------")
PrintTable(SrvDupeES.SQL.GetAllCategories())
print("-----------")
PrintTable(SrvDupeES.SQL.GetAllDupes())
