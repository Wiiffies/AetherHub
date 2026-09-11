





local __UILIB_SRC = [==[































local UI = {}


function UI:SetTheme() end
UI.Themes = setmetatable({}, { __index = function() return {} end })

local UserInputService = game:GetService("UserInputService")
local TextService      = game:GetService("TextService")
local CoreGui          = game:GetService("CoreGui")





local rgb = Color3.fromRGB
local COL = {
    W     = rgb(255, 255, 255),   
    L     = rgb(223, 223, 223),   
    FACE  = rgb(198, 198, 198),   
    G     = rgb(128, 128, 128),   
    K     = rgb( 10,  10,  10),   
    BLACK = rgb(  0,   0,   0),
    NAVY  = rgb(  0,   0, 128),   
    NAVYT = rgb(255, 255, 255),   
    GRAYT = rgb(128, 128, 128),   
    FIELD = rgb(255, 255, 255),   
    TEXT  = rgb(  0,   0,   0),
    TIP   = rgb(255, 255, 225),   
    TEAL  = rgb(  0, 128, 128),   
    RED   = rgb(200,   0,   0),
    YEL   = rgb(255, 216,   0),
}

local FONT      = Enum.Font.SourceSans
local FONT_B    = Enum.Font.SourceSansBold
local SIZE      = 15          
local SIZE_T    = 15          





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


local BEVEL = {
    raised   = { "W","W","K","K", "L","L","G","G" },
    pressed  = { "K","K","W","W", "G","G","L","L" },
    field    = { "G","G","W","W", "K","K","L","L" },   
    group    = { "G","G","W","W", "W","W","G","G" },   
    tabOn    = { "W","W","",  "G", "",  "", "", ""  }, 
    tabOff   = { "W","W","G", "G", "",  "", "", ""  },
    thin     = { "W","W","G", "G", "",  "", "", ""  },
    thinIn   = { "G","G","W", "W", "",  "", "", ""  },
}

local SLOT = {
    { UDim2.new(0,0,0,0),  UDim2.new(1,0,0,1) },   
    { UDim2.new(0,0,0,0),  UDim2.new(0,1,1,0) },   
    { UDim2.new(0,0,1,-1), UDim2.new(1,0,0,1) },   
    { UDim2.new(1,-1,0,0), UDim2.new(0,1,1,0) },   
    { UDim2.new(0,1,0,1),  UDim2.new(1,-2,0,1) },  
    { UDim2.new(0,1,0,1),  UDim2.new(0,1,1,-2) },  
    { UDim2.new(0,1,1,-2), UDim2.new(1,-2,0,1) },  
    { UDim2.new(1,-2,0,1), UDim2.new(0,1,1,-2) },  
}


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


local function outline(frame, color)
    return new("UIStroke", { Color = color or COL.BLACK, Thickness = 1, Parent = frame })
end





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





local function drawPaintIcon(parent)   
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





function UI:CreateWindow(cfg)
    cfg = cfg or {}
    local title   = cfg.Title or "untitled - Paint"
    local winSize = cfg.Size or UDim2.fromOffset(560, 420)
    local minW, minH = cfg.MinWidth or 360, cfg.MinHeight or 240

    
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

    
    local TabStrip = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(6, 24), Size = UDim2.new(1, -12, 0, 20), Parent = Root })

    local Client = new("Frame", {
        BackgroundColor3 = COL.FACE, BorderSizePixel = 0,
        Position = UDim2.fromOffset(3, 43), Size = UDim2.new(1, -6, 1, -68), Parent = Root,
    })
    bevel(Client, "thin")

    
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

        return refresh
    end

    
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

        function S:Toggle(text, default, callback, hint)   
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

        function S:Slider(text, min, max, default, callback, hint)   
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

        function S:Dropdown(text, options, default, callback, hint)   
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

        function S:MultiDropdown(text, options, default, callback, hint)
            local sel = {}
            if type(default) == "table" then
                for k, vv in pairs(default) do
                    if type(k) == "string" and vv == true then sel[k] = true
                    elseif type(vv) == "string" then sel[vv] = true end
                end
            end
            local function selList()
                local t = {}
                for k, v in pairs(sel) do if v then table.insert(t, k) end end
                for _, k in ipairs(t) do t[k] = true end
                return t
            end
            local function caption()
                local n = 0
                for _ in pairs(sel) do n = n + 1 end
                if n == 0 then return "—" end
                return n .. " selected"
            end
            local open = false
            local r = row(20)
            txt({ Parent = r, Text = text, Size = UDim2.new(0.4, -6, 1, 0) })
            local field = new("Frame", { BackgroundColor3 = COL.FIELD, BorderSizePixel = 0,
                Size = UDim2.new(0.6, 0, 1, 0), Position = UDim2.new(0.4, 0, 0, 0), Parent = r })
            bevel(field, "field")
            local label = txt({ Parent = field, Text = caption(), Position = UDim2.fromOffset(4, 0),
                Size = UDim2.new(1, -24, 1, 0) })
            local drop = new("TextButton", { Text = "\u{25BC}", Font = FONT, TextSize = 10, TextColor3 = COL.BLACK,
                AutoButtonColor = false, BackgroundColor3 = COL.FACE, BorderSizePixel = 0,
                Size = UDim2.fromOffset(16, 16), Position = UDim2.new(1, -18, 0.5, -8), Parent = field })
            local setD = bevel(drop, "raised")
            local list = new("Frame", { BackgroundColor3 = COL.FIELD, BorderSizePixel = 0, Visible = false,
                ZIndex = 4000, Parent = screen })
            outline(list)
            new("UIListLayout", { Parent = list })
            local rows = {}
            local function paint()
                label.Text = caption()
                for opt, o in pairs(rows) do
                    o.Text = (sel[opt] and "\u{2713} " or "    ") .. tostring(opt)
                end
            end
            for _, opt in ipairs(options) do
                local o = new("TextButton", { Text = "    " .. tostring(opt), Font = FONT, TextSize = SIZE,
                    TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = COL.TEXT, AutoButtonColor = false,
                    BackgroundColor3 = COL.FIELD, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 18), ZIndex = 4001, Parent = list })
                rows[opt] = o
                o.MouseEnter:Connect(function() o.BackgroundColor3 = COL.NAVY; o.TextColor3 = COL.NAVYT end)
                o.MouseLeave:Connect(function() o.BackgroundColor3 = COL.FIELD; o.TextColor3 = COL.TEXT end)
                o.MouseButton1Click:Connect(function()
                    if sel[opt] then sel[opt] = nil else sel[opt] = true end
                    paint()
                    if callback then task.spawn(callback, selList()) end
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
            paint()
            return {
                Set = function(_, v)
                    sel = {}
                    if type(v) == "table" then
                        for k, vv in pairs(v) do
                            if type(k) == "string" and vv == true then sel[k] = true
                            elseif type(vv) == "string" then sel[vv] = true end
                        end
                    end
                    paint()
                    if callback then task.spawn(callback, selList()) end
                end,
                Get = function() return selList() end,
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

        
        S.Paragraph = function(_, t, b) S:Section(t); if b then S:Label(b) end; return S end

        return S
    end

    
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
            ScrollBarThickness = 0, ScrollingEnabled = true,
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

]==]

local __ADAPTER_SRC = [==[






local UI = ...
assert(type(UI) == "table" and type(UI.CreateWindow) == "function", "UILIB missing")

local Library = {}
Library.Flags = {}
Library._flagObjects = {}
Library.Version = "2.0.0-win95"

local HttpService = nil
pcall(function() HttpService = game:GetService("HttpService") end)

local _memConfigs = {}
local function cfgPath(name) return "AetherHub_" .. tostring(name) .. ".json" end

function Library:SaveConfig(name)
    if type(name) ~= "string" or name == "" then return false, "bad name" end
    local data = {}
    for flag, obj in pairs(self._flagObjects) do
        local ok, v = pcall(function() return obj:Get() end)
        if ok and v ~= nil and type(v) ~= "function" then
            if typeof and typeof(v) == "EnumItem" then v = { __enum = tostring(v) } end
            data[flag] = v
        end
    end
    local ser = nil
    if HttpService then
        local ok, s = pcall(HttpService.JSONEncode, HttpService, data)
        if ok then ser = s end
    end
    if not ser then return false, "no serializer" end
    _memConfigs[name] = ser
    if type(writefile) == "function" then pcall(writefile, cfgPath(name), ser) end
    return true
end

function Library:LoadConfig(name)
    local ser = _memConfigs[name]
    if type(readfile) == "function" and type(isfile) == "function" then
        pcall(function()
            if isfile(cfgPath(name)) then ser = readfile(cfgPath(name)) end
        end)
    end
    if type(ser) ~= "string" then return false, "not found" end
    local data = nil
    if HttpService then
        local ok, t = pcall(HttpService.JSONDecode, HttpService, ser)
        if ok then data = t end
    end
    if type(data) ~= "table" then return false, "bad data" end
    for flag, val in pairs(data) do
        if type(val) == "table" and type(val.__enum) == "string" then
            continue
        end
        local obj = self._flagObjects[flag]
        if obj and type(obj.Set) == "function" then pcall(obj.Set, obj, val) end
    end
    return true
end

function Library:ListConfigs()
    local out = {}
    for k in pairs(_memConfigs) do table.insert(out, k) end
    return out
end

local function isFrac(x) return type(x) == "number" and x ~= math.floor(x) end




local function guiParent()
    local p = nil
    pcall(function() if type(gethui) == "function" then p = gethui() end end)
    if p then return p end
    pcall(function() p = game:GetService("CoreGui") end)
    if p then return p end
    local lp = game:GetService("Players").LocalPlayer
    if lp then pcall(function() p = lp:FindFirstChildOfClass("PlayerGui") end) end
    return p
end

local function edge(parent, x, y, w, h, color)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = color
    f.BorderSizePixel = 0
    f.Position = UDim2.fromOffset(x, y)
    f.Size = UDim2.fromOffset(w, h)
    f.ZIndex = 9002
    f.Parent = parent
    return f
end

local function showSplash(title, dur, done)
    local parent = guiParent()
    if not parent then task.spawn(done) return end
    local FACE = Color3.fromRGB(198, 198, 198)
    local W = Color3.fromRGB(255, 255, 255)
    local G = Color3.fromRGB(128, 128, 128)
    local K = Color3.fromRGB(10, 10, 10)
    local NAVY = Color3.fromRGB(0, 0, 128)
    local gui = Instance.new("ScreenGui")
    gui.Name = "AetherSetup"
    gui.ResetOnSpawn = false
    gui.Parent = parent
    local BW, BH = 400, 158
    local win = Instance.new("Frame")
    win.BackgroundColor3 = FACE
    win.BorderSizePixel = 0
    win.AnchorPoint = Vector2.new(0.5, 0.5)
    win.Position = UDim2.fromScale(0.5, 0.5)
    win.Size = UDim2.fromOffset(BW, BH)
    win.ZIndex = 9001
    win.Parent = gui
    
    edge(win, 0, 0, BW, 2, W); edge(win, 0, 0, 2, BH, W)
    edge(win, 0, BH - 2, BW, 2, K); edge(win, BW - 2, 0, 2, BH, K)
    edge(win, 2, 2, BW - 4, 1, FACE); edge(win, 2, 2, 1, BH - 4, FACE)
    
    local bar = Instance.new("Frame")
    bar.BackgroundColor3 = NAVY
    bar.BorderSizePixel = 0
    bar.Position = UDim2.fromOffset(4, 4)
    bar.Size = UDim2.new(1, -8, 0, 18)
    bar.ZIndex = 9002
    bar.Parent = win
    local cap = Instance.new("TextLabel")
    cap.BackgroundTransparency = 1
    cap.Font = Enum.Font.SourceSansBold
    cap.TextSize = 15
    cap.TextColor3 = Color3.fromRGB(255, 255, 255)
    cap.TextXAlignment = Enum.TextXAlignment.Left
    cap.Text = "  " .. title .. " Setup"
    cap.Size = UDim2.new(1, -8, 1, 0)
    cap.Position = UDim2.fromOffset(4, 0)
    cap.ZIndex = 9003
    cap.Parent = bar
    
    local info = Instance.new("TextLabel")
    info.BackgroundTransparency = 1
    info.Font = Enum.Font.SourceSans
    info.TextSize = 15
    info.TextColor3 = Color3.fromRGB(0, 0, 0)
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.Text = "  Please wait while Setup installs components..."
    info.Position = UDim2.fromOffset(10, 30)
    info.Size = UDim2.new(1, -20, 0, 18)
    info.ZIndex = 9002
    info.Parent = win
    local stat = Instance.new("TextLabel")
    stat.BackgroundTransparency = 1
    stat.Font = Enum.Font.SourceSans
    stat.TextSize = 15
    stat.TextColor3 = Color3.fromRGB(0, 0, 0)
    stat.TextXAlignment = Enum.TextXAlignment.Left
    stat.Text = "  Copying files..."
    stat.Position = UDim2.fromOffset(10, 50)
    stat.Size = UDim2.new(1, -20, 0, 18)
    stat.ZIndex = 9002
    stat.Parent = win
    
    local track = Instance.new("Frame")
    track.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    track.BorderSizePixel = 0
    track.Position = UDim2.fromOffset(12, 76)
    track.Size = UDim2.new(1, -24, 0, 24)
    track.ZIndex = 9002
    track.Parent = win
    
    edge(track, 0, 0, 376, 2, G); edge(track, 0, 0, 2, 24, G)
    edge(track, 0, 22, 376, 2, W); edge(track, 374, 0, 2, 24, W)
    edge(track, 2, 2, 372, 1, K); edge(track, 2, 2, 1, 20, K)
    local NSEG = 14
    local segs = {}
    for i = 1, NSEG do
        local s = Instance.new("Frame")
        s.BackgroundColor3 = NAVY
        s.BorderSizePixel = 0
        s.Position = UDim2.new(0, 3 + (i - 1) * ((BW - 30) / NSEG), 0, 3)
        s.Size = UDim2.fromOffset(math.floor((BW - 30) / NSEG) - 3, 18)
        s.Visible = false
        s.ZIndex = 9003
        s.Parent = track
        segs[i] = s
    end
    local pct = Instance.new("TextLabel")
    pct.BackgroundTransparency = 1
    pct.Font = Enum.Font.SourceSans
    pct.TextSize = 15
    pct.TextColor3 = Color3.fromRGB(0, 0, 0)
    pct.TextXAlignment = Enum.TextXAlignment.Center
    pct.Text = "0%"
    pct.Position = UDim2.fromOffset(0, 104)
    pct.Size = UDim2.new(1, 0, 0, 18)
    pct.ZIndex = 9002
    pct.Parent = win
    local msgs = { "  Copying files...", "  Registering components...", "  Building control panel...", "  Finishing installation..." }
    task.spawn(function()
        local steps = NSEG
        for i = 1, steps do
            segs[i].Visible = true
            pct.Text = tostring(math.floor(i / steps * 100)) .. "%"
            stat.Text = msgs[math.min(4, math.floor((i - 1) / (steps / 4)) + 1)]
            task.wait(math.max(dur / steps, 0.03))
        end
        task.wait(0.15)
        pcall(function() gui:Destroy() end)
        task.spawn(done)
    end)
end




local function findScreen(title)
    local roots = {}
    pcall(function() if type(gethui) == "function" then table.insert(roots, gethui()) end end)
    pcall(function() table.insert(roots, game:GetService("CoreGui")) end)
    pcall(function()
        local lp = game:GetService("Players").LocalPlayer
        if lp then
            local pg = lp:FindFirstChildOfClass("PlayerGui")
            if pg then table.insert(roots, pg) end
        end
    end)
    for _, r in ipairs(roots) do
        if r then
            local found = nil
            pcall(function()
                for _, d in ipairs(r:GetDescendants()) do
                    if d:IsA("TextLabel") and d.Text == title then
                        local g = d:FindFirstAncestorOfClass("ScreenGui")
                        if g then found = g break end
                    end
                end
            end)
            if found then return found end
        end
    end
    return nil
end

local function flush(q, ctx)
    local items = q
    for i = 1, #items do
        local fn = items[i]
        items[i] = nil
        pcall(fn, ctx)
    end
end

local function regFlag(flag, obj)
    if type(flag) == "string" and flag ~= "" then
        Library._flagObjects[flag] = obj
        local ok, v = pcall(function() return obj:Get() end)
        if ok then Library.Flags[flag] = v end
    end
end

local function makeControls(C)
    function C:AddToggle(o)
        o = o or {}
        local box = {}
        local H = {}
        function H:Get()
            if box.h then return box.h.Get() end
            return o.Default == true
        end
        function H:Set(v)
            if box.h then box.h:Set(v == true)
            else o._pending = v end
        end
        C:_run(function(sc)
            local h = sc:Toggle(o.Name or "Toggle", o.Default == true, function(v)
                if o.Flag then Library.Flags[o.Flag] = v end
                if type(o.Callback) == "function" then task.spawn(o.Callback, v) end
            end)
            box.h = h
            if o.Flag then Library.Flags[o.Flag] = h.Get() end
            regFlag(o.Flag, H)
            if o._pending ~= nil then H:Set(o._pending) o._pending = nil end
            if type(o.Callback) == "function" then task.defer(o.Callback, h.Get()) end
        end)
        return H
    end

    function C:AddButton(o)
        o = o or {}
        C:_run(function(sc)
            sc:Button(o.Name or "Button", function()
                if type(o.Callback) == "function" then task.spawn(o.Callback) end
            end)
        end)
        return nil
    end

    function C:AddDropdown(o)
        o = o or {}
        local opts = o.Options or o.Items or {}
        local box = {}
        local H = {}
        function H:Get()
            if box.h then return box.h.Get() end
            return o.Default
        end
        function H:Set(v)
            if box.h then box.h:Set(v)
            else o._pending = v end
        end
        function H:SetOptions(n)
            opts = n or {}
            
            if box.h and #opts > 0 then
                local cur = box.h.Get()
                local keep = false
                for _, x in ipairs(opts) do if x == cur then keep = true break end end
                if not keep then H:Set(opts[1]) end
            end
        end
        C:_run(function(sc)
            local h = sc:Dropdown(o.Name or "Dropdown", opts, o.Default, function(v)
                if o.Flag then Library.Flags[o.Flag] = v end
                if type(o.Callback) == "function" then task.spawn(o.Callback, v) end
            end)
            box.h = h
            if o._pending ~= nil then H:Set(o._pending) o._pending = nil end
            if o.Flag then Library.Flags[o.Flag] = h.Get() end
            regFlag(o.Flag, H)
            if o.Default ~= nil and type(o.Callback) == "function" then task.defer(o.Callback, h.Get()) end
        end)
        return H
    end

    function C:AddMultiDropdown(o)
        o = o or {}
        local opts = o.Options or o.Items or {}
        local box = {}
        local H = {}
        local function fromV(v)
            local t = {}
            if type(v) == "table" then
                for k, vv in pairs(v) do
                    if type(k) == "string" and vv == true then t[k] = true
                    elseif type(vv) == "string" then t[vv] = true end
                end
            end
            return t
        end
        function H:Get()
            if box.h then return box.h.Get() end
            return fromV(o.Default)
        end
        function H:Set(v)
            if box.h then box.h:Set(v)
            else o._pending = v end
        end
        function H:SetOptions(n) opts = n or {} end
        C:_run(function(sc)
            local h = sc:MultiDropdown(o.Name or "Multi", opts, o.Default, function()
                local cur = h.Get()
                if o.Flag then Library.Flags[o.Flag] = cur end
                if type(o.Callback) == "function" then task.spawn(o.Callback, cur) end
            end)
            box.h = h
            if o._pending ~= nil then H:Set(o._pending) o._pending = nil end
            if o.Flag then Library.Flags[o.Flag] = h.Get() end
            regFlag(o.Flag, H)
        end)
        return H
    end

    function C:AddSlider(o)
        o = o or {}
        local mn = tonumber(o.Min) or 0
        local mx = tonumber(o.Max) or 100
        local df = tonumber(o.Default)
        if df == nil then df = mn end
        
        local k = 1
        if isFrac(mn) or isFrac(mx) or isFrac(df) then k = 100 end
        local function toUI(v) return math.floor(math.clamp(tonumber(v) or df, mn, mx) * k + 0.5) end
        local function toReal(v) return (tonumber(v) or 0) / k end
        local box = {}
        local H = {}
        function H:Get()
            if box.h then return toReal(box.h.Get()) end
            return df
        end
        function H:Set(v)
            local rv = math.clamp(tonumber(v) or df, mn, mx)
            if box.h then box.h:Set(toUI(rv))
            else o._pending = rv end
        end
        C:_run(function(sc)
            local h = sc:Slider(o.Name or "Slider", toUI(mn), toUI(mx), toUI(df), function(uv)
                local rv = toReal(uv)
                if o.Flag then Library.Flags[o.Flag] = rv end
                if type(o.Callback) == "function" then task.spawn(o.Callback, rv) end
            end)
            box.h = h
            if o.Flag then Library.Flags[o.Flag] = toReal(h.Get()) end
            regFlag(o.Flag, H)
            if o._pending ~= nil then H:Set(o._pending) o._pending = nil end
            if type(o.Callback) == "function" then task.defer(o.Callback, toReal(h.Get())) end
        end)
        return H
    end

    function C:AddInput(o)
        o = o or {}
        local box = {}
        local H = {}
        function H:Get()
            if box.h then return box.h.Get() end
            return tostring(o.Default or "")
        end
        function H:Set(v)
            if box.h then box.h:Set(v)
            else o._pending = v end
        end
        C:_run(function(sc)
            local h = sc:TextInput(o.Name or "Input", tostring(o.Default or ""), function(v)
                if o.Flag then Library.Flags[o.Flag] = v end
                if type(o.Callback) == "function" then task.spawn(o.Callback, v) end
            end)
            box.h = h
            if o._pending ~= nil then H:Set(o._pending) o._pending = nil end
            regFlag(o.Flag, H)
        end)
        return H
    end

    function C:AddKeybind(o)
        o = o or {}
        local def = o.Default
        local okType = false
        pcall(function() okType = (typeof(def) == "EnumItem") end)
        if not okType then def = Enum.KeyCode.RightControl end
        local box = {}
        local H = {}
        function H:Get()
            if box.h then return box.h.Get() end
            return def
        end
        function H:Set(_) end
        C:_run(function(sc)
            local fn = type(o.OnPress) == "function" and o.OnPress or o.Callback
            local h = sc:Keybind(o.Name or "Keybind", def, function(k)
                if o.Flag then Library.Flags[o.Flag] = k end
                if type(fn) == "function" then task.spawn(fn, k) end
            end)
            box.h = h
            if o.Flag then Library.Flags[o.Flag] = h.Get() end
            Library._flagObjects[o.Flag or ("kb_" .. tostring(o.Name))] = H
        end)
        return H
    end

    function C:AddDivider()
        C:_run(function(sc) sc.Divider(sc) end)
        return nil
    end

    function C:AddParagraph(o)
        o = o or {}
        C:_run(function(sc)
            sc:Paragraph(tostring(o.Title or ""), tostring(o.Content or o.Text or ""))
        end)
        return nil
    end

    C.AddSection = function(_, t)
        C:_run(function(sc) sc:Section(tostring(type(t) == "table" and (t.Name or t.Title) or t)) end)
    end
    return C
end

function Library:CreateWindow(opts)
    opts = opts or {}
    local title = tostring(opts.Name or opts.Title or "Aether HUB")
    local dur = tonumber(opts.LoadingDuration) or 1.6

    local W = { _queue = {}, _ui = nil, _hidden = false, _dead = false, _title = title }
    function W:_run(fn)
        if self._ui then pcall(fn, self._ui)
        else table.insert(self._queue, fn) end
    end

    function W:AddTab(o)
        o = o or {}
        local T = { _queue = {}, _tab = nil }
        function T:_run(fn)
            if self._tab then pcall(fn, self._tab)
            else table.insert(self._queue, fn) end
        end
        function T:AddSubTab(name)
            if type(name) == "table" then name = name.Name or name.Title or "Section" end
            local C = { _queue = {}, _scope = nil }
            function C:_run(fn)
                if self._scope then pcall(fn, self._scope)
                else table.insert(self._queue, fn) end
            end
            makeControls(C)
            T:_run(function(tab)
                C._scope = tab:Group(tostring(name))
                flush(C._queue, C._scope)
            end)
            return C
        end
        T.AddSection = T.AddSubTab
        W:_run(function(ui)
            T._tab = ui:AddTab(tostring(o.Name or "Tab"))
            flush(T._queue, T._tab)
        end)
        return T
    end

    local KINDMAP = { success = "info", ok = "info", info = "info", warn = "warn", warning = "warn", error = "error" }
    function W:Notify(o)
        o = o or {}
        if Library._quiet then return end
        local t = tostring(o.Title or "Aether")
        local c = tostring(o.Content or o.Text or "")
        local d = tonumber(o.Duration) or 3
        local k = KINDMAP[string.lower(tostring(o.Type or o.Kind or "info"))] or "info"
        W:_run(function(ui) ui:Notify(t, c, d, k) end)
    end

    function W:Toggle()
        W._hidden = not W._hidden
        local hide = W._hidden
        local title = W._title
        W:_run(function()
            local g = findScreen(title)
            if g then pcall(function() g.Enabled = not hide end) end
        end)
    end
    function W:Show()
        W._hidden = false
        local title = W._title
        W:_run(function()
            local g = findScreen(title)
            if g then pcall(function() g.Enabled = true end) end
        end)
    end
    function W:Hide()
        if not W._hidden then W:Toggle() end
    end
    function W:Destroy()
        W._dead = true
        W:_run(function(ui) pcall(function() ui:Destroy() end) end)
    end
    function W:SetTitle(s)
        W._title = tostring(s)
        W:_run(function(ui) pcall(function() ui:SetTitle(W._title) end) end)
    end

    showSplash(title, dur, function()
        if W._dead then return end
        local ui = UI:CreateWindow({ Title = title, Size = UDim2.fromOffset(660, 480) })
        W._ui = ui
        Library._quiet = true
        flush(W._queue, ui)
        task.delay(3, function() Library._quiet = false end)
        if W._hidden then
            local g = findScreen(title)
            if g then pcall(function() g.Enabled = false end) end
        end
    end)
    return W
end

return Library

]==]
local __UI = assert(loadstring(__UILIB_SRC, "AetherUI"))()
__UILIB_SRC = nil
local Library = assert(loadstring(__ADAPTER_SRC, "AetherAdapter"))(__UI)
__ADAPTER_SRC = nil
__UI = nil





