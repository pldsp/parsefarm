local Players = game:GetService("Players")

local EXPECTED_OFFSET = "399DK39XKDS9FWKF92FK4G8SD"
if not getgenv()._PARSEFARM_AUTH or getgenv()._PARSEFARM_OFFSET ~= EXPECTED_OFFSET or type(getgenv()._PARSEFARM_PAYLOADS) ~= "function" then
    Players.LocalPlayer:Kick("parsefarm | invalid or outdated offset!")
    return
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
local status = player.PlayerGui:WaitForChild("Main_Gui"):WaitForChild("DataMenu_Frame"):WaitForChild("Muscle"):WaitForChild("Status")

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
end
initUID()

local gui = Instance.new("ScreenGui")
gui.Name = "Gamesense_MainUI"
gui.ResetOnSpawn = false
if CoreGui:FindFirstChild("Gamesense_MainUI") then CoreGui.Gamesense_MainUI:Destroy() end
gui.Parent = CoreGui

local c_bg = Color3.fromRGB(23, 23, 23)
local c_outline = Color3.fromRGB(10, 10, 10)
local c_inner = Color3.fromRGB(50, 50, 50)
local c_text = Color3.fromRGB(200, 200, 200)
local c_accent = Color3.fromRGB(160, 200, 80) 

local watermark = Instance.new("Frame")
watermark.Size = UDim2.new(0, 250, 0, 20)
watermark.Position = UDim2.new(1, -260, 0, 10)
watermark.BackgroundColor3 = c_bg
watermark.BorderColor3 = c_outline
watermark.BorderSizePixel = 1
watermark.Visible = false
watermark.Parent = gui

local wmInner = Instance.new("Frame")
wmInner.Size = UDim2.new(1, -2, 1, -2)
wmInner.Position = UDim2.new(0, 1, 0, 1)
wmInner.BackgroundColor3 = c_bg
wmInner.BorderColor3 = c_inner
wmInner.BorderSizePixel = 1
wmInner.Parent = watermark

local wmGrad = Instance.new("Frame")
wmGrad.Size = UDim2.new(1, 0, 0, 2)
wmGrad.BorderSizePixel = 0
wmGrad.Parent = wmInner

local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(59, 175, 222)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(202, 70, 205)),
    ColorSequenceKeypoint.new(0.66, Color3.fromRGB(201, 227, 58)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(59, 175, 222))
})
grad.Parent = wmGrad

local wmText = Instance.new("TextLabel")
wmText.Size = UDim2.new(1, -10, 1, -2)
wmText.Position = UDim2.new(0, 5, 0, 2)
wmText.BackgroundTransparency = 1
wmText.Font = Enum.Font.Code
wmText.TextSize = 12
wmText.TextColor3 = c_text
wmText.TextXAlignment = Enum.TextXAlignment.Right
wmText.Parent = wmInner

task.spawn(function()
    while true do
        if watermark.Visible then
            local fps = math.floor(1 / RunService.RenderStepped:Wait())
            local ping = "N/A"
            pcall(function() ping = math.floor(player:GetNetworkPing() * 1000) .. "ms" end)
            wmText.Text = string.format("parsefarm | %s | uid: %s | %d fps | %s", player.Name, uid, fps, ping)
            
            local TextService = game:GetService("TextService")
            local bounds = TextService:GetTextSize(wmText.Text, 12, Enum.Font.Code, Vector2.new(1000, 20))
            watermark.Size = UDim2.new(0, bounds.X + 15, 0, 20)
            watermark.Position = UDim2.new(1, -(bounds.X + 25), 0, 10)
        end
        task.wait(0.5)
    end
end)

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 480, 0, 360)
frame.Position = UDim2.new(0.5, -240, 0.5, -180)
frame.BackgroundColor3 = c_bg
frame.BorderColor3 = c_outline
frame.BorderSizePixel = 1
frame.Active = true
frame.Parent = gui

local fInner = Instance.new("Frame")
fInner.Size = UDim2.new(1, -2, 1, -2)
fInner.Position = UDim2.new(0, 1, 0, 1)
fInner.BackgroundColor3 = c_bg
fInner.BorderColor3 = c_inner
fInner.BorderSizePixel = 1
fInner.Parent = frame

local topGrad = Instance.new("Frame")
topGrad.Size = UDim2.new(1, 0, 0, 2)
topGrad.BorderSizePixel = 0
topGrad.Parent = fInner
grad:Clone().Parent = topGrad

