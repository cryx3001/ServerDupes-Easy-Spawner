hook.Add( "SrvDupeES_Populate", "Example", function( pnlContent, tree, node )
    print("SrvDupeES_Populate")
    -- TODO

end)

local function createButtonAdminManagement(parent)
    if not SrvDupeES.CheckPlyWritePermissions(LocalPlayer()) then return end

    SrvDupeES.ButtonManage = vgui.Create( "DButton", parent )
    SrvDupeES.ButtonManage:SetText("Admin Management")
    SrvDupeES.ButtonManage:SetSize(120, 50)

    SrvDupeES.ButtonManage.DoClick = function()
        -- TODO
    end
end

spawnmenu.AddCreationTab( "Server Dupes", function()
    SrvDupeES.PanelSpawnMenu = vgui.Create("SpawnmenuContentPanel")
    SrvDupeES.PanelSpawnMenu:CallPopulateHook( "SrvDupeES_Populate" )

    SrvDupeES.PanelSpawnMenu.OnSizeChanged = function(_, w, h)
        if not SrvDupeES.ButtonManage then return end
        SrvDupeES.ButtonManage:SetPos(w - 120 - 10, h - 50 - 10)
    end

    return SrvDupeES.PanelSpawnMenu
end, "icon16/server_database.png", 60 )

hook.Add("InitPostEntity", "SrvDupeES_InitPostEntity_SpawnDupe", function()
    createButtonAdminManagement(SrvDupeES.PanelSpawnMenu)
end)