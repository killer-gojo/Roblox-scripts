-- By killer_gojo
-- Simple Hub V0.4.2 - Adapté pour AppleLibrary (Interface à Sections)

-- ** CHARGEMENT DE LA LIBRAIRIE APPLELIBRARY **
local library = loadstring(game:HttpGet("https://github.com/GoHamza/AppleLibrary/blob/main/main.lua?raw=true"))()

-- Initialisation de la fenêtre. (RightShift pour afficher/cacher)
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
    window:TempNotify("Téléportation", "Téléporté à la nouvelle position.", "rbxassetid://6037042858")
end

-- ====================================================================
-- I. AC Bypass (Section Indépendante)
-- ====================================================================

window:Divider("AC Bypass")

local function KillAC(state)
    if state then
        local hrp = Player.Character and Player.Character.HumanoidRootPart
        if hrp then hrp:SetNetworkOwner(Player) end
        pcall(setexecutorflags, "disableanticheat", true) 
        window:TempNotify("AC Bypass", "Anti-Cheat Local OFF", "rbxassetid://6037042858")
    else
        pcall(setexecutorflags, "disableanticheat", false)
    end
end
window:Switch("Disable Anti Cheat (Flag)", true, KillAC)
KillAC(true)


-- ====================================================================
-- II. Main (Mouvement)
-- ====================================================================

local MainSection = window:Section("Main: Mouvement")

local function SetWalkSpeed(speed) local human = Player.Character and Player.Character.Humanoid if human then human.WalkSpeed = speed end end
local function SetJumpPower(power) local human = Player.Character and Player.Character.Humanoid if human then human.JumpPower = power end end
local function SetGravity(gravity) Workspace.Gravity = gravity end

MainSection:Slider("WalkSpeed", 16, 200, 1, SetWalkSpeed, 16)
MainSection:Slider("JumpPower", 50, 500, 5, SetJumpPower, 50)
MainSection:Switch("NoClip", false, function(Value) local hrp = Player.Character and Player.Character.HumanoidRootPart if hrp then hrp.CanCollide = not Value end end)

MainSection:Divider("Float Controls")

MainSection:Slider("Float Speed", 10, 500, 5, function(Value) CurrentFloatSpeed = Value end, 50)

local function FlyLoop()
    local hrp = Player.Character and Player.Character.HumanoidRootPart
    if not hrp or not IsFloating then return end
    local velocity = Vector3.new(0, 0, 0)
    if UserInputService:IsKeyDown(Keybinds["FloatUp"]) then velocity = velocity + Vector3.new(0, CurrentFloatSpeed, 0) end
    if UserInputService:IsKeyDown(Keybinds["FloatDown"]) then velocity = velocity - Vector3.new(0, CurrentFloatSpeed, 0) end
    if velocity ~= Vector3.new(0, 0, 0) then hrp.CFrame = hrp.CFrame + velocity / 60 end
end

