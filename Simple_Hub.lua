-- By killer_gojo

-- ** PATCH: Chargement Rayfield plus stable **
local HttpService = game:GetService("HttpService")
local RayfieldSource = game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source', true)
local Rayfield = loadstring(RayfieldSource)()
-- ** FIN PATCH **

local Player = game.Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local SaveFolderName = "killer_gojo_V042_Hub"
local WaypointsFileName = "waypoints.json"
local WaypointsFilePath = Rayfield.GetConfigFolder() .. "\\" .. SaveFolderName .. "\\" .. WaypointsFileName

local InitialSpawnPosition = Player.Character and Player.Character.HumanoidRootPart.Position or Vector3.new(0, 50, 0)
local OldPosition, CurrentFloatSpeed, IsFloating, FlyLoopConn = nil, 50, false, nil

local Keybinds = {["FloatUp"] = Enum.KeyCode.Space, ["FloatDown"] = Enum.KeyCode.LeftShift, ["TPToCursor"] = Enum.KeyCode.J}

local Window = Rayfield:CreateWindow({
    Name = "Simple Hub V0.4.2", LoadingTitle = "Loading V0.4.2", LoadingSubtitle = "by killer_gojo",
    ConfigurationSaving = {Enabled = true, FolderName = SaveFolderName, FileName = "config"},
    Discord = {Enabled = false}, KeySystem = false 
})

-- FONCTIONS COMMUNES
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

-- FONCTIONS WAYPOINTS
local WaypointsList = {}
local success, content = pcall(readfile, WaypointsFilePath)
if success and content and content ~= "" then
    local decoded = Rayfield:Decode(content)
    if type(decoded) == "table" then WaypointsList = decoded end
end

local function SaveWaypoints()
    writefile(WaypointsFilePath, Rayfield:Encode(WaypointsList))
end

-- V. AC Bypass
local ACBypassTab = Window:CreateTab("AC Bypass", 4483362458) 

local function KillAC(state)
    if state then
        local hrp = Player.Character and Player.Character.HumanoidRootPart
        if hrp then hrp:SetNetworkOwner(Player) end
        pcall(setexecutorflags, "disableanticheat", true) 
        Rayfield:Notify({Title = "AC Bypass", Content = "Anti-Cheat Local Disabled (ON par défaut).", Duration = 3})
    else
        pcall(setexecutorflags, "disableanticheat", false)
        Rayfield:Notify({Title = "AC Bypass", Content = "Anti-Cheat Local Enabled.", Duration = 3})
    end
end

ACBypassTab:CreateToggle({Name = "Disable Anti Cheat", CurrentValue = true, Flag = "DisableAC", Callback = KillAC})
KillAC(true)

-- I. Main
local MainTab = Window:CreateTab("Main", 4483362458)
local function SetWalkSpeed(speed) local human = Player.Character and Player.Character.Humanoid if human then human.WalkSpeed = speed end end
local function SetJumpPower(power) local human = Player.Character and Player.Character.Humanoid if human then human.JumpPower = power end end
local function SetGravity(gravity) Workspace.Gravity = gravity end

MainTab:CreateSlider({Name = "WalkSpeed", Range = {16, 200}, Increment = 1, Suffix = "Studs/s", CurrentValue = 16, Flag = "WalkSpeedSlider", Callback = SetWalkSpeed})
MainTab:CreateSlider({Name = "JumpPower", Range = {50, 500}, Increment = 5, Suffix = "Power", CurrentValue = 50, Flag = "JumpPowerSlider", Callback = SetJumpPower})
MainTab:CreateToggle({Name = "NoClip", CurrentValue = false, Flag = "NoClipToggle", Callback = function(Value) local hrp = Player.Character and Player.Character.HumanoidRootPart if hrp then hrp.CanCollide = not Value end end})
MainTab:CreateSlider({Name = "Float Speed", Range = {10, 500}, Increment = 5, Suffix = "Speed", CurrentValue = CurrentFloatSpeed, Flag = "FloatSpeedSlider", Callback = function(Value) CurrentFloatSpeed = Value end})

