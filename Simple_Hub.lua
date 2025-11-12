-- By killer_gojo

-- ** CHARGEMENT DE LA LIBRAIRIE APPLELIBRARY **
-- Cette librairie est choisie pour sa légèreté et sa compatibilité mobile.
local library = loadstring(game:HttpGet("https://github.com/GoHamza/AppleLibrary/blob/main/main.lua?raw=true"))()

local window = library:init("Simple Hub V0.4.2", true, Enum.KeyCode.RightShift, true)

-- Services et Variables
local Player = game.Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local OldPosition, CurrentFloatSpeed, IsFloating, FlyLoopConn = nil, 50, false, nil

local Keybinds = {["FloatUp"] = Enum.KeyCode.Space, ["FloatDown"] = Enum.KeyCode.LeftShift, ["TPToCursor"] = Enum.KeyCode.J}

-- LOGIQUE COMMUNE
local function FindPlayer(name)
    for _, p in pairs(Players:GetPlayers()) do
        local pNameLower, dNameLower, targetNameLower = string.lower(p.Name), string.lower(p.DisplayName), string.lower(name)
        if pNameLower == targetNameLower or dNameLower == targetNameLower then return p end
    end
    return nil
end

local function TeleportPlayer(targetPos)
    local hrp = Player.Character and Player.Character.HumanoidRootPart
    if not hrp then return end
    OldPosition = hrp.Position
    hrp.CFrame = CFrame.new(targetPos) * CFrame.Angles(0, 0, 0) 
end

-- ====================================================================
-- TABS (ONGLETS)
-- ====================================================================

-- I. Main (Mouvement)
local MainTab = window:Tab("Main")

local function SetWalkSpeed(speed) local human = Player.Character and Player.Character.Humanoid if human then human.WalkSpeed = speed end end
local function SetJumpPower(power) local human = Player.Character and Player.Character.Humanoid if human then human.JumpPower = power end end
local function SetGravity(gravity) Workspace.Gravity = gravity end

MainTab:Slider("WalkSpeed", 16, 200, 1, SetWalkSpeed, 16)
MainTab:Slider("JumpPower", 50, 500, 5, SetJumpPower, 50)
MainTab:Toggle("NoClip", false, function(Value) local hrp = Player.Character and Player.Character.HumanoidRootPart if hrp then hrp.CanCollide = not Value end end)

MainTab:Slider("Float Speed", 10, 500, 5, function(Value) CurrentFloatSpeed = Value end, 50)

local function FlyLoop()
    local hrp = Player.Character and Player.Character.HumanoidRootPart
    if not hrp or not IsFloating then return end
    local velocity = Vector3.new(0, 0, 0)
    if UserInputService:IsKeyDown(Keybinds["FloatUp"]) then velocity = velocity + Vector3.new(0, CurrentFloatSpeed, 0) end
    if UserInputService:IsKeyDown(Keybinds["FloatDown"]) then velocity = velocity - Vector3.new(0, CurrentFloatSpeed, 0) end
    if velocity ~= Vector3.new(0, 0, 0) then hrp.CFrame = hrp.CFrame + velocity / 60 end
end

MainTab:Toggle("Float / Fly (Space/LShift)", false, function(Value)
    IsFloating = Value
    local hrp = Player.Character and Player.Character.HumanoidRootPart
    local human = Player.Character and Player.Character.Humanoid
    if Value then
        if hrp and human then
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) 
            human.PlatformStand = true
            FlyLoopConn = RunService.RenderStepped:Connect(FlyLoop)
        end
    elseif FlyLoopConn then
        FlyLoopConn:Disconnect()
        FlyLoopConn = nil
        if human then human.PlatformStand = false end
    end
end)

MainTab:Slider("Gravity", 0, 196.2, 1, SetGravity, 196.2)


-- II. Visual
local VisualTab = window:Tab("Visual")

local IsESPActive, IsChamsActive, TeamESP = false, false, true
local function UpdateVisuals(name, Value) print("Visuals logic called for: " .. name .. " - " .. tostring(Value)) end

VisualTab:Toggle("Player ESP", IsESPActive, function(Value) IsESPActive = Value; UpdateVisuals("Player ESP", Value) end)
VisualTab:Toggle("Chams / X-Ray", IsChamsActive, function(Value) IsChamsActive = Value; UpdateVisuals("Chams", Value) end)
VisualTab:Toggle("Draw Box", true, function(Value) UpdateVisuals("Draw Box", Value) end)
VisualTab:Toggle("Team ESP (Prioritaire)", TeamESP, function(Value) TeamESP = Value; UpdateVisuals("Team ESP", Value) end)

-- III. Teleport
local TeleportTab = window:Tab("Teleport")
local InitialSpawnPosition = Player.Character and Player.Character.HumanoidRootPart.Position or Vector3.new(0, 50, 0)

-- TP to Cursor nécessite une boucle, l'activation est via le Keybind
local function TPToCursorLoop()
    if UserInputService:IsKeyDown(Keybinds["TPToCursor"]) then
        local mouse = Player:GetMouse()
        local targetPos = mouse.Hit.Position
        TeleportPlayer(targetPos)
    end
