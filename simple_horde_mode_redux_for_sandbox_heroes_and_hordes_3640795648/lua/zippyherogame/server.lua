util.AddNetworkString("ZippyHeroGame_Start")
util.AddNetworkString("ZippyHeroGame_GameStartConfirmed")
util.AddNetworkString("ZippyHeroGame_EnableButton")
util.AddNetworkString("ZippyHeroGame_ForceEnd")
util.AddNetworkString("ZippyHeroGame_ForceEndWave")
util.AddNetworkString("ZippyHeroAddHalo")


if !Z_HEROGAME then
    Z_HEROGAME = {}
    Z_HEROGAME.NPCs = {}
    Z_HEROGAME.WaveNPCCount = 0
    Z_HEROGAME.WaveNPCsKilled = 0
    Z_HEROGAME.NextPrintNPCsLeft = CurTime()
end



function Z_HEROGAME:NPC_Good_Position( npc, pos )

    local vectorExtra = Vector(0, 0, -npc:OBBMins().z)

    if npc:GetClass() == "npc_strider" then
        vectorExtra = vectorExtra + Vector(0, 0, 400)
    elseif npc.ZippyHERO_PositionOffset then
        vectorExtra = vectorExtra + Vector(0, 0, npc.ZippyHERO_PositionOffset)
    elseif npc.IsVJBaseSNPC && npc.MovementType == VJ_MOVETYPE_AERIAL then
        vectorExtra = vectorExtra + Vector(0, 0, npc.AA_GroundLimit)
    end

    return pos + vectorExtra

end


local DistMinCvar = GetConVar("zippyHERO_spawndist_min")
local DistMaxCvar = GetConVar("zippyHERO_spawndist")
local maxNodeIter = 10
function Z_HEROGAME:FindNodePos( ply )
    table.Shuffle(self.NodePositions)

    local DistMin = DistMinCvar:GetInt()^2
    local DistMax = DistMaxCvar:GetInt()^2
    local iters = 0
    local plyPos = ply:GetPos()
    for _, v in ipairs(self.NodePositions) do
        local dist = v:DistToSqr(plyPos)
        if dist >= DistMin && dist <= DistMax then
            return v
        end

        iters = iters + 1
        if iters >= maxNodeIter then
            break
        end
    end
end


function Z_HEROGAME:CheckVisibility( pos )
    for _, ply in player.Iterator() do
        if ply:PosInView(pos) then
            return true
        end
    end

    return false
end



local TracerStartUpAmt = 150
local TracerEndPosDownVec = Vector(0, 0, 500)
local UseNodesCvar = GetConVar("zippyHERO_use_nodes")
local zippyHERO_vischeck = GetConVar("zippyHERO_vischeck")

local tbl_HeroGameStarted = {
"REINFORCEMENT STARTED",
"Hero GAME COMMENCE",
"DEATHMATCH",
"HERE THEY COME",
"YOU ALERTED THE Hero",
"WAVE STARTED",
"TAKE NO PRISONERS COMRADES",
"Hero GAME",
"LOCK AND LOAD",
"ROCK AND ROLL",
"GET READY",
"MISSION STARTED",
}

local tbl_End = {
"REINFORCEMENT ABANDONED",
"Hero GAME ABORTED",
"MISSION ABORTED",
"STOPPED",
"YOU ALERTED THE Hero",
"WAVE STOPPED",
"BATTLE CONTROL TERMINATED",
"BATTLE CONTROL OFFLINE",
"HOW COULD YOU END AT ONCE",
"ROCK AND ROLL?",
"SOME ISSUES?",
}

local tbl_Lost = {
"PLAYER LOST",
"Hero GAME LOST",
"MISSION FAILED",
"MISSION FAILED. WE'LL GET EM NEXT TIME",
"YOU FAILED",
"WAVE LOST",
"TRY AGAIN",
"BATTLE CONTROL OFFLINE",
"HOW COULD YOU DIED AT ONCE",
"YOU DIED",
"DEFEATED",
}