local function FlyLoop()
    local hrp = Player.Character and Player.Character.HumanoidRootPart
    if not hrp or not IsFloating then return end
    local velocity = Vector3.new(0, 0, 0)
    if UserInputService:IsKeyDown(Keybinds["FloatUp"]) then velocity = velocity + Vector3.new(0, CurrentFloatSpeed, 0) end
    if UserInputService:IsKeyDown(Keybinds["FloatDown"]) then velocity = velocity - Vector3.new(0, CurrentFloatSpeed, 0) end
    if velocity ~= Vector3.new(0, 0, 0) then hrp.CFrame = hrp.CFrame + velocity / 60 end
end

MainTab:CreateToggle({
    Name = "Float / Fly (Space / LShift)", CurrentValue = false, Flag = "FloatToggle",
    Callback = function(Value)
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
    end,
})

MainTab:CreateSlider({Name = "Gravity", Range = {0, 196.2}, Increment = 1, Suffix = "Grav", CurrentValue = 196.2, Flag = "GravitySlider", Callback = SetGravity})

-- II. Visual
local VisualTab = Window:CreateTab("Visual", 4483362458)
local IsESPActive, IsChamsActive, ESPColor, TeamESP = false, false, Color3.new(1, 0, 0), true
local function UpdateVisuals() print("INFO: Visuals Update logic called.") end

VisualTab:CreateToggle({Name = "Player ESP", CurrentValue = IsESPActive, Flag = "PlayerESP", Callback = function(Value) IsESPActive = Value; UpdateVisuals() end})
VisualTab:CreateToggle({Name = "Chams / X-Ray", CurrentValue = IsChamsActive, Flag = "ChamsToggle", Callback = function(Value) IsChamsActive = Value; UpdateVisuals() end})
VisualTab:CreateToggle({Name = "Draw Box", CurrentValue = true, Flag = "DrawBox", Callback = UpdateVisuals})
VisualTab:CreateToggle({Name = "Team ESP (Prioritaire)", CurrentValue = TeamESP, Flag = "TeamESP", Callback = function(Value) TeamESP = Value; UpdateVisuals() end})
VisualTab:CreateColorPicker({Name = "ESP Color", Color = ESPColor, Flag = "ESPColor", Callback = function(Color) ESPColor = Color; UpdateVisuals() end})

-- IV. Fling
local FlingTab = Window:CreateTab("Fling", 4483362458)
local FlingPower, FlingAuraRadius, FlingAuraActive = 500, 10, false

local function ApplyFling(targetHRP)
    if not FlingAuraActive then pcall(ToggleInstability, true) delay(0.5, pcall, ToggleInstability, false) end
    local FlingMagnitude = FlingPower * 100 
    local BForce = Instance.new("VectorForce")
    BForce.Force = Vector3.new(0, FlingMagnitude, 0)
    BForce.Attachment0 = targetHRP.Attachment or Instance.new("Attachment", targetHRP)
    BForce.RelativeTo = Enum.ActuatorRelativeTo.World
    BForce.Parent = targetHRP
    Debris:AddItem(BForce, 0.1) 
end
local function ToggleInstability(state) print("INFO: Toggle Instability " .. (state and "ON" or "OFF")) end

FlingTab:CreateInput({Name = "Target Player", PlaceholderText = "Username", RemoveTextAfterFocusLost = false})
FlingTab:CreateButton({
    Name = "Fling",
    Callback = function()
        local name = FlingTab:GetInput("Target Player").Instance.Text 
        local target = FindPlayer(name)
        if target and target.Character and target.Character.HumanoidRootPart then
            ApplyFling(target.Character.HumanoidRootPart)
            Rayfield:Notify({Title = "Fling", Content = "Fling appliqué à " .. target.DisplayName, Duration = 3})
        else
            Rayfield:Notify({Title = "Erreur Fling", Content = "Cible non trouvée.", Duration = 3})
        end
    end,
})