end

TeleportTab:Toggle("TP to Cursor (Keybind: J)", false, function(Value)
    if Value then RunService:BindToRenderStep("TPToCursorLoop", Enum.RenderPriority.Heartbeat.Value, TPToCursorLoop)
    else RunService:UnbindFromRenderStep("TPToCursorLoop") end
end)
TeleportTab:Button("TP to Initial Spawn", function() TeleportPlayer(InitialSpawnPosition) end)

-- Coords & Back
TeleportTab:Section("Coordinates")

local XInput = TeleportTab:Input("X Coordinate", "0")
local YInput = TeleportTab:Input("Y Coordinate", "0")
local ZInput = TeleportTab:Input("Z Coordinate", "0")

TeleportTab:Button("Teleport to Coords", function()
    local x, y, z = tonumber(XInput.Instance.Text) or 0, tonumber(YInput.Instance.Text) or 0, tonumber(ZInput.Instance.Text) or 0
    if x and y and z then TeleportPlayer(Vector3.new(x, y, z)) end
end)
TeleportTab:Button("Back to Old Pos", function() 
    if OldPosition then TeleportPlayer(OldPosition) end 
end)

-- Waypoints (In-Memory for mobile stability)
local WaypointsList = {}
TeleportTab:Section("Waypoints")
local WPNameInput = TeleportTab:Input("Waypoint Name", "New WP")

local function RenderWaypoints()
    -- L'AppleLibrary ne permet pas de créer des listes dynamiques facilement, 
    -- nous allons garder la gestion simple:
    print("INFO: Waypoints List needs refresh, current count: " .. #WaypointsList)
end

TeleportTab:Button("Create Waypoint", function()
    local name = WPNameInput.Instance.Text
    local currentPos = Player.Character and Player.Character.HumanoidRootPart.Position
    if not currentPos then return end
    local wpName = (name == "" or name == "Waypoint Name") and ("Waypoint " .. #WaypointsList + 1) or name
    local newWaypoint = {Name = wpName, X = currentPos.X, Y = currentPos.Y, Z = currentPos.Z}
    table.insert(WaypointsList, newWaypoint)
    print("Waypoint '" .. wpName .. "' created in memory.")
    RenderWaypoints()
end)

-- IV. Fling
local FlingTab = window:Tab("Fling")
local FlingPower, FlingAuraRadius, FlingAuraActive = 500, 10, false

local function ApplyFling(targetHRP)
    local FlingMagnitude = FlingPower * 100 
    local BForce = Instance.new("VectorForce")
    BForce.Force = Vector3.new(0, FlingMagnitude, 0)
    BForce.Attachment0 = targetHRP.Attachment or Instance.new("Attachment", targetHRP)
    BForce.RelativeTo = Enum.ActuatorRelativeTo.World
    BForce.Parent = targetHRP
    Debris:AddItem(BForce, 0.1) 
end

local FlingInput = FlingTab:Input("Target Username", "Username")
FlingTab:Button("Fling Player", function()
    local name = FlingInput.Instance.Text 
    local target = FindPlayer(name)
    if target and target.Character and target.Character.HumanoidRootPart then
        ApplyFling(target.Character.HumanoidRootPart)
    end
end)

FlingTab:Toggle("Fling Aura", false, function(Value) FlingAuraActive = Value; print("Fling Aura ON/OFF") end)
FlingTab:Slider("Radius", 1, 20, 0.5, function(Value) FlingAuraRadius = Value end, 10)
FlingTab:Slider("Power", 100, 10000, 100, function(Value) FlingPower = Value end, 500)


-- V. AC Bypass
local ACBypassTab = window:Tab("AC Bypass")
local function KillAC(state)
    if state then
        local hrp = Player.Character and Player.Character.HumanoidRootPart
        if hrp then hrp:SetNetworkOwner(Player) end
        pcall(setexecutorflags, "disableanticheat", true) 
    else
        pcall(setexecutorflags, "disableanticheat", false)
    end
end
ACBypassTab:Toggle("Disable Anti Cheat (Flag)", true, KillAC)
KillAC(true)


-- VI. General & VII. Credits
local GeneralTab = window:Tab("General")
local CreditsTab = window:Tab("Credits")

GeneralTab:Label("Configuration", "Sauvegarde et Chargement manuel de la configuration non supporté dans cette librairie minimaliste.")
GeneralTab:Button("Simuler Sauvegarde", function() print("INFO: Sauvegarde simulée.") end)

CreditsTab:Label("Developer", "Made by killer_gojo")
CreditsTab:Label("Version", "Simple Hub V0.4.2 (AppleLibrary)")
local DiscordLink = "ton_lien_discord_ici" 
CreditsTab:Button("Copy Discord Link", function() pcall(setclipboard, DiscordLink) end)

print("Simple Hub V0.4.2 (AppleLibrary) Loaded Successfully.")
