-- By killer_gojo
-- Simple Hub V0.4.2 - Adapté pour Jan UI

-- ** CHARGEMENT DE LA LIBRAIRIE JAN UI **
local library = loadstring(game:HttpGet('https://garfieldscripts.xyz/ui-libs/janlib.lua'))()

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

local Main_Tab = library:AddTab("Main")
local Teleport_Tab = library:AddTab("Teleport")
local Fling_Tab = library:AddTab("Fling")
local Visual_Tab = library:AddTab("Visuals")
local Utility_Tab = library:AddTab("Utility & Credits")

-- ====================================================================
-- I. Main (Mouvement)
-- ====================================================================

local Main_Col1 = Main_Tab:AddColumn();
local Main_Section = Main_Col1:AddSection("Mouvement Control")

local function SetWalkSpeed(speed) local human = Player.Character and Player.Character.Humanoid if human then human.WalkSpeed = speed end end
local function SetJumpPower(power) local human = Player.Character and Player.Character.Humanoid if human then human.JumpPower = power end end
local function SetGravity(gravity) Workspace.Gravity = gravity end

Main_Section:AddDivider("Vitesse & Saut")

Main_Section:AddSlider{
    text = "WalkSpeed", 
    flag = "WalkSpeed", 
    min = 16, 
    max = 200, 
    value = 16, 
    callback = SetWalkSpeed
}

Main_Section:AddSlider{
    text = "JumpPower", 
    flag = "JumpPower", 
    min = 50, 
    max = 500, 
    value = 50, 
    callback = SetJumpPower
}

Main_Section:AddToggle{
    text = "NoClip", 
    flag = "NoClipEnabled", 
    callback = function(State) 
        local hrp = Player.Character and Player.Character.HumanoidRootPart 
        if hrp then hrp.CanCollide = not State end 
    end
}

Main_Section:AddSlider{
    text = "Gravity", 
    flag = "GravityValue", 
    min = 0, 
    max = 196.2, 
    value = 196.2, 
    callback = SetGravity
}


local Float_Section = Main_Col1:AddSection("Float / Fly")

Float_Section:AddDivider("Contrôles")

Float_Section:AddSlider{
    text = "Float Speed", 
    flag = "FloatSpeed", 
    min = 10, 
    max = 500, 
    value = 50, 
    callback = function(Value) CurrentFloatSpeed = Value end
}

local function FlyLoop()
    local hrp = Player.Character and Player.Character.HumanoidRootPart
    if not hrp or not IsFloating then return end
    local velocity = Vector3.new(0, 0, 0)
    if UserInputService:IsKeyDown(Keybinds["FloatUp"]) then velocity = velocity + Vector3.new(0, CurrentFloatSpeed, 0) end
    if UserInputService:IsKeyDown(Keybinds["FloatDown"]) then velocity = velocity - Vector3.new(0, CurrentFloatSpeed, 0) end
    if velocity ~= Vector3.new(0, 0, 0) then hrp.CFrame = hrp.CFrame + velocity / 60 end
end

Float_Section:AddToggle{
    text = "Float / Fly (Space/LShift)", 
    flag = "FloatEnabled",
    callback = function(Value)
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
    end
}

-- ====================================================================
-- II. Teleport
-- ====================================================================

local TP_Col1 = Teleport_Tab:AddColumn();
local TP_Section = TP_Col1:AddSection("Téléportation Rapide")

local InitialSpawnPosition = Player.Character and Player.Character.HumanoidRootPart.Position or Vector3.new(0, 50, 0)

-- TP to Cursor
local function TPToCursorLoop()
    if UserInputService:IsKeyDown(Keybinds["TPToCursor"]) then
        local mouse = Player:GetMouse()
        local targetPos = mouse.Hit.Position
        TeleportPlayer(targetPos)
    end
end

TP_Section:AddToggle{
    text = "TP to Cursor (Keybind: J)",
    flag = "TPToCursor",
    callback = function(Value)
        if Value then RunService:BindToRenderStep("TPToCursorLoop", Enum.RenderPriority.Heartbeat.Value, TPToCursorLoop)
        else RunService:UnbindFromRenderStep("TPToCursorLoop") end
    end
}

TP_Section:AddButton{
    text = "TP to Initial Spawn",
    callback = function() TeleportPlayer(InitialSpawnPosition) end
}

TP_Section:AddButton{
    text = "Back to Old Pos",
    callback = function() 
        if OldPosition then TeleportPlayer(OldPosition) end 
    end
}

-- Jan UI a des Listes, nous allons les utiliser pour une simple fonction de Waypoint (stockée en mémoire)
local WP_Col2 = Teleport_Tab:AddColumn();
local WP_Section = WP_Col2:AddSection("Waypoints (Mémoire)")
local WaypointsList = {}
local WP_List

