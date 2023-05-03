CreateConVar("r6_server_allow_teamkillmark", "1", FCVAR_ARCHIVE, "If disabled, all killmarkers will appear red, no matter the team. Can be disabled in case teams shouldn't be revealed to players.", 0, 1)
CreateConVar("r6_server_coop", "0", FCVAR_ARCHIVE, "If enabled, all players will be counted as friendly, giving white killmarkers for players. Use in PvE.", 0, 1)
CreateConVar("r6_server_npcteams", "0", FCVAR_ARCHIVE, "If enabled, NPCs that count as 'friends' (citizens, rebels, etc.) will show a white killmarker when killed.", 0, 1)
CreateConVar("r6_server_allow_npckillmark", "1", FCVAR_ARCHIVE, "Allows players to see killmarkers when they kill an npc. For server owners only.", 0, 1)
CreateConVar("r6_server_allow_playerkillmark", "1", FCVAR_ARCHIVE, "Allows players to see killmarkers when they kill a player. For server owners only.", 0, 1)


util.AddNetworkString("r6Killmark")

hook.Add("PlayerDeath", "r6KillmarkPlayer", function (victim, inflictor, attacker)
  if (attacker:IsPlayer() and GetConVar("r6_server_allow_playerkillmark"):GetBool()) then
    local friend = false 
    if (GetConVar("r6_server_coop"):GetBool()) then
      friend = true
    end
    if (victim:Team() ~= 0 and victim:Team() ~= 1001 and victim:Team() ~= 1002) then
      if (victim:Team() == attacker:Team()) then
        friend = true
      end
    end
    sendKillMark(attacker, victim, friend)
  end
end)

hook.Add("OnNPCKilled", "r6KillmarkNPC", function (npc, attacker)
  if (attacker:IsPlayer() and GetConVar("r6_server_allow_npckillmark"):GetBool()) then
    local friend = false 
    if (GetConVar("r6_server_npcteams"):GetBool()) then
      if (IsFriendEntityName(npc:GetClass())) then
        friend = true
      end
    end
    sendKillMark(attacker, npc, friend)
  end
end)

function sendKillMark(ply, victim, friend)
  if (not GetConVar("r6_server_allow_teamkillmark"):GetBool()) then
    friend = false
  end
  net.Start("r6Killmark")
  net.WriteBool(friend)
  net.WriteEntity(victim)
  net.Send(ply)
end