local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")

local status = player.PlayerGui
    :WaitForChild("Main_Gui")
    :WaitForChild("DataMenu_Frame")
    :WaitForChild("Muscle")
    :WaitForChild("Status")

--// Rayfield-esque UI Base
local gui = Instance.new("ScreenGui")
gui.Name = "Rayfield_MuscleUI"
gui.ResetOnSpawn = false
if CoreGui:FindFirstChild("Rayfield_MuscleUI") then
    CoreGui.Rayfield_MuscleUI:Destroy()
end
gui.Parent = CoreGui

--// Professional Debug System
local debugGui = Instance.new("Frame")
debugGui.Size = UDim2.new(0, 320, 0, 220)
debugGui.Position = UDim2.new(1, -340, 1, -240)
debugGui.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
debugGui.BackgroundTransparency = 0.35 -- Transparent to see under it
debugGui.BorderSizePixel = 0
debugGui.Visible = false
debugGui.Active = true
debugGui.Parent = gui

local debugCorner = Instance.new("UICorner")
debugCorner.CornerRadius = UDim.new(0, 6)
debugCorner.Parent = debugGui

local debugTitle = Instance.new("TextLabel")
debugTitle.Size = UDim2.new(1, 0, 0, 25)
debugTitle.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
debugTitle.BackgroundTransparency = 0.35
debugTitle.Text = "  Developer Console"
debugTitle.Font = Enum.Font.GothamMedium
debugTitle.TextSize = 12
debugTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
debugTitle.TextXAlignment = Enum.TextXAlignment.Left
debugTitle.Parent = debugGui
Instance.new("UICorner", debugTitle).CornerRadius = UDim.new(0, 6)

local fixCorner = Instance.new("Frame")
fixCorner.Size = UDim2.new(1, 0, 0, 5)
fixCorner.Position = UDim2.new(0, 0, 1, -5)
fixCorner.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
fixCorner.BackgroundTransparency = 0.35
fixCorner.BorderSizePixel = 0
fixCorner.Parent = debugTitle

local debugScroll = Instance.new("ScrollingFrame")
debugScroll.Size = UDim2.new(1, -10, 1, -35)
debugScroll.Position = UDim2.new(0, 5, 0, 30)
debugScroll.BackgroundTransparency = 1
debugScroll.BorderSizePixel = 0
debugScroll.ScrollBarThickness = 2
debugScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
debugScroll.Parent = debugGui

local debugLayout = Instance.new("UIListLayout")
debugLayout.SortOrder = Enum.SortOrder.LayoutOrder
debugLayout.Parent = debugScroll

local logCounter = 0
local function DebugLog(text)
    logCounter += 1
    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, 0, 0, 14)
    msg.BackgroundTransparency = 1
    msg.Font = Enum.Font.Gotham
    msg.TextSize = 11
    msg.TextColor3 = Color3.fromRGB(220, 220, 220)
    msg.TextXAlignment = Enum.TextXAlignment.Left
    msg.Text = "[INFO] " .. tostring(text)
    msg.LayoutOrder = logCounter
    msg.Parent = debugScroll
    
    if #debugScroll:GetChildren() > 80 then
        local oldest
        for _, c in ipairs(debugScroll:GetChildren()) do
            if c:IsA("TextLabel") then
                if not oldest or c.LayoutOrder < oldest.LayoutOrder then
                    oldest = c
                end
            end
        end
        if oldest then oldest:Destroy() end
    end
    
    task.spawn(function()
        task.wait()
        debugScroll.CanvasPosition = Vector2.new(0, debugLayout.AbsoluteContentSize.Y)
    end)
end

-- Proper drag for debug
local dDrag, dStart, dPos, dInput
debugGui.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then 
        dDrag = true; dStart = input.Position; dPos = debugGui.Position 
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dDrag = false end end)
    end
end)
debugGui.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dInput and dDrag then
        local d = input.Position - dStart
        debugGui.Position = UDim2.new(dPos.X.Scale, dPos.X.Offset + d.X, dPos.Y.Scale, dPos.Y.Offset + d.Y)
    end