local tbl_Victory = {
"NO MORE REINFORCEMENT",
"Hero GAME VICTORY",
"MISSION ACCOMPLISHED",
"VICTORY",
"YOU DEFEATED THE Hero",
"WAVE COMPLETED",
"YOU DEFEATED THE WAVE",
"THEY'LL BE BACK",
"PLAYER LOST",
"MISSION COMPLETE",
"CONFIRMED",
}

local tbl_WaveComplete = {
"REINFORCEMENT KIA",
"Hero GAME REINFORCEMENT KIA",
"MISSION ACCEPTED",
"WELL DONE",
"YOU DEFEATED THE WAVE. THEY'LL BE BACK",
"WAVE COMPLETED",
"YOU DEFEATED THE WAVE",
"THEY'LL BE BACK",
"NEXT WAVE",
"MISSION COMPLETE",
"WAVE CONFIRMED",
}
function Z_HEROGAME:FindPlyRelPos( ply )
    local DownTRStartPos
    if UseNodesCvar:GetBool() && !(istable(self.NodePositions) && table.IsEmpty(self.NodePositions)) then

        -- Use nodes

        if !istable(self.NodePositions) then

            self.NodePositions = ZIPPYHeroGAME_GET_NODE_POSITIONS()
            if table.IsEmpty(self.NodePositions) then
                PrintMessage(HUD_PRINTTALK, "[HERO] Could not find nodes :(")
                PrintMessage(HUD_PRINTTALK, "[HERO] Try setting 'ai_norebuildgraph' to '1', or if it's '1', set it back to '0'.")
            else
                PrintMessage(HUD_PRINTTALK, "[HERO] Nodes fetched!")
            end

        end

        DownTRStartPos = self:FindNodePos( ply )

    else

        -- Don't use nodes

        local VecMin = DistMaxCvar:GetInt()
        local VecMax = DistMinCvar:GetInt()
        local PlyPos = ply:WorldSpaceCenter()
        local xMult = table.Random({-1, 1})
        local yMult = table.Random({-1, 1})
        DownTRStartPos = PlyPos + Vector( math.random(VecMin, VecMax)*xMult, math.random(VecMin, VecMax)*yMult, TracerStartUpAmt )

        debugoverlay.Line(PlyPos, DownTRStartPos, 3)

    end


    -- Position not in world, don't continue
    if !util.IsInWorld(DownTRStartPos) then return end


    -- Down trace
    local tr = util.TraceLine({
        start=DownTRStartPos,
        endpos = DownTRStartPos-TracerEndPosDownVec,
        mask = MASK_NPCWORLDSTATIC,
    })

    -- Must hit floor to spawn NPC
    if !tr.Hit then return end


    -- Debug
    debugoverlay.Line(DownTRStartPos, DownTRStartPos-TracerEndPosDownVec, 3)


    -- Final position
    local ReturnPos = tr.HitPos+tr.HitNormal*15


    -- A player can see this position right now, don't return
    if zippyHERO_vischeck:GetBool() && self:CheckVisibility(ReturnPos) then return end


    -- All checks satisfied, return the position
    return ReturnPos

end