FlingTab:CreateToggle({
    Name = "Fling Aura", CurrentValue = false, Flag = "FlingAuraToggle",
    Callback = function(Value)
        FlingAuraActive = Value
        if Value then pcall(ToggleInstability, true) else pcall(ToggleInstability, false) end
        print("INFO: Fling Aura ON/OFF")
    end,
})

FlingTab:CreateSlider({Name = "Radius", Range = {1, 20}, Increment = 0.5, Suffix = "Studs", CurrentValue = FlingAuraRadius, Flag = "FlingRadiusSlider", Callback = function(Value) FlingAuraRadius = Value end})
FlingTab:CreateToggle({Name = "Touch to Fling (Furtif)", CurrentValue = false, Flag = "TouchFlingToggle", Callback = function(Value) print("INFO: Touch to Fling ON/OFF") end})
FlingTab:CreateSlider({Name = "Power", Range = {100, 10000}, Increment = 1, Suffix = "Force", CurrentValue = FlingPower, Flag = "FlingPowerSlider", Callback = function(Value) FlingPower = Value end})

-- III. Teleport
local TeleportTab = Window:CreateTab("Teleport", 4483362458)

local function TPToCursorLoop()
    if UserInputService:IsKeyDown(Keybinds["TPToCursor"]) then
        local mouse = Player:GetMouse()
        local targetPos = mouse.Hit.Position
        if (Player.Character.HumanoidRootPart.Position - targetPos).magnitude < 5000 then
            TeleportPlayer(targetPos)
        else
            Rayfield:Notify({Title = "Erreur TP", Content = "TP annulé : Trop loin (> 5000 studs)", Duration = 2})
        end
    end
end

local TPCursorToggle = TeleportTab:CreateToggle({
    Name = "TP to Cursor (Keybind: J)", CurrentValue = false, Flag = "TPCursorToggle", 
    Callback = function(Value)
        if Value then RunService:BindToRenderStep("TPToCursorLoop", Enum.RenderPriority.Heartbeat.Value, TPToCursorLoop)
        else RunService:UnbindFromRenderStep("TPToCursorLoop") end
    end,
})
TeleportTab:CreateButton({Name = "TP to Initial Spawn", Callback = function() TeleportPlayer(InitialSpawnPosition) Rayfield:Notify({Title = "Spawn", Content = "Téléporté à votre position de spawn initiale.", Duration = 3}) end})

local CoordsSection = TeleportTab:CreateSection("Coordinates / Back")
CoordsSection:CreateToggle({Name = "Show Coords (Draggable)", CurrentValue = false, Flag = "ShowCoordsToggle", Callback = function(Value) print("INFO: Coords display ON/OFF") end})
local XInput = CoordsSection:CreateInput({Name = "X", PlaceholderText = "X Coordinate", RemoveTextAfterFocusLost = false, Flag = "CoordX"})
local YInput = CoordsSection:CreateInput({Name = "Y", PlaceholderText = "Y Coordinate", RemoveTextAfterFocusLost = false, Flag = "CoordY"})
local ZInput = CoordsSection:CreateInput({Name = "Z", PlaceholderText = "Z Coordinate", RemoveTextAfterFocusLost = false, Flag = "CoordZ"})

CoordsSection:CreateButton({
    Name = "Teleport",
    Callback = function()
        local x, y, z = tonumber(XInput.Instance.Text) or 0, tonumber(YInput.Instance.Text) or 0, tonumber(ZInput.Instance.Text) or 0
        if x and y and z then
            TeleportPlayer(Vector3.new(x, y, z))
            Rayfield:Notify({Title = "TP Coords", Content = "Téléporté à X:"..x.." Y:"..y.." Z:"..z, Duration = 3})
        else
            Rayfield:Notify({Title = "Erreur Saisie", Content = "Veuillez entrer des coordonnées numériques valides.", Duration = 3})
        end
    end,
})
CoordsSection:CreateButton({
    Name = "Back to Old Pos",
    Callback = function()
        if OldPosition then
            Player.Character.HumanoidRootPart.CFrame = CFrame.new(OldPosition) * CFrame.Angles(0, 0, 0)
            Rayfield:Notify({Title = "Retour", Content = "Retour à la position précédente.", Duration = 3})
        else
            Rayfield:Notify({Title = "Retour", Content = "Aucune ancienne position enregistrée.", Duration = 3})
        end
    end,
})

