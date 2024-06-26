local LocalPlayer = LocalPlayer
local surface_DrawRect = surface.DrawRect

local plyKillMark = CreateClientConVar( "r6_enable_playerkillmark", "1", true, false, "Show killmarkers when killing players.", 0, 1 )
local npcKillMark = CreateClientConVar( "r6_enable_npckillmark", "1", true, false, "Show killmarkers when killing NPCs.", 0, 1 )
local suicideKillMark = CreateClientConVar( "r6_suicidekillmark", "0", true, false, "Show a white killmarker when you commit suicide.", 0, 1 )
local animRate = CreateClientConVar( "r6_anim_rate", "1", true, false, "The rate of the killmarker animation.", 0.01, 10 )
local opac = CreateClientConVar( "r6_opacity", "1", true, false, "Opacity (inverse transparency) of the killmarker. 1 = fully visible, 0 = fully transparent", 0, 1 )
local frameInd = CreateClientConVar( "r6_anim_framerateindependent", "1", true, false, "Whether the killmarker should render independent of framerate or not.", 0, 1 )
local killMarkScale = CreateClientConVar( "r6_killmark_scale", "1", true, false, "The killmarker scales with resolution automatically, but scale is provided for customization.", 0.1, 200 )
local debugFrame = CreateClientConVar( "r6_debug_frame", "-1", false, false, "Only for debug purposes. Forces the killmarker's animation frame to this number.", -1, 24 )

local animTimer = -1
local friendMark = false
local rotationAngle = Angle( 0, 45, 0 )

local function px( x )
    local scale = ScrH() / 1080 * killMarkScale:GetFloat()

    return x * scale
end

local function drawCenterRect( x, y, w, h )
    surface_DrawRect( x - w / 2, y - h / 2, w, h )
end

local function gradientRect( x, y, w, h, segments, axis )
    for i = 0, segments do
        if not axis then
            drawCenterRect( x, y, w * i / segments, h )
        else
            drawCenterRect( x, y, w, h * i / segments )
        end
    end
end

net.Receive( "r6Killmark", function()
    local friend = net.ReadBool()
    local victim = net.ReadEntity()
    if victim:IsPlayer() and not plyKillMark:GetBool() then return end
    if victim:IsNPC() and not npcKillMark:GetBool() then return end

    if victim == LocalPlayer() then
        if not suicideKillMark:GetBool() then return end
        friend = true
    end

    friendMark = friend
    animTimer = 0
end )

hook.Add( "HUDPaint", "r6KillmarkDraw", function()
    local xcenter = ScrW() / 2
    local ycenter = ScrH() / 2
    local opacMult = opac:GetFloat()
    local curDebugFrame = debugFrame:GetFloat()

    if animTimer ~= -1 then
        --render.OverrideBlend( true, BLEND_SRC_COLOR, BLEND_SRC_ALPHA, BLENDFUNC_ADD, BLEND_ONE, BLEND_ZERO, BLENDFUNC_ADD )
        cam.Start2D()
        local m = Matrix()
        m:Translate( Vector( xcenter, ycenter ) )
        m:Rotate( rotationAngle )
        m:Translate( -Vector( xcenter, ycenter ) )
        cam.PushModelMatrix( m )

        if animTimer <= 3 then
            if friendMark then
                surface.SetDrawColor( 255, 255, 255, animTimer / 3 * 255 * opacMult )
            else
                surface.SetDrawColor( 255, 0, 0, animTimer / 3 * 255 * opacMult )
            end
        else
            if friendMark then
                surface.SetDrawColor( 255, 255, 255, 255 * opacMult )
            else
                surface.SetDrawColor( 255, 0, 0, 255 * opacMult )
            end
        end

        if animTimer > 7 then
            if friendMark then
                surface.SetDrawColor( 255, 255, 255, math.Remap( animTimer, 7, 24, 255, 0 ) )
            else
                surface.SetDrawColor( 255, 0, 0, math.Remap( animTimer, 7, 24, 255, 0 ) )
            end
        end

        drawCenterRect( xcenter, ycenter, px( 20 ), px( 2.5 ) )
        drawCenterRect( xcenter, ycenter, px( 2.5 ), px( 20 ) )

        if animTimer < 10 then
            local offset = math.Remap( math.Clamp( animTimer, 0, 8 ), 0, 7, 40, 8 )
            local alpha = math.Remap( animTimer, 0, 10, 4, 0 )

            if friendMark then
                surface.SetDrawColor( 255, 255, 255, alpha * opacMult )
            else
                surface.SetDrawColor( 255, 0, 0, alpha * opacMult )
            end

            gradientRect( xcenter + px( offset ), ycenter, px( 30 ), px( 4 ), 64 )
            gradientRect( xcenter, ycenter + px( offset ), px( 4 ), px( 30 ), 64, true )
            gradientRect( xcenter - px( offset ), ycenter, px( 30 ), px( 4 ), 64 )
            gradientRect( xcenter, ycenter - px( offset ), px( 4 ), px( 30 ), 64, true )
        end

        cam.PopModelMatrix()

        if curDebugFrame == -1 then
            local animAdd = animRate:GetFloat()

            if frameInd:GetBool() then
                animAdd = animAdd * ( RealFrameTime() ^ -1 / 60 ) ^ -1
            end

            animTimer = animTimer + animAdd
        end

        cam.End2D()
        render.OverrideBlend( false )
    end

    if animTimer > 24 and curDebugFrame == -1 then
        animTimer = -1
    end

    if curDebugFrame ~= -1 then
        animTimer = curDebugFrame
    end
end )