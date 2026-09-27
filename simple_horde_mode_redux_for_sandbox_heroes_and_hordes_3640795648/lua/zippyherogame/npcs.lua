util.AddNetworkString("ZippyHeroGame_NewNPC")
util.AddNetworkString("ZippyHeroGame_RefreshNPCList")
util.AddNetworkString("ZippyHERO_RemoveNPC")
util.AddNetworkString("ZippyHERO_EditNPC")

if !Z_HEROGAME.NPCsToSpawn then
    Z_HEROGAME.NPCsToSpawn = {}
end



local function addNPC( class, data )

    if table.Count(Z_HEROGAME.NPCsToSpawn) > 100 then
        PrintMessage(HUD_PRINTTALK, "WARNING: NPC limit reached!")   return
    end

    local data = data or {}
    local spawnmenuData = list.Get("NPC")[class]

    Z_HEROGAME.NPCsToSpawn[class] = {
        spawnmenuData=spawnmenuData,
        chance=data.chance or 1,
        waveStart=data.start,
        waveEnd=data._end,
    }

end


local function refreshList()

    net.Start("ZippyHeroGame_RefreshNPCList")
    net.WriteTable( Z_HEROGAME.NPCsToSpawn )
    net.Broadcast()

end


net.Receive("ZippyHeroGame_NewNPC", function( _, ply )

    if !ply:IsSuperAdmin() then return end

    local npcClass = net.ReadString()
    local curPresetName = net.ReadString()

    addNPC( npcClass )
    Z_HEROGAME:PresetSave( curPresetName )

    refreshList()

end)


net.Receive("ZippyHERO_RemoveNPC", function( _, ply )

    if !ply:IsSuperAdmin() then return end

    local npcClass = net.ReadString()
    local curPresetName = net.ReadString()

    Z_HEROGAME.NPCsToSpawn[ npcClass ] = nil
    Z_HEROGAME:PresetSave( curPresetName )

    refreshList()

end)


net.Receive("ZippyHERO_EditNPC", function( _, ply )

    if !ply:IsSuperAdmin() then return end

    local npcClass = net.ReadString()
    local curPresetName = net.ReadString()
    local npcData = net.ReadTable()

    Z_HEROGAME.NPCsToSpawn[npcClass] = npcData
    Z_HEROGAME:PresetSave( curPresetName )

    refreshList()

end)

