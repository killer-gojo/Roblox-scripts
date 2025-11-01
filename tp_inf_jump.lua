local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local configFileName = "relative_coords_config.json"
local hasWrite = type(writefile) == "function"
local hasRead = type(readfile) == "function"
local hasIsFile = type(isfile) == "function"
local hasFileApi = hasWrite and hasRead

local function safeDecode(jsonText)
    local ok, tbl = pcall(function() return HttpService:JSONDecode(jsonText) end)
    if ok and type(tbl) == "table" then return tbl end
    return nil
end
local function safeEncode(tbl)
    local ok, s = pcall(function() return HttpService:JSONEncode(tbl) end)
    if ok then return s end
    return nil
end
local function saveConfigToFile(tbl)
    if not hasFileApi then return false, "no file api" end
    local json = safeEncode(tbl) or "{}"
    local ok, err = pcall(function() writefile(configFileName, json) end)
    return ok, err
end
local function loadConfigFromFile()
    if not hasFileApi then return nil end
    local exists = false
    if hasIsFile then
        local ok, res = pcall(function() return isfile(configFileName) end)
        exists = ok and res
    else
        local okr, _ = pcall(function() return readfile(configFileName) end)
        exists = okr
    end
    if not exists then return nil end
    local ok, content = pcall(function() return readfile(configFileName) end)
    if not ok or not content then return nil end
    return safeDecode(content)
end
local function saveConfigToAttributes(tbl)
    for k,v in pairs(tbl) do
        player:SetAttribute(k, tostring(v))
    end
end
local function loadConfigFromAttributes()
    local x = player:GetAttribute("savedX")
    local y = player:GetAttribute("savedY")
    local z = player:GetAttribute("savedZ")
    local lbx = player:GetAttribute("LAST_BEFORE_X")
    local lby = player:GetAttribute("LAST_BEFORE_Y")
    local lbz = player:GetAttribute("LAST_BEFORE_Z")
    if x or y or z or lbx or lby or lbz then
        local res = {
            X = tostring(x or "0"),
            Y = tostring(y or "0"),
            Z = tostring(z or "0")
        }
        if lbx and lby and lbz then
            res.LAST_BEFORE = { X = tostring(lbx), Y = tostring(lby), Z = tostring(lbz) }
        end
        return res
    end
    return nil
end
local function saveConfig(tbl)
    if hasFileApi then
        local ok, err = saveConfigToFile(tbl)
        if not ok then
            saveConfigToAttributes(tbl)
        end
    else
        saveConfigToAttributes(tbl)
    end
end
local function loadConfig()
    if hasFileApi then
        local f = loadConfigFromFile()
        if f then return f end
    end
    local a = loadConfigFromAttributes()
    if a then return a end
    return { X = "0", Y = "0", Z = "0" }
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RelativeCoordsUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = playerGui

local TextLabel = Instance.new("TextLabel")
TextLabel.Size = UDim2.new(0.6, 0, 0.08, 0)
TextLabel.Position = UDim2.new(0.02, 0, 0.02, 0)
TextLabel.BackgroundTransparency = 0.3
TextLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel.TextScaled = true
TextLabel.Font = Enum.Font.GothamBold
TextLabel.Text = "Coordinates : (0, 0, 0)"
TextLabel.Parent = ScreenGui
TextLabel.ZIndex = 10
TextLabel.TextStrokeTransparency = 0.5
TextLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0.5, 0, 0.25, 0)
Frame.Position = UDim2.new(0.25, 0, 0.75, 0)
Frame.BackgroundTransparency = 0.3
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.Parent = ScreenGui
Frame.Visible = true
Frame.ZIndex = 5

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0.15, 0, 0.07, 0)
ToggleButton.Position = UDim2.new(0.83, 0, 0.45, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 100, 255)
ToggleButton.Text = "📍 GUI"
ToggleButton.TextScaled = true
ToggleButton.TextColor3 = Color3.new(1,1,1)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Parent = ScreenGui
ToggleButton.ZIndex = 15

ToggleButton.MouseButton1Click:Connect(function()
    Frame.Visible = not Frame.Visible
end)

local InfJumpButton = Instance.new("TextButton")
InfJumpButton.Size = UDim2.new(0.15, 0, 0.07, 0)
InfJumpButton.Position = UDim2.new(0.83, 0, 0.36, 0)
InfJumpButton.BackgroundColor3 = Color3.fromRGB(0,200,100)
InfJumpButton.Text = "🟢 Inf Jump: OFF"
InfJumpButton.TextScaled = true
InfJumpButton.TextColor3 = Color3.new(1,1,1)
InfJumpButton.Font = Enum.Font.GothamBold
InfJumpButton.Parent = ScreenGui
InfJumpButton.ZIndex = 15

local infiniteJumpEnabled = false
InfJumpButton.MouseButton1Click:Connect(function()
    infiniteJumpEnabled = not infiniteJumpEnabled
    if infiniteJumpEnabled then
        InfJumpButton.Text = "🟢 Inf Jump: ON"
        InfJumpButton.BackgroundColor3 = Color3.fromRGB(0,255,120)
    else
        InfJumpButton.Text = "🔴 Inf Jump: OFF"
        InfJumpButton.BackgroundColor3 = Color3.fromRGB(200,0,0)
    end
end)

