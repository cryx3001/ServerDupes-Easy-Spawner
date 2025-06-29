local function populateItemsList(tab, node, data, idToFilter)
    tab.list_items:Clear()

    local dataFiltered = {}
    for k, tbl in pairs(data) do
        if not idToFilter or (idToFilter and tbl.id == idToFilter) then
            dataFiltered[k] = tbl
        end
    end

    for _, item in pairs(dataFiltered) do
        local limit = item.max_value or -1
        if limit == "-1" then
            limit = "∞"
        end

        local line = tab.list_items:AddLine(item.usergroup, item.id or "", limit)
        line.itemData = item
        line.itemData.node = node
        line.OnSelect = function()
            tab.SelectedItem = line
        end
    end
end

local function populateUsergroups(tab)
    tab.list_usergroups:Clear()

    local listUserGroups = CAMI.GetUsergroups()
    for k, group in pairs(listUserGroups) do
        local line = tab.list_usergroups:AddLine(group.Name)
        line.itemData = group.Name or k
        line.OnSelect = function()
            tab.SelectedUserGroup = line
        end
    end

    if #tab.list_usergroups:GetLines() > 0 then
        tab.list_usergroups:SelectFirstItem()
        _, tab.SelectedUserGroup = tab.list_usergroups:GetSelectedLine()
    else
        tab.SelectedUserGroup = nil
    end
end

local function nodeDoClick(tab, node)
    tab.SelectedNode = node
    tab.SelectedItem = nil
    populateItemsList(tab, node, SrvDupeES.Permissions[node.type] or {}, node.itemData)
end

local function createCategoryNode(tab, categoryId, dupesTbl)
    local nodeCategory = tab.list_suggestions.ItemsNode:AddNode(categoryId or "undefined", "icon16/folder.png")
    nodeCategory.itemData = categoryId
    nodeCategory.type = "CATEGORY_LIMITS"
    nodeCategory.Dupes = {}

    for _, dupe in pairs(dupesTbl) do
        local nodeDupe = nodeCategory:AddNode(dupe.id, "icon16/brick.png")
        nodeDupe.itemData = dupe.id
        nodeDupe.type = "DUPE_LIMITS"
        nodeDupe.DoClick = function(self)
            nodeDoClick(tab, self)
        end
    end

    nodeCategory:ExpandRecurse(true)
    nodeCategory.DoClick = function(self)
        nodeDoClick(tab, self)
    end
end

local function populateSuggestions(tab)
    tab.list_suggestions:Clear()

    local categorisedDupes = SrvDupeES.BuildDupesCategories()

    local nodeGlobalMaxDupes = tab.list_suggestions:AddNode("Max dupes for usergroup", "icon16/user.png")
    nodeGlobalMaxDupes.type = "USERGROUP_GLOBAL_LIMITS"
    nodeGlobalMaxDupes.DoClick = function(self)
        nodeDoClick(tab, self)
    end

    tab.list_suggestions.ItemsNode = tab.list_suggestions:AddNode("Item limits", "icon16/brick.png")

    for categoryId, tbl in pairs(categorisedDupes) do
        createCategoryNode(tab, categoryId, tbl.dupes or {})
    end
    tab.list_suggestions.ItemsNode:ExpandRecurse(true)
end

local function onButtonDeleteClick(tab)
    if not tab.SelectedItem then 
        SrvDupeES.Notify("No item selected to delete.", 1, 5)
        return
    end

    local itemData = tab.SelectedItem.itemData
    local usergroup = itemData.usergroup
    local id = itemData.id or ""
    local type = itemData.node.type

    print("DELETE ", usergroup, "X", id, type)
    RunConsoleCommand("srvdupe_es_limits", "delete", type, usergroup, 0, id)
end

local function onButtonAddClick(tab)
    if not tab.SelectedUserGroup then
        SrvDupeES.Notify("No usergroup selected.", 1, 5)
        return
    end

    if not tab.SelectedNode then
        SrvDupeES.Notify("No item selected.", 1, 5)
        return
    end

    local valueSlider = tab.slider_limit:GetValue()
    local usergroup = tab.SelectedUserGroup.itemData
    local itemData = tab.SelectedNode.itemData
    local type = tab.SelectedNode.type

    print("ADD ", usergroup, valueSlider, itemData, type)
    RunConsoleCommand("srvdupe_es_limits", "add", type, usergroup, valueSlider, itemData)