function Z_HEROGAME:TryPositionNPC( npc, noTeleportFromEffect )


    local ply = player.GetAll()[math.random(1, player.GetCount())]
    local useSpawnPoints = !table.IsEmpty(ZHERO_SPAWN_POINTS)
    local function effect( pos )
        if GetConVar("zippyHERO_teleport_fx"):GetBool() then

            if !noTeleportFromEffect then
                ParticleEffect("aurora_shockwave", npc:GetPos(), Angle())
                sound.Play("beams/beamstart7.wav", npc:GetPos(), 90, math.random(90, 110), 0.5)
            end

            ParticleEffect("aurora_shockwave", pos, Angle())
            sound.Play("beams/beamstart7.wav", pos, 90, math.random(90, 110), 0.5)

        end
    end


    if useSpawnPoints then
        -- Spawn point spawning
        for _, v in ipairs(ZHERO_SPAWN_POINTS) do
            local checkPos = self:NPC_Good_Position(npc, v:GetPos()+Vector(0, 0, 25))

            local trData = {
                start = checkPos,
                endpos = checkPos,
                filter = npc,
            }

            if util.TraceEntity(trData, npc).Hit then continue end

            effect( checkPos )

            npc:SetPos(checkPos)
            npc:SetAngles(Angle(0, math.random(1, 360), 0))
            -- npc:SetNoDraw(false)
            npc:ClearSchedule()
            return true
        end
    else

        -- Relative spawning
        local pos = self:FindPlyRelPos(ply)
        if pos then
            local checkPos = self:NPC_Good_Position(npc, pos+Vector(0, 0, 25))

            local trData = {
                start = checkPos,
                endpos = checkPos,
                filter = npc,
            }

            if !util.TraceEntity(trData, npc).Hit then

                effect( checkPos )

                npc:SetPos(checkPos)
                npc:SetAngles(Angle(0, math.random(1, 360), 0))
                -- npc:SetNoDraw(false)
                npc:ClearSchedule()
                return true

            end
        end

    end

end


function Z_HEROGAME:TooCloseToPlayer( pos )
    for _, ply in player.Iterator() do
        local dist = GetConVar("zippyHERO_spawndist_min"):GetInt()
        if pos:DistToSqr(ply:GetPos()) < dist^2 then return true end
    end
end


function Z_HEROGAME:GetBasedOnStrength( number )
    return math.floor( number*self.NPCStrength + number*self.NPCStrengthIncreaseAmount*self.WavesDone )
end


function Z_HEROGAME:GetAliveNPCsCount( spawnmenuClass )

    local count = 0

    for _, npc in ipairs(self.NPCs) do
        if npc.ZippyHeroSpawnMenuClass == spawnmenuClass then count = count+1 end
    end

    return count

end


function Z_HEROGAME:DecideNPC()

    local npcPool = {}
    local wave = self.WavesDone+1

    -- Decide what NPCs could spawn now --
    for key, npc in pairs(self.NPCsToSpawn) do
        -- WAVE START AND END STUFF --
        if npc.waveStart && wave < npc.waveStart then continue end
        if npc.waveEnd && wave > npc.waveEnd then continue end
        ----------------------------------------------------=#

        -- NPC LIMIT PER WAVE --
        local spawnedNPCs = self.WaveNPCsSpawnedCount[key]
        if npc.maxPerWave && spawnedNPCs && spawnedNPCs >= npc.maxPerWave then continue end
        ----------------------------------------------------=#

        -- MAX NPCS ALIVE AT ONCE --
        local aliveNPCs = self:GetAliveNPCsCount(key)
        if npc.maxAlive && aliveNPCs >= npc.maxAlive then continue end
        ----------------------------------------------------=#


        npcPool[key] = npc
    end


    local npcData, spawnmenuClass = table.Random(npcPool)

    if !npcData then
        PrintMessage(HUD_PRINTTALK, "[HERO] WARNING: No NPCs to spawn!")
    end

    while math.random(1, npcData.chance) != 1 do
        npcData = table.Random(npcPool)
    end

    return npcData.spawnmenuData, spawnmenuClass, npcData.CustomWeapons

end

