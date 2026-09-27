AddCSLuaFile()

CreateConVar("zippyHERO_start_time", "10", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
CreateConVar("zippyHERO_start_time2", "3", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
CreateConVar("zippyHERO_spawndist", "2000", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
CreateConVar("zippyHERO_spawndist_min", "1000", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
CreateConVar("zippyHERO_max_spawned", "40", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
CreateConVar("zippyHERO_teleport_fx", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
CreateConVar("zippyHERO_teleport", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
CreateConVar("zippyHERO_refill_health", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
CreateConVar("zippyHERO_chase_player", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
CreateConVar("zippyHERO_run_chase", "0", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
CreateConVar("zippyHERO_no_noclip", "0", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
CreateConVar("zippyHERO_end_on_death", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
CreateConVar("zippyHERO_use_nodes", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
CreateConVar("zippyHERO_vischeck", "0", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))

if CLIENT then
    Z_HERO_HALO_ENABLE = CreateConVar("zippyHERO_halo_enable", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
    -- Z_HERO_HALO_BLUR = CreateConVar("zippyHERO_halo_blur", "8", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
end