end)

DebugLog("Script container initialized")

--// UID System
local uid = "1"
local function initUID()
    if isfile and readfile and writefile then
        if isfile("nl_muscle_uid.txt") then
            uid = readfile("nl_muscle_uid.txt")
        else
            pcall(function()
                local res = game:HttpGet("https://api.counterapi.dev/v1/musclesimulator_script/users/up")
                local data = HttpService:JSONDecode(res)
                uid = tostring(data.count)
                writefile("nl_muscle_uid.txt", uid)
            end)
        end
    else
        uid = tostring(math.random(1000, 9999))
    end
    DebugLog("User UID authenticated: " .. uid)
end
initUID()
DebugLog("Engine hooks parsed")

--// parsing function
local function parse(text)
    local function conv(v)
        v = v:upper():gsub(" ", "")
        local n = tonumber(v:match("[%d%.]+")) or 0

        if v:find("K") then return n * 1e3 end
        if v:find("M") then return n * 1e6 end
        if v:find("B") then return n * 1e9 end
        return n
    end

    local a, b = text:match("([^/]+)/([^/]+)")
    if not a or not b then return 0, 0 end

    return conv(a), conv(b)
end

--// state
local enabled = false
local saveAutofarm = false
local limitValue = 0
local fullCounter = 0
local safePlatform = nil
local safeMode = false

-- Colors
local c_bg = Color3.fromRGB(30, 30, 35)
local c_top = Color3.fromRGB(40, 40, 45)
local c_element = Color3.fromRGB(45, 45, 50)
local c_text = Color3.fromRGB(255, 255, 255)
local c_text_dark = Color3.fromRGB(180, 180, 180)
local c_accent = Color3.fromRGB(100, 150, 255)
local c_border = Color3.fromRGB(55, 55, 60)

-- Watermark
local watermark = Instance.new("Frame")
watermark.Size = UDim2.new(0, 300, 0, 25)
watermark.Position = UDim2.new(0, 15, 0, 15)
watermark.BackgroundColor3 = c_bg
watermark.BorderSizePixel = 0
watermark.Visible = false
watermark.Parent = gui

local wmCorner = Instance.new("UICorner")
wmCorner.CornerRadius = UDim.new(0, 6)
wmCorner.Parent = watermark

local wmStroke = Instance.new("UIStroke")
wmStroke.Color = c_border
wmStroke.Thickness = 1
wmStroke.Parent = watermark

local wmGlow = Instance.new("UIStroke")
wmGlow.Color = c_accent
wmGlow.Transparency = 0.5
wmGlow.Thickness = 2
wmGlow.Parent = watermark

local wmText = Instance.new("TextLabel")
wmText.Size = UDim2.new(1, -20, 1, 0)
wmText.Position = UDim2.new(0, 10, 0, 0)
wmText.BackgroundTransparency = 1
wmText.Font = Enum.Font.GothamMedium
wmText.TextSize = 13
wmText.TextColor3 = c_text
wmText.TextXAlignment = Enum.TextXAlignment.Left
wmText.Parent = watermark

local function getPing()
    local success, ping = pcall(function() return math.floor(player:GetNetworkPing() * 1000) end)
    return success and tostring(ping) .. "ms" or "N/A"
end

local function getExec()
    local success, exec = pcall(function() return identifyexecutor() end)
    return success and exec or "Unknown"
end
local executorName = getExec()

local frames = 0
local fps = 60
RunService.RenderStepped:Connect(function()
    frames = frames + 1
end)

task.spawn(function()
    while true do
        fps = frames
        frames = 0
        if watermark.Visible then
            wmText.Text = string.format("Parsefarm | %s | UID: %s | FPS: %d | Latency: %s | Exec: %s", player.Name, uid, fps, getPing(), executorName)
            local textBounds = game:GetService("TextService"):GetTextSize(wmText.Text, 13, Enum.Font.GothamMedium, Vector2.new(1000, 25))
            watermark.Size = UDim2.new(0, textBounds.X + 20, 0, 25)
        end
        task.wait(1)
    end
end)