local telecvar = GetConVar("zippyHERO_teleport")
function Z_HEROGAME:SpawnNPC()

    -- Create NPC --
    local npcSpawnmenuData, spawnmenuClass, customWeapons = self:DecideNPC()
    local wep = customWeapons && table.Random(customWeapons)
    local NPC = ents.CreateSpawnMenuNPC( spawnmenuClass, pos, (wep && wep.Class) or nil )

    -- Vars
    NPC.IsZippyHeroNPC = true
    NPC.ZippyHeroSpawnMenuClass = spawnmenuClass
    NPC.ZippyHERO_PositionOffset = npcSpawnmenuData.Offset


    -- Register
    NPC:CallOnRemove("HeroRegisterDeadOnRemove", function()
        self:RegisterDead(NPC)
    end)
    table.insert(Z_HEROGAME.NPCs, NPC)


    -- Count
    if !self.WaveNPCsSpawnedCount[spawnmenuClass] then
        self.WaveNPCsSpawnedCount[spawnmenuClass] = 0
    end
    self.WaveNPCsSpawnedCount[spawnmenuClass] = self.WaveNPCsSpawnedCount[spawnmenuClass] + 1


    -- New Health Based on Strenght
    timer.Simple(0.1, function()

        if !IsValid(NPC) then return end

        local newHealth = self:GetBasedOnStrength( NPC:GetMaxHealth() )
        NPC:SetMaxHealth(newHealth)
        NPC:SetHealth(newHealth)

    end)


    -- Position it, or let us know if it failed
    NPC.ZippyHERO_NotPositionedYet = !self:TryPositionNPC(NPC, true)


    -- AUTO TELEPORT SYSTEM (FROM PROXSPAWN)
    -- Try moving to another location if it has been out of view for some time
    NPC:ConvTimer( "ProxyMove", math.Rand(30, 40), function()

        if telecvar:GetBool() && !self:CheckVisibility( NPC:GetPos() ) then
            local success = self:TryPositionNPC( NPC )
            if success && NPC:IsNPC() && NPC:IsGoalActive() then -- Clear goal after teleportation so we don't just run off
                NPC:ClearGoal()
            end
        end

    end, 0 )
end


function Z_HEROGAME:SpawnWave_Announce()

    local printStuff = {
        "---------------------------------------------------",
        "SQUAD "..self.WavesDone+1,
        self.WaveNPCCount.." NPCs",
        "NPC Strength: "..self:GetBasedOnStrength(100).."%",
        "---------------------------------------------------",
    }

    PrintMessage(HUD_PRINTCENTER, "REINFORCEMENTS ARRIVE: SQUAD "..self.WavesDone+1)

    for _, text in ipairs(printStuff) do
        PrintMessage(HUD_PRINTTALK, text)
    end

end


function Z_HEROGAME:StartExtraSpawnTimer( count )

    local extraNPCsSpawned = 0

    timer.Create("ZippyHeroSpawnRestTimer", 1, 0, function()

        if table.Count(Z_HEROGAME.NPCs) >= GetConVar("zippyHERO_max_spawned"):GetInt() then return end

        self:SpawnNPC()
        extraNPCsSpawned = extraNPCsSpawned+1

        if extraNPCsSpawned >= count then timer.Remove("ZippyHeroSpawnRestTimer") end

    end)

end


function Z_HEROGAME:SpawnWave()

    self.WaveActive = true
    self.DidHalo = false

    self:SpawnWave_Announce()

    local startNPCCount = math.Clamp(self.WaveNPCCount, 0, GetConVar("zippyHERO_max_spawned"):GetInt())
    local extraNPCCount = self.WaveNPCCount - startNPCCount

    timer.Create("ZippyHeroSpawnRestTimer", 0, startNPCCount, function()
        self:SpawnNPC()
        if timer.RepsLeft("ZippyHeroSpawnRestTimer") == 0 && extraNPCCount > 0 then self:StartExtraSpawnTimer(extraNPCCount) end
    end)
end


function Z_HEROGAME:RefillHealth()

    if !GetConVar("zippyHERO_refill_health"):GetBool() then return end

    for _, ply in player.Iterator() do
        ply:SetHealth(ply:GetMaxHealth())
        ply:SetArmor(ply:GetMaxArmor())
    end

    PrintMessage(HUD_PRINTTALK, "[HERO] Health and armor refilled!")

end


function Z_HEROGAME:StartWave()

    self.WaveNPCsKilled = 0
    self.WaveNPCsSpawnedCount = {}
    self.WaveNPCCount = self.BaseNPCCount + self.NPCIncreaseAmount*self.WavesDone

    local startTime = GetConVar("zippyHERO_start_time"):GetInt()
    PrintMessage(HUD_PRINTCENTER, "REINFORCEMENTS WILL ARRIVE IN "..startTime.." SECONDS")
    timer.Create("ZippyHeroWaitTimer", startTime, 1, function() self:SpawnWave() end)

