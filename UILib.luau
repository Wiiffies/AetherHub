--[[
    Aether UI  —  MS Paint edition

    A Windows 95 / MS Paint styled Roblox UI library. One look, done properly:
      * 2px chiselled bevels on every surface (raised / pressed / sunken / etched)
      * Navy title bar with a drawn program icon and real _ [] X glyph buttons
      * Win95 tab control, group boxes, checkboxes, trackbars, comboboxes, spin fields
      * Custom beveled scrollbar with arrow buttons
      * Status bar with sunken hint panels, resize grip, maximise / restore
      * "Zoom rectangle" open + close, instant everything else (authentic — Win95 didn't animate)
      * Tooltips (the yellow kind)
      * Message-box style notifications that cascade

    The screen behind the window is NOT darkened.

    API (backwards compatible with earlier Aether):
      local UI  = loadstring(...)()
      local win = UI:CreateWindow({ Title = "untitled - Paint", Size = UDim2.fromOffset(560, 420) })
      local tab = win:AddTab("Options")            -- ("name"[, iconUnused])
        tab:Section("Tools")
        tab:Label("plain text", "status-bar hint")
        tab:Button("Do it", fn, "hint")
        tab:Toggle("Enable thing", false, fn, "hint")        -- checkbox
        tab:Slider("Brush size", 1, 64, 8, fn, "hint")       -- trackbar
        tab:Dropdown("Mode", {"Pencil","Brush","Airbrush"}, "Brush", fn, "hint")
        tab:Keybind("Pick colour", Enum.KeyCode.K, fn, "hint")
        tab:Radio("Fill", {"None","Outline","Solid"}, "Outline", fn)
        tab:TextInput("Name", "untitled", fn)
        local g = tab:Group("Advanced")                       -- group box; same methods
          g:Toggle("Anti-alias", true)
      win:Notify("Paint", "Saved to Desktop.", 4)             -- Notify(title,text[,dur[,kind]])  kind: "info"|"warn"|"error"
]]

local UI = {}

-- harmless stubs so scripts written against the themed build don't hard-error
function UI:SetTheme() end
UI.Themes = setmetatable({}, { __index = function() return {} end })

local UserInputService = game:GetService("UserInputService")
local TextService      = game:GetService("TextService")
local CoreGui          = game:GetService("CoreGui")

--============================================================================
-- Palette (Windows 95 default scheme)
--============================================================================

local rgb = Color3.fromRGB
local COL = {
    W     = rgb(255, 255, 255),   -- button highlight
    L     = rgb(223, 223, 223),   -- button light
    FACE  = rgb(198, 198, 198),   -- 3D face
    G     = rgb(128, 128, 128),   -- button shadow
    K     = rgb( 10,  10,  10),   -- button dark shadow
    BLACK = rgb(  0,   0,   0),
    NAVY  = rgb(  0,   0, 128),   -- active title / selection
    NAVYT = rgb(255, 255, 255),   -- active title text
    GRAYT = rgb(128, 128, 128),   -- inactive title / disabled text
    FIELD = rgb(255, 255, 255),   -- input background
    TEXT  = rgb(  0,   0,   0),
    TIP   = rgb(255, 255, 225),   -- tooltip background
    TEAL  = rgb(  0, 128, 128),   -- the desktop
    RED   = rgb(200,   0,   0),
    YEL   = rgb(255, 216,   0),
}

local FONT      = Enum.Font.SourceSans
local FONT_B    = Enum.Font.SourceSansBold
local SIZE      = 15          -- body text
local SIZE_T    = 15          -- title text

--============================================================================
-- Low-level helpers
--============================================================================

local function new(class, props)
    local i = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then i[k] = v end
    end
    if props and props.Parent then i.Parent = props.Parent end
    return i
end

local function txt(props)
    props.Font = props.Font or FONT
    props.TextSize = props.TextSize or SIZE
    props.TextColor3 = props.TextColor3 or COL.TEXT
    props.BackgroundTransparency = props.BackgroundTransparency or 1
    props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    props.TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center
    props.RichText = false
    return new("TextLabel", props)
end

local function measure(s, size, font)
    return TextService:GetTextSize(s, size or SIZE, font or FONT, Vector2.new(4000, 40)).X
end

-- 8-slot chiselled border.  Slots: t0 l0 b0 r0 t1 l1 b1 r1
local BEVEL = {
    raised   = { "W","W","K","K", "L","L","G","G" },
    pressed  = { "K","K","W","W", "G","G","L","L" },
    field    = { "G","G","W","W", "K","K","L","L" },   -- sunken (inputs, client)
    group    = { "G","G","W","W", "W","W","G","G" },   -- etched (group boxes)
    tabOn    = { "W","W","",  "G", "",  "", "", ""  }, -- active tab: no bottom
    tabOff   = { "W","W","G", "G", "",  "", "", ""  },
    thin     = { "W","W","G", "G", "",  "", "", ""  },
    thinIn   = { "G","G","W", "W", "",  "", "", ""  },
}

local SLOT = {
    { UDim2.new(0,0,0,0),  UDim2.new(1,0,0,1) },   -- t0
    { UDim2.new(0,0,0,0),  UDim2.new(0,1,1,0) },   -- l0
    { UDim2.new(0,0,1,-1), UDim2.new(1,0,0,1) },   -- b0
    { UDim2.new(1,-1,0,0), UDim2.new(0,1,1,0) },   -- r0
    { UDim2.new(0,1,0,1),  UDim2.new(1,-2,0,1) },  -- t1
    { UDim2.new(0,1,0,1),  UDim2.new(0,1,1,-2) },  -- l1
    { UDim2.new(0,1,1,-2), UDim2.new(1,-2,0,1) },  -- b1
    { UDim2.new(1,-2,0,1), UDim2.new(0,1,1,-2) },  -- r1
}

-- attaches a bevel to `frame`; returns setter(styleName)
local function bevel(frame, style)
    local edges = {}
    for i = 1, 8 do
        edges[i] = new("Frame", {
            Name = "_bevel", BorderSizePixel = 0,
            Position = SLOT[i][1], Size = SLOT[i][2],
            ZIndex = frame.ZIndex, Parent = frame,
        })
    end
    local function apply(s)
        local spec = BEVEL[s] or BEVEL.raised
        for i = 1, 8 do
            local key = spec[i]
            if key and key ~= "" then
                edges[i].BackgroundColor3 = COL[key]
                edges[i].Visible = true
            else
                edges[i].Visible = false
            end
        end
    end
    apply(style or "raised")
    return apply
end

-- solid 1px border (dropdown lists, tooltips)
local function outline(frame, color)
    return new("UIStroke", { Color = color or COL.BLACK, Thickness = 1, Parent = frame })
end

--============================================================================
-- Screen / tooltip singletons
--============================================================================

local screen = new("ScreenGui", {
    Name = "AetherPaint",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 9999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = (gethui and gethui()) or CoreGui,
})

local Tip = new("Frame", {
    BackgroundColor3 = COL.TIP, BorderSizePixel = 0, Visible = false,
    ZIndex = 6000, AutomaticSize = Enum.AutomaticSize.XY, Parent = screen,
})
outline(Tip)
local TipText = txt({ Parent = Tip, Position = UDim2.fromOffset(4, 2), AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0), ZIndex = 6001 })
new("UIPadding", { PaddingLeft = UDim.new(0,4), PaddingRight = UDim.new(0,4), PaddingTop = UDim.new(0,1), PaddingBottom = UDim.new(0,2), Parent = Tip })