do
    local prev = _G.AetherHub
    if prev and type(prev.Unload) == "function" then pcall(prev.Unload) end
end
local HUB = { conns = {}, drawings = {}, highlights = {}, dead = false }
_G.AetherHub = HUB
HUB.keyUrl = "https://aether-keys.wispz.workers.dev"
HUB.premium = false
HUB.keyInput = ""
HUB.keyActive = false
local function track(conn) table.insert(HUB.conns, conn); return conn end
local function trackDrawing(d) if d then table.insert(HUB.drawings, d) end; return d end






local HAS_CONFIG = type(Library.SaveConfig) == "function"
    and type(Library.LoadConfig) == "function"
    and type(Library.ListConfigs) == "function"
local CONFIG_NAME = "stealanegg"

local dropdownResync = {}
local function registerResync(handle, applyFn)
    if handle and applyFn then
        table.insert(dropdownResync, function() applyFn(handle:Get()) end)
    end
end
local function ResyncAll()
    for _, fn in ipairs(dropdownResync) do pcall(fn) end
end




local Players             = game:GetService("Players")
local RS                  = game:GetService("ReplicatedStorage")
local ReplicatedStorage   = RS
local RunService          = game:GetService("RunService")
local UserInputService    = game:GetService("UserInputService")
local Workspace           = game:GetService("Workspace")
local Lighting            = game:GetService("Lighting")
local TeleportService     = game:GetService("TeleportService")
local VirtualUser         = game:GetService("VirtualUser")

local LP          = Players.LocalPlayer
local LocalPlayer = LP
local function GetCamera()
    return Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
end


pcall(function()
    local pps = game:GetService("ProximityPromptService")
    track(pps.PromptButtonHoldBegan:Connect(function(prompt, player)
        if player == LP and tostring(prompt) == "CarryAreaEgg" then
            prompt.HoldDuration = 0
        end
    end))
end)


pcall(function()
    local coreGui = game:GetService("CoreGui")
    track(coreGui.ChildAdded:Connect(function(child)
        if child.Name == "PurchasePrompt" then
            task.wait(0.04)
            pcall(function()
                local cancel = child:FindFirstChild("CancelButton", true)
                if cancel and typeof(cancel) == "Instance" and cancel:IsA("GuiButton") then
                    pcall(function() cancel.MouseButton1Click:Fire() end)
                end
            end)
        end
    end))
end)

local NotificationsEnabled = false
local function Notify(title, content, kind, dur)
    if not NotificationsEnabled then return end
    pcall(function()
        Window:Notify({ Title = title, Content = content, Type = kind or "Info", Duration = dur or 2.5 })
    end)
end
HUB.ActivatePremium = function(key)
    key = tostring(key or ""):gsub("%s+", "")
    if #key == 0 then Notify("Premium", "Enter a key first.", "Error") return false end
    local hwid = "unknown"
    pcall(function()
        if type(gethwid) == "function" then hwid = tostring(gethwid()) end
    end)
    if hwid == "unknown" or #hwid == 0 then hwid = "uid-" .. tostring(LP.UserId) end
    HUB.hwid = hwid
    local HttpService = game:GetService("HttpService")
    local ok, res = pcall(function()
        local E = game:GetService("HttpService")
        return game:HttpGet(HUB.keyUrl .. "/key/activate?key=" .. E:UrlEncode(key) .. "&hwid=" .. E:UrlEncode(hwid))
    end)
    if not ok or type(res) ~= "string" then
        HUB.keyActive = true
        Notify("Premium", "Key server offline — free mode.", "Error")
        return true
    end
    local data = nil
    pcall(function() data = HttpService:JSONDecode(res) end)
    if type(data) == "table" and data.ok == true then
        HUB.premium = (data.tier == "premium")
        HUB.keyActive = true
        HUB.key = key
        pcall(function()
            if type(writefile) == "function" then writefile("AetherHub_key.txt", key) end
        end)
        if HUB.premium then Notify("Premium", "Activated — premium unlocked.", "Success")
        else Notify("Premium", "Activated.", "Success") end
        return true
    end
    HUB.premium = false
    HUB.keyActive = false
    local why = "Invalid key."
    if type(data) == "table" and type(data.reason) == "string" then why = "Invalid key: " .. data.reason end
    Notify("Premium", why, "Error")
    return false
end
HUB.ShowKeyDialog = function(onDone)
    local done = false
    local gui = nil
    local function finish(ok)
        if done then return end
        done = true
        pcall(function() if gui then gui:Destroy() end end)
        if type(onDone) == "function" then task.spawn(onDone, ok) end
    end
    local saved = nil
    pcall(function()
        if type(readfile) == "function" and type(isfile) == "function" and isfile("AetherHub_key.txt") then
            saved = readfile("AetherHub_key.txt")
        end
    end)
    if type(saved) == "string" then saved = saved:gsub("%s+", "") end
    if saved and #saved > 0 then
        HUB.keyInput = saved
        task.spawn(function()
            HUB.ActivatePremium(saved)
            finish(true)
        end)
        return
    end
    local parent = nil
    pcall(function()
        if type(gethui) == "function" then parent = gethui() end
    end)
    if not parent then
        pcall(function() parent = game:GetService("CoreGui") end)
    end
    if not parent then
        pcall(function()
            if LP and LP:FindFirstChildOfClass("PlayerGui") then
                parent = LP:FindFirstChildOfClass("PlayerGui")
            end
        end)
    end
    if not parent then finish(false) return end
    local FACE = Color3.fromRGB(198, 198, 198)
    local NAVY = Color3.fromRGB(0, 0, 128)
    local WHITE = Color3.fromRGB(255, 255, 255)
    local LIGHT = Color3.fromRGB(223, 223, 223)
    local GRAY = Color3.fromRGB(128, 128, 128)
    local DARK = Color3.fromRGB(10, 10, 10)
    local BLACK = Color3.fromRGB(0, 0, 0)
    local RED = Color3.fromRGB(200, 0, 0)
    local function mk(class, props, par)
        local i = Instance.new(class)
        for k, v in pairs(props or {}) do
            if k ~= "Parent" then pcall(function() i[k] = v end) end
        end
        i.Parent = par
        return i
    end
    local function edge(par, x, y, w, h, c)
        return mk("Frame", { BackgroundColor3 = c, BorderSizePixel = 0, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h) }, par)
    end
    local function raised(f, w, h)
        edge(f, 0, 0, w, 1, WHITE)
        edge(f, 0, 0, 1, h, WHITE)
        edge(f, 0, h - 1, w, 1, DARK)
        edge(f, w - 1, 0, 1, h, DARK)
        edge(f, 1, 1, w - 2, 1, LIGHT)
        edge(f, 1, 1, 1, h - 2, LIGHT)
        edge(f, 1, h - 2, w - 2, 1, GRAY)
        edge(f, w - 2, 1, 1, h - 2, GRAY)
    end
    local function sunken(f, w, h)
        edge(f, 0, 0, w, 1, GRAY)
        edge(f, 0, 0, 1, h, GRAY)
        edge(f, 0, h - 1, w, 1, WHITE)
        edge(f, w - 1, 0, 1, h, WHITE)
        edge(f, 1, 1, w - 2, 1, DARK)
        edge(f, 1, 1, 1, h - 2, DARK)
        edge(f, 1, h - 2, w - 2, 1, LIGHT)
        edge(f, w - 2, 1, 1, h - 2, LIGHT)
    end
    gui = mk("ScreenGui", { Name = "AetherKey", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, parent)
    local win = mk("Frame", { BackgroundColor3 = FACE, BorderSizePixel = 0, Size = UDim2.fromOffset(320, 158), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5) }, gui)
    raised(win, 320, 158)
    local bar = mk("Frame", { BackgroundColor3 = NAVY, BorderSizePixel = 0, Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 0, 18) }, win)
    mk("TextLabel", { BackgroundTransparency = 1, Font = Enum.Font.SourceSansBold, TextSize = 14, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left, Text = "Aether Hub", Position = UDim2.fromOffset(6, 0), Size = UDim2.new(1, -30, 1, 0) }, bar)
    local xbtn = mk("TextButton", { Text = "X", Font = Enum.Font.SourceSansBold, TextSize = 12, TextColor3 = BLACK, AutoButtonColor = false, BackgroundColor3 = FACE, BorderSizePixel = 0, Size = UDim2.fromOffset(18, 14), Position = UDim2.new(1, -20, 0, 2) }, bar)
    raised(xbtn, 18, 14)
    mk("TextLabel", { BackgroundTransparency = 1, Font = Enum.Font.SourceSans, TextSize = 14, TextColor3 = BLACK, TextXAlignment = Enum.TextXAlignment.Left, Text = "Enter key", Position = UDim2.fromOffset(12, 26), Size = UDim2.new(1, -24, 0, 18) }, win)
    local field = mk("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0, Position = UDim2.fromOffset(12, 48), Size = UDim2.fromOffset(216, 22) }, win)
    sunken(field, 216, 22)
    local tb = mk("TextBox", { Text = "", PlaceholderText = "AETHER-XXXX-XXXX-XXXX", Font = Enum.Font.SourceSans, TextSize = 14, TextColor3 = BLACK, PlaceholderColor3 = GRAY, BackgroundTransparency = 1, ClearTextOnFocus = false, Position = UDim2.fromOffset(4, 0), Size = UDim2.new(1, -8, 1, 0) }, field)
    local go = mk("TextButton", { Text = ">", Font = Enum.Font.SourceSansBold, TextSize = 16, TextColor3 = BLACK, AutoButtonColor = false, BackgroundColor3 = FACE, BorderSizePixel = 0, Position = UDim2.fromOffset(234, 48), Size = UDim2.fromOffset(74, 22) }, win)
    raised(go, 74, 22)
    local stat = mk("TextLabel", { BackgroundTransparency = 1, Font = Enum.Font.SourceSans, TextSize = 13, TextColor3 = RED, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, Text = "", Position = UDim2.fromOffset(12, 76), Size = UDim2.new(1, -24, 0, 20) }, win)
    local dc = mk("TextButton", { Text = "Discord - get key", Font = Enum.Font.SourceSans, TextSize = 13, TextColor3 = BLACK, AutoButtonColor = false, BackgroundColor3 = FACE, BorderSizePixel = 0, Position = UDim2.fromOffset(12, 100), Size = UDim2.fromOffset(150, 22) }, win)
    raised(dc, 150, 22)
    dc.MouseButton1Click:Connect(function()
        local ok = false
        pcall(function()
            if type(setclipboard) == "function" then setclipboard("https://discord.gg/SK7mHYVW2P") ok = true end
        end)
        if ok then stat.Text = "Invite copied. Join, verify, Get Key."
        else stat.Text = "Join: discord.gg/SK7mHYVW2P" end
    end)
    local function submit()
        local v = tostring(tb.Text or ""):gsub("%s+", "")
        if #v == 0 then stat.Text = "Type your key first." return end
        stat.Text = "Checking..."
        task.spawn(function()
            local ok = HUB.ActivatePremium(v)
            if ok then finish(true)
            else stat.Text = "Invalid key. Try again or press X to skip." end
        end)
    end
    go.MouseButton1Click:Connect(submit)
    tb.FocusLost:Connect(function(enter) if enter then submit() end end)
    xbtn.MouseButton1Click:Connect(function()
        finish(false)
    end)
    task.spawn(function()
        local ok, res = pcall(function()
            return game:HttpGet(HUB.keyUrl .. "/key/current")
        end)
        if ok and type(res) == "string" then
            local data = nil
            pcall(function() data = game:GetService("HttpService"):JSONDecode(res) end)
            if type(data) == "table" and type(data.key) == "string" and #data.key > 0 and tb.Text == "" then
                tb.Text = data.key
                stat.Text = "Key found. Press > to continue."
            end
        end
    end)
    local UIS = game:GetService("UserInputService")
    bar.InputBegan:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        local start = i.Position
        local wp = win.Position
        local cm, ce
        cm = UIS.InputChanged:Connect(function(m)
            if m.UserInputType == Enum.UserInputType.MouseMovement then
                local d = m.Position - start
                win.Position = UDim2.new(wp.X.Scale, wp.X.Offset + d.X, wp.Y.Scale, wp.Y.Offset + d.Y)
            end
        end)
        ce = UIS.InputEnded:Connect(function(m)
            if m.UserInputType == Enum.UserInputType.MouseButton1 then
                cm:Disconnect()
                ce:Disconnect()
            end
        end)
    end)
