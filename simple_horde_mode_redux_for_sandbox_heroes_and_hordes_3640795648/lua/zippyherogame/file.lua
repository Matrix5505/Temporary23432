util.AddNetworkString("ZippyHERO_GetPresets")
util.AddNetworkString("ZippyHERO_SendPresetsToClient")
util.AddNetworkString("ZippyHERO_SelectPreset")
util.AddNetworkString("ZippyHERO_GivePresetContents")
util.AddNetworkString("ZippyHERO_RemovePreset")
util.AddNetworkString("ZippyHERO_NewPreset")

local PATH = "Herogame_presets/"
local DEFAULT_PRESET_NAME = PATH.."default.json"

local function sendPresetsToClient()
    local files = file.Find(PATH.."*", "DATA")

    net.Start("ZippyHERO_SendPresetsToClient")
    net.WriteTable(files)
    net.Broadcast()
end

net.Receive("ZippyHERO_GetPresets", function( _, ply )
    if !ply:IsSuperAdmin() then return end
    sendPresetsToClient()
end)

net.Receive("ZippyHERO_SelectPreset", function( _, ply )

    if !ply:IsSuperAdmin() then return end

    local presetToSelect = net.ReadString()..".json"
    local files = file.Find(PATH.."*", "DATA")

    for _, preset in ipairs(files) do
        if preset != presetToSelect then continue end

        Z_HEROGAME.NPCsToSpawn = util.JSONToTable(file.Read(PATH..preset))

        net.Start("ZippyHeroGame_RefreshNPCList")
        net.WriteTable( Z_HEROGAME.NPCsToSpawn )
        net.Broadcast()

        break
    end

end)


function Z_HEROGAME:PresetSave( name )

    if name == "default" then return end

    file.Write(PATH..string.lower( name )..".json", util.TableToJSON(Z_HEROGAME.NPCsToSpawn, true))
    sendPresetsToClient()

end


net.Receive("ZippyHERO_NewPreset", function( _, ply )

    if !ply:IsSuperAdmin() then return end

    local files = file.Find(PATH.."*", "DATA")

    if #files > 100 then
        PrintMessage(HUD_PRINTTALK, "WARNING: Preset limit reached!")   return
    end

    Z_HEROGAME:PresetSave( net.ReadString() )

end)


net.Receive("ZippyHERO_RemovePreset", function( _, ply )

    if !ply:IsSuperAdmin() then return end

    file.Delete(PATH..net.ReadString()..".json")
    sendPresetsToClient()

end)


local function makeDefaultPreset()

    local fileContents = util.TableToJSON(
    {
        npc_citizen = {
			Name = "#npc_citizen_rebel",
            spawnmenuData=list.Get("NPC")["npc_citizen"],
            chance = 1,
			SpawnFlags = 262144,
			Weapons = {
				"weapon_pistol",
				"weapon_smg1",
				"weapon_ar2",
				"weapon_shotgun",
				"weapon_rpg"
			},
        }
    }
    )

    file.Write(DEFAULT_PRESET_NAME, fileContents)

end


hook.Add("Initialize", "Initialize_ZippyHERO_FileStuff", function()

    if !file.Exists(PATH, "DATA") then
        file.CreateDir(PATH)
    end

    if !file.Exists(DEFAULT_PRESET_NAME, "DATA") then
        makeDefaultPreset()
    end

end)