UIS.JumpRequest:Connect(function()
    if infiniteJumpEnabled then
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

local function createInput(name, pos)
    local label = Instance.new("TextLabel")
    label.Text = name .. ":"
    label.Size = UDim2.new(0.15, 0, 0.3, 0)
    label.Position = UDim2.new(pos, 0, 0.1, 0)
    label.BackgroundTransparency = 1
    label.TextScaled = true
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.Font = Enum.Font.GothamBold
    label.Parent = Frame

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(0.2, 0, 0.3, 0)
    input.Position = UDim2.new(pos + 0.1, 0, 0.1, 0)
    input.PlaceholderText = "0"
    input.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    input.TextColor3 = Color3.fromRGB(255,255,255)
    input.TextScaled = true
    input.Font = Enum.Font.Gotham
    input.Parent = Frame
    return input
end

local inputX = createInput("X", 0.05)
local inputY = createInput("Y", 0.4)
local inputZ = createInput("Z", 0.75)

local cfg = loadConfig()
inputX.Text = tostring(cfg.X or "0")
inputY.Text = tostring(cfg.Y or "0")
inputZ.Text = tostring(cfg.Z or "0")

local function toNumberSafe(v) return tonumber(v) end
local lastBeforePos = nil
if cfg and cfg.LAST_BEFORE then
    local lx = toNumberSafe(cfg.LAST_BEFORE.X)
    local ly = toNumberSafe(cfg.LAST_BEFORE.Y)
    local lz = toNumberSafe(cfg.LAST_BEFORE.Z)
    if lx and ly and lz then
        lastBeforePos = Vector3.new(lx, ly, lz)
    end
end

local function onFocusLost()
    local tosave = {
        X = inputX.Text ~= "" and inputX.Text or "0",
        Y = inputY.Text ~= "" and inputY.Text or "0",
        Z = inputZ.Text ~= "" and inputZ.Text or "0"
    }
    if lastBeforePos then
        tosave.LAST_BEFORE = { X = tostring(lastBeforePos.X), Y = tostring(lastBeforePos.Y), Z = tostring(lastBeforePos.Z) }
    end
    saveConfig(tosave)
end
inputX.FocusLost:Connect(onFocusLost)
inputY.FocusLost:Connect(onFocusLost)
inputZ.FocusLost:Connect(onFocusLost)

local tpButton = Instance.new("TextButton")
tpButton.Size = UDim2.new(0.44, 0, 0.3, 0)
tpButton.Position = UDim2.new(0.05, 0, 0.6, 0)
tpButton.BackgroundColor3 = Color3.fromRGB(0,150,0)
tpButton.Text = "Teleport"
tpButton.TextScaled = true
tpButton.TextColor3 = Color3.fromRGB(255,255,255)
tpButton.Font = Enum.Font.GothamBold
tpButton.Parent = Frame
tpButton.ZIndex = 10

local backButton = Instance.new("TextButton")
backButton.Size = UDim2.new(0.44, 0, 0.3, 0)
backButton.Position = UDim2.new(0.51, 0, 0.6, 0)
backButton.BackgroundColor3 = Color3.fromRGB(150,75,0)
backButton.Text = "Back Old Pos"
backButton.TextScaled = true
backButton.TextColor3 = Color3.fromRGB(255,255,255)
backButton.Font = Enum.Font.GothamBold
backButton.Parent = Frame
backButton.ZIndex = 10

local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local spawnPos = root.Position

RunService.RenderStepped:Connect(function()
    if character and root then
        local rel = root.Position - spawnPos
        TextLabel.Text = string.format("Coordinates : (%d, %d, %d)",
            math.floor(rel.X + 0.5),
            math.floor(rel.Y + 0.5),
            math.floor(rel.Z + 0.5)
        )
    end
end)

tpButton.MouseButton1Click:Connect(function()
    local x = tonumber(inputX.Text) or 0
    local y = tonumber(inputY.Text) or 0
    local z = tonumber(inputZ.Text) or 0
    if character and root then
        lastBeforePos = root.Position
        root.CFrame = CFrame.new(spawnPos + Vector3.new(x, y, z))
        local saved = {
            X = inputX.Text,
            Y = inputY.Text,
            Z = inputZ.Text,
            LAST_BEFORE = { X = tostring(lastBeforePos.X), Y = tostring(lastBeforePos.Y), Z = tostring(lastBeforePos.Z) }
        }
        saveConfig(saved)
    end
end)

backButton.MouseButton1Click:Connect(function()
    if character and root and lastBeforePos then
        root.CFrame = CFrame.new(lastBeforePos)
    end
end)

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    root = newChar:WaitForChild("HumanoidRootPart")
    spawnPos = root.Position
end)

local ticker = 0
RunService.Heartbeat:Connect(function(dt)
    ticker = ticker + dt
    if ticker > 5 then
        ticker = 0
        local saved = { X = inputX.Text, Y = inputY.Text, Z = inputZ.Text }
        if lastBeforePos then
            saved.LAST_BEFORE = { X = tostring(lastBeforePos.X), Y = tostring(lastBeforePos.Y), Z = tostring(lastBeforePos.Z) }
        end
        saveConfig(saved)
    end
end)