local function attachTip(host, text, onHint)
    if not text or text == "" then return end
    local token
    host.MouseEnter:Connect(function()
        if onHint then onHint(text) end
        token = {}
        local mine = token
        task.delay(0.7, function()
            if token ~= mine then return end
            local m = UserInputService:GetMouseLocation()
            -- GetMouseLocation omits the 36px top-inset; screen uses IgnoreGuiInset
            Tip.Position = UDim2.fromOffset(m.X + 12, m.Y + 36 + 18)
            TipText.Text = text
            Tip.Visible = true
        end)
    end)
    host.MouseLeave:Connect(function()
        token = nil
        Tip.Visible = false
        if onHint then onHint(nil) end
    end)
    host.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            token = nil; Tip.Visible = false
        end
    end)
end

--============================================================================
-- Drawn glyphs
--============================================================================

local function drawPaintIcon(parent)   -- 14x14 program icon
    local box = new("Frame", { BackgroundColor3 = COL.W, BorderSizePixel = 0, Size = UDim2.fromScale(1,1), Parent = parent })
    outline(box)
    local swatch = { COL.RED, rgb(0,168,0), rgb(0,0,255), COL.YEL }
    for idx, c in ipairs(swatch) do
        local col = (idx - 1) % 2
        local row = math.floor((idx - 1) / 2)
        new("Frame", {
            BackgroundColor3 = c, BorderSizePixel = 0,
            Size = UDim2.fromOffset(4, 4),
            Position = UDim2.fromOffset(2 + col * 5, 2 + row * 5),
            Parent = box,
        })
    end
end

local function glyphMin(b)
    new("Frame", { BackgroundColor3 = COL.BLACK, BorderSizePixel = 0,
        Size = UDim2.fromOffset(7, 2), Position = UDim2.new(0, 4, 1, -4), AnchorPoint = Vector2.new(0, 1), Parent = b })
end

local function glyphMax(b)
    local w = new("Frame", { BackgroundColor3 = COL.FACE, BorderSizePixel = 0,
        Size = UDim2.fromOffset(9, 8), Position = UDim2.fromScale(.5,.5), AnchorPoint = Vector2.new(.5,.5), Parent = b })
    outline(w)
    new("Frame", { BackgroundColor3 = COL.BLACK, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 2), Parent = w })
end

local function glyphRestore(b)
    local back = new("Frame", { BackgroundColor3 = COL.FACE, BorderSizePixel = 0,
        Size = UDim2.fromOffset(7, 6), Position = UDim2.new(.5, 1, .5, -2), AnchorPoint = Vector2.new(.5,.5), Parent = b })
    outline(back)
    new("Frame", { BackgroundColor3 = COL.BLACK, BorderSizePixel = 0, Size = UDim2.new(1,0,0,2), Parent = back })
    local front = new("Frame", { BackgroundColor3 = COL.FACE, BorderSizePixel = 0,
        Size = UDim2.fromOffset(7, 6), Position = UDim2.new(.5, -1, .5, 2), AnchorPoint = Vector2.new(.5,.5), Parent = b })
    outline(front)
    new("Frame", { BackgroundColor3 = COL.BLACK, BorderSizePixel = 0, Size = UDim2.new(1,0,0,2), Parent = front })
end