-- Main Frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 380, 0, 260)
frame.Position = UDim2.new(0.5, -190, 0.5, -130)
frame.BackgroundColor3 = c_bg
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
frame.Active = true
frame.Parent = gui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 10)
frameCorner.Parent = frame

local glow = Instance.new("UIStroke")
glow.Color = c_accent
glow.Transparency = 0.2
glow.Thickness = 2
glow.Parent = frame

task.spawn(function()
    while true do
        local t1 = TweenService:Create(glow, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.6, Thickness = 4})
        t1:Play()
        t1.Completed:Wait()
        local t2 = TweenService:Create(glow, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.2, Thickness = 2})
        t2:Play()
        t2.Completed:Wait()
    end
end)

-- Top Bar
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 40)
topBar.BackgroundColor3 = c_top
topBar.BorderSizePixel = 0
topBar.Active = true -- Explicitly allow input
topBar.Parent = frame

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 10)
topCorner.Parent = topBar

local topFix = Instance.new("Frame")
topFix.Size = UDim2.new(1, 0, 0, 10)
topFix.Position = UDim2.new(0, 0, 1, -10)
topFix.BackgroundColor3 = c_top
topFix.BorderSizePixel = 0
topFix.Parent = topBar

local topBorder = Instance.new("Frame")
topBorder.Size = UDim2.new(1, 0, 0, 1)
topBorder.Position = UDim2.new(0, 0, 1, 0)
topBorder.BackgroundColor3 = c_border
topBorder.BorderSizePixel = 0
topBorder.Parent = topBar

local gameName = "Unknown Game"
if game.PlaceId == 4898652375 then
    gameName = "No Limit Lifting Simulator"
end

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -90, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Parsefarm <font color='#888888'>|</font> " .. gameName .. " <font color='#888888'>|</font> UID: " .. uid
title.RichText = true
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = c_text
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

-- Settings Button
local settingsBtn = Instance.new("TextButton")
settingsBtn.Size = UDim2.new(0, 30, 0, 40)
settingsBtn.Position = UDim2.new(1, -70, 0, 0)
settingsBtn.BackgroundTransparency = 1
settingsBtn.Text = "⚙"
settingsBtn.Font = Enum.Font.GothamBold
settingsBtn.TextSize = 18
settingsBtn.TextColor3 = c_text_dark
settingsBtn.Parent = topBar

settingsBtn.MouseEnter:Connect(function()
    TweenService:Create(settingsBtn, TweenInfo.new(0.2), {TextColor3 = c_accent}):Play()
end)
settingsBtn.MouseLeave:Connect(function()
    if settingsBtn.Name ~= "Active" then
        TweenService:Create(settingsBtn, TweenInfo.new(0.2), {TextColor3 = c_text_dark}):Play()
    end
end)

-- Close Button
local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 40, 0, 40)
close.Position = UDim2.new(1, -40, 0, 0)
close.BackgroundTransparency = 1
close.Text = "X"
close.Font = Enum.Font.GothamBold
close.TextSize = 14
close.TextColor3 = c_text_dark
close.Parent = topBar

close.MouseEnter:Connect(function()
    TweenService:Create(close, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 80, 80)}):Play()
end)
close.MouseLeave:Connect(function()
    TweenService:Create(close, TweenInfo.new(0.2), {TextColor3 = c_text_dark}):Play()
end)
close.MouseButton1Click:Connect(function()
    gui:Destroy()
    enabled = false
    if safePlatform then safePlatform:Destroy() end
end)

-- Content Lists
local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, -30, 1, -60)
content.Position = UDim2.new(0, 15, 0, 50)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 2
content.Parent = frame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = content

local settingsContent = Instance.new("ScrollingFrame")
settingsContent.Size = UDim2.new(1, -30, 1, -60)
settingsContent.Position = UDim2.new(0, 15, 0, 50)
settingsContent.BackgroundTransparency = 1
settingsContent.BorderSizePixel = 0
settingsContent.ScrollBarThickness = 2
settingsContent.Visible = false
settingsContent.Parent = frame

