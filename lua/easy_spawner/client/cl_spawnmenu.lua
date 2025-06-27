local function checkBlankOrEmptyStr(str)
    return not str or str == "" or str:Trim() == " \t"
end

local function checkMandatoryStrFields(tbl, fields)
    for _, field in ipairs(fields) do
        if checkBlankOrEmptyStr(tbl[field]) then
            return false, "Field '" .. field .. "' is mandatory."
        end
    end
    return true, nil
end

local function clearEmptyEntries(tbl)
    for k, v in pairs(tbl) do
        if type(v) == "string" and checkBlankOrEmptyStr(v) then
            tbl[k] = nil
        end
    end
end

local function createListPanel(parent, tbl)
    local listPanel = vgui.Create("DPanel", parent)
    listPanel:Dock(LEFT)
    listPanel:SetWidth(200)

    local listView = vgui.Create("DListView", listPanel)
    listView:Dock(FILL)
    listView:AddColumn("Name")
    listView:AddColumn("ID")
    listView:SetMultiSelect(false)

    parent.SelectedLine = nil

    for _, item in pairs(tbl) do
        local line = listView:AddLine(item.name, item.id)
        line.itemData = item
        line.OnSelect = function()
            parent.SelectedLine = line

            if IsValid(parent.SaveButton) and parent.SaveButton.SetText then
                parent.SaveButton:SetText("Update " .. item.name)
            end

            if parent.Entries then
                for key, entry in pairs(parent.Entries) do
                    if IsValid(entry) and entry.SetValue then
                        entry:SetValue(item[key] or "")
                    end
                end
            end
        end
    end

    local addButton = vgui.Create("DButton", listPanel)
    addButton:Dock(BOTTOM)
    addButton:SetText("Add New")
    addButton.DoClick = function ()
        parent.SelectedLine = nil
        listView:ClearSelection()
        if IsValid(parent.SaveButton) and parent.SaveButton.SetText then
            parent.SaveButton:SetText("Save")
        end

        if parent.Entries then
            for _, entry in pairs(parent.Entries) do
                if IsValid(entry) and entry.SetValue then
                    entry:SetValue("")
                end
            end
        end
    end

    return listView
end

local function panelWithLabel(parent, labelText, entry, funcOnCreationEntry)
    if not entry then return end

    local panel = vgui.Create("DPanel", parent)
    panel:Dock(TOP)
    panel:DockMargin(5, 5, 5, 5)

    local label = vgui.Create("DLabel", panel)
    label:Dock(TOP)
    label:SetText(labelText)
    label:SetColor(color_black)

    entry:SetParent(panel)
    entry:Dock(TOP)

    if funcOnCreationEntry then
        funcOnCreationEntry(entry)
    end

    panel:SetHeight(label:GetTall() + entry:GetTall() + 5)

    return entry
end

local function saveButtonDoClick(tab, mandatoryFields, netMessage)
    local dataEntries = {}

    for key, entry in pairs(tab.Entries) do
        if IsValid(entry) and entry.GetValue then
            dataEntries[key] = entry:GetValue()
        end
    end

    local isValid, errMsg = checkMandatoryStrFields(dataEntries, mandatoryFields)
    if not isValid then
        SrvDupeES.Notify(errMsg, 1, 5)
        return
    end

    if tab.SelectedLine then
        dataEntries.SELECTED_ID = tab.SelectedLine.itemData.id
    end

    clearEmptyEntries(dataEntries)

    net.Start(netMessage)
        net.WriteTable(dataEntries)
    net.SendToServer()

    surface.PlaySound("ui/buttonclickrelease.wav")
end

local function createSaveButton(parent, tab, mandatoryFields, netMessage)
    local saveButton = vgui.Create("DButton", parent)
    saveButton:Dock(BOTTOM)
    saveButton:DockMargin(10, 50, 10, 10)
    saveButton:SetText("Save")
    saveButton.DoClick = function()
        saveButtonDoClick(tab, mandatoryFields, netMessage)
    end

    return saveButton
end