end


function Z_HEROGAME:WaveOver()

    self.WaveActive = false
	local startTime2 = GetConVar("zippyHERO_start_time2"):GetInt()

    self.WavesDone = self.WavesDone+1

    if self.WavesDone >= self.WaveCount then
        PrintMessage(HUD_PRINTCENTER, "NO MORE REINFORCEMENTS")

        net.Start("ZippyHeroGame_EnableButton")
        net.Broadcast()

        self.Started = false
    else
        PrintMessage(HUD_PRINTCENTER, "FRIENDLIES KIA")
        timer.Create("ZippyHeroWaitTimer", startTime2, 1, function() self:StartWave() end) -- 2
    end

    self:RefillHealth()

end


local NPCsLeft_Halo = 8
function Z_HEROGAME:RegisterDead( ent )

    if !ent.IsZippyHeroNPC then return end
    if ent.ZippyHERO_Dead then return end

    ent.ZippyHERO_Dead = true
    table.RemoveByValue(Z_HEROGAME.NPCs, ent)

    self.WaveNPCsKilled = self.WaveNPCsKilled+1
    local npcsLeft = self.WaveNPCCount-self.WaveNPCsKilled

    if self.NextPrintNPCsLeft < CurTime() then
        timer.Simple(1, function()
            if !self.WaveActive then return end

            local npcsLeft = self.WaveNPCCount-self.WaveNPCsKilled
            if npcsLeft < 1 then return end

            PrintMessage(HUD_PRINTTALK, npcsLeft.." Friendlies left!")
        end)

        self.NextPrintNPCsLeft = CurTime() + 5
    end

    -- Add halos when not many left
    if !self.DidHalo && npcsLeft < NPCsLeft_Halo then
        for _, v in ipairs(self.NPCs) do
            net.Start("ZippyHeroAddHalo")
            net.WriteEntity(v)
            net.Broadcast()
        end
        self.DidHalo = true
    end


    if npcsLeft < 1 then
        self:WaveOver()
    end

end


function Z_HEROGAME:RemoveAllLiveNPCs()

    for _, ent in ents.Iterator() do
        if !ent.IsZippyHeroNPC then continue end

        ent.ZippyHERO_Dead = true -- Prevent register
        table.RemoveByValue(Z_HEROGAME.NPCs, ent) -- Still remove from table
        ent:Remove()
    end

end

net.Receive("ZippyHeroGame_Start", function( _, ply )

	local startTime3 = GetConVar("zippyHERO_start_time2"):GetInt()

    if !ply:IsSuperAdmin() then return end
    if Z_HEROGAME.Started then return end

    Z_HEROGAME.Started = true
    Z_HEROGAME.WavesDone = 0

    PrintMessage(HUD_PRINTCENTER, "REINFORCEMENT STARTED")

    Z_HEROGAME.WaveCount = net.ReadInt(32)
    Z_HEROGAME.BaseNPCCount = net.ReadInt(32)
    Z_HEROGAME.NPCIncreaseAmount = net.ReadInt(32)
    Z_HEROGAME.NPCStrength = net.ReadFloat()
    Z_HEROGAME.NPCStrengthIncreaseAmount = net.ReadFloat()

    Z_HEROGAME:RefillHealth()

    timer.Create("ZippyHeroWaitTimer", startTime3, 1, function() Z_HEROGAME:StartWave() end)

    net.Start("ZippyHeroGame_GameStartConfirmed")
    net.Broadcast()

end)


