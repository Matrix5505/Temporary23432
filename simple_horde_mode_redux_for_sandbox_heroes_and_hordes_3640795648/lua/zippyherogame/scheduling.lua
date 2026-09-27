local ENT = FindMetaTable("Entity")



function ENT:Z_HEROGame_LastTargetShouldBeSeeked()
    local t = self.Z_HEROGame_LastSeekOutTarget
    return IsValid(t) && !( t:IsPlayer() && !t:Alive() )
end


function ENT:Z_HEROGame_SeekOutPotentialEnemy()

    if self.Z_HEROGame_NextSeekOut && self.Z_HEROGame_NextSeekOut > CurTime() then return end
    if IsValid(self:GetEnemy()) then return end
    if self:IsCurrentSchedule(SCHED_TARGET_CHASE) then return end
    if self.IsVJBaseSNPC && self:IsBusy() then return end

    local potientialEnemy = self:Z_HEROGame_LastTargetShouldBeSeeked() && self.Z_HEROGame_LastSeekOutTarget or player.GetAll()[math.random(1, player.GetCount())]
    if potientialEnemy then
        self:SetTarget(potientialEnemy)

        if self.IsVJBaseSNPC then
            self:VJ_TASK_GOTO_TARGET("TASK_"..(GetConVar("zippyHERO_run_chase"):GetBool() && "RUN" or "WALK").."_PATH")
            self.Z_HEROGame_NextSeekOut = CurTime() + 5 -- Cooldown for VJ Base SNPCs so that it doesn't fire so often
        else
            self:SetSchedule(SCHED_TARGET_CHASE)
        end
        self.Z_HEROGame_LastSeekOutTarget = potientialEnemy

        -- print(self, " target --> ", potientialEnemy)
    end

end


function ENT:Z_HEROGame_TargetChaseWalkActivity()
    if GetConVar("zippyHERO_run_chase"):GetBool() then return end
    -- Make non-vj npcs walk to the target as opposed to running towards it
    if !self.IsVJBaseSNPC && self:IsCurrentSchedule(SCHED_TARGET_CHASE) && self:GetNavType() == NAV_GROUND then
        self:SetMovementActivity(ACT_WALK)
    end
end


function ENT:Z_HEROGame_CanSeekOut()
    if self:IsNPC() then
        local navType = self:GetNavType()   return navType == NAV_GROUND or navType == NAV_FLY
    end
end


hook.Add("Think", "Think_Z_HEROGame_Scheduling", function()

    if !Z_HEROGAME.Started then return end
    if !GetConVar("zippyHERO_chase_player"):GetBool() then return end
    if GetConVar("ai_disabled"):GetBool() then return end
    if GetConVar("ai_ignoreplayers"):GetBool() then return end
    if Z_HEROGAME.WaveNPCsKilled >= Z_HEROGAME.WaveNPCCount then return end

    Z_HEROGame_SCHED_ENTS = ents.FindByClass("npc_*")

    for _, v in ipairs(Z_HEROGame_SCHED_ENTS) do
        if v.IsZippyHeroNPC && v:Z_HEROGame_CanSeekOut() then
            v:Z_HEROGame_SeekOutPotentialEnemy()
            v:Z_HEROGame_TargetChaseWalkActivity()
        end
    end

end)