local function tabMngmtDupes(tabs)
    local tab = vgui.Create("DPanel", tabs)
    SrvDupeES.WindowAdmin.MngDupes = tab

    tab.Entries = tab.Entries or {}

    local panel = vgui.Create("DPanel", tab)
    panel:Dock(FILL)

    tab.Entries.id = panelWithLabel(panel, "* ID", vgui.Create("DTextEntry"))
    tab.Entries.name = panelWithLabel(panel, "* Name", vgui.Create("DTextEntry"))

    tab.Entries.category_id = panelWithLabel(panel, "* Category", vgui.Create("DComboBox", panel), function(combo)
        for k, v in pairs(SrvDupeES.AvailableCategories) do
            combo:AddChoice(v.name, v.id)
        end
    end)
    tab.Entries.category_id.SetValue = function(self, category_id)
        local dataChoices = tab.Entries.category_id.Data
        for k, v in pairs(dataChoices) do
            if v == category_id then
                tab.Entries.category_id:ChooseOptionID(k)
                return
            end
        end
    end
    tab.Entries.category_id.GetValue = function()
        local _, data = tab.Entries.category_id:GetSelected()
        return data
    end

    tab.Entries.path = panelWithLabel(panel, "* Path (relative to srvdupe/)", vgui.Create("DTextEntry"))
    tab.Entries.author = panelWithLabel(panel, "Author", vgui.Create("DTextEntry"))
    tab.Entries.description = panelWithLabel(panel, "Description", vgui.Create("DTextEntry"), function(entry)
        entry:SetMultiline(true)
        entry:SetTall(50)
    end)
    tab.Entries.image = panelWithLabel(panel, "Image url", vgui.Create("DTextEntry"))

    tab.Entries.active = vgui.Create("DCheckBoxLabel", panel)
    tab.Entries.active:Dock(TOP)
    tab.Entries.active:DockMargin(5, 5, 5, 5)
    tab.Entries.active:SetText("Active")
    tab.Entries.active:SetTextColor(color_black)
    tab.Entries.active:SetValue(true)
    tab.Entries.active.GetValue = function()
        return tab.Entries.active:GetChecked() and 1 or 0
    end
    
    tab.SaveButton = createSaveButton(panel, tab, {"id", "name", "category_id", "path"}, "SrvDupeES_SaveDupe")

    tab.ListView = createListPanel(tab, SrvDupeES.AvailableDupes)
end

local function tabMngmtCategories(tabs)
    local tab = vgui.Create("DPanel", tabs)
    SrvDupeES.WindowAdmin.MngCategories = tab

    tab.Entries = tab.Entries or {}

    local panel = vgui.Create("DPanel", tab)
    panel:Dock(FILL)

    tab.Entries.id = panelWithLabel(panel, "* ID", vgui.Create("DTextEntry"))
    tab.Entries.name = panelWithLabel(panel, "* Name", vgui.Create("DTextEntry"))

    tab.SaveButton = createSaveButton(panel, tab, {"id", "name"}, "SrvDupeES_SaveCategory")
    tab.ListView = createListPanel(tab, SrvDupeES.AvailableCategories)
end

local function createAdminManagementWindow()
    if SrvDupeES.WindowAdmin then return end

    SrvDupeES.WindowAdmin = vgui.Create( "DFrame" )
    SrvDupeES.WindowAdmin:SetSize(600, 700)
    SrvDupeES.WindowAdmin:Center()
    SrvDupeES.WindowAdmin:SetTitle("Server Dupes - Admin Panel")
    SrvDupeES.WindowAdmin:SetVisible(true)
    SrvDupeES.WindowAdmin:SetDraggable(false)
    SrvDupeES.WindowAdmin:ShowCloseButton(true)
    SrvDupeES.WindowAdmin:MakePopup()

    local tabs = vgui.Create("DPropertySheet", SrvDupeES.WindowAdmin)
    tabs:Dock(FILL)

    -- Dupes
    tabMngmtDupes(tabs)
    tabs:AddSheet("Dupes", SrvDupeES.WindowAdmin.MngDupes, "icon16/brick_edit.png")

    -- Categories
    tabMngmtCategories(tabs)
    tabs:AddSheet("Categories", SrvDupeES.WindowAdmin.MngCategories, "icon16/folder.png")

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
        for _, tab in pairs(SrvDupeES.WindowAdmin.Tabs.Items) do
            if tab.Tab:GetText() == activeTabName then
                SrvDupeES.WindowAdmin.Tabs:SwitchToName(activeTabName)
                break
            end
        end
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
        RunConsoleCommand("srvdupe_es_spawn", dupe.id)
        surface.PlaySound( "ui/buttonclickrelease.wav" )
    end

    icon.OpenMenuExtra = function( self, menu ) end
    icon.OpenMenu = function(self)
        local menu = DermaMenu()

        if SrvDupeES.CheckPlyWritePermissions(LocalPlayer()) then
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

local function buildDupesCategories()
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

    return categorisedDupes
end

local function addCategory(tree, categoryId, dupes)
    local categoryName = categoryId or "undefined"
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

    local categorisedDupes = buildDupesCategories()
    for categoryId, tbl in pairs(categorisedDupes) do
        local dupes = tbl.dupes or {}
        addCategory(tree, categoryId, dupes)
    end

    refreshPanels()

    -- get first node of tree.Categories
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

    SrvDupeES.AvailableDupes = dupes
    SrvDupeES.AvailableCategories = categories

    SrvDupeES.PanelSpawnMenu:CallPopulateHook("SrvDupeES_Populate")
end)