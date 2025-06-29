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
    listPanel:SetWidth(250)

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

    listView.SelectLineByDataId = function(id)
        for _, line in pairs(listView:GetLines()) do
            if line.itemData and line.itemData.id == id then
                listView:SelectItem(line)
                line.OnSelect()
                return true
            end
        end
        return false
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

function SrvDupeES.VGUI.tabMngmtDupes(tabs)
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

function SrvDupeES.VGUI.tabMngmtCategories(tabs)
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