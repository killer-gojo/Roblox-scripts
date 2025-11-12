-- By killer_gojo
-- Simple Hub V0.4.2 - Adapté pour GameSneeze UI (KRNL Android/VNG)

-- ** CHARGEMENT DE LA LIBRAIRIE GAMESNEEZE **
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/frel0/gamesneeze-ui/main/main.lua"))()

-- Initialisation de la fenêtre. (Style 1, 7 pages car nous en aurons 6-7 pour l'organisation)
local Window = Library:New({
    Name = "Simple Hub V0.4.2", 
    Style = 1, 
    PageAmmount = 7, 
    Size = Vector2.new(554, 629)
})

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
-- PAGES (ONGLETS)
-- ====================================================================

local Main_Page = Window:Page({Name = "Main"})
local Teleport_Page = Window:Page({Name = "Teleport"})
local Fling_Page = Window:Page({Name = "Fling"})
local Visual_Page = Window:Page({Name = "Visual"})
local AC_Page = Window:Page({Name = "AC Bypass"})
local General_Page = Window:Page({Name = "General"})
local Credits_Page = Window:Page({Name = "Credits"})


-- ====================================================================
-- I. Main (Mouvement)
-- ====================================================================

local Mouvement_Section = Main_Page:Section({Name = "Mouvement Control", Fill = false, Side = "Left"})
local Float_Section = Main_Page:Section({Name = "Float / Fly", Fill = false, Side = "Right"})

local function SetWalkSpeed(speed) local human = Player.Character and Player.Character.Humanoid if human then human.WalkSpeed = speed end end
local function SetJumpPower(power) local human = Player.Character and Player.Character.Humanoid if human then human.JumpPower = power end end
local function SetGravity(gravity) Workspace.Gravity = gravity end

Mouvement_Section:Slider({Name = "WalkSpeed", Default = 16, Minimum = 16, Maximum = 200, Callback = SetWalkSpeed})
Mouvement_Section:Slider({Name = "JumpPower", Default = 50, Minimum = 50, Maximum = 500, Callback = SetJumpPower})
Mouvement_Section:Toggle({Name = "NoClip", Default = false, Callback = function(State) 
    local hrp = Player.Character and Player.Character.HumanoidRootPart 
    if hrp then hrp.CanCollide = not State end 
end})
Mouvement_Section:Slider({Name = "Gravity", Default = 196.2, Minimum = 0, Maximum = 196.2, Callback = SetGravity})

Float_Section:Slider({Name = "Float Speed", Default = 50, Minimum = 10, Maximum = 500, Callback = function(Value) CurrentFloatSpeed = Value end})

local function FlyLoop()
    local hrp = Player.Character and Player.Character.HumanoidRootPart
    if not hrp or not IsFloating then return end
    local velocity = Vector3.new(0, 0, 0)
    if UserInputService:IsKeyDown(Keybinds["FloatUp"]) then velocity = velocity + Vector3.new(0, CurrentFloatSpeed, 0) end
    if UserInputService:IsKeyDown(Keybinds["FloatDown"]) then velocity = velocity - Vector3.new(0, CurrentFloatSpeed, 0) end
    if velocity ~= Vector3.new(0, 0, 0) then hrp.CFrame = hrp.CFrame + velocity / 60 end
end

Float_Section:Toggle({Name = "Float / Fly (Space/LShift)", Default = false, Callback = function(Value)
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
end})


-- ====================================================================
-- II. Teleport
-- ====================================================================

local TP_Controls_Section = Teleport_Page:Section({Name = "TP Controls", Fill = false, Side = "Left"})
local Coords_Section = Teleport_Page:Section({Name = "Coordinates", Fill = false, Side = "Right"})

local InitialSpawnPosition = Player.Character and Player.Character.HumanoidRootPart.Position or Vector3.new(0, 50, 0)

-- TP to Cursor
local function TPToCursorLoop()
    if UserInputService:IsKeyDown(Keybinds["TPToCursor"]) then
        local mouse = Player:GetMouse()
        local targetPos = mouse.Hit.Position
        TeleportPlayer(targetPos)
    end
end

TP_Controls_Section:Toggle({Name = "TP to Cursor (Keybind: J)", Default = false, Callback = function(Value)
    if Value then RunService:BindToRenderStep("TPToCursorLoop", Enum.RenderPriority.Heartbeat.Value, TPToCursorLoop)
    else RunService:UnbindFromRenderStep("TPToCursorLoop") end
end})

TP_Controls_Section:Button({Name = "TP to Initial Spawn", Callback = function() TeleportPlayer(InitialSpawnPosition) end})
TP_Controls_Section:Button({Name = "Back to Old Pos", Callback = function() if OldPosition then TeleportPlayer(OldPosition) end end})

-- Coords
local XInput = Coords_Section:Input({Name = "X Coordinate", Default = "0"})
local YInput = Coords_Section:Input({Name = "Y Coordinate", Default = "0"})
local ZInput = Coords_Section:Input({Name = "Z Coordinate", Default = "0"})

Coords_Section:Button({Name = "Teleport to Coords", Callback = function()
    -- Accès au texte via la propriété .Value standard des Inputs GameSneeze
    local x, y, z = tonumber(XInput.Value) or 0, tonumber(YInput.Value) or 0, tonumber(ZInput.Value) or 0
    if x and y and z then TeleportPlayer(Vector3.new(x, y, z)) end
end})

-- Waypoints (GameSneeze a un PlayerList, mais pour les WP simples, nous allons le faire manuellement)
local WaypointsList = {}
local WP_Section = Teleport_Page:Section({Name = "Waypoints (Session Only)", Fill = false, Side = "Left"})
local WPNameInput = WP_Section:Input({Name = "Waypoint Name", Default = "New WP"})

WP_Section:Button({Name = "Create Waypoint", Callback = function()
    local name = WPNameInput.Value
    local currentPos = Player.Character and Player.Character.HumanoidRootPart.Position
    if not currentPos then return end
    local wpName = (name == "" or name == "Waypoint Name") and ("Waypoint " .. #WaypointsList + 1) or name
    local newWaypoint = {Name = wpName, X = currentPos.X, Y = currentPos.Y, Z = currentPos.Z}
    table.insert(WaypointsList, newWaypoint)
    
    -- Pour la simplicité, nous n'afficherons pas les WP dynamiquement ici, 
    -- car cela nécessiterait de reconstruire la section.
    print("Waypoint '" .. wpName .. "' created in memory.")
end})


-- ====================================================================
-- III. Fling
-- ====================================================================

local Fling_Section = Fling_Page:Section({Name = "Fling Controls", Fill = false, Side = "Left"})
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

local FlingInput = Fling_Section:Input({Name = "Target Username", Default = "Username"})
Fling_Section:Button({Name = "Fling Player", Callback = function()
    local name = FlingInput.Value 
    local target = FindPlayer(name)
    if target and target.Character and target.Character.HumanoidRootPart then
        ApplyFling(target.Character.HumanoidRootPart)
    end
end})

Fling_Section:Toggle({Name = "Fling Aura", Default = false, Callback = function(Value) FlingAuraActive = Value; print("Fling Aura ON/OFF") end})
Fling_Section:Slider({Name = "Radius", Default = 10, Minimum = 1, Maximum = 20, Callback = function(Value) FlingAuraRadius = Value end})
Fling_Section:Slider({Name = "Power", Default = 500, Minimum = 100, Maximum = 10000, Callback = function(Value) FlingPower = Value end})


-- ====================================================================
-- IV. Visuals
-- ====================================================================

local Visual_Section = Visual_Page:Section({Name = "Visuals (ESP/Chams)", Fill = true, Side = "Left"})
local IsESPActive, IsChamsActive, TeamESP = false, false, true

Visual_Section:Toggle({Name = "Player ESP", Default = IsESPActive, Callback = function(Value) IsESPActive = Value end})
Visual_Section:Toggle({Name = "Chams / X-Ray", Default = IsChamsActive, Callback = function(Value) IsChamsActive = Value end})
Visual_Section:Toggle({Name = "Draw Box", Default = true, Callback = function(Value) end})
Visual_Section:Toggle({Name = "Team ESP (Prioritaire)", Default = TeamESP, Callback = function(Value) TeamESP = Value end})


-- ====================================================================
-- V. AC Bypass
-- ====================================================================

local AC_Section = AC_Page:Section({Name = "Anti-Cheat Flags", Fill = true, Side = "Left"})

local function KillAC(state)
    if state then
        local hrp = Player.Character and Player.Character.HumanoidRootPart
        if hrp then hrp:SetNetworkOwner(Player) end
        pcall(setexecutorflags, "disableanticheat", true) 
    else
        pcall(setexecutorflags, "disableanticheat", false)
    end
end

AC_Section:Toggle({Name = "Disable Anti Cheat (Flag)", Default = true, Callback = KillAC})
KillAC(true)


-- ====================================================================
-- VI. General & VII. Credits
-- ====================================================================

local General_Section = General_Page:Section({Name = "Configuration", Fill = true, Side = "Left"})
local Credits_Section = Credits_Page:Section({Name = "Info", Fill = true, Side = "Left"})

General_Section:Label({Name = "Configuration: Sauvegarde désactivée pour la stabilité mobile."})

Credits_Section:Label({Name = "Made by killer_gojo"})
Credits_Section:Label({Name = "Version: Simple Hub V0.4.2 (GameSneeze UI)"})
local DiscordLink = "ton_lien_discord_ici" 
Credits_Section:Button({Name = "Copy Discord Link", Callback = function() pcall(setclipboard, DiscordLink) end})


-- ** INITIALISATION FINALE **
Window:Initialize()

print("Simple Hub V0.4.2 (GameSneeze UI) Loaded Successfully.")