local WaypointSection = TeleportTab:CreateSection("WAYPOINTS") 
local WPNameInput = WaypointSection:CreateInput({Name = "Create a Waypoint", PlaceholderText = "Name", RemoveTextAfterFocusLost = false})

WaypointSection:CreateButton({
    Name = "Create",
    Callback = function()
        local name = WPNameInput.Instance.Text
        local currentPos = Player.Character and Player.Character.HumanoidRootPart.Position
        if not currentPos then return end
        local wpName = (name == "" or name == "Name") and ("Waypoint " .. #WaypointsList + 1) or name
        local newWaypoint = {Name = wpName, X = math.floor(currentPos.X * 10) / 10, Y = math.floor(currentPos.Y * 10) / 10, Z = math.floor(currentPos.Z * 10) / 10}
        table.insert(WaypointsList, newWaypoint)
        SaveWaypoints()
        RenderWaypoints() 
        Rayfield:Notify({Title = "Waypoint", Content = "Waypoint '" .. wpName .. "' créé!", Duration = 3})
    end,
})

local WaypointSections = {}
function RenderWaypoints()
    for _, section in pairs(WaypointSections) do section:Destroy() end
    WaypointSections = {}

    for i, wp in ipairs(WaypointsList) do
        local wpSection = TeleportTab:CreateSection(wp.Name .. " ("..wp.Y.." Y)") 
        table.insert(WaypointSections, wpSection)
        wpSection:CreateButton({Name = "Teleport", Callback = function() TeleportPlayer(Vector3.new(wp.X, wp.Y, wp.Z)) Rayfield:Notify({Title = "TP Waypoint", Content = "Téléporté à " .. wp.Name, Duration = 3}) end})
        wpSection:CreateButton({
            Name = "Delete",
            Callback = function()
                table.remove(WaypointsList, i)
                SaveWaypoints()
                RenderWaypoints() 
                Rayfield:Notify({Title = "Waypoint", Content = "Waypoint '" .. wp.Name .. "' supprimé.", Duration = 3})
            end,
        })
    end
end
RenderWaypoints()

-- VI. General
local GeneralTab = Window:CreateTab("General", 4483362458)
local ConfigSection = GeneralTab:CreateSection("Configuration File")
ConfigSection:CreateButton({Name = "Save Config", Callback = function() Rayfield:SaveConfiguration() Rayfield:Notify({Title = "Config", Content = "Configuration générale sauvegardée (Fichier: config.json).", Duration = 3}) end})
ConfigSection:CreateButton({Name = "Load Config", Callback = function() Rayfield:LoadConfiguration() Rayfield:Notify({Title = "Config", Content = "Configuration générale rechargée (Fichier: config.json).", Duration = 3}) end})

-- VII. Credits
local CreditsTab = Window:CreateTab("Credits", 4483362458)
CreditsTab:CreateParagraph({Title = "Made by killer_gojo", Content = "Simple Hub Version 0.4.2"})
local DiscordLink = "ton_lien_discord_ici" 
CreditsTab:CreateButton({Name = "Copy Discord Link", Callback = function() pcall(setclipboard, DiscordLink) Rayfield:Notify({Title = "Discord", Content = "Lien Discord copié dans le presse-papiers!", Duration = 3}) end})

-- VIII. FINALISATION
if TPCursorToggle.CurrentValue then RunService:BindToRenderStep("TPToCursorLoop", Enum.RenderPriority.Heartbeat.Value, TPToCursorLoop) end