net.Receive("ZippyHeroGame_ForceEnd", function( _, ply )

    if !ply:IsSuperAdmin() then return end
    if !Z_HEROGAME.Started then return end

    if timer.Exists("ZippyHeroWaitTimer") then timer.Remove("ZippyHeroWaitTimer") end
    if timer.Exists("ZippyHeroSpawnRestTimer") then timer.Remove("ZippyHeroSpawnRestTimer") end

    Z_HEROGAME:RemoveAllLiveNPCs()

    Z_HEROGAME.Started = false

    net.Start("ZippyHeroGame_EnableButton")
    net.Broadcast()

    PrintMessage(HUD_PRINTCENTER, "FRIENDLIES ABANDONED")

end)


net.Receive("ZippyHeroGame_ForceEndWave", function( _, ply )

    if !ply:IsSuperAdmin() then return end
    if !Z_HEROGAME.Started then return end
    if !Z_HEROGAME.WaveActive then return end

    if timer.Exists("ZippyHeroSpawnRestTimer") then timer.Remove("ZippyHeroSpawnRestTimer") end

    Z_HEROGAME:RemoveAllLiveNPCs()
    Z_HEROGAME:WaveOver()

end)


hook.Add("EntityTakeDamage", "EntityTakeDamage_ZippyHero", function( ent, dmginfo )

    local attacker = dmginfo:GetAttacker()
    local inflictor = dmginfo:GetInflictor()

    if attacker.IsZippyHeroNPC or inflictor.IsZippyHeroNPC or (IsValid(inflictor) && inflictor:GetOwner().IsZippyHeroNPC) then

        if attacker.ZippyHERO_NotPositionedYet then
            -- Not positioned, cannot deal damage
            return true
        end

        local newDamage = Z_HEROGAME:GetBasedOnStrength(dmginfo:GetDamage())
        dmginfo:SetDamage(newDamage)

    end


    if ent.ZippyHERO_NotPositionedYet then
        -- Not positioned, cannot be hurt
        return true
    end

end)


hook.Add("OnNPCKilled", "OnNPCKilled_ZippyHero", function( npc )
    Z_HEROGAME:RegisterDead(npc)
end)



hook.Add("PlayerNoClip", "ZippyHeroNoNoclip", function( ply, desiredState )
    if Z_HEROGAME.Started && GetConVar("zippyHERO_no_noclip"):GetBool() && desiredState==true then
        return false
    end
end)


hook.Add("PlayerDeath", "ZippyHeroEnd", function()

    if !Z_HEROGAME.Started then return end
    if !GetConVar("zippyHERO_end_on_death"):GetBool() then return end
    if timer.Exists("ZippyHeroWaitTimer") then timer.Remove("ZippyHeroWaitTimer") end
    if timer.Exists("ZippyHeroSpawnRestTimer") then timer.Remove("ZippyHeroSpawnRestTimer") end

    Z_HEROGAME:RemoveAllLiveNPCs()

    Z_HEROGAME.Started = false

    net.Start("ZippyHeroGame_EnableButton")
    net.Broadcast()

    PrintMessage(HUD_PRINTCENTER, "PLAYER LOST")

end)


local function retryPosition( NPC )

    -- Position if still on its default (0;0;0) coordinates:
    NPC.ZippyHERO_NotPositionedYet = !Z_HEROGAME:TryPositionNPC(NPC)

end


local nextTick = CurTime()
hook.Add("Tick", "ZippyHERO_Thinker", function()

    if nextTick > CurTime() then return end
    if !Z_HEROGAME.Started then return end

    for _, NPC in ipairs(Z_HEROGAME.NPCs) do

        if NPC.ZippyHERO_NotPositionedYet then
            retryPosition( NPC )
        end

        -- Freeze AI if it hasn't been positioned yet
        if NPC.ZippyHERO_NotPositionedYet && NPC:IsNPC() && !NPC:IsCurrentSchedule(SCHED_NPC_FREEZE) then
            NPC:TaskComplete()
            NPC:ClearGoal()
            NPC:ClearSchedule()
            NPC:StopMoving()
            NPC:SetMoveVelocity(vector_origin)
            NPC:SetSchedule(SCHED_NPC_FREEZE)
        end

    end

    nextTick = CurTime()+1

end)