local settingsLayout = Instance.new("UIListLayout")
settingsLayout.Padding = UDim.new(0, 8)
settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
settingsLayout.Parent = settingsContent

-- Settings Toggle Logic
local inSettings = false
settingsBtn.MouseButton1Click:Connect(function()
    inSettings = not inSettings
    content.Visible = not inSettings
    settingsContent.Visible = inSettings
    
    settingsBtn.Name = inSettings and "Active" or "Inactive"
    TweenService:Create(settingsBtn, TweenInfo.new(0.2), {TextColor3 = inSettings and c_accent or c_text_dark}):Play()
    
    if inSettings then
        title.Text = "Parsefarm <font color='#888888'>|</font> Settings"
    else
        title.Text = "Parsefarm <font color='#888888'>|</font> " .. gameName .. " <font color='#888888'>|</font> UID: " .. uid
    end
end)

-- Function to create toggles
local function createToggle(name, defaultState, callback, parentOverride)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, -10, 0, 45)
    toggleFrame.BackgroundColor3 = c_element
    toggleFrame.BorderSizePixel = 0
    toggleFrame.Parent = parentOverride or content

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = toggleFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = c_border
    stroke.Thickness = 1
    stroke.Parent = toggleFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 14
    label.TextColor3 = c_text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = toggleFrame

    local box = Instance.new("Frame")
    box.Size = UDim2.new(0, 44, 0, 22)
    box.Position = UDim2.new(1, -59, 0.5, -11)
    box.BackgroundColor3 = defaultState and c_accent or Color3.fromRGB(35, 35, 40)
    box.BorderSizePixel = 0
    box.Parent = toggleFrame

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(1, 0)
    boxCorner.Parent = box

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color = c_border
    boxStroke.Thickness = 1
    boxStroke.Parent = box

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 16, 0, 16)
    circle.Position = defaultState and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    circle.BorderSizePixel = 0
    circle.Parent = box

    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = circle

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = toggleFrame

    local state = defaultState
    local function SetState(newState)
        if state == newState then return end
        state = newState
        local targetPos = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        local targetColor = state and c_accent or Color3.fromRGB(35, 35, 40)
        
        TweenService:Create(circle, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Position = targetPos}):Play()
        TweenService:Create(box, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {BackgroundColor3 = targetColor}):Play()
        
        callback(state)
    end

    btn.MouseButton1Click:Connect(function()
        SetState(not state)
    end)
    
    return {
        SetState = SetState
    }
end

-- Function to create inputs
local function createInput(name, placeholder, callback, parentOverride)
    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(1, -10, 0, 45)
    inputFrame.BackgroundColor3 = c_element
    inputFrame.BorderSizePixel = 0
    inputFrame.Parent = parentOverride or content

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = inputFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = c_border
    stroke.Thickness = 1
    stroke.Parent = inputFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 14
    label.TextColor3 = c_text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = inputFrame

    local boxBg = Instance.new("Frame")
    boxBg.Size = UDim2.new(0.5, -25, 0, 30)
    boxBg.Position = UDim2.new(0.5, 10, 0.5, -15)
    boxBg.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    boxBg.BorderSizePixel = 0
    boxBg.Parent = inputFrame

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 6)
    boxCorner.Parent = boxBg
    
    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color = c_border
    boxStroke.Thickness = 1
    boxStroke.Parent = boxBg

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -10, 1, 0)
    box.Position = UDim2.new(0, 5, 0, 0)
    box.BackgroundTransparency = 1
    box.PlaceholderText = placeholder
    box.Text = ""
    box.Font = Enum.Font.Gotham
    box.TextSize = 13
    box.TextColor3 = c_text
    box.TextXAlignment = Enum.TextXAlignment.Center
    box.Parent = boxBg

    box.Focused:Connect(function()
        TweenService:Create(boxStroke, TweenInfo.new(0.3), {Color = c_accent}):Play()
    end)
    box.FocusLost:Connect(function()
        TweenService:Create(boxStroke, TweenInfo.new(0.3), {Color = c_border}):Play()
        callback(box.Text)
    end)
