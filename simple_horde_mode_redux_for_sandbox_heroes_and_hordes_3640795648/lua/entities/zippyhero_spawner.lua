AddCSLuaFile()

ENT.Base = "base_gmodentity"
ENT.Type = "anim"
ENT.PrintName = "Spawn Point (Hero)"
ENT.Author = "Zippy"
ENT.Category = "Horde Mode"
ENT.Spawnable = true
ENT.AdminOnly = true

if !ZHERO_SPAWN_POINTS then 
    ZHERO_SPAWN_POINTS = {}
end

function ENT:Initialize()
    if SERVER then
        self:SetModel("models/props_c17/streetsign004e.mdl")
        self:SetAngles(Angle(0, 0, 90))
        self:SetPos(self:GetPos() - Vector(0, 0, 10))
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_NONE)
        self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

        if (!ZHERO_SPAWN_POINT_MSG_T or ZHERO_SPAWN_POINT_MSG_T < CurTime()) && table.IsEmpty(ZHERO_SPAWN_POINTS) then
            PrintMessage(HUD_PRINTTALK, "NOTE: Spawn points force NPCs spawned by the horde mode to spawn on their position, "..
            "regardless of spawn distance options. "..
            "Remove all spawn points if you want to use map wide spawning again.")
        end
        ZHERO_SPAWN_POINT_MSG_T = CurTime()+60

        table.insert(ZHERO_SPAWN_POINTS, self)
        self:CallOnRemove("ZHERO_SPAWN_POINTS_REMOVE", function() 
            table.RemoveByValue(ZHERO_SPAWN_POINTS, self)
        end)
    end
end