local closeMain = Instance.new("TextButton")
closeMain.Size = UDim2.new(0, 20, 0, 20)
closeMain.Position = UDim2.new(1, -25, 0, 2)
closeMain.BackgroundTransparency = 1
closeMain.Text = "X"
closeMain.Font = Enum.Font.Code
closeMain.TextSize = 12
closeMain.TextColor3 = Color3.fromRGB(150, 150, 150)
closeMain.Parent = fInner

closeMain.MouseEnter:Connect(function() closeMain.TextColor3 = Color3.fromRGB(255, 100, 100) end)
closeMain.MouseLeave:Connect(function() closeMain.TextColor3 = Color3.fromRGB(150, 150, 150) end)
closeMain.MouseButton1Click:Connect(function() 
    gui:Destroy() 
    enabled = false
    if safePlatform then safePlatform:Destroy() end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.Insert then
        frame.Visible = not frame.Visible
    end
end)

local dragArea = Instance.new("Frame")
dragArea.Size = UDim2.new(1, 0, 0, 20)
dragArea.BackgroundTransparency = 1
dragArea.Parent = fInner

local mainTitle = Instance.new("TextLabel")
mainTitle.Size = UDim2.new(1, -50, 0, 20)
mainTitle.Position = UDim2.new(0, 10, 0, 2)
mainTitle.BackgroundTransparency = 1
mainTitle.Text = "parsefarm - gamesense"
mainTitle.Font = Enum.Font.Code
mainTitle.TextSize = 12
mainTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
mainTitle.TextXAlignment = Enum.TextXAlignment.Left
mainTitle.Parent = fInner

local mDrag, mStart, mPos, mInput
dragArea.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        mDrag = true; mStart = input.Position; mPos = frame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then mDrag = false end end)
    end
end)
dragArea.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then mInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == mInput and mDrag then
        local d = input.Position - mStart
        frame.Position = UDim2.new(mPos.X.Scale, mPos.X.Offset + d.X, mPos.Y.Scale, mPos.Y.Offset + d.Y)
    end
end)

local tabsArea = Instance.new("Frame")
tabsArea.Size = UDim2.new(0, 100, 1, -22)
tabsArea.Position = UDim2.new(0, 0, 0, 22)
tabsArea.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
tabsArea.BorderColor3 = c_inner
tabsArea.BorderSizePixel = 1
tabsArea.Parent = fInner

local tabLayout = Instance.new("UIListLayout")
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = tabsArea

local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -110, 1, -32)
contentArea.Position = UDim2.new(0, 105, 0, 27)
contentArea.BackgroundTransparency = 1
contentArea.Parent = fInner

local activeTab = nil
local contents = {}

local function createTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
    btn.BorderSizePixel = 0
    btn.Text = "  " .. name
    btn.Font = Enum.Font.Code
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(150, 150, 150)
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = tabsArea
    
    local c = Instance.new("ScrollingFrame")
    c.Size = UDim2.new(1, 0, 1, 0)
    c.BackgroundTransparency = 1
    c.BorderSizePixel = 0
    c.ScrollBarThickness = 0
    c.Visible = false
    c.Parent = contentArea
    
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 10)
    l.Parent = c
    
    contents[name] = c
    
    btn.MouseButton1Click:Connect(function()
        if activeTab then activeTab.TextColor3 = Color3.fromRGB(150, 150, 150) end
        for _, v in pairs(contents) do v.Visible = false end
        btn.TextColor3 = c_text
        c.Visible = true
        activeTab = btn
    end)
    
    if not activeTab then
        btn.TextColor3 = c_text
        c.Visible = true
        activeTab = btn
    end
    
    return c
end

local function createToggle(name, parent, callback)
    local tFrame = Instance.new("Frame")
    tFrame.Size = UDim2.new(1, 0, 0, 15)
    tFrame.BackgroundTransparency = 1
    tFrame.Parent = parent
    
    local boxBg = Instance.new("Frame")
    boxBg.Size = UDim2.new(0, 10, 0, 10)
    boxBg.Position = UDim2.new(0, 5, 0, 2)
    boxBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    boxBg.BorderColor3 = c_outline
    boxBg.BorderSizePixel = 1
    boxBg.Parent = tFrame
    
    local boxInner = Instance.new("Frame")
    boxInner.Size = UDim2.new(1, -2, 1, -2)
    boxInner.Position = UDim2.new(0, 1, 0, 1)
    boxInner.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    boxInner.BorderSizePixel = 0
    boxInner.Parent = boxBg
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -25, 1, 0)
    lbl.Position = UDim2.new(0, 25, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 12
    lbl.TextColor3 = c_text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = tFrame
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = tFrame
    
    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        boxInner.BackgroundColor3 = state and c_accent or Color3.fromRGB(45, 45, 45)
        callback(state)
    end)
    
    return {
        Set = function(v)
            state = v
            boxInner.BackgroundColor3 = state and c_accent or Color3.fromRGB(45, 45, 45)
            callback(state)
        end
    }