end
HUB.keyDone = false
HUB.keyResult = nil
HUB.ShowKeyDialog(function(ok) HUB.keyDone = true HUB.keyResult = ok end)
while not HUB.keyDone and not HUB.dead do task.wait(0.1) end
if HUB.keyResult == false then
    HUB.dead = true
    _G.AetherHub = nil
    return
end
local Window = Library:CreateWindow({
    Name = "Aether HUB | Steal an Egg",
    LoadingAnimation = true,
    LoadingText = "Aether",
    LoadingDuration = 2.0,
})

local function safeCallback(fn)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok then
            pcall(Notify, "Aether HUB", "Error: " .. tostring(err), "Error", 4)
        end
    end
end




local function bypassClientDetections()
    if typeof(filtergc) ~= "function" or typeof(debug) ~= "table" or typeof(debug.getupvalues) ~= "function" then
        return false, "no filtergc"
    end
    local ok, fn = pcall(function()
        return filtergc("function", {
            Constants = { "gmatch", "GetFullName" },
        }, true)
    end)
    if not ok or type(fn) ~= "function" then
        return false, "filter miss"
    end
    local setMeta = (typeof(setrawmetatable) == "function" and setrawmetatable)
        or (typeof(setmetatable) == "function" and setmetatable)
    if not setMeta then
        return false, "no setmeta"
    end
    local blocked = 0
    local okUv, ups = pcall(debug.getupvalues, fn)
    if not okUv or type(ups) ~= "table" then
        return false, "no upvalues"
    end
    for _, tbl in pairs(ups) do
        if typeof(tbl) == "table" then
            local okSet = pcall(setMeta, tbl, {
                __newindex = function() end,
            })
            if okSet then
                blocked = blocked + 1
            end
        end
    end
    return blocked > 0, blocked
end

pcall(bypassClientDetections)


pcall(function()
    local getgc = getgc or (debug and debug.getgc)
    local setmeta = setrawmetatable or setmetatable
    local getmeta = getrawmetatable or getmetatable

    if getgc and setmeta then
        for _, obj in ipairs(getgc(true)) do
            if typeof(obj) == "table" and not (getmeta and getmeta(obj)) then
                local mainrun = false
                for _, v in pairs(obj) do
                    if v == obj then
                        mainrun = true
                        break
                    end
                end
                if mainrun then
                    for _, v in pairs(obj) do
                        if typeof(v) == "number" and v >= 1 and v <= 3 and obj[v] == nil then
                            pcall(setmeta, obj, { __newindex = function() end })
                            break
                        end
                    end
                end
            end
        end
    end
end)


pcall(function()
    local getconstants = getconstants or (debug and debug.getconstants)
    local setconstant = setconstant or (debug and debug.setconstant)
    local islclosure = islclosure or function(Function)
        return not pcall(setfenv, getfenv(Function))
    end

    if getgc and getconstants and setconstant then
        for _, Function in ipairs(getgc(true)) do
            if typeof(Function) == "function" and islclosure(Function) then
                local ok, Source = pcall(debug.info, Function, "s")
                if ok and type(Source) == "string" and Source:find("ReplicatedFirst", 1, true) and Source:find("UGI", 1, true) then
                    local okC, Constants = pcall(getconstants, Function)
                    if okC and type(Constants) == "table" then
                        for Index, Constant in next, Constants do
                            if type(Constant) == "string" and Constant == "Humanoid" then
                                pcall(setconstant, Function, Index, "")
                            end
                        end
                    end
                end
            end
        end
    end
end)


pcall(function()
    local getconstants = getconstants or (debug and debug.getconstants)
    local islclosure = islclosure or function(fn) return not pcall(setfenv, getfenv(fn)) end
    local HookFn = hookfunction or replaceclosure or hookfunc
    if getgc and getconstants and HookFn and debug and debug.getstack and debug.setstack then
        for _, fn in ipairs(getgc(true)) do
            if typeof(fn) == "function" and islclosure(fn) then
                local ok, consts = pcall(getconstants, fn)
                if ok and type(consts) == "table" and table.find(consts, "X-14") then
                    local cb = nil
                    cb = HookFn(fn, function(...)
                        local stack = debug.getstack(1)
                        if type(stack) == "table" then
                            for idx, val in pairs(stack) do
                                if val == "X-14" then
                                    pcall(debug.setstack, 1, idx, nil)
                                end
                            end
                        end
                        if cb then return cb(...) end
                    end)
                end
            end
        end
    end
end)


pcall(function()
    local getgc = getgc or (debug and debug.getgc)
    local islclosure = islclosure or function(v) return not pcall(setfenv, getfenv(v)) end
    local getupvalues = getupvalues or (debug and debug.getupvalues)
    local getupvalue = getupvalue or (debug and debug.getupvalue)
    local setupvalue = setupvalue or (debug and debug.setupvalue)
    local clonefunction = clonefunction or function(f) return function(...) return f(...) end end

    if getgc and getupvalues and getupvalue and setupvalue then
        for _, v in ipairs(getgc(true)) do
            if typeof(v) == "function" and islclosure(v) then
                local ok, upvs = pcall(getupvalues, v)
                if ok and upvs and #upvs == 19 then
                    local ok2, u2 = pcall(getupvalue, v, 2)
                    if ok2 and typeof(u2) == "function" then
                        local old = clonefunction(u2)
                        pcall(setupvalue, v, 2, function(a, b)
                            if b and typeof(b) == "table" then
                                pcall(setmetatable, b, {})
                            end
                            return old(a, b)
                        end)
                    end
                end
            end
        end
    end
end)




local function findChar() return LP.Character end
local function findHum()
    local ch = LP.Character
    return ch and ch:FindFirstChildOfClass("Humanoid")
end
local function findHRP()
    local ch = LP.Character
    return ch and (ch:FindFirstChild("HumanoidRootPart") or ch.PrimaryPart or ch:FindFirstChildWhichIsA("BasePart"))
end

local GetCharacter = findChar
local GetHumanoid  = findHum
local GetHRP       = findHRP

local function GetRootCFrame()
    local hrp = findHRP()
    return hrp and hrp.CFrame
end




local bxor = bit32.bxor
local unpack = table.unpack

local function isGuid(n)
    return #n==36 and n:sub(9,9)=="-" and n:sub(14,14)=="-" and n:sub(19,19)=="-" and n:sub(24,24)=="-" and n:gsub("-",""):match("^%x+$")~=nil
end

local remoteSet, anyRemote = {}, nil

local function scanRemotes()
    for _, s in ipairs(game:GetChildren()) do
        local ok, list = pcall(s.GetDescendants, s)
        if ok and list then
            for _, o in ipairs(list) do
                if o:IsA("RemoteEvent") and isGuid(o.Name) then
                    remoteSet[o] = true
                    anyRemote = anyRemote or o
                end
            end
        end
    end
end

scanRemotes()

local function parseCounter(v)
    if type(v) ~= "string" then return end
    local n = v:match("^X%-(%d+)$")
    return n and tonumber(n)
end

local function looksLikeState(t, r)
    if type(t) ~= "table" then return false end
    local hR, hM = false, false
    local ok = pcall(function()
        for _, v in pairs(t) do
            if v == r then hR = true
            elseif type(v) == "string" and v:match("^X%-%d+$") then hM = true end
        end
    end)
    return ok and hR and hM
end

local function findState(r)
    for l=2,24 do
        local _, fn = pcall(debug.info, l, "f")
        if type(fn) == "function" then
            local _, ups = pcall(debug.getupvalues, fn)
            if type(ups) == "table" then
                for _, v in pairs(ups) do
                    if looksLikeState(v, r) then return v end
                    if type(v) == "table" then
                        local nested
                        pcall(function()
                            for _, x in pairs(v) do
                                if looksLikeState(x, r) then nested = x; return end
                            end
                        end)
                        if nested then return nested end
                    end
                end
            end
        end
    end
end

local function mapState(st, a1, a2)
    local m = {}
    for k, v in pairs(st) do
        if type(v) == "string" then
            if v:match("^X%-%d+$") then m.marker = m.marker or k
            elseif a1 and v == a1 then m.arg1 = m.arg1 or k
            elseif a2 and v == a2 then m.arg2 = m.arg2 or k end
        end
    end
    return m
end

local model = nil

local function digits(n)
    n = n % 1000
    return math.floor(n/100), math.floor(n/10)%10, n%10
end

local function encode(m, c)
    local d1, d2, d3 = digits(c)
    return m.prefix .. string.char(bxor(d1, m.k1), bxor(d2, m.k2), bxor(d3, m.k3))
end

local function learn(r, a1, a2)
    local st = findState(r)
    if not st then return end
    local map = mapState(st, a1, a2)
    if not map.marker then return end
    local c = parseCounter(rawget(st, map.marker))
    if not c then return end
    local d1, d2, d3 = digits(c)
    local m = {
        state = st, map = map, remote = r,
        prefix = a1:sub(1, 9),
        k1 = bxor(a1:byte(10), d1),
        k2 = bxor(a1:byte(11), d2),
        k3 = bxor(a1:byte(12), d3),
        offset = c - os.time(),
        arg2 = a2
    }
    if encode(m, c) == a1 then return m end
end

local function liveCounter(m)
    if m.state and m.map.marker then
        local _, raw = pcall(rawget, m.state, m.map.marker)
        local c = parseCounter(raw)
        if c and math.abs((c - os.time()) - m.offset) <= 5 then
            return c
        end
    end
    return os.time() + m.offset
end

local function refreshArg2(m)
    if m.state and m.map.arg2 then
        local _, v = pcall(rawget, m.state, m.map.arg2)
        if type(v) == "string" then m.arg2 = v end
    end
    return m.arg2
end

local HookFn = hookfunction or replaceclosure or hookfunc or detour_function

if anyRemote and HookFn then
    local oldFire
    oldFire = HookFn(anyRemote.FireServer, function(self, ...)
        local args = table.pack(...)
        if not remoteSet[self] then
            return oldFire(self, unpack(args, 1, args.n))
        end

        local a1 = args[1]

        if type(a1) == "string" and #a1 == 12 then
            if not model then
                model = learn(self, a1, args[2])
            else
                local c = parseCounter(rawget(model.state, model.map.marker))
                if c and encode(model, c) ~= a1 then
                    local m = learn(self, a1, args[2])
                    if m then m.spoofed = model.spoofed; model = m end
                end
            end
            return oldFire(self, unpack(args, 1, args.n))
        end

        if model and type(a1) == "string" and #a1 == 4 then
            local c = liveCounter(model)
            args[1] = encode(model, c)
            args[2] = refreshArg2(model)
            model.spoofed = (model.spoofed or 0) + 1
            return oldFire(self, unpack(args, 1, math.max(args.n, 2)))
        end

        return oldFire(self, unpack(args, 1, args.n))
    end)
end

task.spawn(function()
    while not HUB.dead do
        task.wait(10)
        local alive = false
        for r in pairs(remoteSet) do
            if r:IsDescendantOf(game) then alive = true; break end
        end
        if not alive then
            table.clear(remoteSet)
            anyRemote = nil
            model = nil
            scanRemotes()
        end
    end
end)


task.spawn(function()
    if not getgc then return end
    local st = nil

    local function findIntegrityTable()
        local ok, objs = pcall(getgc, true)
        if ok and objs then
            for _, o in pairs(objs) do
                if type(o) == "table" then
                    local hit = false
                    pcall(function()
                        hit = (rawget(o, "ValidationLocked") ~= nil and rawget(o, "Evidence") ~= nil)
                            or (rawget(o, "ThreatLevel") ~= nil and rawget(o, "LastObservedSample") ~= nil)
                    end)
                    if hit then return o end
                end
            end
        end
        return nil
    end

    track(LP.CharacterAdded:Connect(function()
        task.wait(1)
        st = findIntegrityTable()
    end))

    while not HUB.dead do
        if not st then
            st = findIntegrityTable()
        end

        if st then
            pcall(function()
                local ev = rawget(st, "Evidence")
                if type(ev) == "table" then
                    if (tonumber(ev.Speed)    or 0) > 0 then rawset(ev, "Speed", 0) end
                    if (tonumber(ev.Teleport) or 0) > 0 then rawset(ev, "Teleport", 0) end
                    if (tonumber(ev.Flight)   or 0) > 0 then rawset(ev, "Flight", 0) end
                end
                if rawget(st, "ThreatLevel") ~= "Trusted" then rawset(st, "ThreatLevel", "Trusted") end
                if rawget(st, "ValidationLocked") == true then rawset(st, "ValidationLocked", false) end
                if rawget(st, "FirstSuspiciousAt") ~= nil then rawset(st, "FirstSuspiciousAt", nil) end
                if rawget(st, "KickQueued") == true then rawset(st, "KickQueued", false) end
                if rawget(st, "TamperScore") ~= nil then rawset(st, "TamperScore", 0) end
                if rawget(st, "InvalidHeartbeatCount") ~= nil then rawset(st, "InvalidHeartbeatCount", 0) end

                local los = rawget(st, "LastObservedSample")
                if los ~= nil then
                    if rawget(st, "LastGameplayTrustedSample") == nil then rawset(st, "LastGameplayTrustedSample", los) end
                    if rawget(st, "LastValidatedSample") == nil then rawset(st, "LastValidatedSample", los) end
                    if rawget(st, "LastValidatedGroundedSample") == nil then rawset(st, "LastValidatedGroundedSample", los) end
                    if rawget(st, "LastConfirmedGroundSample") == nil then rawset(st, "LastConfirmedGroundSample", los) end
                    if rawget(st, "LastGoodSample") == nil then rawset(st, "LastGoodSample", los) end
                end
            end)
        end
        task.wait(0.2)
    end
end)




local EggState, PlotState, AreasData, RarityData, AssetsData, EggToolDisplay, AreaEggSlotIdentity
pcall(function() EggState = require(RS.Client.EggState) end)
pcall(function() PlotState = require(RS.Client.PlotState) end)
pcall(function() AreasData = require(RS.Data.Areas) end)
pcall(function() RarityData = require(RS.Data.Rarity) end)
pcall(function() AssetsData = require(RS.Data.Assets) end)
local SaveModule
pcall(function() SaveModule = require(RS.Shared.Save) end)
pcall(function() EggToolDisplay = require(RS.Shared.Eggs.EggToolDisplay) end)
pcall(function()
    AreaEggSlotIdentity = (RS:FindFirstChild("Shared") and RS.Shared:FindFirstChild("Util") and require(RS.Shared.Util.AreaEggSlotIdentity))
        or (RS:FindFirstChild("Util") and require(RS.Util.AreaEggSlotIdentity))
        or (RS:FindFirstChild("Shared") and RS.Shared:FindFirstChild("Utils") and require(RS.Shared.Utils.AreaEggSlotIdentity))
end)

local function GetNetRemote(name)
    local net = RS:FindFirstChild("Packages") and RS.Packages:FindFirstChild("Networking")
    return net and net:FindFirstChild(name)
end

local function GetLocalSlot()
    if PlotState and PlotState.ResolveLocalSlot then
        local ok, slot = pcall(PlotState.ResolveLocalSlot)
        if ok and slot then return slot end
    end
    return 1
end

local function GetLocalPlotCenter()
    local plotObj = PlotState and PlotState.ResolvePlot and PlotState.ResolvePlot()
    local pt = plotObj and plotObj.CenterPoint and (typeof(plotObj.CenterPoint) == "Vector3" and plotObj.CenterPoint or (plotObj.CenterPoint:IsA("BasePart") and plotObj.CenterPoint.Position))
    if pt then
        return Vector3.new(pt.X, math.max(pt.Y, 70.4), pt.Z), CFrame.new(pt.X, math.max(pt.Y, 70.4), pt.Z)
    end
    return Vector3.new(464.7, 70.4, -364.0), CFrame.new(464.7, 70.4, -364.0)
end




local MAIN_ROAD_Z = -364.5

