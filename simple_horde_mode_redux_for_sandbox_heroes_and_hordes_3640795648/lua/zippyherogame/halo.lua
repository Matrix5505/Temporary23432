Z_HERO_HALO_ENTS = Z_HERO_HALO_ENTS or {}
Z_HERO_HALO_ENTS_ITER = Z_HERO_HALO_ENTS_ITER or ipairs(Z_HERO_HALO_ENTS)


net.Receive("ZippyHeroAddHalo", function()

    local ent = net.ReadEntity()

    if IsValid(ent) then
        table.InsertEntity( Z_HERO_HALO_ENTS, ent )
    end

    Z_HERO_HALO_ENTS_ITER = ipairs(Z_HERO_HALO_ENTS)

end)

local blurstrenght = 1
local color_green = Color( 0, 255, 0 )
hook.Add("PreDrawHalos", "ZippyHero", function()
    if !Z_HERO_HALO_ENABLE:GetBool() then return end


    local ply = LocalPlayer()

    if IsValid(ply) && !table.IsEmpty(Z_HERO_HALO_ENTS) then

        halo.Add( Z_HERO_HALO_ENTS, color_green, blurstrenght, blurstrenght, 1, true, true )

    end
end)