end

local function createInput(name, parent, callback)
    local tFrame = Instance.new("Frame")
    tFrame.Size = UDim2.new(1, 0, 0, 35)
    tFrame.BackgroundTransparency = 1
    tFrame.Parent = parent
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, 15)
    lbl.Position = UDim2.new(0, 5, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 12
    lbl.TextColor3 = c_text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = tFrame
    
    local boxBg = Instance.new("Frame")
    boxBg.Size = UDim2.new(0, 150, 0, 18)
    boxBg.Position = UDim2.new(0, 5, 0, 16)
    boxBg.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
    boxBg.BorderColor3 = c_outline
    boxBg.BorderSizePixel = 1
    boxBg.Parent = tFrame
    
    local boxInner = Instance.new("Frame")
    boxInner.Size = UDim2.new(1, -2, 1, -2)
    boxInner.Position = UDim2.new(0, 1, 0, 1)
    boxInner.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
    boxInner.BorderColor3 = c_inner
    boxInner.BorderSizePixel = 1
    boxInner.Parent = boxBg
    
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -4, 1, 0)
    box.Position = UDim2.new(0, 2, 0, 0)
    box.BackgroundTransparency = 1
    box.Text = "0"
    box.Font = Enum.Font.Code
    box.TextSize = 12
    box.TextColor3 = c_text
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.Parent = boxInner
    
    box.FocusLost:Connect(function() callback(box.Text) end)
end

local tabFarm = createTab("Farming")
local tabMisc = createTab("Miscellaneous")

local enabled = false
local safeAutofarm = false
local safeMode = false
local limitValue = 0
local safePlatform = nil
local fullCounter = 0

local autoFarmToggle = createToggle("Enable Auto Farm", tabFarm, function(s) enabled = s end)

createToggle("Safe Zone (Teleport Up)", tabFarm, function(state)
    safeAutofarm = state
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    if state then
        autoFarmToggle.Set(true)
        root.CFrame = root.CFrame + Vector3.new(0, 5000, 0)
        if not safePlatform then
            safePlatform = Instance.new("Part")
            safePlatform.Name = "SafePlatform"
            safePlatform.Size = Vector3.new(100, 2, 100)
            safePlatform.Position = root.Position - Vector3.new(0, 4, 0)
            safePlatform.Anchored = true
            safePlatform.Material = Enum.Material.SmoothPlastic
            safePlatform.Color = Color3.fromRGB(30, 30, 30)
            safePlatform.Parent = workspace
        else
            safePlatform.Position = root.Position - Vector3.new(0, 4, 0)
        end
    else
        if safePlatform then safePlatform:Destroy(); safePlatform = nil end
        char:BreakJoints()
    end
end)

createInput("Sell Limit (0 = off)", tabFarm, function(t)
    local v = tonumber(t)
    limitValue = (v and v > 0) and v or 0
end)

createToggle("Safe Mode (Anti-Cheat Bypass)", tabMisc, function(s) safeMode = s end)
createToggle("Watermark Overlay", tabMisc, function(s) watermark.Visible = s end)

local function parseCapacity(text)
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

task.spawn(function()
    while true do
        local waitTime = 0.1
        if enabled then
            local current, max = parseCapacity(status.Text)
            if current >= max then fullCounter += 1 else fullCounter = 0 end
            
            local limitOk = (limitValue == 0) or (current >= limitValue)
            local sellDelay = safeMode and 0.4 or 0.2
            local gainDelay = safeMode and 1.0 or 0.4
            
            -- CRUCIAL LOADER DEPENDENCY
            local sellCmd = getgenv()._PARSEFARM_PAYLOADS("sell")
            local gainCmd = getgenv()._PARSEFARM_PAYLOADS("gain")
            
            if fullCounter >= 0.6 and limitOk then
                RemoteEvent:FireServer({[1] = sellCmd})
                waitTime = sellDelay
            else
                RemoteEvent:FireServer({[1] = gainCmd})
                waitTime = gainDelay
            end
        end
        task.wait(waitTime)
    end
end)
