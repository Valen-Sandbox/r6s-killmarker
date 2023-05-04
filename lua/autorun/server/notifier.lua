local net_Start = net.Start
local net_WriteBool = net.WriteBool
local net_WriteEntity = net.WriteEntity
local net_Send = net.Send
local IsFriendEntityName = IsFriendEntityName

util.AddNetworkString( "r6Killmark" )

local cvarFlags = { FCVAR_ARCHIVE, FCVAR_REPLICATED }
local teamKillMark = CreateConVar( "r6_server_allow_teamkillmark", "1", cvarFlags, "If disabled, all killmarkers will appear red, no matter the team. Can be disabled in case teams shouldn't be revealed to players.", 0, 1 )
local plyCoop = CreateConVar( "r6_server_coop", "0", cvarFlags, "If enabled, all players will be counted as friendly, giving white killmarkers for players. Use in PvE.", 0, 1 )
local npcTeams = CreateConVar( "r6_server_npcteams", "0", cvarFlags, "If enabled, NPCs that count as 'friends' (citizens, rebels, etc.) will show a white killmarker when killed.", 0, 1 )
local npcKillMark = CreateConVar( "r6_server_allow_npckillmark", "1", cvarFlags, "Allows players to see killmarkers when they kill an npc. For server owners only.", 0, 1 )
local plyKillMark = CreateConVar( "r6_server_allow_playerkillmark", "1", cvarFlags, "Allows players to see killmarkers when they kill a player. For server owners only.", 0, 1 )

local function sendKillMark( ply, victim, friend )
    if not teamKillMark:GetBool() then
        friend = false
    end

    net_Start( "r6Killmark" )
        net_WriteBool( friend )
        net_WriteEntity( victim )
    net_Send( ply )
end

hook.Add( "PlayerDeath", "r6KillmarkPlayer", function( victim, _, attacker )
    if not attacker:IsPlayer() or not plyKillMark:GetBool() then return end
    local friend = false

    if plyCoop:GetBool() then
        friend = true
    end

    local vicTeam = victim:Team()
    if vicTeam ~= 0 and vicTeam ~= 1001 and vicTeam ~= 1002 and vicTeam == attacker:Team() then
        friend = true
    end

    sendKillMark( attacker, victim, friend )
end )

hook.Add( "OnNPCKilled", "r6KillmarkNPC", function( npc, attacker )
    if not attacker:IsPlayer() or not npcKillMark:GetBool() then return end
    local friend = false

    if npcTeams:GetBool() and IsFriendEntityName( npc:GetClass() ) then
        friend = true
    end

    sendKillMark( attacker, npc, friend )
end )