local function glyphX(b)
    for _, r in ipairs({ 45, -45 }) do
        new("Frame", { BackgroundColor3 = COL.BLACK, BorderSizePixel = 0, Rotation = r,
            Size = UDim2.fromOffset(9, 2), Position = UDim2.fromScale(.5,.5), AnchorPoint = Vector2.new(.5,.5), Parent = b })
    end
end

--============================================================================
-- A caption button ( _ [] X and the like )
--============================================================================

local function captionButton(parent, xOff, draw, onClick)
    local b = new("TextButton", {
        Text = "", AutoButtonColor = false, BackgroundColor3 = COL.FACE, BorderSizePixel = 0,
        Size = UDim2.fromOffset(16, 14), Position = UDim2.new(1, xOff, 0, 2), Parent = parent,
    })
    local setB = bevel(b, "raised")
    local hold = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1,1), ZIndex = 2, Parent = b })
    draw(hold)
    b.MouseButton1Down:Connect(function()
        setB("pressed"); hold.Position = UDim2.fromOffset(1, 1)
    end)
    local function up() setB("raised"); hold.Position = UDim2.fromOffset(0, 0) end
    b.MouseButton1Up:Connect(up)
    b.MouseLeave:Connect(up)
    b.MouseButton1Click:Connect(function() if onClick then onClick() end end)
    return b, hold, draw
end

--============================================================================
-- Window
--============================================================================

