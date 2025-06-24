local function tabMngmtDupes(tab)

end

local function tabMngmtCategories(tab)

end

local function createAdminManagementWindow()
    if SrvDupeES.WindowAdmin then return end

    SrvDupeES.WindowAdmin = vgui.Create( "DFrame" )
    SrvDupeES.WindowAdmin:SetSize(800, 500)
    SrvDupeES.WindowAdmin:Center()
    SrvDupeES.WindowAdmin:SetTitle("Name window")
    SrvDupeES.WindowAdmin:SetVisible(true)
    SrvDupeES.WindowAdmin:SetDraggable(false)
    SrvDupeES.WindowAdmin:ShowCloseButton(true)
    SrvDupeES.WindowAdmin:MakePopup()

    local tabs = vgui.Create("DPropertySheet", SrvDupeES.WindowAdmin)
    tabs:Dock(FILL)

    -- Dupes
    local mngDupe = vgui.Create("DPanel", tabs)
    tabMngmtDupes(mngDupe)
    tabs:AddSheet("Dupes", mngDupe, "icon16/brick_edit.png")

    -- Categories
    local mngCat = vgui.Create("DPanel", tabs)
    tabMngmtCategories(mngCat)
    tabs:AddSheet("Categories", mngCat, "icon16/folder.png")

    SrvDupeES.WindowAdmin.OnClose = function()
        SrvDupeES.WindowAdmin = nil
    end
end

local function createButtonAdminManagement(parent)
    if not SrvDupeES.CheckPlyWritePermissions(LocalPlayer()) then return end

    SrvDupeES.ButtonManage = vgui.Create( "DButton", parent )
    SrvDupeES.ButtonManage:SetText("Admin Management")
    SrvDupeES.ButtonManage:SetSize(120, 50)

    SrvDupeES.ButtonManage.DoClick = function()
        createAdminManagementWindow()
    end
end

spawnmenu.AddCreationTab( "Server Dupes", function()
    SrvDupeES.PanelSpawnMenu = vgui.Create("SpawnmenuContentPanel")

    SrvDupeES.PanelSpawnMenu.OnSizeChanged = function(_, w, h)
        if not SrvDupeES.ButtonManage then return end
        SrvDupeES.ButtonManage:SetPos(w - 120 - 10, h - 50 - 10)
    end

    return SrvDupeES.PanelSpawnMenu
end, "icon16/server_database.png", 60 )

spawnmenu.AddContentType( "server_dupe", function( container, obj )
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
        RunConsoleCommand("srvdupe_spawn", dupe.path) -- TODO: Edit or use another command to work with the dupe id
        surface.PlaySound( "ui/buttonclickrelease.wav" )
    end

    icon.OpenMenuExtra = function( self, menu ) end
    icon.OpenMenu = icon.OpenGenericSpawnmenuRightClickMenu

    if ( IsValid( container ) ) then
        container:Add( icon )
    end

    return icon
end)

local function buildDupesCategories()
    local categorisedDupes = {}

    for id, v in pairs(SrvDupeES.AvailableCategories) do
        categorisedDupes[v.name] = {}
    end

    for _, dupe in pairs(SrvDupeES.AvailableDupes) do
        if not dupe.active or dupe.active == 0 then continue end

        local categoryDupeId = dupe.category_id
        local categoryDupe = SrvDupeES.AvailableCategories[categoryDupeId]
        local categoryDupeName = "Undefined"

        if categoryDupe then
            categoryDupeName = categoryDupe.name
        else
            categorisedDupes["Undefined"] = categorisedDupes["Undefined"] or {}
        end

        table.insert(categorisedDupes[categoryDupeName], dupe)
    end

    return categorisedDupes
end

local function addCategory(tree, categoryName, dupes)
    local node = tree:AddNode(categoryName)
    tree.Categories[categoryName] = node

    node.DoPopulate = function(self)
        print("node.DoPopulate")

        self.PropPanel = vgui.Create("ContentContainer", tree.pnlContent)
        self.PropPanel:SetVisible(false)
        self.PropPanel:SetTriggerSpawnlistChange(false)

        for _, d in pairs(dupes) do
            spawnmenu.CreateContentIcon("server_dupe", self.PropPanel, {dupe = d })
        end
    end

    node.DoClick = function(self)
        self:DoPopulate()
        tree.pnlContent:SwitchPanel(self.PropPanel)
    end

    node.OnRemove = function(self)
        if IsValid(self.PropPanel) then
            self.PropPanel:Remove()
        end
    end

    return node
end

hook.Add("SrvDupeES_Populate", "SrvDupeES_Populate", function(pnlContent, tree, node)
    print("SrvDupeES_Populate")

    tree.Categories = {}
    tree.pnlContent = pnlContent

    local categorisedDupes = buildDupesCategories()
    PrintTable(buildDupesCategories())
    for categoryName, dupes in pairs(categorisedDupes) do
        addCategory(tree, categoryName, dupes)
    end

    local firstNode = tree:Root():GetChildNode(0)
    if IsValid(firstNode) then
        firstNode:InternalDoClick()
    end
end)

hook.Add("InitPostEntity", "SrvDupeES_InitPostEntity_SpawnDupe", function()
    createButtonAdminManagement(SrvDupeES.PanelSpawnMenu)

    net.Start("SrvDupe_ES_RequestDupesAndCategories")
    net.SendToServer()
end)

net.Receive("SrvDupe_ES_SendDupesAndCategories", function()
    print("SrvDupe_ES_SendDupesAndCategories")

    local dupes = net.ReadTable() or {}
    local categories = net.ReadTable() or {}
    PrintTable(dupes)
    PrintTable(categories)

    SrvDupeES.AvailableDupes = dupes
    SrvDupeES.AvailableCategories = categories

    SrvDupeES.PanelSpawnMenu:CallPopulateHook("SrvDupeES_Populate")
end)