end

-- Toggles & Inputs
local autoFarmToggle = createToggle("Auto Farm", false, function(state)
    enabled = state
    DebugLog(state and "Auto farm enabled" or "Auto farm disabled")
end)

createToggle("Save Autofarm (Safe Zone)", false, function(state)
    saveAutofarm = state
    
    if saveAutofarm then
        DebugLog("Safe zone triggered")
        autoFarmToggle.SetState(true)
    else
        DebugLog("Safe zone disabled")
    end

    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    if saveAutofarm then
        local targetCFrame = root.CFrame + Vector3.new(0, 5000, 0)
        root.CFrame = targetCFrame
        DebugLog(string.format("Teleported to secure coordinates: %.1f, %.1f, %.1f", targetCFrame.X, targetCFrame.Y, targetCFrame.Z))
        
        if not safePlatform then
            safePlatform = Instance.new("Part")
            safePlatform.Name = "SafePlatform_NoLimit"
            safePlatform.Size = Vector3.new(100, 2, 100)
            safePlatform.Position = root.Position - Vector3.new(0, 4, 0)
            safePlatform.Anchored = true
            safePlatform.Material = Enum.Material.SmoothPlastic
            safePlatform.Color = Color3.fromRGB(30, 30, 30)
            safePlatform.Parent = workspace
            DebugLog("Safe zone secure platform established")
        else
            safePlatform.Position = root.Position - Vector3.new(0, 4, 0)
        end
    else
        if safePlatform then
            safePlatform:Destroy()
            safePlatform = nil
        end
        char:BreakJoints()
    end
end)

createInput("Sell Limit", "0 = none", function(text)
    local v = tonumber(text)
    if not v or v <= 0 then
        limitValue = 0
        DebugLog("Sell limit cleared")
    else
        limitValue = v
        DebugLog("Sell limit explicitly set to: " .. tostring(v))
    end
end)

-- Settings Tab Items
createToggle("Safe Mode", false, function(state)
    safeMode = state
    DebugLog("Safe mode parameters " .. (state and "ACTIVE" or "INACTIVE"))
end, settingsContent)

createToggle("Watermark", false, function(state)
    watermark.Visible = state
    DebugLog("Watermark overlay " .. tostring(state))
end, settingsContent)

createToggle("Debug Window", false, function(state)
    debugGui.Visible = state
    if state then DebugLog("Developer debug console surfaced") end
end, settingsContent)

-- Proper Bulletproof UI Dragging
local mDrag, mStart, mPos, mInput
topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        mDrag = true; mStart = input.Position; mPos = frame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then mDrag = false end end)
    end
end)
topBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then mInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == mInput and mDrag then
        local d = input.Position - mStart
        frame.Position = UDim2.new(mPos.X.Scale, mPos.X.Offset + d.X, mPos.Y.Scale, mPos.Y.Offset + d.Y)
    end
end)

DebugLog("UI engine loaded and authenticated")

--// Loop
task.spawn(function()
    while true do
        local waitTime = 0.1
        
        if enabled then
            local current, max = parse(status.Text)

            if current >= max then
                fullCounter += 1
            else
                fullCounter = 0
            end

            local limitOk = (limitValue == 0) or (current >= limitValue)

            local sellDelay = safeMode and 0.4 or 0.2
            local gainDelay = safeMode and 1.0 or 0.4

            if fullCounter >= 0.6 and limitOk then
                RemoteEvent:FireServer({[1] = "SellMuscle"})
                DebugLog("Remote -> Action: SellMuscle")
                waitTime = sellDelay
            else
                RemoteEvent:FireServer({[1] = "GainMuscle"})
                DebugLog("Remote -> Action: GainMuscle")
                waitTime = gainDelay
            end
        end

        task.wait(waitTime)
    end
end)