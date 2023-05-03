CreateClientConVar("r6_enable_playerkillmark", "1", true, false, "Show killmarkers when killing players", 0, 1)
CreateClientConVar("r6_enable_npckillmark", "1", true, false, "Show killmarkers when killing NPCs", 0, 1)
CreateClientConVar("r6_suicidekillmark", "0", true, false, "Show a white killmarker when you commit suicide.", 0, 1)
CreateClientConVar("r6_anim_rate", "1", true, false, "The rate of the killmarker animation", 0.01, 10)
CreateClientConVar("r6_anim_rate", "1", true, false, "The rate of the killmarker animation", 0.01, 10)
CreateClientConVar("r6_opacity", "1", true, false, "Opacity (inverse transparency) of the killmarker. 1=fully visible, 0=fully transparent", 0, 1)
CreateClientConVar("r6_anim_framerateindependent", "1", true, false, "desc", 0, 1)
CreateClientConVar("r6_killmark_scale", "1", true, false, "The killmarker scales with resolution automatically but scale is provided for customization", 0.1, 200)
CreateClientConVar("r6_debug_frame", "-1", false, false, "Only for debug purposes. Forces the killmarker's animation frame to this number.", -1, 24)



local animTimer = -1
local friendMark = false

//util.AddNetworkString("r6Killmark")

function px(x)
  local scale = (ScrH()/1080)*GetConVar("r6_killmark_scale"):GetFloat()
  return x * scale
end

function u(x)
  local scale = ((ScrH()/1080)*GetConVar("r6_killmark_scale"):GetFloat())^-1
  return x * scale
end

print(u(ScrW()/2))

net.Receive("r6Killmark", function ()
  local friend = net.ReadBool()
  local victim = net.ReadEntity()
  if (victim:IsPlayer() and not GetConVar("r6_enable_playerkillmark"):GetBool()) then
    return
  end
  if (victim:IsNPC() and not GetConVar("r6_enable_npckillmark"):GetBool()) then
    return
  end
  if (victim == LocalPlayer()) then
    if (GetConVar("r6_suicidekillmark"):GetBool()) then
      friend = true
    else
      return
    end
  end
  friendMark = friend
  animTimer = 0
end)

hook.Add("HUDPaint", "r6KillmarkDraw", function ()
  local xcenter = ScrW()/2
  local ycenter = ScrH()/2
  local opac = GetConVar("r6_opacity"):GetFloat()
  if (animTimer ~= -1) then
    //render.OverrideBlend( true, BLEND_SRC_COLOR, BLEND_SRC_ALPHA, BLENDFUNC_ADD, BLEND_ONE, BLEND_ZERO, BLENDFUNC_ADD )
    cam.Start2D()
    local m = Matrix()
    m:Translate(Vector(xcenter, ycenter))
    m:Rotate( Angle(0, 45, 0) )
    m:Translate(-Vector(xcenter, ycenter))

    cam.PushModelMatrix(m)
    if (animTimer <= 3) then
      if (friendMark) then
        surface.SetDrawColor(255, 255, 255, ((animTimer)/3)*255)
      else
        surface.SetDrawColor(255, 0, 0, ((animTimer)/3)*255)
      end
    else
      if (friendMark) then
        surface.SetDrawColor(255, 255, 255)
      else
        surface.SetDrawColor(255, 0, 0)
      end
    end
    
    if (animTimer > 7) then
      if (friendMark) then
        surface.SetDrawColor(255, 255, 255, math.Remap(animTimer, 7, 24, 255, 0))
      else
        surface.SetDrawColor(255, 0, 0, math.Remap(animTimer, 7, 24, 255, 0))
      end
    end

    drawCenterRect(xcenter, ycenter, px(20), px(2.5))
    drawCenterRect(xcenter, ycenter, px(2.5), px(20))
    if (animTimer < 10) then
      local offset = math.Remap(math.Clamp(animTimer, 0, 8), 0, 7, 40, 8)
      local alpha = math.Remap(animTimer, 0, 10, 4, 0)
      if (friendMark) then
        surface.SetDrawColor(255, 255, 255, alpha)
      else
        surface.SetDrawColor(255, 0, 0, alpha)
      end
      gradientRect(xcenter + px(offset), ycenter, px(30), px(4), 64)
      gradientRect(xcenter, ycenter + px(offset), px(4), px(30), 64, true)
      gradientRect(xcenter - px(offset), ycenter, px(30), px(4), 64)
      gradientRect(xcenter, ycenter - px(offset), px(4), px(30), 64, true)
    end
    
    cam.PopModelMatrix()
    if (GetConVar("r6_debug_frame"):GetFloat() == -1) then
      local animAdd = GetConVar("r6_anim_rate"):GetFloat()
      if (GetConVar("r6_anim_framerateindependent"):GetBool()) then
        animAdd = animAdd * (RealFrameTime()^-1/60)^-1
      end
      animTimer = animTimer + animAdd
    end
    cam.End2D()
    render.OverrideBlend(false)
  end
  if (animTimer > 24 and GetConVar("r6_debug_frame"):GetFloat() == -1) then
    animTimer = -1
  end
  if (GetConVar("r6_debug_frame"):GetFloat() ~= -1) then
    animTimer = GetConVar("r6_debug_frame"):GetFloat()
  end
end)

function drawCenterRect(x, y, w, h)
  surface.DrawRect(x-w/2, y-h/2, w, h)
end 

function gradientRect(x, y, w, h, segments, axis)
  for i=0,segments do
    if (not axis) then
      drawCenterRect(x, y, w*(i/segments), h)
    else
      drawCenterRect(x, y, w, h*(i/segments))
    end
  end
end