local function createAdminManagementWindow()
    if SrvDupeES.WindowAdmin then return end

    SrvDupeES.WindowAdmin = vgui.Create( "DFrame" )
    SrvDupeES.WindowAdmin:SetSize(750, 600)
    SrvDupeES.WindowAdmin:Center()
    SrvDupeES.WindowAdmin:SetTitle("Server Dupes - Admin Panel")
    SrvDupeES.WindowAdmin:SetVisible(true)
    SrvDupeES.WindowAdmin:SetDraggable(false)
    SrvDupeES.WindowAdmin:ShowCloseButton(true)
    SrvDupeES.WindowAdmin:MakePopup()

    local tabs = vgui.Create("DPropertySheet", SrvDupeES.WindowAdmin)
    tabs:Dock(FILL)

    -- Dupes
    SrvDupeES.VGUI.tabMngmtDupes(tabs)
    tabs:AddSheet("Dupes", SrvDupeES.WindowAdmin.MngDupes, "icon16/brick_edit.png")

    -- Categories
    SrvDupeES.VGUI.tabMngmtCategories(tabs)
    tabs:AddSheet("Categories", SrvDupeES.WindowAdmin.MngCategories, "icon16/folder.png")

    -- Permissions
    SrvDupeES.VGUI.tabMngmtPermissions(tabs)
    tabs:AddSheet("Permissions", SrvDupeES.WindowAdmin.MngPermissions, "icon16/key.png")

    SrvDupeES.WindowAdmin.Tabs = tabs
    SrvDupeES.WindowAdmin.OnClose = function()
        SrvDupeES.WindowAdmin = nil
    end
end

local function refreshPanels()
    if not SrvDupeES.WindowAdmin or not IsValid(SrvDupeES.WindowAdmin) then return end

    local activeTab = SrvDupeES.WindowAdmin.Tabs:GetActiveTab()
    local activeTabName = activeTab and activeTab:GetText() or ""

    SrvDupeES.WindowAdmin:Remove()
    SrvDupeES.WindowAdmin = nil
    createAdminManagementWindow()

    if SrvDupeES.WindowAdmin and SrvDupeES.WindowAdmin.Tabs then
        SrvDupeES.WindowAdmin.Tabs:SwitchToName(activeTabName)
    end
end

local function createButtonAdminManagement(parent)
    if not SrvDupeES.CheckPlyWritePermissions(LocalPlayer()) then return end

    SrvDupeES.ButtonManage = vgui.Create( "DButton", parent )
    SrvDupeES.ButtonManage:SetText("Admin Panel")
    SrvDupeES.ButtonManage:SetSize(120, 50)

    SrvDupeES.ButtonManage.DoClick = function()
        createAdminManagementWindow()
    end
end

spawnmenu.AddCreationTab("Server Dupes", function()
    SrvDupeES.PanelSpawnMenu = vgui.Create("SpawnmenuContentPanel")

    SrvDupeES.PanelSpawnMenu.OnSizeChanged = function(_, w, h)
        if not SrvDupeES.ButtonManage then return end
        SrvDupeES.ButtonManage:SetPos(w - 120 - 10, h - 50 - 10)
    end

    return SrvDupeES.PanelSpawnMenu
end, "icon16/server_database.png", 60)

local function openAndFillEntries(tabName, tabKey, id)
    if not SrvDupeES.WindowAdmin or not IsValid(SrvDupeES.WindowAdmin) then
        createAdminManagementWindow()
    end

    if SrvDupeES.WindowAdmin and SrvDupeES.WindowAdmin.Tabs then
        SrvDupeES.WindowAdmin.Tabs:SwitchToName(tabName)
    end

    local tab = SrvDupeES.WindowAdmin[tabKey]
    if not tab or not IsValid(tab) then return end
    tab.ListView:ClearSelection()
    tab.ListView.SelectLineByDataId(id)
end

spawnmenu.AddContentType("server_dupe", function( container, obj )
    if (not obj.dupe) then return end

    local dupe = obj.dupe
    local icon = vgui.Create("ContentIcon", container)
    icon:SetContentType("server_dupe")
    icon:SetSpawnName(dupe.id)
    icon:SetName(dupe.name)
    icon:SetMaterial("") -- TODO
    icon:SetColor(Color( 205, 92, 92, 255))

    local toolTip = (dupe.name or "") .. "\n"
    if dupe.description then
        toolTip = toolTip .. "\n" .. dupe.description
    end

    if dupe.author then
        toolTip = toolTip .. "\nAuthor: " .. dupe.author
    end

    icon:SetTooltip( toolTip )

    icon.DoClick = function()
        RunConsoleCommand("srvdupe_es_spawn", dupe.id)
        surface.PlaySound( "ui/buttonclickrelease.wav" )
    end

    icon.OpenMenuExtra = function( self, menu ) end
    icon.OpenMenu = function(self)
        local menu = DermaMenu()

        menu:AddOption("Copy to clipboard", function()
            SetClipboardText(dupe.id)
        end):SetIcon("icon16/page_copy.png")

        if SrvDupeES.CheckPlyWritePermissions(LocalPlayer()) then
            menu:AddSpacer()

            menu:AddOption("Edit", function()
                openAndFillEntries("Dupes", "MngDupes", dupe.id)
            end):SetIcon("icon16/pencil.png")

            menu:AddOption("Delete", function()
                Derma_Query("Are you sure you want to delete this dupe?", "Delete Dupe",
                    "Yes", function()
                        net.Start("SrvDupeES_DeleteDupe")
                        net.WriteString(dupe.id)
                        net.SendToServer()
                    end,
                    "No", function() end
                )
            end):SetIcon("icon16/delete.png")
        end

        menu:Open()
    end

    if ( IsValid( container ) ) then
        container:Add( icon )
    end

    return icon
end)