MainSection:Switch("Float / Fly (Space/LShift)", false, function(Value)
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

MainSection:Slider("Gravity", 0, 196.2, 1, SetGravity, 196.2)


-- ====================================================================
-- III. Teleport & Waypoints
-- ====================================================================

local TeleportSection = window:Section("Teleport & Waypoints")
local InitialSpawnPosition = Player.Character and Player.Character.HumanoidRootPart.Position or Vector3.new(0, 50, 0)

-- TP to Cursor
local function TPToCursorLoop()
    if UserInputService:IsKeyDown(Keybinds["TPToCursor"]) then
        local mouse = Player:GetMouse()
        local targetPos = mouse.Hit.Position
        TeleportPlayer(targetPos)
    end
end

TeleportSection:Switch("TP to Cursor (Keybind: J)", false, function(Value)
    if Value then RunService:BindToRenderStep("TPToCursorLoop", Enum.RenderPriority.Heartbeat.Value, TPToCursorLoop)
    else RunService:UnbindFromRenderStep("TPToCursorLoop") end
end)
TeleportSection:Button("TP to Initial Spawn", function() TeleportPlayer(InitialSpawnPosition) end)

TeleportSection:Divider("Coordinates & Back")

local XInput = TeleportSection:TextField("X Coordinate", "0")
local YInput = TeleportSection:TextField("Y Coordinate", "0")
local ZInput = TeleportSection:TextField("Z Coordinate", "0")

TeleportSection:Button("Teleport to Coords", function()
    -- Utilisation de l'accès au texte comme montré dans l'exemple TextField
    local x, y, z = tonumber(XInput.Instance.Text) or 0, tonumber(YInput.Instance.Text) or 0, tonumber(ZInput.Instance.Text) or 0
    if x and y and z then TeleportPlayer(Vector3.new(x, y, z)) end
end)
TeleportSection:Button("Back to Old Pos", function() 
    if OldPosition then TeleportPlayer(OldPosition) end 
end)

-- Waypoints (In-Memory for mobile stability)
local WaypointsList = {}
TeleportSection:Divider("Waypoints (Session Only)")
local WPNameInput = TeleportSection:TextField("Waypoint Name", "New WP")

TeleportSection:Button("Create Waypoint", function()
    local name = WPNameInput.Instance.Text
    local currentPos = Player.Character and Player.Character.HumanoidRootPart.Position
    if not currentPos then return end
    local wpName = (name == "" or name == "Waypoint Name") and ("Waypoint " .. #WaypointsList + 1) or name
    local newWaypoint = {Name = wpName, X = currentPos.X, Y = currentPos.Y, Z = currentPos.Z}
    table.insert(WaypointsList, newWaypoint)
    window:TempNotify("Waypoint", "Waypoint '" .. wpName .. "' créé en mémoire.", "rbxassetid://6037042858")
    
    -- Ajout du bouton de TP au fur et à mesure pour la session
    TeleportSection:Button("TP to: " .. wpName, function()
        TeleportPlayer(Vector3.new(newWaypoint.X, newWaypoint.Y, newWaypoint.Z))
    end)
end)


-- ====================================================================
-- IV. Fling
-- ====================================================================

local FlingSection = window:Section("Fling / Anti-Grief")
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

local FlingInput = FlingSection:TextField("Target Username", "Username")
FlingSection:Button("Fling Player", function()
    local name = FlingInput.Instance.Text 
    local target = FindPlayer(name)
    if target and target.Character and target.Character.HumanoidRootPart then
        ApplyFling(target.Character.HumanoidRootPart)
        window:TempNotify("Fling", "Fling appliqué à " .. target.DisplayName, "rbxassetid://6037042858")
    else
        window:TempNotify("Erreur", "Cible non trouvée ou non chargée.", "rbxassetid://6037042858")
    end
end)

FlingSection:Switch("Fling Aura", false, function(Value) FlingAuraActive = Value; print("Fling Aura ON/OFF") end)
FlingSection:Slider("Radius", 1, 20, 0.5, function(Value) FlingAuraRadius = Value end, 10)
FlingSection:Slider("Power", 100, 10000, 100, function(Value) FlingPower = Value end, 500)


-- ====================================================================
-- V. Visuals
-- ====================================================================

local VisualSection = window:Section("Visuals (ESP/Chams)")
local IsESPActive, IsChamsActive, TeamESP = false, false, true
local function UpdateVisuals(name, Value) print("Visuals logic called for: " .. name .. " - " .. tostring(Value)) end

VisualSection:Switch("Player ESP", IsESPActive, function(Value) IsESPActive = Value; UpdateVisuals("Player ESP", Value) end)
VisualSection:Switch("Chams / X-Ray", IsChamsActive, function(Value) IsChamsActive = Value; UpdateVisuals("Chams", Value) end)
VisualSection:Switch("Draw Box", true, function(Value) UpdateVisuals("Draw Box", Value) end)
VisualSection:Switch("Team ESP (Prioritaire)", TeamESP, function(Value) TeamESP = Value; UpdateVisuals("Team ESP", Value) end)


-- ====================================================================
-- VI. General & Credits
-- ====================================================================

window:Divider("General & Credits")

window:Label("Configuration", "Sauvegarde de la configuration désactivée pour la compatibilité mobile.")
window:Label("Developer", "Made by killer_gojo")
window:Label("Version", "Simple Hub V0.4.2 (AppleLibrary)")
local DiscordLink = "ton_lien_discord_ici" 
window:Button("Copy Discord Link", function() pcall(setclipboard, DiscordLink) end)

print("Simple Hub V0.4.2 (AppleLibrary) Loaded Successfully.")