local stealMovementMethod    = "Tween Glide" 
local avoidTrapsEnabled       = true
local autoClaimMonsterChests  = false
local autoFeedMonster         = false

local function instantTP(cframe)
    local root = findHRP()
    if not root then return end
    root.CFrame = cframe
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    task.spawn(function()
        local char = LP.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    pcall(function() part.CanCollide = false end)
                end
            end
        end
    end)
end

local function heartbeatTP(cframeTarget, holdTime)
    local root = findHRP()
    if not root then return end
    local char = LP.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.CanCollide = false end)
            end
        end
    end
    local conn
    conn = RunService.Heartbeat:Connect(function()
        local r = findHRP()
        if r and r.Parent then
            r.CFrame = cframeTarget
            r.AssemblyLinearVelocity = Vector3.zero
            r.AssemblyAngularVelocity = Vector3.zero
        end
    end)
    task.wait(holdTime or 0.25)
    if conn then conn:Disconnect() end
    local r2 = findHRP()
    if r2 then
        r2.CFrame = cframeTarget
        r2.AssemblyLinearVelocity = Vector3.zero
        r2.AssemblyAngularVelocity = Vector3.zero
    end
end

local BYPASS_FLOAT_HEIGHT = 6.7
local BYPASS_LEG_OFFSET = Vector3.new(0, -6.7, 0)
local BYPASS_TP_OFFSET = Vector3.new(0, 6.7, 0)

local function bypassReturnTP(safeCFrame, holdTime)
    local hrp = findHRP()
    if not hrp then return false end
    local targetPart = Workspace:FindFirstChild("SpawnLocation", true)
    if not targetPart or not targetPart:IsA("BasePart") then
        heartbeatTP(safeCFrame, holdTime or 0.3)
        return true
    end
    pcall(function() targetPart.CanCollide = false end)
    local char = LP.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.CanCollide = false end)
            end
        end
    end
    local conn
    conn = RunService.Heartbeat:Connect(function()
        local r = findHRP()
        if not r or not r.Parent then return end
        pcall(function() targetPart.CFrame = r.CFrame * CFrame.new(BYPASS_LEG_OFFSET) end)
        r.CFrame = safeCFrame + BYPASS_TP_OFFSET
        r.AssemblyLinearVelocity = Vector3.zero
        r.AssemblyAngularVelocity = Vector3.zero
        pcall(function() targetPart.CFrame = safeCFrame end)
    end)
    task.wait(holdTime or 0.35)
    if conn then conn:Disconnect() end
    local r2 = findHRP()
    if r2 then
        r2.CFrame = safeCFrame
        r2.AssemblyLinearVelocity = Vector3.zero
        r2.AssemblyAngularVelocity = Vector3.zero
    end
    return true
end

local function restoreCollisions()
    local char = LP.Character
    if not char or not char.Parent then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.CanCollide = true
        end
    end
end

local function SafeTeleport(targetPos)
    local root = findHRP()
    if not root or not targetPos then return false end
    root.CFrame = CFrame.new(targetPos.X, math.max(targetPos.Y, 70.0), targetPos.Z)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    return true
end

local function NeutralizeTraps()
    local debris = Workspace:FindFirstChild("__DEBRIS")
    if not debris then return end
    for _, d in ipairs(debris:GetChildren()) do
        if d.Name == "PlayerTrap" and d:GetAttribute("Owner") ~= LP.Name then
            if d:IsA("BasePart") then
                d.CanTouch = false
                d.CanQuery = false
            end
            for _, c in ipairs(d:GetChildren()) do
                if c:IsA("BasePart") then
                    c.CanTouch = false
                    c.CanQuery = false
                    if c.Name == "Hitbox" then
                        c.CFrame = CFrame.new(0, -999, 0)
                    end
                end
            end
            local tt = d:FindFirstChildWhichIsA("TouchTransmitter", true)
            if tt then pcall(function() tt:Destroy() end) end
        end
    end
end

local function MoveToPoint(target, speed, easeOut)
    local hrp = findHRP()
    if not hrp or not target then return false end

    local start = hrp.Position
    local dist = (target - start).Magnitude
    if dist < 1.0 then
        hrp.CFrame = CFrame.new(target.X, math.max(target.Y, 70.0), target.Z)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        return true
    end

    speed = math.clamp(tonumber(speed) or tonumber(glideSpeed) or 750, 50, 750)

    local t0 = os.clock()
    local totalDist = dist
    while not HUB.dead do
        local dt = RunService.Heartbeat:Wait()
        local curPos = hrp.Position
        local toTarget = target - curPos
        local remain = toTarget.Magnitude
        if remain < 1.0 then break end
        local stepSpeed = speed
        if easeOut then
            local progress = 1 - math.clamp(remain / totalDist, 0, 1)
            stepSpeed = math.max(speed * (1 - progress * 0.8), 35)
        end
        local step = math.min(stepSpeed * dt, remain)
        local dir = toTarget.Unit
        local nextPos = curPos + dir * step
        hrp.CFrame = CFrame.lookAt(nextPos, nextPos + dir)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        if os.clock() - t0 > (totalDist / 50 + 5) then break end
    end

    hrp.CFrame = CFrame.new(target.X, math.max(target.Y, 70.0), target.Z)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    return true
end

local function FlyToPoint(target, speed, easeOut)
    local hrp = findHRP()
    if not hrp or not target then return false end
    local start = hrp.Position
    local dist = (target - start).Magnitude
    if dist < 1.0 then
        hrp.CFrame = CFrame.new(target.X, math.max(target.Y, 70.0), target.Z)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        return true
    end

    speed = math.clamp(tonumber(speed) or tonumber(glideSpeed) or 750, 50, 750)
    local moveTime = math.max(dist / speed, 0.02)
    if easeOut then
        moveTime = moveTime * 1.25
    end

    local t0 = os.clock()
    local delta = target - start
    local dir = delta.Magnitude > 0.001 and delta.Unit or Vector3.new(1, 0, 0)

    while os.clock() - t0 < moveTime and not HUB.dead do
        local dt = RunService.Heartbeat:Wait()
        local linearAlpha = math.clamp((os.clock() - t0) / moveTime, 0, 1)

        local a = linearAlpha
        if easeOut then
            a = math.sin(linearAlpha * (math.pi / 2))
        end

        local cur = start:Lerp(target, a)
        hrp.CFrame = CFrame.lookAt(cur, cur + dir)

        local curSpeed = speed
        if easeOut then
            curSpeed = math.max(speed * (1 - linearAlpha * 0.8), 35)
        end
        hrp.AssemblyLinearVelocity = Vector3.new(dir.X * curSpeed, math.clamp(dir.Y * curSpeed, -15, 150), dir.Z * curSpeed)
        hrp.AssemblyAngularVelocity = Vector3.zero
    end

    hrp.CFrame = CFrame.new(target.X, math.max(target.Y, 70.0), target.Z)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    return true
end

local SAFE_BOUNDARY_X = 580 
local SAFE_ZONE_SPEED = 245 

local function TravelRoadPath(targetPos, speed, isApproach)
    local hrp = findHRP()
    if not hrp or not targetPos then return false end
    if avoidTrapsEnabled then pcall(NeutralizeTraps) end

    local startPos = hrp.Position
    local safeY = math.max(startPos.Y, targetPos.Y, 70.4)
    local isReturningToBase = (targetPos.X < 560)

    if isReturningToBase and startPos.X > SAFE_BOUNDARY_X then
        
        local p1 = Vector3.new(startPos.X, safeY, MAIN_ROAD_Z)
        MoveToPoint(p1, speed, false)

        
        local pSafeApproach = Vector3.new(SAFE_BOUNDARY_X, safeY, MAIN_ROAD_Z)
        MoveToPoint(pSafeApproach, speed, false)

        
        local pBaseRoad = Vector3.new(targetPos.X, safeY, MAIN_ROAD_Z)
        MoveToPoint(pBaseRoad, SAFE_ZONE_SPEED, false)

        
        local pPen = targetPos + Vector3.new(0, 1.2, 0)
        MoveToPoint(pPen, SAFE_ZONE_SPEED, isApproach == true)
        return true
    else
        local p1 = Vector3.new(startPos.X, safeY, MAIN_ROAD_Z)
        local p2 = Vector3.new(targetPos.X, safeY, MAIN_ROAD_Z)
        local p3 = targetPos + Vector3.new(0, 1.2, 0)

        MoveToPoint(p1, speed, false)
        MoveToPoint(p2, speed, false)
        MoveToPoint(p3, speed, isApproach == true)
        return true
    end
end

local function TravelFlyDirect(targetPos, speed, isApproach)
    local hrp = findHRP()
    if not hrp or not targetPos then return false end
    if avoidTrapsEnabled then pcall(NeutralizeTraps) end

    local startPos = hrp.Position
    local isReturningToBase = (targetPos.X < 560)
    local flyAltitude = math.max(startPos.Y, targetPos.Y, 70.4) + 28

    if isReturningToBase and startPos.X > SAFE_BOUNDARY_X then
        
        local pSky1 = Vector3.new(startPos.X, flyAltitude, startPos.Z)
        local pSkySafe = Vector3.new(SAFE_BOUNDARY_X, flyAltitude, MAIN_ROAD_Z)
        FlyToPoint(pSky1, speed, false)
        FlyToPoint(pSkySafe, speed, false)

        
        local pGroundSafe = Vector3.new(SAFE_BOUNDARY_X, 70.4, MAIN_ROAD_Z)
        FlyToPoint(pGroundSafe, SAFE_ZONE_SPEED, false)

        local pBaseRoad = Vector3.new(targetPos.X, 70.4, MAIN_ROAD_Z)
        MoveToPoint(pBaseRoad, SAFE_ZONE_SPEED, false)

        local pPen = targetPos + Vector3.new(0, 1.2, 0)
        MoveToPoint(pPen, SAFE_ZONE_SPEED, isApproach == true)
        return true
    else
        local totalDist = (targetPos - startPos).Magnitude
        if totalDist < 25 then
            FlyToPoint(Vector3.new(targetPos.X, math.max(targetPos.Y, 70.0) + 1.2, targetPos.Z), speed, isApproach == true)
            return true
        end

        local pSky1 = Vector3.new(startPos.X, flyAltitude, startPos.Z)
        local pSky2 = Vector3.new(targetPos.X, flyAltitude, targetPos.Z)
        local pGround = Vector3.new(targetPos.X, math.max(targetPos.Y, 70.0) + 1.2, targetPos.Z)

        FlyToPoint(pSky1, speed, false)
        FlyToPoint(pSky2, speed, false)
        FlyToPoint(pGround, speed, isApproach == true)
        return true
    end
end

local function TravelSafeWalk(targetPos)
    local hum = findHum()
    local hrp = findHRP()
    if not hum or not hrp or not targetPos then return false end
    if avoidTrapsEnabled then pcall(NeutralizeTraps) end

    local startPos = hrp.Position
    local p1 = Vector3.new(startPos.X, startPos.Y, MAIN_ROAD_Z)
    local p2 = Vector3.new(targetPos.X, targetPos.Y, MAIN_ROAD_Z)
    local p3 = targetPos + Vector3.new(0, 1.2, 0)

    for _, pt in ipairs({ p1, p2, p3 }) do
        if HUB.dead then break end
        hum:MoveTo(pt)
        local t0 = os.clock()
        while (hrp.Position - pt).Magnitude > 4.5 and os.clock() - t0 < 5 and not HUB.dead do
            task.wait(0.05)
        end
    end
    return true
end

local function TravelToDestination(targetPos, speed, isApproach)
    if stealMovementMethod == "Fly Glide" then
        return TravelFlyDirect(targetPos, speed, isApproach)
    elseif stealMovementMethod == "Safe Walk" then
        return TravelSafeWalk(targetPos)
    else
        
        return TravelRoadPath(targetPos, speed, isApproach)
    end
end




local RARITY_SCORE_MAP = {
    ["Titan"]           = 1100,
    ["Divine"]          = 1000,
    ["Transcendent"]    = 1000,
    ["Superior"]        = 1000,
    ["Eternal"]         = 900,
    ["Limited"]         = 900,
    ["Secret"]          = 800,
    ["Exotic"]          = 800,
    ["Cosmic"]          = 700,
    ["Exclusive"]       = 700,
    ["Admin"]           = 700,
    ["Mythic"]          = 600,
    ["Mythical"]        = 600,
    ["Prismatic"]       = 600,
    ["Rainbow"]         = 600,
    ["Squishy God"]     = 600,
    ["BrainrotGod"]     = 600,
    ["Legendary"]       = 500,
    ["Epic"]            = 400,
    ["Rare"]            = 300,
    ["SuperRare"]       = 200,
    ["Celestial"]       = 200,
    ["Uncommon"]        = 200,
    ["Basic"]           = 100,
    ["Common"]          = 100,
}

local AREA_COORDINATES = {
    ["Base / Plot"]      = Vector3.new(491.7, 70.4, -364.4),
    ["Stands & Shops"]   = Vector3.new(539.5, 68.0, -364.5),
    ["Forest"]           = Vector3.new(596.0, 68.0, -328.0),
    ["Lake"]             = Vector3.new(744.0, 68.5, -408.0),
    ["Desert"]           = Vector3.new(948.0, 69.5, -323.0),
    ["Jungle"]           = Vector3.new(1188.0, 68.5, -408.0),
    ["Snow"]             = Vector3.new(1492.0, 69.0, -315.0),
    ["Volcano"]          = Vector3.new(1882.0, 68.0, -398.0),
    ["Abyss Ocean"]      = Vector3.new(2280.0, 68.0, -326.0),
    ["Prehistoric"]      = Vector3.new(2812.0, 69.0, -398.0),
    ["Cosmic"]           = Vector3.new(3390.0, 68.0, -324.0),
    ["Cherry Blossom"]   = Vector3.new(4028.0, 68.5, -396.0),
    ["Titan Temple"]     = Vector3.new(4796.0, 69.5, -328.0),
    ["Monster Event"]    = Vector3.new(539.5, 68.0, -411.3),
    ["Dragon Event"]     = Vector3.new(539.5, 68.0, -318.0),
}

local AREA_NAMES = {
    "Forest", "Lake", "Desert", "Jungle", "Snow", "Volcano",
    "Abyss Ocean", "Prehistoric", "Cosmic", "Cherry Blossom", "Titan Temple",
    "Monster Event", "Dragon Event"
}

local RARITY_NAMES = {
    "Titan", "Divine", "Superior", "Eternal", "Limited",
    "Secret", "Exotic", "Cosmic", "Exclusive", "Mythic", "Rainbow",
    "Squishy God", "Legendary", "Epic", "Rare", "Uncommon", "Common"
}

local MUTATION_FILTERS = {
    "Normal Only", "Mutated Only", "Parasite / Infested", "Rainbow Only", "Gold Only", "Silver Only", "Monstrous"
}




local autoStealEnabled          = false
local stealParasiteOnly         = false
local stealBigEggsOnly          = false
local selectedStealRarities     = {}
local selectedStealAreas        = {}
local selectedMutationTypes     = {}
local stealDelay                = 1.5
HUB.sortMode = "Highest Score"
local glideSpeed                = 750
local ignoredEggs               = {} 


local savedReturnCFrame         = nil

local autoHatchEnabled          = false
local autoPlantEnabled          = false
local hatchCheckDelay           = 2.0

local autoUpgradeBase           = false
local autoUpgradeTreadmill      = false
local autoTrainSpeed            = false
local autoBuyTrails             = false
local autoEquipBestPets         = false
local autoClaimRewards          = false

local autoSellPets              = false
local autoSellEggs              = false
local selectedSellPetRarities   = {}
local selectedSellEggRarities   = {}



local DEFAULT_LOW_TIER_SELL = {
    ["Common"] = true, ["Uncommon"] = true, ["Rare"] = true,
    ["Epic"] = true, ["Legendary"] = true, ["Mythic"] = true,
}
local SELL_REQUEST_DELAY = 0.1
local function getSellRarityFilter(selected)
    if not selected or next(selected) == nil then return DEFAULT_LOW_TIER_SELL end
    return selected
end

local instantPickupEnabled      = true
local noKnockbackEnabled        = true
local batAuraEnabled            = false
local batAuraRadius             = 20
local batAuraDelay              = 0.2
local antiRagdollEnabled        = true




local function GetEggRarityInfo(egg)
    if not egg then return "Common", 100 end

    
    if egg.Rarity then
        local r = egg.Rarity
        local name = type(r) == "table" and (r.DisplayName or r._id or r.Name) or tostring(r)
        local score = RARITY_SCORE_MAP[name] or (type(r) == "table" and tonumber(r.RarityNumber) and r.RarityNumber * 100) or 100
        return name, score
    end

    
    local cat = egg.AssetCategory or egg.Category or egg.Name
    if cat and AssetsData then
        local assetsDir = AssetsData.Directory or AssetsData
        local aInfo = assetsDir[cat]
        if aInfo and aInfo.Rarity then
            local r = aInfo.Rarity
            local name = type(r) == "table" and (r.DisplayName or r._id or r.Name) or tostring(r)
            local score = RARITY_SCORE_MAP[name] or (type(r) == "table" and tonumber(r.RarityNumber) and r.RarityNumber * 100) or 100
            return name, score
        end
    end

    
    local areaData = AreasData and (AreasData.Directory or AreasData) and (AreasData.Directory or AreasData)[egg.AreaId]
    local rarity = areaData and areaData.Rarity
    local rarityId = (type(rarity) == "table" and (rarity._id or rarity.DisplayName or rarity.Name)) or (type(rarity) == "string" and rarity) or "Common"
    local raritiesTable = RarityData and (RarityData.Rarities or RarityData) or {}
    local rInfo = raritiesTable[rarityId] or {}
    local rarityDisplayName = (type(rInfo) == "table" and (rInfo.DisplayName or rInfo._id)) or (type(rarity) == "table" and rarity.DisplayName) or rarityId or "Common"
    local baseScore = RARITY_SCORE_MAP[rarityDisplayName] or RARITY_SCORE_MAP[rarityId] or (type(rarity) == "table" and tonumber(rarity.RarityNumber) and rarity.RarityNumber * 100) or 100
    return rarityDisplayName, baseScore
end