WP_Section:AddBox{text = "Waypoint Name", flag = "NewWPName"}
WP_Section:AddButton{
    text = "Create Waypoint", 
    callback = function()
        local name = library.flags["NewWPName"] or "Waypoint"
        local currentPos = Player.Character and Player.Character.HumanoidRootPart.Position
        if not currentPos then return end
        
        local wpName = (name == "" or name == "Waypoint Name") and ("Waypoint " .. #WaypointsList + 1) or name
        local newWaypoint = {Name = wpName, Pos = currentPos}
        table.insert(WaypointsList, newWaypoint)
        
        -- Mettre à jour la liste des Waypoints
        local newValues = {}
        for _, wp in pairs(WaypointsList) do table.insert(newValues, wp.Name) end
        if WP_List then WP_List:SetValues(newValues) end
    end
}

WP_List = WP_Section:AddList({
    text = "Load Waypoint", 
    flag = "SelectedWP", 
    value = "None", 
    values = {"None"}
})

WP_Section:AddButton{
    text = "Teleport to Selected WP", 
    callback = function()
        local selectedName = library.flags["SelectedWP"]
        for _, wp in pairs(WaypointsList) do
            if wp.Name == selectedName then
                TeleportPlayer(wp.Pos)
                return
            end
        end
    end
}


-- ====================================================================
-- III. Fling
-- ====================================================================

local Fling_Col1 = Fling_Tab:AddColumn();
local Fling_Section = Fling_Col1:AddSection("Fling Controls")
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

Fling_Section:AddButton{
    text = "Fling Nearest Player",
    callback = function()
        local nearestTarget = nil
        local minDistance = math.huge
        local playerHRP = Player.Character and Player.Character.HumanoidRootPart
        
        if not playerHRP then return end
        
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= Player and p.Character and p.Character.HumanoidRootPart then
                local targetHRP = p.Character.HumanoidRootPart
                local distance = (playerHRP.Position - targetHRP.Position).Magnitude
                if distance < minDistance then
                    minDistance = distance
                    nearestTarget = targetHRP
                end
            end
        end
        
        if nearestTarget then
            ApplyFling(nearestTarget)
        end
    end
}

Fling_Section:AddDivider("Fling Aura")

Fling_Section:AddToggle{
    text = "Fling Aura", 
    flag = "FlingAuraEnabled", 
    callback = function(Value) FlingAuraActive = Value end
}

Fling_Section:AddSlider{
    text = "Radius", 
    flag = "FlingRadius", 
    min = 1, 
    max = 20, 
    value = 10, 
    callback = function(Value) FlingAuraRadius = Value end
}

Fling_Section:AddSlider{
    text = "Power", 
    flag = "FlingPower", 
    min = 100, 
    max = 10000, 
    value = 500, 
    callback = function(Value) FlingPower = Value end
}


-- ====================================================================
-- IV. Visuals
-- ====================================================================

local Visual_Col1 = Visual_Tab:AddColumn();
local Visual_Section = Visual_Col1:AddSection("Visuals (ESP/Chams)")

Visual_Section:AddToggle{text = "Player ESP", flag = "PlayerESP"}
Visual_Section:AddToggle{text = "Chams / X-Ray", flag = "Chams"}
Visual_Section:AddToggle{text = "Draw Box", flag = "DrawBox", value = true}
Visual_Section:AddToggle{text = "Team ESP (Prioritaire)", flag = "TeamESP"}


-- ====================================================================
-- V. Utility & Credits (Inclus dans un seul Tab)
-- ====================================================================

local Utility_Col1 = Utility_Tab:AddColumn();
local AC_Section = Utility_Col1:AddSection("AC Bypass")

local function KillAC(state)
    if state then
        local hrp = Player.Character and Player.Character.HumanoidRootPart
        if hrp then hrp:SetNetworkOwner(Player) end
        pcall(setexecutorflags, "disableanticheat", true) 
    else
        pcall(setexecutorflags, "disableanticheat", false)
    end
end

AC_Section:AddToggle{text = "Disable Anti Cheat (Flag)", flag = "AC_Bypass", value = true, callback = KillAC}
KillAC(true)


local Credit_Section = Utility_Col1:AddSection("Info & Credits")
Credit_Section:AddDivider("Infos")
Credit_Section:AddLabel{text = "Developer: killer_gojo"}
Credit_Section:AddLabel{text = "Version: Simple Hub V0.4.2 (Jan UI)"}
local DiscordLink = "ton_lien_discord_ici" 
Credit_Section:AddButton{
    text = "Copy Discord Link", 
    callback = function() pcall(setclipboard, DiscordLink) end
}


-- ** INITIALISATION FINALE **
library:Init()
library:selectTab(library.tabs[1])

print("Simple Hub V0.4.2 (Jan UI) Loaded Successfully.")