end

local function onButtonEditClick(tab)
    if not tab.SelectedItem then
        SrvDupeES.Notify("No item selected to delete.", 1, 5)
        return
    end

    local valueSlider = tab.slider_limit:GetValue()
    local itemData = tab.SelectedItem.itemData
    local usergroup = itemData.usergroup
    local id = itemData.id or ""
    local type = itemData.node.type


    print("EDIT ", usergroup, valueSlider, id, type)
    RunConsoleCommand("srvdupe_es_limits", "edit", type, usergroup, valueSlider, id)
end

function SrvDupeES.VGUI.tabMngmtPermissions(tabs)
    local tab = vgui.Create("DPanel", tabs)
    tab:SetSize(SrvDupeES.WindowAdmin:GetWide(), SrvDupeES.WindowAdmin:GetTall() - 70)
    SrvDupeES.WindowAdmin.MngPermissions = tab

	tab.Command = {}
	tab.Command.Add = "setlimit"
	tab.Command.Delete = "unsetlimit"
	tab.Command.Edit = "setlimit"

	--Limit chooser
	tab.slider_limit = vgui.Create("SrvDupeESSlider", tab)
	tab.slider_limit:SetMinMax(1, 500)
	tab.slider_limit:SetText("Limit")
	tab.slider_limit:SetMaxOverride(-1, "∞")
    tab.slider_limit:SetPos(5, 5)
	tab.slider_limit:SetDecimals(0)
	tab.slider_limit:SetSize(100, 40)

	--Usergroups list
	tab.list_usergroups = vgui.Create("DListView", tab)
	tab.list_usergroups:SetMultiSelect(true)
	tab.list_usergroups:AddColumn("Usergroups")
    
    tab.list_usergroups:SetPos(5, tab.slider_limit.y + tab.slider_limit:GetTall() + 5)
	tab.list_usergroups:SetSize(tab.slider_limit:GetWide(), tab:GetTall() - tab.list_usergroups.y - 5)

	--Edit button
	tab.button_edit = vgui.Create("DButton", tab)
	tab.button_edit:SetText("Edit")
	tab.button_edit.DoClick = function()
        onButtonEditClick(tab)
    end
    tab.button_edit:SetSize(200, 25)
	tab.button_edit:SetPos(tab:GetWide() - 30 - tab.button_edit:GetWide(), tab:GetTall() - 5 - tab.button_edit:GetTall())

	--Delete button
	tab.button_delete = vgui.Create("DButton", tab)
	tab.button_delete:SetText("Delete")
	tab.button_delete.DoClick = function()
        onButtonDeleteClick(tab)
    end
    tab.button_delete:SetSize(tab.button_edit:GetSize())
	tab.button_delete:SetPos(tab.button_edit.x, (tab.button_edit.y - 5) - tab.button_delete:GetTall())

	--Add button
	tab.button_add = vgui.Create("DButton", tab)
	tab.button_add:SetText("Add")
	tab.button_add.DoClick = function()
        onButtonAddClick(tab)
    end

	tab.button_add:SetSize(tab.button_edit:GetSize())
	tab.button_add:SetPos(tab.button_delete.x, (tab.button_delete.y - 5) - tab.button_delete:GetTall())

	--Suggestion list
	tab.list_suggestions = vgui.Create("DTree", tab)
	tab.list_suggestions:SetPos(tab.button_add.x, 5)
	tab.list_suggestions:SetSize(tab.button_edit:GetWide(), tab.button_add.y - tab.list_suggestions.y - 5)

    --Items list
	tab.list_items = vgui.Create("DListView", tab)
	tab.list_items:AddColumn("Usergroup")
	tab.list_items:AddColumn("Item")
	tab.list_items:AddColumn("Limit"):SetFixedWidth(70)
    tab.list_items:SetPos(tab.slider_limit.x + 5 + tab.slider_limit:GetWide(), 5)
    tab.list_items:SetSize(tab.list_suggestions.x - tab.list_items.x - 5, tab:GetTall() - 10)

    populateUsergroups(tab)
    populateSuggestions(tab)
end