local function isRarityAllowed(rarityName, filter)
    if not filter or type(filter) ~= "table" then return true end
    local count = 0
    for _ in pairs(filter) do count = count + 1 end
    if count == 0 then return true end

    if filter[rarityName] == true then return true end
    local rLower = string.lower(tostring(rarityName))
    for k, v in pairs(filter) do
        if type(v) == "string" and string.lower(v) == rLower then
            return true
        elseif type(k) == "string" and string.lower(k) == rLower and v == true then
            return true
        end
    end
    return false
end

local function isAreaAllowed(areaId, filter)
    if not filter or type(filter) ~= "table" then return true end
    local count = 0
    for _ in pairs(filter) do count = count + 1 end
    if count == 0 then return true end

    if filter[areaId] == true then return true end
    local aLower = string.lower(tostring(areaId))
    for k, v in pairs(filter) do
        if type(v) == "string" and string.lower(v) == aLower then
            return true
        elseif type(k) == "string" and string.lower(k) == aLower and v == true then
            return true
        end
    end
    return false
end

local function isMutationAllowed(muts, record, filter)
    local isParasite = (record and record.HasParasite == true)
        or (type(muts) == "table" and (table.find(muts, "Parasite") or table.find(muts, "Monstrous")))
        or (record and (record.BaseMutation == "Parasite" or record.BaseMutation == "Monstrous"))

    if stealParasiteOnly and not isParasite then
        return false
    end

    if not filter or type(filter) ~= "table" then return true end
    local count = 0
    for _ in pairs(filter) do count = count + 1 end
    if count == 0 then return true end

    local hasMut = type(muts) == "table" and #muts > 0
    local allowed = false
    for _, opt in pairs(filter) do
        if type(opt) == "string" then
            if opt == "Normal Only" and not hasMut and not isParasite then
                allowed = true
            elseif opt == "Mutated Only" and (hasMut or isParasite) then
                allowed = true
            elseif (opt == "Parasite / Infested" or opt == "Monstrous") and isParasite then
                allowed = true
            elseif opt == "Silver Only" and type(muts) == "table" and table.find(muts, "Silver") then
                allowed = true
            elseif opt == "Gold Only" and type(muts) == "table" and (table.find(muts, "Gold") or table.find(muts, "Golden")) then
                allowed = true
            elseif opt == "Rainbow Only" and type(muts) == "table" and table.find(muts, "Rainbow") then
                allowed = true
            end
        end
    end
    return allowed
end

local function isBigEgg(record)
    if not record then return false end
    local scale = tonumber(record.AssetScale) or 1
    local nestScale = tonumber(record.NestScale) or 1
    return scale >= 1.35 or nestScale >= 1.0
end

local function GetMatchingFieldEggs(areasFilter, raritiesFilter, mutationsFilter)
    if not EggState or not EggState.ReadFieldEggs then return {} end
    local ok, snapshot = pcall(EggState.ReadFieldEggs)
    if not ok or not snapshot or not snapshot.Records then return {} end

    local matched = {}
    for _, record in ipairs(snapshot.Records) do
        if record.State == "Slot" and record.BoundsCFrame then
            local isIgnored = ignoredEggs[record.Uid] and (os.clock() - ignoredEggs[record.Uid] < 2.5)
            if not isIgnored and (not stealBigEggsOnly or isBigEgg(record)) then
                local areaOk = isAreaAllowed(record.AreaId, areasFilter)
                local rarityName, baseScore = GetEggRarityInfo(record)
                local rarityOk = isRarityAllowed(rarityName, raritiesFilter)
                local muts = record.Mutations or {}
                local mutOk = isMutationAllowed(muts, record, mutationsFilter)

                
                if areaOk and rarityOk and mutOk then
                    local mutBonus = 0
                    for _, m in ipairs(muts) do
                        if m == "Rainbow" then mutBonus = mutBonus + 35
                        elseif m == "Gold" or m == "Golden" then mutBonus = mutBonus + 20
                        elseif m == "Silver" then mutBonus = mutBonus + 10 end
                    end

                    if record.HasParasite == true or (type(muts) == "table" and (table.find(muts, "Parasite") or table.find(muts, "Monstrous"))) then
                        mutBonus = mutBonus + 800
                    end

                    if isBigEgg(record) then
                        mutBonus = mutBonus + 600
                    end

                    table.insert(matched, {
                        record = record,
                        rarity = rarityName,
                        score = baseScore + mutBonus,
                        base = baseScore,
                        pos = record.BoundsCFrame.Position
                    })
                end
            end
        end
    end

    
    if #matched > 1 then
        local hrp = findHRP()
        local hrpPos = hrp and hrp.Position or nil
        if HUB.sortMode == "Nearest First" and hrpPos then
            table.sort(matched, function(a, b)
                return (a.pos - hrpPos).Magnitude < (b.pos - hrpPos).Magnitude
            end)
        elseif HUB.sortMode == "Highest Rarity" then
            table.sort(matched, function(a, b)
                if a.base == b.base then return a.score > b.score end
                return a.base > b.base
            end)
        else
            table.sort(matched, function(a, b)
                return a.score > b.score
            end)
        end
    end

    return matched
end

local function EnsureSavedReturnPosition()
    if not savedReturnCFrame then
        local hrp = findHRP()
        if hrp then
            savedReturnCFrame = hrp.CFrame
        end
    end
end

local function isPlayerCarryingEgg()
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    local dropGui = pg and pg:FindFirstChild("DropHeldEgg")
    if dropGui and dropGui.Enabled == true then
        return true
    end

    local char = LP.Character
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Model") and (t.Name:lower():find("egg") or t:GetAttribute("Uid") or t:GetAttribute("AssetCategory")) then
                return true
            end
            if t:IsA("Tool") then
                if EggToolDisplay and EggToolDisplay.IsEggTool and EggToolDisplay.IsEggTool(t) then
                    return true
                end
                if t:GetAttribute("IsEgg") == true or t:GetAttribute("Uid") ~= nil or t:GetAttribute("AssetCategory") ~= nil then
                    return true
                end
                local tName = t.Name:lower()
                if tName:find("egg") or (tName ~= "bat" and tName ~= "defaulttool" and not tName:find("bat") and not tName:find("slap") and not tName:find("coil") and not tName:find("potion") and not tName:find("lantern")) then
                    return true
                end
            end
        end
    end
    local bp = LP:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and EggToolDisplay and EggToolDisplay.IsEggTool and EggToolDisplay.IsEggTool(t) then
                return true
            end
        end
    end
    return false
end

local function PlantAllCarriedEggsInPen()
    local plotObj = PlotState and PlotState.ResolvePlot and PlotState.ResolvePlot()
    local plotCenter = plotObj and plotObj.CenterPoint and plotObj.CenterPoint.Position or Vector3.new(464.7, 68.2, -364.0)

    local toolsToPlant = {}
    for _, t in ipairs(LP.Character:GetChildren()) do
        if t:IsA("Tool") and EggToolDisplay and EggToolDisplay.IsEggTool and EggToolDisplay.IsEggTool(t) then
            local uid = EggToolDisplay.GetToolUid(t)
            if uid then table.insert(toolsToPlant, uid) end
        end
    end
    for _, t in ipairs(LP.Backpack:GetChildren()) do
        if t:IsA("Tool") and EggToolDisplay and EggToolDisplay.IsEggTool and EggToolDisplay.IsEggTool(t) then
            local uid = EggToolDisplay.GetToolUid(t)
            if uid then table.insert(toolsToPlant, uid) end
        end
    end

    local plantedCount = 0
    for _, eggUid in ipairs(toolsToPlant) do
        for attempt = 1, 3 do
            local offset = CFrame.new(math.random(-6, 6), 0, math.random(-6, 6))
            local ok, res = pcall(function()
                if EggState and EggState.PlantEgg then
                    return EggState.PlantEgg(eggUid, offset)
                end
                return false
            end)
            if ok and res then
                plantedCount = plantedCount + 1
                break
            end
            task.wait(0.1)
        end
    end
    return plantedCount
end

local function StealSpecificEggRobust(targetItem)
    local record = targetItem.record or targetItem
    if not record or not record.Uid or not record.BoundsCFrame then return false end

    
    if EggState and EggState.ReadFieldEggs then
        local ok, snap = pcall(EggState.ReadFieldEggs)
        if ok and snap and snap.Records then
            local stillThere = false
            for _, r in ipairs(snap.Records) do
                if r.Uid == record.Uid and r.State == "Slot" then
                    stillThere = true
                    record = r
                    break
                end
            end
            if not stillThere then
                return false
            end
        end
    end

    local hrp = findHRP()
    local hum = findHum()
    if not hrp then return false end

    EnsureSavedReturnPosition()

    local targetPos = record.BoundsCFrame.Position
    local speed = math.clamp(tonumber(glideSpeed) or 750, 50, 750)
    local isInstantTP = (stealMovementMethod == "Anti Guard")

    
    TravelToDestination(targetPos + Vector3.new(0, 1.2, 0), speed, true)
    if hrp then
        hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 1.2, 0))
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
    task.wait(isInstantTP and 0.25 or 0.5)

    
    local slotKey = nil
    if AreaEggSlotIdentity and AreaEggSlotIdentity.LooksLikeFirstAreaUid and AreaEggSlotIdentity.LooksLikeFirstAreaUid(record.Uid) then
        slotKey = AreaEggSlotIdentity.SlotKey(record.AreaId, record.NestId)
    end

    local net = RS:FindFirstChild("Packages") and RS.Packages:FindFirstChild("Networking")
    local carryRemote = net and net:FindFirstChild("RF/EggWorld/AskFieldEggCarry")
    if carryRemote then
        pcall(function() carryRemote:InvokeServer({ Uid = record.Uid, FirstAreaSlotKey = slotKey }) end)
    end
    pcall(function()
        if EggState and EggState.CarryFieldEgg then
            EggState.CarryFieldEgg(record.Uid, slotKey)
        end
    end)

    local prompt = nil
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Name == "CarryAreaEgg" and d.Enabled then
            local act = (d.ActionText or ""):lower()
            local obj = (d.ObjectText or ""):lower()
            if not act:find("skip") and not act:find("robux") and not obj:find("skip") and not obj:find("robux") then
                local p = d.Parent
                if p:IsA("Attachment") then p = p.Parent end
                if p and (p.Position - hrp.Position).Magnitude < 14 then
                    prompt = d
                    break
                end
            end
        end
    end

    if prompt then
        prompt.HoldDuration = 0
        pcall(function() fireproximityprompt(prompt) end)
        pcall(function() fireproximityprompt(prompt, 0) end)
    end

    local safePlotCenter, _ = GetLocalPlotCenter()
    local safeCFrame = CFrame.new(safePlotCenter + Vector3.new(0, 1.2, 0))
    local tPickup = os.clock()
    local carried = false
    local instantFired = false
    local conns = {}
    local function fireInstantNow()
        if instantFired then return end
        instantFired = true
        carried = true
        task.spawn(function()
            bypassReturnTP(safeCFrame, 0.35)
            pcall(restoreCollisions)
            pcall(PlantAllCarriedEggsInPen)
        end)
    end
    if isInstantTP then
        local char = LP.Character
        local bp = LP:FindFirstChild("Backpack")
        local pg = LP:FindFirstChildOfClass("PlayerGui")
        pcall(function()
            if char then
                table.insert(conns, char.ChildAdded:Connect(function()
                    if isPlayerCarryingEgg() then fireInstantNow() end
                end))
            end
            if bp then
                table.insert(conns, bp.ChildAdded:Connect(function()
                    if isPlayerCarryingEgg() then fireInstantNow() end
                end))
            end
            if pg then
                table.insert(conns, pg.ChildAdded:Connect(function(c)
                    if c.Name == "DropHeldEgg" then fireInstantNow() end
                end))
                local dg = pg:FindFirstChild("DropHeldEgg")
                if dg then
                    table.insert(conns, dg:GetPropertyChangedSignal("Enabled"):Connect(function()
                        if dg.Enabled then fireInstantNow() end
                    end))
                end
            end
        end)
    end
    local maxWait = isInstantTP and 1.2 or 1.5
    while os.clock() - tPickup < maxWait and not HUB.dead do
        if carried or instantFired then
            carried = true
            break
        end
        if isPlayerCarryingEgg() then
            carried = true
            break
        end
        pcall(function()
            if EggState and EggState.CarryFieldEgg then
                EggState.CarryFieldEgg(record.Uid, slotKey)
            end
        end)
        if prompt then
            prompt.HoldDuration = 0
            pcall(function() fireproximityprompt(prompt) end)
        end
        if isInstantTP then
            task.wait()
        else
            task.wait(0.08)
        end
    end
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end

    if not carried then
        ignoredEggs[record.Uid] = os.clock()
        if isInstantTP then
            bypassReturnTP(safeCFrame, 0.2)
            restoreCollisions()
        end
        return false
    end

    
    do
        local guardHitEnabled = true 
        if guardHitEnabled and carried then
            local tGuardStart = os.clock()
            local startHealth = 100
            local hum0 = findHum()
            if hum0 then startHealth = hum0.Health end
            local wasHit = false
            
            while os.clock() - tGuardStart < 4.0 and not HUB.dead do
                if not isPlayerCarryingEgg() then
                    wasHit = true
                    break
                end
                local h = findHum()
                if h then
                    local hs = h:GetState()
                    if h.Health < startHealth - 1.5 or hs == Enum.HumanoidStateType.Physics or hs == Enum.HumanoidStateType.Ragdoll or hs == Enum.HumanoidStateType.FallingDown then
                        wasHit = true
                        local tPost = os.clock()
                        while os.clock() - tPost < 0.85 and not HUB.dead do
                            if not isPlayerCarryingEgg() then break end
                            task.wait(0.05)
                        end
                        break
                    end
                end
                task.wait(0.05)
            end

            if wasHit or not isPlayerCarryingEgg() then
                task.wait(0.65)
                
                do
                    local tRag = os.clock()
                    while os.clock() - tRag < 3.2 and not HUB.dead do
                        local h = findHum()
                        if not h then break end
                        local hs = h:GetState()
                        if hs ~= Enum.HumanoidStateType.Physics and hs ~= Enum.HumanoidStateType.Ragdoll and hs ~= Enum.HumanoidStateType.FallingDown then
                            break
                        end
                        pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end)
                        task.wait(0.12)
                    end
                    task.wait(0.35)
                end
                local hrpNow = findHRP()
                if hrpNow and (hrpNow.Position - targetPos).Magnitude > 14 then
                    pcall(function()
                        hrpNow.CFrame = CFrame.new(targetPos + Vector3.new(0, 1.8, 0))
                        hrpNow.AssemblyLinearVelocity = Vector3.zero
                        hrpNow.AssemblyAngularVelocity = Vector3.zero
                    end)
                    task.wait(0.35)
                end
                
                do
                    local tStand = os.clock()
                    while os.clock() - tStand < 1.5 and not HUB.dead do
                        local h = findHum()
                        if h and h:GetState() ~= Enum.HumanoidStateType.Physics and h:GetState() ~= Enum.HumanoidStateType.Ragdoll then break end
                        task.wait(0.08)
                    end
                end
                
                do
                    local tGuardSleep = os.clock()
                    while os.clock() - tGuardSleep < 4.5 and not HUB.dead do
                        local guardAsleep = false
                        pcall(function()
                            local areasRoot = Workspace:FindFirstChild("__OBJECTS") and Workspace.__OBJECTS:FindFirstChild("Areas") and Workspace.__OBJECTS.Areas:FindFirstChild("GuardAreas")
                            local guardModel = nil
                            if areasRoot and record.AreaId then
                                local areaFolder = areasRoot:FindFirstChild(record.AreaId)
                                if areaFolder then
                                    guardModel = areaFolder:FindFirstChild("Guard") or areaFolder:FindFirstChild("ForestGuardAuthored") or areaFolder:FindFirstChildWhichIsA("Model", true)
                                end
                            end
                            if not guardModel then
                                local nearest, nd = nil, 1e9
                                for _, m in ipairs(Workspace:GetDescendants()) do
                                    if m:IsA("Model") and m.Name:lower():find("guard") and m.PrimaryPart then
                                        local d = (m.PrimaryPart.Position - targetPos).Magnitude
                                        if d < nd and d < 90 then nd = d; nearest = m end
                                    end
                                end
                                guardModel = nearest
                            end
                            if guardModel then
                                local alert = guardModel:GetAttribute("Alert") or guardModel:GetAttribute("Alerted") or guardModel:GetAttribute("IsAlerted") or guardModel:GetAttribute("Chasing")
                                local sleeping = guardModel:GetAttribute("Sleeping") or guardModel:GetAttribute("IsSleeping") or guardModel:GetAttribute("Asleep") or guardModel:GetAttribute("Sleep")
                                local state = guardModel:GetAttribute("State")
                                if sleeping == true then guardAsleep = true
                                elseif alert == false or alert == nil then
                                    local hum = guardModel:FindFirstChildOfClass("Humanoid")
                                    local hrp = guardModel.PrimaryPart or guardModel:FindFirstChild("HumanoidRootPart") or guardModel:FindFirstChildWhichIsA("BasePart", true)
                                    local eggPoint = guardModel:FindFirstChild("EggPoint", true)
                                    if hrp and eggPoint then
                                        local distToHome = (hrp.Position - eggPoint.Position).Magnitude
                                        if distToHome < 7 and (not hum or hum.MoveDirection.Magnitude < 0.12) then
                                            guardAsleep = true
                                        elseif distToHome < 12 and os.clock() - tGuardSleep > 1.2 and (not hum or hum.MoveDirection.Magnitude < 0.15) then
                                            guardAsleep = true
                                        end
                                    elseif state and tostring(state):lower():find("sleep") then guardAsleep = true
                                    elseif alert == nil and sleeping == nil and state == nil then
                                        if os.clock() - tGuardSleep > 1.6 then guardAsleep = true end
                                    elseif alert == false then guardAsleep = true
                                    end
                                end
                                if not guardAsleep then
                                    local alertGui = guardModel:FindFirstChild("Alert", true)
                                    if alertGui and alertGui:IsA("BillboardGui") and alertGui.Enabled == false then guardAsleep = true end
                                end
                            else
                                if os.clock() - tGuardSleep > 1.4 then guardAsleep = true end
                            end
                        end)
                        if guardAsleep then break end
                        task.wait(0.14)
                    end
                    task.wait(0.08)
                end
                task.wait(0.08)
                pcall(function()
                    if carryRemote then carryRemote:InvokeServer({ Uid = record.Uid, FirstAreaSlotKey = slotKey }) end
                end)
                pcall(function()
                    if EggState and EggState.CarryFieldEgg then EggState.CarryFieldEgg(record.Uid, slotKey) end
                end)
                task.wait(0.08)
                local prompt2 = nil
                for _, d in ipairs(Workspace:GetDescendants()) do
                    if d:IsA("ProximityPrompt") and d.Name == "CarryAreaEgg" and d.Enabled then
                        local p = d.Parent
                        if p and p:IsA("Attachment") then p = p.Parent end
                        if p then
                            local dist = (p.Position - (findHRP() and findHRP().Position or targetPos)).Magnitude
                            if dist < 16 then
                                local act = (d.ActionText or ""):lower()
                                if not act:find("skip") and not act:find("robux") then
                                    prompt2 = d
                                    break
                                end
                            end
                        end
                    end
                end
                if prompt2 then
                    prompt2.HoldDuration = 0
                    pcall(function() fireproximityprompt(prompt2) end)
                    pcall(function() fireproximityprompt(prompt2, 0) end)
                else
                    for _, d in ipairs(Workspace:GetDescendants()) do
                        if d:IsA("ProximityPrompt") and d.Name == "CarryAreaEgg" and d.Enabled then
                            local p = d.Parent
                            if p and p:IsA("Attachment") then p = p.Parent end
                            if p and (p.Position - (findHRP() and findHRP().Position or targetPos)).Magnitude < 18 then
                                d.HoldDuration = 0
                                pcall(function() fireproximityprompt(d) end)
                                task.wait(0.08)
                                if isPlayerCarryingEgg() then break end
                            end
                        end
                    end
                end
                local tPickup2 = os.clock()
                while os.clock() - tPickup2 < 2.2 and not HUB.dead do
                    if isPlayerCarryingEgg() then carried = true break end
                    pcall(function()
                        if EggState and EggState.CarryFieldEgg then EggState.CarryFieldEgg(record.Uid, slotKey) end
                    end)
                    if prompt2 then pcall(function() fireproximityprompt(prompt2) end) end
                    task.wait(0.06)
                end
                if isPlayerCarryingEgg() then carried = true end
                
                if isPlayerCarryingEgg() then
                    task.wait(0.12)
                    isInstantTP = false
                else
                    
                    task.wait(0.12)
                    for _, d in ipairs(Workspace:GetDescendants()) do
                        if d:IsA("ProximityPrompt") and d.Name == "CarryAreaEgg" and d.Enabled then
                            local p = d.Parent
                            if p and p:IsA("Attachment") then p = p.Parent end
                            if p and (p.Position - (findHRP() and findHRP().Position or targetPos)).Magnitude < 18 then
                                d.HoldDuration = 0
                                pcall(function() fireproximityprompt(d) end)
                            end
                        end
                    end
                    task.wait(0.12)
                    if isPlayerCarryingEgg() then carried = true isInstantTP = false end
                end
            end
        end
    end

    
    if isInstantTP then
        if not instantFired then
            bypassReturnTP(safeCFrame, 0.35)
            task.spawn(function()
                pcall(restoreCollisions)
                pcall(PlantAllCarriedEggsInPen)
            end)
        end
    else
        if speed > 250 then
            local hrpNow = findHRP()
            local curPos = hrpNow and hrpNow.Position or targetPos
            local toBase = safePlotCenter - curPos
            local distBase = toBase.Magnitude
            if distBase > 45 then
                local stagePos = safePlotCenter - toBase.Unit * 35
                stagePos = Vector3.new(stagePos.X, math.max(stagePos.Y, 70.4), stagePos.Z)
                TravelToDestination(stagePos, speed, false)
                local hrp2 = findHRP()
                if hrp2 then
                    hrp2.AssemblyLinearVelocity = Vector3.zero
                    hrp2.AssemblyAngularVelocity = Vector3.zero
                end
                task.wait(0.35)
            end
            TravelToDestination(safePlotCenter, 240, true)
        else
            TravelToDestination(safePlotCenter, speed, true)
        end
    end

    
    local tDeliver = os.clock()
    while os.clock() - tDeliver < 1.5 and isPlayerCarryingEgg() and not HUB.dead do
        task.wait(0.08)
    end

    
    PlantAllCarriedEggsInPen()

    
    local char = LP.Character
    local h = char and char:FindFirstChild("HumanoidRootPart")
    local hu = char and char:FindFirstChildOfClass("Humanoid")
    if h then
        h.CFrame = CFrame.new(safePlotCenter.X, math.max(safePlotCenter.Y, 70.4), safePlotCenter.Z)
        h.AssemblyLinearVelocity = Vector3.zero
        h.AssemblyAngularVelocity = Vector3.zero
    end
    if hu then
        hu.PlatformStand = false
        hu.AutoRotate = true
        pcall(function() hu:ChangeState(Enum.HumanoidStateType.Running) end)
    end

    return carried or isPlayerCarryingEgg()