local function sortDupes(dupesTbl, key)
    table.sort(dupesTbl, function(a, b)
        if not a[key] or not b[key] then return false end
        return string.lower(a[key]) < string.lower(b[key])
    end)
end

local function sortCategories(categoriesTbl)
    local sortedKeys = {}
    for key in pairs(categoriesTbl) do
        table.insert(sortedKeys, key)
    end
    table.sort(sortedKeys)

    local sortedCategories = {}
    for _, key in ipairs(sortedKeys) do
        sortedCategories[key] = categoriesTbl[key]
        sortDupes(sortedCategories[key].dupes, "id")
    end
    return sortedCategories
end

function SrvDupeES.BuildDupesCategories()
    local categorisedDupes = {}

    for id, v in pairs(SrvDupeES.AvailableCategories) do
        categorisedDupes[v.id] = {
            name = v.name,
            dupes = {}
        }
    end

    for _, dupe in pairs(SrvDupeES.AvailableDupes) do
        if not dupe.active or dupe.active == 0 then continue end

        local categoryDupeId = dupe.category_id
        local categoryDupe = SrvDupeES.AvailableCategories[categoryDupeId]
        local categoryDupeId = "undefined"

        if categoryDupe then
            categoryDupeId = categoryDupe.id
        else
            categorisedDupes["undefined"] = categorisedDupes["undefined"] or {
                name = "Undefined",
                dupes = {}
            }
        end

        table.insert(categorisedDupes[categoryDupeId].dupes, dupe)
    end

    return sortCategories(categorisedDupes)
end

local function addCategory(tree, categoryId, tbl)
    local dupes = tbl.dupes or {}
    local categoryName = tbl.name or "Undefined"
    local node = tree:AddNode(categoryName)
    tree.Categories[categoryId] = node

    node.DoPopulate = function(self)
        self.PropPanel = vgui.Create("ContentContainer", tree.pnlContent)
        self.PropPanel:SetVisible(false)
        self.PropPanel:SetTriggerSpawnlistChange(false)

        for _, d in pairs(dupes) do
            local icon = spawnmenu.CreateContentIcon("server_dupe", self.PropPanel, {dupe = d })
            SrvDupeES.AttemptGetImage(d.image, function(imageData, ext)
                if not imageData or imageData == "" then return end

                local path = SrvDupeES.SaveImageIfNotExistsAndGet(d.id, imageData, ext)
                if path then
                    icon:SetMaterial("data/" .. path)
                end

            end)
        end
    end

    node.DoClick = function(self)
        self:DoPopulate()
        tree.pnlContent:SwitchPanel(self.PropPanel)
    end

    node.DoRightClick = function(self)
        tree.pnlContent:SwitchPanel(self.PropPanel)
        local menu = DermaMenu(self)
        menu:AddOption("Refresh", function()
            self:DoPopulate()
            tree.pnlContent:SwitchPanel(self.PropPanel)
        end):SetIcon("icon16/arrow_refresh.png")

        if SrvDupeES.CheckPlyWritePermissions(LocalPlayer()) and categoryId ~= "undefined" then
            menu:AddSpacer()

            menu:AddOption("Edit", function()
                openAndFillEntries("Categories", "MngCategories", categoryId)
            end):SetIcon("icon16/pencil.png")

            menu:AddOption("Delete Category", function()
                Derma_Query("Are you sure you want to delete this category?", "Delete Category",
                    "Yes", function()
                        net.Start("SrvDupeES_DeleteCategory")
                        net.WriteString(categoryId)
                        net.SendToServer()
                    end,
                    "No", function() end
                )
            end):SetIcon("icon16/delete.png")
        end

        menu:Open()
    end

    node.OnRemove = function(self)
        if IsValid(self.PropPanel) then
            self.PropPanel:Remove()
        end
    end

    return node
end

hook.Add("SrvDupeES_Populate", "SrvDupeES_Populate", function(pnlContent, tree, node)
    tree.Categories = tree.Categories or {}
    tree.pnlContent = pnlContent

    for k, v in pairs(tree.Categories) do
        v:Remove()
    end

    tree.Categories = {}

    local categorisedDupes = SrvDupeES.BuildDupesCategories()
    for categoryId, tbl in pairs(categorisedDupes) do
        addCategory(tree, categoryId, tbl)
    end

    refreshPanels()

	local firstNodeKey = next(tree.Categories)
	if (IsValid(tree.Categories[firstNodeKey or ""]) ) then
		tree.Categories[firstNodeKey]:InternalDoClick()
	end
end)

hook.Add("InitPostEntity", "SrvDupeES_InitPostEntity_SpawnDupe", function()
    createButtonAdminManagement(SrvDupeES.PanelSpawnMenu)

    net.Start("SrvDupe_ES_RequestDupesAndCategories")
    net.SendToServer()
end)

net.Receive("SrvDupe_ES_SendDupesAndCategories", function()
    local dupes = net.ReadTable() or {}
    local categories = net.ReadTable() or {}
    local permissions = net.ReadTable() or {}

    SrvDupeES.AvailableDupes = dupes
    SrvDupeES.AvailableCategories = categories
    SrvDupeES.Permissions = permissions

    SrvDupeES.PanelSpawnMenu:CallPopulateHook("SrvDupeES_Populate")
end)