function UI:CreateWindow(cfg)
    cfg = cfg or {}
    local title   = cfg.Title or "untitled - Paint"
    local winSize = cfg.Size or UDim2.fromOffset(560, 420)
    local minW, minH = cfg.MinWidth or 360, cfg.MinHeight or 240

    -- optional teal desktop (off by default: screen brightness unchanged)
    local desktop
    if cfg.Desktop then
        desktop = new("Frame", { BackgroundColor3 = COL.TEAL, BorderSizePixel = 0, Size = UDim2.fromScale(1,1), Parent = screen })
    end

    local Root = new("Frame", {
        BackgroundColor3 = COL.FACE, BorderSizePixel = 0,
        Size = winSize, Position = UDim2.fromScale(.5,.5), AnchorPoint = Vector2.new(.5,.5),
        Visible = false, Parent = screen,
    })
    bevel(Root, "raised")

    ------------------------------------------------------------------ title bar
    local Title = new("Frame", {
        BackgroundColor3 = COL.NAVY, BorderSizePixel = 0,
        Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 0, 18), Parent = Root,
    })
    local sysIcon = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(14,14), Position = UDim2.fromOffset(2, 2), Parent = Title })
    drawPaintIcon(sysIcon)
    local titleText = txt({
        Parent = Title, Font = FONT_B, TextSize = SIZE_T, TextColor3 = COL.NAVYT,
        Text = title, Position = UDim2.fromOffset(20, 0), Size = UDim2.new(1, -74, 1, 0),
    })

    local maximized, preRect = false, nil
    local btnMin  = captionButton(Title, -52, glyphMin)
    local btnMaxHold
    local btnMax, mh = captionButton(Title, -36, glyphMax)
    btnMaxHold = mh
    local btnClose = captionButton(Title, -18, glyphX)

    ------------------------------------------------------------------ tab strip
    local TabStrip = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(6, 24), Size = UDim2.new(1, -12, 0, 20), Parent = Root })

    local Client = new("Frame", {
        BackgroundColor3 = COL.FACE, BorderSizePixel = 0,
        Position = UDim2.fromOffset(3, 43), Size = UDim2.new(1, -6, 1, -68), Parent = Root,
    })
    bevel(Client, "thin")

    ------------------------------------------------------------------ status bar
    local Status = new("Frame", { BackgroundColor3 = COL.FACE, BorderSizePixel = 0,
        Position = UDim2.new(0, 3, 1, -21), Size = UDim2.new(1, -6, 0, 18), Parent = Root })
    local function statusPanel(x, w, wScale)
        local p = new("Frame", { BackgroundColor3 = COL.FACE, BorderSizePixel = 0,
            Position = UDim2.new(0, x, 0, 0), Size = UDim2.new(wScale or 0, w, 1, 0), Parent = Status })
        bevel(p, "thinIn")
        return p
    end
    local hintPanel = statusPanel(0, -96, 1)
    local hintText  = txt({ Parent = hintPanel, Text = "For Help, press F1", Position = UDim2.fromOffset(6, 0), Size = UDim2.new(1, -10, 1, 0), TextColor3 = COL.TEXT })
    local sizePanel = statusPanel(0, 92, 0)
    sizePanel.Position = UDim2.new(1, -92, 0, 0)
    local sizeText  = txt({ Parent = sizePanel, Text = "", Position = UDim2.fromOffset(6, 0), Size = UDim2.new(1, -10, 1, 0), TextXAlignment = Enum.TextXAlignment.Center })

    local function setHint(s)
        hintText.Text = s or "For Help, press F1"
    end

    ------------------------------------------------------------------ resize grip
    local grip = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
        Size = UDim2.fromOffset(16, 16), Position = UDim2.new(1, -18, 1, -18), ZIndex = 5, Parent = Root })
    for i = 0, 2 do
        for _, o in ipairs({ {COL.W, 0}, {COL.G, 1} }) do
            new("Frame", { BackgroundColor3 = o[1], BorderSizePixel = 0, Rotation = 45,
                Size = UDim2.fromOffset(14 - i * 5, 2),
                Position = UDim2.fromScale(0.72 - i * 0.16 + o[2] * 0.02, 0.72 - i * 0.16 + o[2] * 0.02),
                AnchorPoint = Vector2.new(.5,.5), Parent = grip })
        end
    end

    local function refreshSize()
        sizeText.Text = math.floor(Root.AbsoluteSize.X) .. " x " .. math.floor(Root.AbsoluteSize.Y)
    end
    Root:GetPropertyChangedSignal("AbsoluteSize"):Connect(refreshSize)

    ------------------------------------------------------------------ drag / resize / maximise
    local function beginDrag(startInput, apply)
        local origin = startInput.Position
        local conMove, conEnd
        conMove = UserInputService.InputChanged:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
                apply(i.Position - origin)
            end
        end)
        conEnd = UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                conMove:Disconnect(); conEnd:Disconnect()
            end
        end)
    end

    Title.InputBegan:Connect(function(i)
        if maximized then return end
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            local startPos = Root.Position
            beginDrag(i, function(d)
                Root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end)
        end
    end)

    grip.InputBegan:Connect(function(i)
        if maximized then return end
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            local s = Root.AbsoluteSize
            beginDrag(i, function(d)
                Root.Size = UDim2.fromOffset(math.max(minW, s.X + d.X), math.max(minH, s.Y + d.Y))
            end)
        end
    end)

    local function setMaximized(v)
        maximized = v
        for _, c in ipairs(btnMaxHold:GetChildren()) do c:Destroy() end
        if v then
            preRect = { Root.Position, Root.Size }
            Root.AnchorPoint = Vector2.new(0, 0)
            Root.Position = UDim2.fromOffset(0, 0)
            Root.Size = UDim2.new(1, 0, 1, 0)
            glyphRestore(btnMaxHold)
        else
            Root.AnchorPoint = Vector2.new(.5, .5)
            if preRect then Root.Position, Root.Size = preRect[1], preRect[2] end
            glyphMax(btnMaxHold)
        end
    end
    btnMax.MouseButton1Click:Connect(function() setMaximized(not maximized) end)
    do
        local last = 0
        Title.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                local t = os.clock()
                if t - last < 0.3 then setMaximized(not maximized) end
                last = t
            end
        end)
    end

    ------------------------------------------------------------------ open / close zoom
    local function zoomRect(fromAbs, toAbs, steps, done)
        local o = new("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 8000, Parent = screen })
        outline(o, COL.W).Thickness = 2
        for s = 0, steps do
            local t = s / steps
            local p = fromAbs.p:Lerp(toAbs.p, t)
            local sz = fromAbs.s:Lerp(toAbs.s, t)
            o.Position = UDim2.fromOffset(p.X, p.Y)
            o.Size = UDim2.fromOffset(sz.X, sz.Y)
            task.wait(0.016)
        end
        o:Destroy()
        if done then done() end
    end

    task.spawn(function()
        local vp = screen.AbsoluteSize
        local final = { p = Vector2.new(vp.X/2 - winSize.X.Offset/2, vp.Y/2 - winSize.Y.Offset/2), s = Vector2.new(winSize.X.Offset, winSize.Y.Offset) }
        local start = { p = final.p + final.s * 0.4, s = final.s * 0.2 }
        zoomRect(start, final, 3, function() Root.Visible = true; refreshSize() end)
    end)

    local closed = false
    local function destroy()
        if closed then return end
        closed = true
        Root.Visible = false
        local from = { p = Root.AbsolutePosition, s = Root.AbsoluteSize }
        local to   = { p = from.p + from.s * 0.4, s = from.s * 0.2 }
        zoomRect(from, to, 3, function()
            if desktop then desktop:Destroy() end
            Root:Destroy()
        end)
    end
    btnClose.MouseButton1Click:Connect(destroy)

    local rolled, preRoll = false, nil
    btnMin.MouseButton1Click:Connect(function()
        rolled = not rolled
        if rolled then
            preRoll = Root.Size
            TabStrip.Visible = false; Client.Visible = false; Status.Visible = false; grip.Visible = false
            Root.Size = UDim2.new(Root.Size.X.Scale, Root.Size.X.Offset, 0, 24)
        else
            Root.Size = preRoll
            TabStrip.Visible = true; Client.Visible = true; Status.Visible = true; grip.Visible = true
        end
    end)

    ------------------------------------------------------------------ pages + scrollbar
    local PageHost = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6), ClipsDescendants = true, Parent = Client })

    local Window, tabs = {}, {}

    local function buildScrollbar(page)
        local SB = new("Frame", { BackgroundColor3 = COL.FACE, BorderSizePixel = 0, Visible = false,
            Position = UDim2.new(1, -16, 0, 0), Size = UDim2.new(0, 16, 1, 0), Parent = page.Parent })
        bevel(SB, "field")
        local function arrow(y, anchorY, glyph)
            local a = new("TextButton", { Text = glyph, Font = FONT, TextSize = 12, TextColor3 = COL.BLACK,
                AutoButtonColor = false, BackgroundColor3 = COL.FACE, BorderSizePixel = 0,
                Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0, 0, y, anchorY), Parent = SB })
            local setA = bevel(a, "raised")
            a.MouseButton1Down:Connect(function() setA("pressed") end)
            a.MouseButton1Up:Connect(function() setA("raised") end)
            a.MouseLeave:Connect(function() setA("raised") end)
            return a
        end
        local up   = arrow(0, 0, "\u{25B2}")
        local down = arrow(1, -16, "\u{25BC}")
        local thumb = new("Frame", { BackgroundColor3 = COL.FACE, BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0, 16), Parent = SB })
        bevel(thumb, "raised")

        local function metrics()
            local vh = page.AbsoluteWindowSize.Y
            local ch = page.AbsoluteCanvasSize.Y
            return vh, ch, math.max(ch - vh, 0)
        end
        local function refresh()
            local vh, ch, maxS = metrics()
            if not page.Visible or maxS < 1 then SB.Visible = false; return end
            SB.Visible = true
            local trackH = SB.AbsoluteSize.Y - 32
            local th = math.clamp(trackH * vh / ch, 16, trackH)
            local p = maxS > 0 and (page.CanvasPosition.Y / maxS) or 0
            thumb.Size = UDim2.new(1, 0, 0, th)
            thumb.Position = UDim2.new(0, 0, 0, 16 + (trackH - th) * p)
        end
        page:GetPropertyChangedSignal("CanvasPosition"):Connect(refresh)
        page:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(refresh)
        page:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(refresh)
        task.defer(refresh)

        local function nudge(delta)
            local _, _, maxS = metrics()
            page.CanvasPosition = Vector2.new(0, math.clamp(page.CanvasPosition.Y + delta, 0, maxS))
        end
        up.MouseButton1Click:Connect(function() nudge(-40) end)
        down.MouseButton1Click:Connect(function() nudge(40) end)

        thumb.InputBegan:Connect(function(i)
            if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            local startY = i.Position.Y
            local startScroll = page.CanvasPosition.Y
            local trackH = SB.AbsoluteSize.Y - 32
            local _, ch, maxS = metrics()
            local conM, conE
            conM = UserInputService.InputChanged:Connect(function(m)
                if m.UserInputType == Enum.UserInputType.MouseMovement then
                    local d = (m.Position.Y - startY) / math.max(trackH, 1)
                    page.CanvasPosition = Vector2.new(0, math.clamp(startScroll + d * ch, 0, maxS))
                end
            end)
            conE = UserInputService.InputEnded:Connect(function(m)
                if m.UserInputType == Enum.UserInputType.MouseButton1 then conM:Disconnect(); conE:Disconnect() end
            end)
        end)

        page.InputChanged:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseWheel then
                nudge(-i.Position.Z * 54)
            end
        end)
        return refresh
    end

    --====================================================================== element factory
    local function makeElements(container, refreshScroll)

        local function row(h)
            return new("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, h), Parent = container })
        end
        local function bump() if refreshScroll then task.defer(refreshScroll) end end

        local S = {}

        function S:Label(text, hint)
            local r = row(16)
            local l = txt({ Parent = r, Text = text, Size = UDim2.fromScale(1,1) })
            attachTip(l, hint, setHint)
            bump(); return S
        end

        function S:Section(text)
            local r = row(20)
            local w = measure(text, SIZE, FONT_B)
            txt({ Parent = r, Font = FONT_B, Text = text, Size = UDim2.new(0, w, 1, 0) })
            local line = new("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0,
                Position = UDim2.fromOffset(w + 6, 8), Size = UDim2.new(1, -(w + 6), 0, 2), Parent = r })
            bevel(line, "thinIn")
            bump(); return S
        end

        S.Divider = function(_) local r = row(6); local ln = new("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,2),Position=UDim2.fromOffset(0,2),Parent=r}); bevel(ln,"thinIn"); bump(); return S end

        function S:Button(text, callback, hint)
            local r = row(24)
            local b = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = COL.FACE,
                BorderSizePixel = 0, Size = UDim2.new(0, math.max(84, measure(text) + 28), 1, 0), Parent = r })
            local setB = bevel(b, "raised")
            local cap = txt({ Parent = b, Text = text, Size = UDim2.fromScale(1,1), ZIndex = 2,
                TextXAlignment = Enum.TextXAlignment.Center })
            b.MouseButton1Down:Connect(function() setB("pressed"); cap.Position = UDim2.fromOffset(1,1) end)
            local function upreset() setB("raised"); cap.Position = UDim2.fromOffset(0,0) end
            b.MouseButton1Up:Connect(upreset)
            b.MouseLeave:Connect(upreset)
            b.MouseButton1Click:Connect(function() if callback then task.spawn(callback) end end)
            attachTip(b, hint, setHint)
            bump(); return S
        end

        function S:Toggle(text, default, callback, hint)   -- checkbox
            local state = default == true
            local r = row(18)
            local box = new("Frame", { BackgroundColor3 = COL.FIELD, BorderSizePixel = 0,
                Size = UDim2.fromOffset(13, 13), Position = UDim2.fromOffset(0, 2), Parent = r })
            bevel(box, "field")
            local tick = new("ImageLabel", { BackgroundTransparency = 1, Image = "rbxassetid://7733715400",
                ImageColor3 = COL.BLACK, Size = UDim2.fromOffset(11, 11), Position = UDim2.fromOffset(1, 1),
                Visible = state, ZIndex = 3, Parent = box })
            txt({ Parent = r, Text = text, Position = UDim2.fromOffset(19, 0), Size = UDim2.new(1, -19, 1, 0) })
            local hit = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
                Size = UDim2.fromScale(1,1), Parent = r })
            local function set(v, fire)
                state = v; tick.Visible = v
                if fire and callback then task.spawn(callback, v) end
            end
            hit.MouseButton1Click:Connect(function() set(not state, true) end)
            attachTip(hit, hint, setHint)
            bump()
            return { Set = function(_, v) set(v == true, true) end, Get = function() return state end }
        end

        function S:Radio(text, options, default, callback, hint)
            local selected = default or options[1]
            local r = row(20 + #options * 18)
            local set
            local circles = {}
            if text and text ~= "" then txt({ Parent = r, Font = FONT_B, Text = text, Size = UDim2.new(1, 0, 0, 16) }) end
            for idx, opt in ipairs(options) do
                local y = 18 + (idx - 1) * 18
                local c = new("Frame", { BackgroundColor3 = COL.FIELD, BorderSizePixel = 0,
                    Size = UDim2.fromOffset(12, 12), Position = UDim2.fromOffset(1, y + 2), Parent = r })
                new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = c })
                local st = outline(c, COL.G); st.Thickness = 1
                local dot = new("Frame", { BackgroundColor3 = COL.BLACK, BorderSizePixel = 0,
                    Size = UDim2.fromOffset(4, 4), Position = UDim2.fromScale(.5,.5), AnchorPoint = Vector2.new(.5,.5),
                    Visible = opt == selected, Parent = c })
                new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })
                circles[opt] = dot
                txt({ Parent = r, Text = tostring(opt), Position = UDim2.fromOffset(19, y), Size = UDim2.new(1, -19, 0, 16) })
                local hit = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, y), Parent = r })
                hit.MouseButton1Click:Connect(function() set(opt, true) end)
                attachTip(hit, hint, setHint)
            end
            set = function(opt, fire)
                selected = opt
                for k, dot in pairs(circles) do dot.Visible = (k == opt) end
                if fire and callback then task.spawn(callback, opt) end
            end
            bump()
            return { Set = function(_, v) set(v, true) end, Get = function() return selected end }
        end

        function S:Slider(text, min, max, default, callback, hint)   -- trackbar
            local value = math.clamp(default or min, min, max)
            local r = row(36)
            txt({ Parent = r, Text = text, Size = UDim2.new(1, -52, 0, 16) })
            local valBox = new("Frame", { BackgroundColor3 = COL.FIELD, BorderSizePixel = 0,
                Size = UDim2.fromOffset(46, 16), Position = UDim2.new(1, -46, 0, 0), Parent = r })
            bevel(valBox, "field")
            local valTxt = txt({ Parent = valBox, Text = tostring(value), Size = UDim2.new(1, -6, 1, 0),
                Position = UDim2.fromOffset(3, 0), TextXAlignment = Enum.TextXAlignment.Right })

            local track = new("Frame", { BackgroundColor3 = COL.G, BorderSizePixel = 0,
                Size = UDim2.new(1, -14, 0, 4), Position = UDim2.fromOffset(2, 24), Parent = r })
            bevel(track, "field")
            -- tick marks
            for t = 0, 10 do
                new("Frame", { BackgroundColor3 = COL.G, BorderSizePixel = 0, Size = UDim2.fromOffset(1, 3),
                    Position = UDim2.new(t / 10, 0, 0, 8), Parent = track })
            end
            local thumb = new("Frame", { BackgroundColor3 = COL.FACE, BorderSizePixel = 0,
                Size = UDim2.fromOffset(12, 20), AnchorPoint = Vector2.new(.5, .5),
                Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0), ZIndex = 3, Parent = track })
            bevel(thumb, "raised")

            local function apply(rel, fire)
                rel = math.clamp(rel, 0, 1)
                value = math.floor(min + (max - min) * rel + 0.5)
                local rr = (value - min) / (max - min)
                thumb.Position = UDim2.new(rr, 0, 0.5, 0)
                valTxt.Text = tostring(value)
                if fire and callback then task.spawn(callback, value) end
            end
            local function fromX(x) return (x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1) end

            local hit = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
                ZIndex = 6, Size = UDim2.new(1, 0, 0, 22), Position = UDim2.fromOffset(0, 15), Parent = r })
            hit.InputBegan:Connect(function(i)
                if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
                apply(fromX(i.Position.X), true)
                local conM, conE
                conM = UserInputService.InputChanged:Connect(function(m)
                    if m.UserInputType == Enum.UserInputType.MouseMovement or m.UserInputType == Enum.UserInputType.Touch then
                        apply(fromX(m.Position.X), true)
                    end
                end)
                conE = UserInputService.InputEnded:Connect(function(m)
                    if m.UserInputType == Enum.UserInputType.MouseButton1 or m.UserInputType == Enum.UserInputType.Touch then
                        conM:Disconnect(); conE:Disconnect()
                    end
                end)
            end)
            attachTip(hit, hint, setHint)
            bump()
            return {
                Set = function(_, v) apply(((math.clamp(v, min, max)) - min) / (max - min), true) end,
                Get = function() return value end,
            }
        end

        function S:Dropdown(text, options, default, callback, hint)   -- combobox
            local selected = default or options[1]
            local open = false
            local r = row(20)
            txt({ Parent = r, Text = text, Size = UDim2.new(0.4, -6, 1, 0) })

            local field = new("Frame", { BackgroundColor3 = COL.FIELD, BorderSizePixel = 0,
                Size = UDim2.new(0.6, 0, 1, 0), Position = UDim2.new(0.4, 0, 0, 0), Parent = r })
            bevel(field, "field")
            local label = txt({ Parent = field, Text = tostring(selected), Position = UDim2.fromOffset(4, 0),
                Size = UDim2.new(1, -24, 1, 0) })
            local drop = new("TextButton", { Text = "\u{25BC}", Font = FONT, TextSize = 10, TextColor3 = COL.BLACK,
                AutoButtonColor = false, BackgroundColor3 = COL.FACE, BorderSizePixel = 0,
                Size = UDim2.fromOffset(16, 16), Position = UDim2.new(1, -18, 0.5, -8), Parent = field })
            local setD = bevel(drop, "raised")

            local list = new("Frame", { BackgroundColor3 = COL.FIELD, BorderSizePixel = 0, Visible = false,
                ZIndex = 4000, Parent = screen })
            outline(list)
            new("UIListLayout", { Parent = list })
            for _, opt in ipairs(options) do
                local o = new("TextButton", { Text = "  " .. tostring(opt), Font = FONT, TextSize = SIZE,
                    TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = COL.TEXT, AutoButtonColor = false,
                    BackgroundColor3 = COL.FIELD, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 18), ZIndex = 4001, Parent = list })
                o.MouseEnter:Connect(function() o.BackgroundColor3 = COL.NAVY; o.TextColor3 = COL.NAVYT end)
                o.MouseLeave:Connect(function() o.BackgroundColor3 = COL.FIELD; o.TextColor3 = COL.TEXT end)
                o.MouseButton1Click:Connect(function()
                    selected = opt; label.Text = tostring(opt)
                    open = false; list.Visible = false; setD("raised")
                    if callback then task.spawn(callback, opt) end
                end)
            end

            local catcher = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
                Size = UDim2.fromScale(1,1), ZIndex = 3999, Visible = false, Parent = screen })

            local function setOpen(v)
                open = v
                list.Visible = v; catcher.Visible = v
                setD(v and "pressed" or "raised")
                if v then
                    local ap, as = field.AbsolutePosition, field.AbsoluteSize
                    list.Position = UDim2.fromOffset(ap.X, ap.Y + as.Y)
                    list.Size = UDim2.fromOffset(as.X, #options * 18)
                end
            end
            local hit = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
                Size = UDim2.fromScale(1,1), Parent = field })
            hit.MouseButton1Click:Connect(function() setOpen(not open) end)
            drop.MouseButton1Click:Connect(function() setOpen(not open) end)
            catcher.MouseButton1Click:Connect(function() setOpen(false) end)
            attachTip(hit, hint, setHint)
            bump()
            return {
                Set = function(_, v) selected = v; label.Text = tostring(v); if callback then task.spawn(callback, v) end end,
                Get = function() return selected end,
            }
        end

        function S:Keybind(text, default, callback, hint)
            local key = default or Enum.KeyCode.Unknown
            local listening = false
            local r = row(20)
            txt({ Parent = r, Text = text, Size = UDim2.new(1, -96, 1, 0) })
            local field = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = COL.FIELD,
                BorderSizePixel = 0, Size = UDim2.fromOffset(92, 18), Position = UDim2.new(1, -92, 0.5, -9), Parent = r })
            bevel(field, "field")
            local kt = txt({ Parent = field, Text = key ~= Enum.KeyCode.Unknown and key.Name or "None",
                Size = UDim2.new(1, -8, 1, 0), Position = UDim2.fromOffset(4, 0), TextXAlignment = Enum.TextXAlignment.Center })
            field.MouseButton1Click:Connect(function()
                listening = true; kt.Text = "Press a key\u{2026}"
            end)
            UserInputService.InputBegan:Connect(function(i, gp)
                if listening and i.UserInputType == Enum.UserInputType.Keyboard then
                    listening = false
                    if i.KeyCode ~= Enum.KeyCode.Escape then key = i.KeyCode end
                    kt.Text = key ~= Enum.KeyCode.Unknown and key.Name or "None"
                    if callback then task.spawn(callback, key) end
                elseif not listening and not gp and i.KeyCode == key and key ~= Enum.KeyCode.Unknown then
                    if callback then task.spawn(callback, key) end
                end
            end)
            attachTip(field, hint, setHint)
            bump()
            return { Get = function() return key end }
        end

        function S:TextInput(text, default, callback, hint)
            local r = row(38)
            txt({ Parent = r, Text = text, Size = UDim2.new(1, 0, 0, 15) })
            local field = new("Frame", { BackgroundColor3 = COL.FIELD, BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 16), Parent = r })
            bevel(field, "field")
            local tb = new("TextBox", { Text = default or "", Font = FONT, TextSize = SIZE, TextColor3 = COL.TEXT,
                BackgroundTransparency = 1, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -8, 1, 0), Position = UDim2.fromOffset(4, 0), Parent = field })
            tb.FocusLost:Connect(function() if callback then task.spawn(callback, tb.Text) end end)
            attachTip(field, hint, setHint)
            bump()
            return { Set = function(_, v) tb.Text = tostring(v) end, Get = function() return tb.Text end }
        end

        function S:Group(titleText)
            local g = new("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0,
                AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Parent = container })
            local border = new("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0,
                Position = UDim2.fromOffset(0, 7), Size = UDim2.new(1, 0, 1, -7), Parent = g })
            bevel(border, "group")
            local w = measure(titleText or "", SIZE, FONT_B)
            local cap = new("Frame", { BackgroundColor3 = COL.FACE, BorderSizePixel = 0,
                Position = UDim2.fromOffset(8, 0), Size = UDim2.fromOffset(w + 8, 15), ZIndex = 2, Parent = g })
            txt({ Parent = cap, Font = FONT_B, Text = titleText or "", Size = UDim2.fromScale(1,1),
                Position = UDim2.fromOffset(4, 0), ZIndex = 3 })
            local inner = new("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0,
                AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, -20, 0, 0), Position = UDim2.fromOffset(10, 18), Parent = g })
            new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = inner })
            new("UIPadding", { PaddingBottom = UDim.new(0, 10), Parent = inner })
            bump()
            return makeElements(inner, refreshScroll)
        end

        -- v1 compat
        S.Paragraph = function(_, t, b) S:Section(t); if b then S:Label(b) end; return S end

        return S
    end

    --====================================================================== tabs
    local tabAccX = 0
    local activeTab

    function Window:AddTab(name)
        local w = math.max(52, measure(name) + 20)
        local x0 = tabAccX
        local btn = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = COL.FACE,
            BorderSizePixel = 0, Size = UDim2.fromOffset(w, 18), Position = UDim2.fromOffset(x0, 2), Parent = TabStrip })
        local setTab = bevel(btn, "tabOff")
        local cap = txt({ Parent = btn, Text = name, Size = UDim2.fromScale(1,1), ZIndex = 2,
            TextXAlignment = Enum.TextXAlignment.Center })
        tabAccX = tabAccX + w - 1

        local page = new("ScrollingFrame", {
            BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, Active = true,
            Size = UDim2.fromScale(1, 1), CanvasSize = UDim2.new(),
            ScrollBarThickness = 0, ScrollingEnabled = false,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = PageHost,
        })
        new("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 20),
            PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 8), Parent = page })
        new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })

        local refreshScroll = buildScrollbar(page)
        local entry = { btn = btn, page = page, cap = cap, setTab = setTab, w = w, x0 = x0, refresh = refreshScroll }

        local function select()
            for _, t in ipairs(tabs) do
                t.page.Visible = false
                t.setTab("tabOff")
                t.btn.Size = UDim2.fromOffset(t.w, 18)
                t.btn.Position = UDim2.fromOffset(t.x0, 2)
                t.cap.TextColor3 = COL.TEXT
                if t.refresh then task.defer(t.refresh) end
            end
            page.Visible = true
            setTab("tabOn")
            btn.Size = UDim2.fromOffset(w + 2, 21)
            btn.Position = UDim2.fromOffset(x0 - 1, 0)
            activeTab = entry
            task.defer(refreshScroll)
        end
        btn.MouseButton1Click:Connect(select)
        attachTip(btn, cfg.TabHint, setHint)

        table.insert(tabs, entry)
        if #tabs == 1 then select() end

        return makeElements(page, refreshScroll)
    end

    --====================================================================== notifications
    local notifX = 0
    function Window:Notify(nTitle, nText, duration, kind)
        duration = duration or 4
        kind = kind or "info"
        local bw, bh = 300, 128
        local box = new("Frame", { BackgroundColor3 = COL.FACE, BorderSizePixel = 0,
            Size = UDim2.fromOffset(bw, bh), AnchorPoint = Vector2.new(.5,.5),
            Position = UDim2.new(0.5, notifX, 0.5, notifX), ZIndex = 5000, Parent = screen })
        bevel(box, "raised")
        notifX = (notifX + 24) % 120

        local bar = new("Frame", { BackgroundColor3 = COL.NAVY, BorderSizePixel = 0, ZIndex = 5001,
            Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 0, 18), Parent = box })
        txt({ Parent = bar, Font = FONT_B, TextColor3 = COL.NAVYT, Text = nTitle or "Paint",
            Position = UDim2.fromOffset(6, 0), Size = UDim2.new(1, -30, 1, 0), ZIndex = 5002 })

        local iconColor = kind == "error" and COL.RED or kind == "warn" and COL.YEL or COL.NAVY
        local glyph = kind == "error" and "\u{2715}" or kind == "warn" and "!" or "i"
        local ic = new("Frame", { BackgroundColor3 = iconColor, BorderSizePixel = 0, ZIndex = 5001,
            Size = UDim2.fromOffset(30, 30), Position = UDim2.fromOffset(16, 34), Parent = box })
        new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ic })
        txt({ Parent = ic, Font = FONT_B, TextSize = 20, TextColor3 = COL.W, Text = glyph,
            Size = UDim2.fromScale(1,1), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 5002 })

        txt({ Parent = box, Text = nText or "", TextWrapped = true, ZIndex = 5001,
            Position = UDim2.fromOffset(58, 30), Size = UDim2.fromOffset(bw - 74, 52) })

        local ok = new("TextButton", { Text = "OK", Font = FONT, TextSize = SIZE, TextColor3 = COL.BLACK,
            AutoButtonColor = false, BackgroundColor3 = COL.FACE, BorderSizePixel = 0, ZIndex = 5001,
            Size = UDim2.fromOffset(76, 22), Position = UDim2.new(0.5, -38, 1, -30), Parent = box })
        local setOk = bevel(ok, "raised")
        new("Frame", { BackgroundColor3 = COL.BLACK, BackgroundTransparency = 0.0, BorderSizePixel = 0, ZIndex = 5000,
            Size = UDim2.new(1, 4, 1, 4), Position = UDim2.fromOffset(-2, -2), Parent = ok }).ZIndex = 4999
        ok.MouseButton1Down:Connect(function() setOk("pressed") end)
        ok.MouseButton1Up:Connect(function() setOk("raised") end)
        local done = false
        local function close() if done then return end done = true; box:Destroy() end
        ok.MouseButton1Click:Connect(close)
        task.delay(duration, close)
    end

    function Window:Destroy() destroy() end
    function Window:SetTitle(s) titleText.Text = s end

    return Window
end

return UI