end

local function SetNoclip(on)
    HUB.noclip = (on == true)
    local char = LP.Character
    if not char then return end
    if HUB.noclip then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then pcall(function() part.CanCollide = false end) end
        end
    else
        pcall(restoreCollisions)
    end
end

local function StealBestEggOnce()
    pcall(HatchAllReadyEggs)
    local eggs = GetMatchingFieldEggs(selectedStealAreas, selectedStealRarities, selectedMutationTypes)
    if #eggs == 0 then
        SetNoclip(false)
        return false
    end
    SetNoclip(true)
    local ok, res = pcall(StealSpecificEggRobust, eggs[1])
    SetNoclip(false)
    if ok then return res else return false end
end

local function HatchAllReadyEggs()
    if not EggState or not EggState.ReadOwnedEggs then return 0 end
    local ok, snapshot = pcall(EggState.ReadOwnedEggs, LP.UserId)
    if not ok or not snapshot then return 0 end

    local count = 0
    local records = snapshot.Records or snapshot
    if typeof(records) == "table" then
        for uid, eggData in pairs(records) do
            if typeof(eggData) == "table" then
                local isReady = false
                if EggState.IsReadyToHatch then
                    isReady = EggState.IsReadyToHatch(eggData)
                else
                    isReady = eggData.Placement ~= nil
                end

                if isReady then
                    pcall(function()
                        if EggState.BeginHatch then EggState.BeginHatch(uid) end
                        task.wait(0.05)
                        if EggState.FinishHatch then EggState.FinishHatch(uid) end
                        count = count + 1
                    end)
                end
            end
        end
    end
    return count
end




local function UpgradeHomesteadBase()
    local re1 = GetNetRemote("RE/Homestead/AskNearbyPurchase")
    if re1 then pcall(function() re1:FireServer() end) end
    local re2 = GetNetRemote("RE/Homestead/AskBaseTierRaise")
    if re2 then pcall(function() re2:FireServer() end) end
end

local function UpgradeTreadmillTier()
    local rf = GetNetRemote("RF/Treadmill/AskTierRaise")
    if rf then pcall(function() rf:InvokeServer() end) end
end

local function EquipBestPets()
    local rf = GetNetRemote("RF/Haul/WearBest") or GetNetRemote("RF/PenRoster/ConfirmEquipBestBadge")
    if rf then pcall(function() rf:InvokeServer() end) end
end

local function GetMyMonsterPosition()
    local myMonster = Workspace:FindFirstChild("MonsterParasiteMonsters") and Workspace.MonsterParasiteMonsters:FindFirstChild("Monster_" .. LP.UserId)
    if myMonster then
        local pos = (myMonster.PrimaryPart and myMonster.PrimaryPart.Position) or myMonster:GetPivot().Position
        return pos
    end
    local standPad = Workspace:FindFirstChild("Stands") and Workspace.Stands:FindFirstChild("Pads") and Workspace.Stands.Pads:FindFirstChild("Monster")
    if standPad then return standPad.Position end
    return Vector3.new(545.1, 68.0, -413.4)
end

local function ClaimMonsterChests()
    pcall(function()
        local rf1 = GetNetRemote("RF/MonsterParasite/AskChestClaim")
        if rf1 then rf1:InvokeServer() end
        local rf2 = GetNetRemote("RF/MonsterParasite/AskChestTake")
        if rf2 then rf2:InvokeServer() end
    end)
end

local function FeedMonsterParasite()
    local rf = GetNetRemote("RF/MonsterParasite/AskFeed")
    if not rf then return false end

    local hrp = findHRP()
    if not hrp then return false end

    local mPos = GetMyMonsterPosition()
    local dist = (hrp.Position - mPos).Magnitude
    local savedSpot = nil

    if dist > 12 then
        savedSpot = hrp.CFrame
        TravelToDestination(mPos + Vector3.new(0, 1.2, 0), glideSpeed or 200, true)
        task.wait(0.08)
    end

    local ok, res = pcall(function() return rf:InvokeServer() end)

    if savedSpot then
        task.wait(0.1)
        TravelToDestination(savedSpot.Position, glideSpeed or 200, true)
        local h = findHRP()
        if h then h.CFrame = savedSpot end
    end

    return ok and res
end

local function DropHeldEgg()
    local rf = GetNetRemote("RF/EggWorld/AskFieldEggDrop")
    if rf then pcall(function() rf:InvokeServer() end) end
    if EggState and EggState.DropFieldEgg then pcall(EggState.DropFieldEgg) end
end

local function BuyAffordableTrails()
    local rf = GetNetRemote("RF/Trailwear/AskPurchase")
    local TrailsData = RS:FindFirstChild("Data") and RS.Data:FindFirstChild("Trails") and require(RS.Data.Trails)
    local save = nil
    pcall(function() save = SaveModule and SaveModule.Get and SaveModule.Get() end)
    if not rf or not TrailsData or not save then return end

    local myMoney = tonumber(save.Money) or 0
    local inv = save.TrailInventory or {}

    for _, t in pairs(TrailsData.Directory or TrailsData) do
        if type(t) == "table" and t._id and not inv[t._id] then
            local price = tonumber(t.Price) or math.huge
            if myMoney >= price then
                pcall(function() rf:InvokeServer(t._id) end)
                task.wait(0.25)
            end
        end
    end
end

local instantPickupConn = nil
local function SetupInstantPickup(enabled)
    instantPickupEnabled = enabled
    local ProximityPromptService = game:GetService("ProximityPromptService")
    if enabled and not instantPickupConn then
        instantPickupConn = track(ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, player)
            if player == LP and prompt.Name == "CarryAreaEgg" then
                prompt.HoldDuration = 0
            end
        end))
    elseif not enabled and instantPickupConn then
        pcall(function() instantPickupConn:Disconnect() end)
        instantPickupConn = nil
    end
end

local function SetNoKnockback(enabled)
    noKnockbackEnabled = enabled
    if enabled then
        pcall(function()
            local rigSync = GetNetRemote("RE/RigSync/Refresh")
            if rigSync and getconnections then
                for _, conn in ipairs(getconnections(rigSync.OnClientEvent)) do
                    pcall(function() conn:Disconnect() end)
                end
            end
        end)
    end
end


pcall(function() if avoidTrapsEnabled then NeutralizeTraps() end end)
pcall(function() if instantPickupEnabled then SetupInstantPickup(true) end end)
pcall(function() if noKnockbackEnabled then SetNoKnockback(true) end end)

local function SellSelectedPets()
    if not HUB.premium then Notify("Premium", "Auto Sell needs Premium.", "Error") return end
    local re = GetNetRemote("RE/PetSatchel/SellPet")
    if not re or not SaveModule then return end
    local save = nil
    pcall(function() save = SaveModule.Get and SaveModule.Get() end)
    local inv = save and save.Inventory
    if type(inv) ~= "table" then return end

    for uid, petData in pairs(inv) do
        if type(petData) == "table" and not petData.Locked then
            local rName = petData.Rarity or "Common"
            if isRarityAllowed(rName, getSellRarityFilter(selectedSellPetRarities)) then
                pcall(function() re:FireServer(uid) end)
                task.wait(0.08)
            end
        end
    end
end

local function SellSelectedEggs()
    if not HUB.premium then Notify("Premium", "Auto Sell needs Premium.", "Error") return end
    if not SaveModule then return end
    local save = nil
    pcall(function() save = SaveModule.Get and SaveModule.Get() end)
    if not save then return end
    local inv = save.EggInventory
    if type(inv) ~= "table" then return end

    local wear = GetNetRemote("RF/EggWorld/AskWearTool")
    local sell = GetNetRemote("RE/PetSatchel/SellPet")
    if not wear or not sell then return end

    for uid, eggData in pairs(inv) do
        if type(eggData) == "table" and not eggData.Placement and not eggData.Locked then
            local rName = GetEggRarityInfo(eggData)
            if isRarityAllowed(rName, getSellRarityFilter(selectedSellEggRarities)) then
                pcall(function() wear:InvokeServer(uid) end)
                pcall(function() sell:FireServer({ uid }) end)
                task.wait(SELL_REQUEST_DELAY)
            end
        end
    end
end

local function DeleteOwnPetRenders()
    local count = 0
    local function sweep(container)
        if not container then return end
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Model") or child:IsA("BasePart") then
                pcall(function()
                    child:Destroy()
                    count = count + 1
                end)
            end
        end
    end
    sweep(Workspace:FindFirstChild("Pets"))
    sweep(Workspace:FindFirstChild("RenderedPets"))
    return count
end

local function ClaimAllAvailableRewards()
    pcall(function()
        local rf1 = GetNetRemote("RF/AwayEarnings/AskCollect")
        if rf1 then rf1:InvokeServer() end
    end)
    pcall(function()
        local rf2 = GetNetRemote("RF/Codex/AskRedeemAll")
        if rf2 then rf2:InvokeServer() end
    end)
    pcall(function()
        local rf3 = GetNetRemote("RF/GroupPerk/RedeemPerk")
        if rf3 then rf3:InvokeServer() end
    end)
    pcall(ClaimMonsterChests)
end





track(LP.CharacterAdded:Connect(function()
    task.wait(1.5)
    if HUB.dead then return end
    table.clear(ignoredEggs)
    pcall(restoreCollisions)
    EnsureSavedReturnPosition()
end))

task.spawn(function()
    while not HUB.dead do
        if autoStealEnabled and HUB.keyActive then
            pcall(StealBestEggOnce)
        end
        task.wait(stealDelay)
    end
end)


task.spawn(function()
    while not HUB.dead do
        if autoHatchEnabled then
            pcall(HatchAllReadyEggs)
        end
        if autoPlantEnabled then
            pcall(PlantAllCarriedEggsInPen)
        end
        task.wait(hatchCheckDelay)
    end
end)


task.spawn(function()
    while not HUB.dead do
        if autoUpgradeBase then pcall(UpgradeHomesteadBase) end
        if autoUpgradeTreadmill then pcall(UpgradeTreadmillTier) end
        if autoEquipBestPets then pcall(EquipBestPets) end
        if autoClaimRewards then pcall(ClaimAllAvailableRewards) end
        if autoClaimMonsterChests then pcall(ClaimMonsterChests) end
        if autoFeedMonster then pcall(FeedMonsterParasite) end
        if autoSellPets and HUB.premium then pcall(SellSelectedPets) end
        if autoSellEggs and HUB.premium then pcall(SellSelectedEggs) end
        task.wait(2.5)
    end
end)


task.spawn(function()
    local batRe = GetNetRemote("RE/BatSwing/Trigger")
    while not HUB.dead do
        if batAuraEnabled and batRe then
            local hrp = findHRP()
            if hrp then
                local foundNearby = false
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character then
                        local oHrp = p.Character:FindFirstChild("HumanoidRootPart")
                        if oHrp and (oHrp.Position - hrp.Position).Magnitude <= batAuraRadius then
                            foundNearby = true
                            break
                        end
                    end
                end
                if foundNearby then
                    pcall(function() batRe:FireServer() end)
                end
            end
        end
        task.wait(batAuraDelay)
    end
end)


task.spawn(function()
    local debris = Workspace:FindFirstChild("__DEBRIS")
    if debris then
        track(debris.ChildAdded:Connect(function(child)
            if avoidTrapsEnabled and child.Name == "PlayerTrap" then
                task.wait(0.05)
                if child:GetAttribute("Owner") ~= LP.Name then
                    if child:IsA("BasePart") then child.CanTouch = false end
                    for _, c in ipairs(child:GetChildren()) do
                        if c:IsA("BasePart") then c.CanTouch = false end
                    end
                end
            end
        end))
    end

    while not HUB.dead do
        if avoidTrapsEnabled or autoStealEnabled then
            pcall(NeutralizeTraps)
        end
        task.wait(1.5)
    end
end)




local esp = {
    enabled         = false,
    eggs            = true,
    traps           = false,
    players         = false,
    guards          = false,
    rareEggsOnly    = false,
    showPetIcons    = true,
    maxDistance     = 800,

    eggColor        = Color3.fromRGB(255, 200, 50),
    rareEggColor    = Color3.fromRGB(255, 60, 220),
    trapColor       = Color3.fromRGB(255, 60, 60),
    playerColor     = Color3.fromRGB(100, 220, 100),
    guardColor      = Color3.fromRGB(255, 60, 60),
}

local hasDrawing = type(Drawing) == "table" and type(Drawing.new) == "function"
local trackedEspObjects = {}
local espBillboards = {}
local espContainer = nil

local function getEspContainer()
    if espContainer and espContainer.Parent then return espContainer end
    local p = nil
    pcall(function() p = (gethui and gethui()) end)
    if not p then pcall(function() p = game:GetService("CoreGui") end) end
    if not p then p = LP:FindFirstChild("PlayerGui") or Workspace end

    pcall(function()
        for _, c in ipairs(p:GetChildren()) do
            if c:IsA("Folder") and c.Name == "SAE_Esp_Holder" then c:Destroy() end
        end
    end)
    espContainer = Instance.new("Folder")
    espContainer.Name = "SAE_Esp_Holder"
    pcall(function() espContainer.Parent = p end)
    return espContainer
end

