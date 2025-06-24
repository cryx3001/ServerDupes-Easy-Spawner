util.AddNetworkString("SrvDupe_ES_RequestDupesAndCategories")
util.AddNetworkString("SrvDupe_ES_SendDupesAndCategories")

function SrvDupeES.SendDupesAndCategories(ply)
    local dupes = SrvDupeES.SQL.GetAllDupes()
    local categories = SrvDupeES.SQL.GetAllCategories()
    net.Start("SrvDupe_ES_SendDupesAndCategories")
        net.WriteTable(dupes)
        net.WriteTable(categories)
    if not ply then
        net.Broadcast()
    else
        net.Send(ply)
    end
end

net.Receive("SrvDupe_ES_RequestDupesAndCategories", function(_, ply)
    SrvDupeES.SendDupesAndCategories(ply)
end)