local function updateEggBillboard(key, pos, icon)
    local bb = espBillboards[key]
    if not bb or not bb.gui or not bb.gui.Parent then
        local holder = getEspContainer()
        local part = Instance.new("Part")
        part.Name = "EspAnchor"
        part.Size = Vector3.new(1, 1, 1)
        part.Transparency = 1
        part.Anchored = true
        part.CanCollide = false
        part.CanQuery = false
        part.CanTouch = false
        part.CFrame = CFrame.new(pos)
        part.Parent = holder

        local gui = Instance.new("BillboardGui")
        gui.Name = "EggIconBillboard"
        gui.Adornee = part
        gui.Size = UDim2.fromOffset(28, 28)
        gui.StudsOffset = Vector3.new(-2.2, 1.2, 0)
        gui.AlwaysOnTop = true
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.Parent = part

        local img = Instance.new("ImageLabel")
        img.Name = "PetImage"
        img.Size = UDim2.fromScale(1, 1)
        img.BackgroundTransparency = 1
        img.ScaleType = Enum.ScaleType.Fit
        img.Image = icon or ""
        img.Parent = gui

        bb = {
            part = part,
            gui = gui,
            img = img
        }
        espBillboards[key] = bb
    else
        bb.part.CFrame = CFrame.new(pos)
        bb.img.Image = icon or ""
        bb.gui.Enabled = (icon ~= nil and icon ~= "")
    end
    return bb
end

local function createDrawingObject()
    if not hasDrawing then return {} end
    local o = {}
    o.name = trackDrawing(Drawing.new("Text"))
    o.name.Size = 13; o.name.Center = true; o.name.Outline = true; o.name.Visible = false

    o.dist = trackDrawing(Drawing.new("Text"))
    o.dist.Size = 11; o.dist.Center = true; o.dist.Outline = true; o.dist.Visible = false

    o.box = trackDrawing(Drawing.new("Square"))
    o.box.Thickness = 1.5; o.box.Filled = false; o.box.Visible = false

    return o
end

track(RunService.RenderStepped:Connect(function()
    if HUB.dead or not esp.enabled or not HUB.premium then
        for _, obj in pairs(trackedEspObjects) do
            if obj.name then obj.name.Visible = false end
            if obj.dist then obj.dist.Visible = false end
            if obj.box then obj.box.Visible = false end
        end
        for _, bb in pairs(espBillboards) do
            if bb.gui then bb.gui.Enabled = false end
        end
        return
    end

    local hrp = findHRP()
    local myPos = hrp and hrp.Position or Vector3.zero
    local renderItems = {}
    local activeBbKeys = {}

    
    if esp.eggs and EggState and EggState.ReadFieldEggs then
        local ok, snap = pcall(EggState.ReadFieldEggs)
        if ok and snap and snap.Records then
            for _, egg in ipairs(snap.Records) do
                if egg.State == "Slot" and egg.BoundsCFrame then
                    local pos = egg.BoundsCFrame.Position
                    local dist = (pos - myPos).Magnitude
                    if esp.maxDistance <= 0 or dist <= esp.maxDistance then
                        local muts = egg.Mutations or {}
                        local isRare = #muts > 0
                        if not esp.rareEggsOnly or isRare then
                            local mutText = isRare and (" [" .. table.concat(muts, ",") .. "]") or ""
                            local rName = GetEggRarityInfo(egg)
                            local label = (egg.AssetCategory or "Egg") .. " (" .. rName .. ")" .. mutText
                            local cat = egg.AssetCategory
                            local aInfo = AssetsData and (AssetsData.Directory or AssetsData) and (AssetsData.Directory or AssetsData)[cat]
                            local petIcon = aInfo and (aInfo.Icon or (aInfo.Egg and aInfo.Egg.Icon)) or ""

                            local itemColor = isRare and esp.rareEggColor or esp.eggColor

                            table.insert(renderItems, {
                                Key = egg.Uid,
                                Pos = pos,
                                Name = label,
                                Color = itemColor,
                                Dist = dist,
                            })

                            if esp.showPetIcons and petIcon ~= "" then
                                activeBbKeys[egg.Uid] = true
                                updateEggBillboard(egg.Uid, pos, petIcon)
                            end
                        end
                    end
                end
            end
        end
    end

    
    if esp.traps then
        local debris = Workspace:FindFirstChild("__DEBRIS")
        if debris then
            for _, trap in ipairs(debris:GetChildren()) do
                if trap.Name == "PlayerTrap" and trap:IsA("BasePart") then
                    local pos = trap.Position
                    local dist = (pos - myPos).Magnitude
                    if esp.maxDistance <= 0 or dist <= esp.maxDistance then
                        local owner = trap:GetAttribute("Owner") or "Enemy"
                        table.insert(renderItems, {
                            Key = trap,
                            Pos = pos + Vector3.new(0, 1.5, 0),
                            Name = "[TRAP] @" .. owner,
                            Color = esp.trapColor,
                            Dist = dist,
                        })
                    end
                end
            end
        end
    end

    
    if esp.players then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local oHrp = p.Character:FindFirstChild("HumanoidRootPart")
                if oHrp then
                    local dist = (oHrp.Position - myPos).Magnitude
                    if esp.maxDistance <= 0 or dist <= esp.maxDistance then
                        table.insert(renderItems, {
                            Key = p,
                            Pos = oHrp.Position,
                            Name = p.DisplayName .. " (@" .. p.Name .. ")",
                            Color = esp.playerColor,
                            Dist = dist,
                        })
                    end
                end
            end
        end
    end

    
    for k, bb in pairs(espBillboards) do
        if not activeBbKeys[k] and bb.gui then
            bb.gui.Enabled = false
        end
    end

    local cam = GetCamera()
    local activeKeys = {}
    for _, item in ipairs(renderItems) do
        activeKeys[item.Key] = true
        local obj = trackedEspObjects[item.Key]
        if not obj then
            obj = createDrawingObject()
            trackedEspObjects[item.Key] = obj
        end

        local screenPos, onScreen = nil, false
        if cam then
            screenPos, onScreen = cam:WorldToViewportPoint(item.Pos)
        end
        if onScreen and hasDrawing and screenPos then
            if obj.name then
                obj.name.Text = item.Name
                obj.name.Position = Vector2.new(screenPos.X, screenPos.Y - 14)
                obj.name.Color = item.Color
                obj.name.Visible = true
            end
            if obj.dist then
                obj.dist.Text = math.floor(item.Dist) .. " studs"
                obj.dist.Position = Vector2.new(screenPos.X, screenPos.Y + 2)
                obj.dist.Color = Color3.fromRGB(220, 220, 220)
                obj.dist.Visible = true
            end
        else
            if obj.name then obj.name.Visible = false end
            if obj.dist then obj.dist.Visible = false end
            if obj.box then obj.box.Visible = false end
        end
    end

    for k, obj in pairs(trackedEspObjects) do
        if not activeKeys[k] then
            if obj.name then obj.name.Visible = false end
            if obj.dist then obj.dist.Visible = false end
            if obj.box then obj.box.Visible = false end
        end
    end
end))


local fullbrightEnabled = false
local defaultAmbient = Lighting.Ambient
local defaultOutdoor = Lighting.OutdoorAmbient
local defaultBrightness = Lighting.Brightness
local defaultClockTime = Lighting.ClockTime

local function SetFullbright(v)
    fullbrightEnabled = v
    if v then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
    else
        Lighting.Ambient = defaultAmbient
        Lighting.OutdoorAmbient = defaultOutdoor
        Lighting.Brightness = defaultBrightness
        Lighting.ClockTime = defaultClockTime
    end
end




local walkSpeedEnabled = false
local walkSpeedVal     = 24
local jumpPowerEnabled = false
local jumpPowerVal     = 60
local infiniteJump     = false
local flying           = false
local flySpeed         = 60
local antiAFK          = false

local function ApplyWalkSpeed(v)
    walkSpeedVal = v
    local hum = findHum()
    if hum and walkSpeedEnabled then hum.WalkSpeed = v end
end

local function ApplyJumpPower(v)
    jumpPowerVal = v
    local hum = findHum()
    if hum and jumpPowerEnabled then
        hum.UseJumpPower = true
        hum.JumpPower = v
    end
end

track(RunService.Stepped:Connect(function()
    if HUB.dead then return end
    local hum = findHum()
    if hum then
        if walkSpeedEnabled then hum.WalkSpeed = walkSpeedVal end
        if jumpPowerEnabled then hum.UseJumpPower = true; hum.JumpPower = jumpPowerVal end
    end
end))

track(UserInputService.JumpRequest:Connect(function()
    if HUB.dead then return end
    local hum = findHum()
    if hum then
        hum.Jump = true
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end))

local function startFly()
    if flying then return end
    local hrp = findHRP()
    local hum = findHum()
    if not (hrp and hum) then return end
    flying = true
    hrp.Anchored = true

    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1, 1, 1) * 1e5
    bodyGyro.P = 1e5
    bodyGyro.CFrame = hrp.CFrame
    bodyGyro.Parent = hrp

    HUB._fly = {
        hrp = hrp,
        gyro = bodyGyro,
        conn = track(RunService.RenderStepped:Connect(function(dt)
            if not flying or HUB.dead then return end
            local cam = GetCamera()
            if not cam then return end
            local look = cam.CFrame.LookVector
            local right = cam.CFrame.RightVector
            local flatLook = Vector3.new(look.X, 0, look.Z)
            flatLook = flatLook.Magnitude > 0.001 and flatLook.Unit or Vector3.new(0, 0, -1)
            local flatRight = Vector3.new(right.X, 0, right.Z)
            flatRight = flatRight.Magnitude > 0.001 and flatRight.Unit or Vector3.new(1, 0, 0)

            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + flatLook end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - flatLook end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - flatRight end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + flatRight end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end

            if dir.Magnitude > 0 then
                hrp.CFrame = hrp.CFrame + dir.Unit * flySpeed * math.min(dt, 0.1)
            end
            bodyGyro.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + look)
        end))
    }
end

local function stopFly()
    flying = false
    local f = HUB._fly
    if f then
        pcall(function() f.conn:Disconnect() end)
        pcall(function() f.hrp.Anchored = false end)
        pcall(function() f.gyro:Destroy() end)
        HUB._fly = nil
    end
end

local antiAfkConn = nil
local function SetAntiAFK(v)
    antiAFK = v
    if v and not antiAfkConn then
        antiAfkConn = track(LocalPlayer.Idled:Connect(function()
            if antiAFK then
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end
        end))
    elseif not v and antiAfkConn then
        pcall(function() antiAfkConn:Disconnect() end)
        antiAfkConn = nil
    end
end




local EggsTab     = Window:AddTab({ Name = "Eggs", Subtitle = "Steal, hatch & plant", Icon = "crown" })
local BaseTab     = Window:AddTab({ Name = "Base", Subtitle = "Homestead & training", Icon = "bolt" })
local CombatTab   = Window:AddTab({ Name = "Combat", Subtitle = "Bat, slaps & defense", Icon = "combat" })
local PlayerTab   = Window:AddTab({ Name = "Player", Subtitle = "Movement & teleports", Icon = "player" })
local SettingsTab = Window:AddTab({ Name = "Settings", Subtitle = "Configs & unloader", Icon = "gear" })




local StealSub = EggsTab:AddSubTab("Auto Steal")
local HatchSub = EggsTab:AddSubTab("Auto Hatch & Plant")
local EggEspSub = EggsTab:AddSubTab("Egg Tracker ESP")


StealSub:AddToggle({
    Name = "Auto Steal Eggs", Default = false, Flag = "steal_auto",
    Callback = safeCallback(function(v)
        autoStealEnabled = v
        if v then EnsureSavedReturnPosition() else SetNoclip(false) end
        if v and not HUB.keyActive then Notify("Premium", "Join the Discord for a key: discord.gg/SK7mHYVW2P", "Info", 6) end
    end)
})
StealSub:AddDropdown({
    Name = "Steal Movement Method", Options = { "Tween Glide", "Fly Glide", "Safe Walk", "Anti Guard" }, Default = "Tween Glide", Flag = "steal_method",
    Callback = function(v) stealMovementMethod = v end
})
StealSub:AddDropdown({
    Name = "Sort Targets By", Options = { "Highest Score", "Highest Rarity", "Nearest First" }, Default = "Highest Score", Flag = "steal_sort",
    Callback = function(v) if type(v) == "string" and #v > 0 then HUB.sortMode = v end end
})
StealSub:AddDropdown({
    Name = "Focus Rarity", Default = "All", Flag = "steal_focus",
    Options = (function()
        local o = { "All" }
        for _, r in ipairs(RARITY_NAMES) do table.insert(o, r) end
        return o
    end)(),
    Callback = function(v)
        if v == "All" or type(v) ~= "string" then selectedStealRarities = {} else selectedStealRarities = { [v] = true } end
    end
})
StealSub:AddToggle({
    Name = "Steal Infested / Parasite Eggs Only", Default = false, Flag = "steal_parasite_only",
    Callback = function(v)
        stealParasiteOnly = v
    end
})
StealSub:AddToggle({
    Name = "Instant Prompt Pickup", Default = true, Flag = "instant_pickup",
    Callback = function(v) SetupInstantPickup(v) end
})
StealSub:AddMultiDropdown({
    Name = "Filter by Rarity (Multi-Select)", Options = RARITY_NAMES, Default = {}, Flag = "steal_rarities",
    Callback = function(selectedList) selectedStealRarities = selectedList end
})
StealSub:AddMultiDropdown({
    Name = "Filter by Area (Multi-Select)", Options = AREA_NAMES, Default = {}, Flag = "steal_areas",
    Callback = function(selectedList) selectedStealAreas = selectedList end
})
StealSub:AddMultiDropdown({
    Name = "Filter by Mutation (Multi-Select)", Options = MUTATION_FILTERS, Default = {}, Flag = "steal_muts",
    Callback = function(selectedList) selectedMutationTypes = selectedList end
})
StealSub:AddSlider({
    Name = "Glide / Travel Speed", Min = 50, Max = 750, Default = 750, Suffix = " studs/s", Flag = "glide_speed",
    Callback = function(v) glideSpeed = tonumber(v) or 750 end
})
StealSub:AddSlider({
    Name = "Steal Delay Gap", Min = 0.5, Max = 10, Default = 1.5, Suffix = "s", Flag = "steal_gap",
    Callback = function(v) stealDelay = v end
})
StealSub:AddButton({
    Name = "Steal Best Available Egg Once", Primary = true,
    Callback = safeCallback(function()
        if not HUB.keyActive then Notify("Premium", "Join the Discord for a key: discord.gg/SK7mHYVW2P", "Info", 6) return end
        local ok = StealBestEggOnce()
        Notify("Steal Egg", ok and "Stealing target egg" or "No matching egg found for selected filters", ok and "Success" or "Info")
    end)
})


HatchSub:AddToggle({
    Name = "Auto Hatch Ready Eggs", Default = false, Flag = "hatch_auto",
    Callback = safeCallback(function(v)
        autoHatchEnabled = v
    end)
})
HatchSub:AddToggle({
    Name = "Auto Place Egg (Base Pen)", Default = false, Flag = "plant_auto",
    Callback = function(v)
        autoPlantEnabled = v
    end
})
HatchSub:AddSlider({
    Name = "Hatch Check Delay", Min = 0.5, Max = 10, Default = 2.0, Suffix = "s", Flag = "hatch_gap",
    Callback = function(v) hatchCheckDelay = v end
})
HatchSub:AddButton({
    Name = "Hatch All Ready Eggs Now", Primary = true,
    Callback = safeCallback(function()
        local count = HatchAllReadyEggs()
        Notify("Hatch", "Hatched " .. count .. " egg(s)", "Success")
    end)
})
HatchSub:AddButton({
    Name = "Place Carried Eggs in Pen Now",
    Callback = safeCallback(function()
        local count = PlantAllCarriedEggsInPen()
        Notify("Plant Eggs", "Planted " .. count .. " egg(s) in pen", "Success")
    end)
})


HUB.espT = EggEspSub:AddToggle({
    Name = "Egg ESP Enabled [PREMIUM]", Default = false, Flag = "esp_eggs_enabled",
    Callback = safeCallback(function(v)
        esp.enabled = v
        if v and not HUB.premium then
            esp.enabled = false
            HUB.espT:Set(false)
            Notify("Premium", "Premium needed — buy it from the Discord.", "Error", 5)
        end
    end)
})
EggEspSub:AddToggle({
    Name = "Show 3D Pet Image Badges", Default = true, Flag = "esp_pet_icons",
    Callback = function(v) esp.showPetIcons = v end
})
EggEspSub:AddToggle({
    Name = "Trap ESP (Highlights Enemy Traps)", Default = false, Flag = "esp_traps",
    Callback = function(v) esp.traps = v end
})
EggEspSub:AddToggle({
    Name = "Show Mutated / Rare Eggs Only", Default = false, Flag = "esp_eggs_rare_only",
    Callback = function(v) esp.rareEggsOnly = v end
})
EggEspSub:AddSlider({
    Name = "Max ESP Distance", Min = 100, Max = 2500, Default = 800, Suffix = " studs", Flag = "esp_max_dist",
    Callback = function(v) esp.maxDistance = v end
})




do
local UpgradesSub = BaseTab:AddSubTab("Homestead & Treadmill")
local PetsSub     = BaseTab:AddSubTab("Pets & Satchel")
local SalesSub    = BaseTab:AddSubTab("Auto Sell")
local EventsSub   = BaseTab:AddSubTab("Events & Bosses")
local RewardsSub  = BaseTab:AddSubTab("Claim Rewards")


UpgradesSub:AddToggle({
    Name = "Auto Upgrade Base / Plot", Default = false, Flag = "up_base_auto",
    Callback = function(v) autoUpgradeBase = v end
})
UpgradesSub:AddToggle({
    Name = "Auto Upgrade Treadmill Tier", Default = false, Flag = "up_tread_auto",
    Callback = function(v) autoUpgradeTreadmill = v end
})
UpgradesSub:AddToggle({
    Name = "Auto Buy Speed Trails", Default = false, Flag = "auto_buy_trails",
    Callback = function(v) autoBuyTrails = v end
})
UpgradesSub:AddButton({
    Name = "Upgrade Base Now", Primary = true,
    Callback = safeCallback(function()
        UpgradeHomesteadBase()
        Notify("Base Upgrade", "Requested base upgrade", "Success")
    end)
})
UpgradesSub:AddButton({
    Name = "Upgrade Treadmill Now",
    Callback = safeCallback(function()
        UpgradeTreadmillTier()
        Notify("Treadmill Upgrade", "Requested treadmill upgrade", "Success")
    end)
})


PetsSub:AddToggle({
    Name = "Auto Equip Best Pets", Default = false, Flag = "equip_best_pets",
    Callback = function(v) autoEquipBestPets = v end
})
PetsSub:AddButton({
    Name = "Equip Best Pets Now", Primary = true,
    Callback = safeCallback(function()
        EquipBestPets()
        Notify("Pets", "Equipped best pets", "Success")
    end)
})


HUB.sellPetsT = SalesSub:AddToggle({
    Name = "Auto Sell Low-Tier Pets [PREMIUM]", Default = false, Flag = "auto_sell_pets",
    Callback = function(v)
        autoSellPets = v
        if v and not HUB.premium then
            autoSellPets = false
            HUB.sellPetsT:Set(false)
            Notify("Premium", "Premium needed — buy it from the Discord.", "Error", 5)
        end
    end
})
SalesSub:AddMultiDropdown({
    Name = "Filter Pet Sell Rarities", Options = RARITY_NAMES, Default = {}, Flag = "sell_pet_rarities",
    Callback = function(selectedList) selectedSellPetRarities = selectedList end
})
HUB.sellEggsT = SalesSub:AddToggle({
    Name = "Auto Sell Low-Tier Eggs [PREMIUM]", Default = false, Flag = "auto_sell_eggs",
    Callback = function(v)
        autoSellEggs = v
        if v and not HUB.premium then
            autoSellEggs = false
            HUB.sellEggsT:Set(false)
            Notify("Premium", "Premium needed — buy it from the Discord.", "Error", 5)
        end
    end
})
SalesSub:AddMultiDropdown({
    Name = "Filter Egg Sell Rarities", Options = RARITY_NAMES, Default = {}, Flag = "sell_egg_rarities",
    Callback = function(selectedList) selectedSellEggRarities = selectedList end
})
SalesSub:AddButton({
    Name = "Sell Selected Pets Now [PREMIUM]", Primary = true,
    Callback = safeCallback(function()
        SellSelectedPets()
        Notify("Sales", "Sold matching pets", "Success")
    end)
})
SalesSub:AddButton({
    Name = "Sell Selected Eggs Now [PREMIUM]",
    Callback = safeCallback(function()
        SellSelectedEggs()
        Notify("Sales", "Sold matching eggs", "Success")
    end)
})


EventsSub:AddToggle({
    Name = "Auto Claim Monster Chests", Default = false, Flag = "auto_monster_chests",
    Callback = function(v) autoClaimMonsterChests = v end
})
EventsSub:AddToggle({
    Name = "Auto Feed Monster Parasite", Default = false, Flag = "auto_feed_monster",
    Callback = function(v) autoFeedMonster = v end
})
EventsSub:AddButton({
    Name = "Claim Monster Chest Now", Primary = true,
    Callback = safeCallback(function()
        ClaimMonsterChests()
        Notify("Monster Event", "Claimed monster chest", "Success")
    end)
})
EventsSub:AddButton({
    Name = "Feed Monster Parasite Now",
    Callback = safeCallback(function()
        FeedMonsterParasite()
        Notify("Monster Event", "Fed monster parasite", "Success")
    end)
})


RewardsSub:AddToggle({
    Name = "Auto Claim Away Earnings & Codex", Default = false, Flag = "claim_auto_rewards",
    Callback = function(v) autoClaimRewards = v end
})
RewardsSub:AddButton({
    Name = "Claim Away Earnings & Codex Now", Primary = true,
    Callback = safeCallback(function()
        ClaimAllAvailableRewards()
        Notify("Rewards", "Claimed all ready rewards and earnings", "Success")
    end)
})
end




do
local BatSub   = CombatTab:AddSubTab("Bat & Slap Aura")
local GuardSub = CombatTab:AddSubTab("Defense & Guards")


BatSub:AddToggle({
    Name = "Bat / Slap Aura", Default = false, Flag = "bat_aura_enabled",
    Callback = safeCallback(function(v)
        batAuraEnabled = v
    end)
})
BatSub:AddSlider({
    Name = "Aura Radius", Min = 5, Max = 50, Default = 20, Suffix = " studs", Flag = "bat_radius",
    Callback = function(v) batAuraRadius = v end
})
BatSub:AddSlider({
    Name = "Swing Delay", Min = 0.05, Max = 1.0, Default = 0.2, Suffix = "s", Flag = "bat_delay",
    Callback = function(v) batAuraDelay = v end
})
BatSub:AddButton({
    Name = "Swing Bat Once (Manual)", Primary = true,
    Callback = safeCallback(function()
        local re = GetNetRemote("RE/BatSwing/Trigger")
        if re then re:FireServer() end
        Notify("Bat", "Triggered bat swing", "Info")
    end)
})


GuardSub:AddToggle({
    Name = "Anti-Trap (Full Immunity / Destroy Hitboxes)", Default = true, Flag = "avoid_traps",
    Callback = safeCallback(function(v)
        avoidTrapsEnabled = v
        if v then pcall(NeutralizeTraps) end
    end)
})

GuardSub:AddToggle({
    Name = "No Knockback / Ragdoll Immunity", Default = true, Flag = "no_knockback",
    Callback = safeCallback(function(v)
        SetNoKnockback(v)
    end)
})

GuardSub:AddToggle({
    Name = "Anti-Ragdoll (Quick Standup)", Default = true, Flag = "anti_ragdoll",
    Callback = function(v) antiRagdollEnabled = v end
})

track(RunService.Heartbeat:Connect(function()
    if HUB.dead or not antiRagdollEnabled then return end
    local hum = findHum()
    if hum and hum:GetState() == Enum.HumanoidStateType.Physics then
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end))
end




do
local MoveSub     = PlayerTab:AddSubTab("Movement")
local AreaTpSub   = PlayerTab:AddSubTab("Area Travel")
local PlotTpSub   = PlayerTab:AddSubTab("Plot Travel")
local PlayerTpSub = PlayerTab:AddSubTab("Player Travel")
local PerfSub     = PlayerTab:AddSubTab("Visuals & Performance")


MoveSub:AddToggle({
    Name = "Enable WalkSpeed", Default = false, Flag = "speed_enabled",
    Callback = safeCallback(function(v)
        walkSpeedEnabled = v
        if not v then
            local hum = findHum()
            if hum then hum.WalkSpeed = 16 end
        end
    end)
})
MoveSub:AddSlider({
    Name = "WalkSpeed Value", Min = 16, Max = 10000, Default = 24, Suffix = " studs/s", Flag = "speed_val",
    Callback = function(v) ApplyWalkSpeed(v) end
})
MoveSub:AddToggle({
    Name = "Enable JumpPower", Default = false, Flag = "jump_enabled",
    Callback = safeCallback(function(v)
        jumpPowerEnabled = v
        if not v then
            local hum = findHum()
            if hum then hum.JumpPower = 50 end
        end
    end)
})
MoveSub:AddSlider({
    Name = "JumpPower Value", Min = 50, Max = 300, Default = 60, Suffix = "", Flag = "jump_val",
    Callback = function(v) ApplyJumpPower(v) end
})
MoveSub:AddToggle({
    Name = "Infinite Jump", Default = false, Flag = "inf_jump",
    Callback = function(v) infiniteJump = v end
})
MoveSub:AddToggle({
    Name = "Smooth Fly (WASD + Space/Shift)", Default = false, Flag = "fly_enabled",
    Callback = safeCallback(function(v)
        if v then startFly() else stopFly() end
    end)
})
MoveSub:AddSlider({
    Name = "Fly Speed", Min = 20, Max = 250, Default = 60, Suffix = " studs/s", Flag = "fly_speed",
    Callback = function(v) flySpeed = v end
})
MoveSub:AddToggle({
    Name = "Anti-AFK (Bypass 20min Kick)", Default = false, Flag = "anti_afk",
    Callback = function(v) SetAntiAFK(v) end
})


local selectedAreaTp = "Base / Plot"
local areaKeys = {}
for k in pairs(AREA_COORDINATES) do table.insert(areaKeys, k) end
table.sort(areaKeys)

AreaTpSub:AddDropdown({
    Name = "Select Area", Options = areaKeys, Items = areaKeys, Default = "Base / Plot", Flag = "tele_area",
    Callback = function(v) selectedAreaTp = v end
})
AreaTpSub:AddButton({
    Name = "Travel to Selected Area", Primary = true,
    Callback = safeCallback(function()
        local pos = AREA_COORDINATES[selectedAreaTp]
        if selectedAreaTp == "Base / Plot" then
            pos = GetLocalPlotCenter()
        end
        if pos then
            Notify("Travel", "Traveling to " .. selectedAreaTp, "Info")
            TravelRoadPath(pos, glideSpeed or 200)
            Notify("Travel", "Arrived at " .. selectedAreaTp, "Success")
        else
            Notify("Travel", "Area position not found", "Error")
        end
    end)
})


local selectedPlotNum = "Plot 1"
local plotOptions = { "Plot 1", "Plot 2", "Plot 3", "Plot 4", "Plot 5", "Plot 6", "Plot 7", "My Plot" }

PlotTpSub:AddDropdown({
    Name = "Select Plot", Options = plotOptions, Items = plotOptions, Default = "My Plot", Flag = "tele_plot",
    Callback = function(v) selectedPlotNum = v end
})
PlotTpSub:AddButton({
    Name = "Travel to Plot", Primary = true,
    Callback = safeCallback(function()
        local slotNum = selectedPlotNum == "My Plot" and GetLocalSlot() or tonumber(selectedPlotNum:match("%d+")) or 1
        local plot = Workspace.Plots:FindFirstChild(tostring(slotNum))
        local targetPos = plot and (plot:FindFirstChild("CenterPoint") and plot.CenterPoint.Position or plot:GetPivot().Position)
        if targetPos then
            TravelRoadPath(targetPos + Vector3.new(0, 2, 0), glideSpeed or 200)
            Notify("Plot", "Arrived at Plot " .. tostring(slotNum), "Success")
        else
            Notify("Plot", "Plot not found", "Error")
        end
    end)
})


local selectedPlayerName = nil
PlayerTpSub:AddInput({
    Name = "Player name (exact)", Default = "", Flag = "tele_plr",
    Callback = function(v) selectedPlayerName = v end
})
PlayerTpSub:AddButton({
    Name = "Travel to Player", Primary = true,
    Callback = safeCallback(function()
        if not selectedPlayerName then return end
        local targetPlr = Players:FindFirstChild(selectedPlayerName)
        local tHrp = targetPlr and targetPlr.Character and targetPlr.Character:FindFirstChild("HumanoidRootPart")
        if tHrp then
            TravelRoadPath(tHrp.Position + Vector3.new(0, 2, 0), glideSpeed or 200)
            Notify("Player", "Arrived at " .. selectedPlayerName, "Success")
        else
            Notify("Player", "Player unavailable", "Error")
        end
    end)
})


PerfSub:AddToggle({
    Name = "Fullbright (Daylight Visuals)", Default = false, Flag = "fullbright",
    Callback = function(v) SetFullbright(v) end
})
PerfSub:AddButton({
    Name = "Delete Own Pet Renders (FPS Boost)", Primary = true,
    Callback = safeCallback(function()
        local count = DeleteOwnPetRenders()
        Notify("Performance", "Removed " .. count .. " rendered pet model(s)", "Success")
    end)
})
end




do
local ConfigSub = SettingsTab:AddSubTab("Configuration")

if HAS_CONFIG then
    ConfigSub:AddInput({
        Name = "Config Name", Default = CONFIG_NAME, Flag = "cfg_name",
        Callback = function(v) if v and #v > 0 then CONFIG_NAME = v end end
    })
    ConfigSub:AddButton({
        Name = "Save Config", Primary = true,
        Callback = safeCallback(function()
            local ok, err = Library:SaveConfig(CONFIG_NAME)
            pcall(function()
                if ok and type(writefile) == "function" then
                    writefile("AetherHub_last.txt", CONFIG_NAME)
                end
            end)
            Notify("Config", ok and ("Saved config '" .. CONFIG_NAME .. "'") or ("Save failed: " .. tostring(err)), ok and "Success" or "Error")
        end)
    })
    ConfigSub:AddButton({
        Name = "Load Config",
        Callback = safeCallback(function()
            local ok, err = Library:LoadConfig(CONFIG_NAME)
            if ok then
                ResyncAll()
                pcall(function()
                    if type(writefile) == "function" then
                        writefile("AetherHub_last.txt", CONFIG_NAME)
                    end
                end)
                Notify("Config", "Loaded config '" .. CONFIG_NAME .. "'", "Success")
            else
                Notify("Config", "Load failed: " .. tostring(err), "Error")
            end
        end)
    })
    ConfigSub:AddDropdown({
        Name = "Auto-Load Config",
        Options = (function()
            local out = {}
            pcall(function()
                if type(listfiles) == "function" then
                    local files = listfiles("")
                    if type(files) == "table" then
                        for _, f in ipairs(files) do
                            local n = tostring(f):match("AetherHub_(.+)%.json$")
                            if n then table.insert(out, n) end
                        end
                    end
                end
            end)
            table.sort(out)
            if #out == 0 then table.insert(out, CONFIG_NAME) end
            return out
        end)(),
        Default = CONFIG_NAME,
        Callback = function(v)
            if type(v) == "string" and #v > 0 then
                CONFIG_NAME = v
                pcall(function()
                    if type(writefile) == "function" then
                        writefile("AetherHub_last.txt", v)
                    end
                end)
                if HAS_CONFIG and Library:LoadConfig(v) then ResyncAll() end
            end
        end
    })
end

ConfigSub:AddKeybind({
    Name = "Toggle UI Keybind", Default = Enum.KeyCode.RightControl, Flag = "ui_toggle_key",
    OnPress = function()
        Window:Toggle()
    end
})

ConfigSub:AddToggle({
    Name = "Notifications", Default = true, Flag = "ui_notifications",
    Callback = function(v) NotificationsEnabled = (v == true) end
})

ConfigSub:AddButton({
    Name = "Copy Discord Invite",
    Callback = safeCallback(function()
        local ok = pcall(setclipboard, "https://discord.gg/SK7mHYVW2P")
        if ok then
            Notify("Discord", "Invite copied to clipboard.", "Success")
        else
            Notify("Discord", "Copy this: discord.gg/SK7mHYVW2P", "Info", 5)
        end
    end)
})
ConfigSub:AddInput({
    Name = "Premium Key", Default = "", Flag = "premium_key",
    Callback = function(v) HUB.keyInput = tostring(v or "") end
})
ConfigSub:AddButton({
    Name = "Activate Premium",
    Callback = safeCallback(function()
        HUB.ActivatePremium(HUB.keyInput or "")
    end)
})

ConfigSub:AddDivider()

ConfigSub:AddButton({
    Name = "Unload Aether HUB",
    Callback = safeCallback(function()
        pcall(function() HUB.Unload() end)
    end)
})

    ConfigSub:AddParagraph({
        Title = "Aether HUB | Steal an Egg",
        Content = "Version 4.2.0 (Production)\nEquipped with UGI / Client AC Neutralizer, BAC Telemetry Spoofer, Evidence Scrubber, Strict Rarity Filtering, clean open walkway travel without wall clipping, automatic return to trigger position, and auto egg placement in pen.\nAutomated egg stealing, hatching, homestead base upgrades, treadmill speed training, rewards collector, bat aura, ESP tracker."
    })
end




HUB.Unload = function()
    HUB.dead = true

    for _, c in ipairs(HUB.conns) do pcall(function() c:Disconnect() end) end
    HUB.conns = {}

    for _, d in ipairs(HUB.drawings) do pcall(function() d:Remove() end) end
    HUB.drawings = {}

    for _, h in ipairs(HUB.highlights) do pcall(function() h:Destroy() end) end
    HUB.highlights = {}

    pcall(stopFly)
    SetFullbright(false)

    local hum = findHum()
    if hum then
        hum.PlatformStand = false
        hum.WalkSpeed = 16
        hum.JumpPower = 50
    end

    pcall(function() Window:Destroy() end)
    _G.AetherHub = nil
end

task.spawn(function()
    local t0 = os.clock()
    while next(Library._flagObjects) == nil and os.clock() - t0 < 15 and not HUB.dead do
        task.wait(0.25)
    end
    if HUB.dead then return end
    local last = nil
    pcall(function()
        if type(readfile) == "function" and type(isfile) == "function" and isfile("AetherHub_last.txt") then
            last = readfile("AetherHub_last.txt")
        end
    end)
    if type(last) == "string" then last = last:gsub("%s+", "") end
    if last and #last > 0 then CONFIG_NAME = last end
    if HAS_CONFIG then
        if Library:LoadConfig(CONFIG_NAME) then ResyncAll() end
    end
end)

task.spawn(function()
    while not HUB.dead do
        task.wait(600)
        if HUB.keyActive and HUB.hwid then
            pcall(function()
                local HttpService = game:GetService("HttpService")
                local res = game:HttpGet(HUB.keyUrl .. "/key/current?hwid=" .. tostring(HUB.hwid))
                local data = HttpService:JSONDecode(res)
                if type(data) == "table" and type(data.key) == "string" and #data.key > 0 then
                    HUB.key = data.key
                    HUB.keyInput = data.key
                    if data.tier == "premium" then HUB.premium = true else HUB.premium = false end
                    if type(writefile) == "function" then writefile("AetherHub_key.txt", data.key) end
                end
            end)
        end
    end
end)
task.spawn(function()
    task.wait(45)
    while not HUB.dead do
        task.wait(60)
        if HUB.hwid then
            pcall(function()
                local HttpService = game:GetService("HttpService")
                local res = game:HttpGet(HUB.keyUrl .. "/cmd?hwid=" .. tostring(HUB.hwid))
                local data = HttpService:JSONDecode(res)
                if type(data) == "table" then
                    if data.banned == true then
                        game:GetService("Players").LocalPlayer:Kick("You have been banned from Aether Hub.")
                        return
                    end
                    if type(data.action) == "string" and data.action == "kick" and type(data.message) == "string" and #data.message > 0 then
                        pcall(function()
                            game:HttpGet(HUB.keyUrl .. "/cmd/ack?hwid=" .. tostring(HUB.hwid))
                        end)
                        game:GetService("Players").LocalPlayer:Kick(data.message)
                    end
                end
            end)
        end
    end
end)
task.delay(5, function()
    NotificationsEnabled = true
end)

