--// SERVICES
local library = loadstring(game:HttpGet('https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wall%20v3'))()
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

--// WINDOW SETUP
local w = library:CreateWindow("Abyss World")

--// VARIABLES
local SlowFallEnabled = false
local FallSpeed = -15
local WaypointPos = nil 
local Connections = {}
local selectedPlayerName = nil
local PlatformEnabled = false
local CurrentPlatform = nil -- Added missing variable definition
local Lighting = game:GetService("Lighting")
local OriginalFogEnd = Lighting.FogEnd
local OriginalBrightness = Lighting.Brightness
local OriginalClockTime = Lighting.ClockTime
local OriginalAmbient = Lighting.Ambient

--// WAYPOINT SETTINGS
local WaypointPart = Instance.new("Part")
WaypointPart.Name = "CustomWaypoint"
WaypointPart.Size = Vector3.new(2, 2, 2)
WaypointPart.Shape = Enum.PartType.Ball
WaypointPart.Color = Color3.fromRGB(0, 255, 0)
WaypointPart.Material = Enum.Material.Neon
WaypointPart.Transparency = 0.5
WaypointPart.CanCollide = false
WaypointPart.Anchored = true
WaypointPart.Parent = nil

--// PLATFORM FUNCTION
local function TogglePlatform()
    local char = Player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if CurrentPlatform then
        CurrentPlatform:Destroy()
        CurrentPlatform = nil
    else
        CurrentPlatform = Instance.new("Part")
        CurrentPlatform.Name = "FollowPlatform"
        CurrentPlatform.Size = Vector3.new(15, 1, 15)
        CurrentPlatform.Anchored = true
        CurrentPlatform.CanCollide = true
        CurrentPlatform.Color = Color3.fromRGB(0, 255, 255)
        CurrentPlatform.Material = Enum.Material.ForceField
        CurrentPlatform.Parent = workspace
        CurrentPlatform.Position = root.Position - Vector3.new(0, 3.5, 0)
    end
end

--// CHECKPOINT DATA
local Checkpoints = {
    ["Checkpoint 1"]  = CFrame.new(-11.140, 21259.896, -105.859),
    ["Checkpoint 2"]  = CFrame.new(40.798, 21018.896, -166.890),
    ["Checkpoint 3"]  = CFrame.new(-298.291, 21000.396, -412.291),
    ["Checkpoint 4"]  = CFrame.new(-39.211, 20785.660, -595.061),
    ["Checkpoint 5"]  = CFrame.new(-82.000, 20348.896, -786.166),
    ["Checkpoint 6"]  = CFrame.new(-205.733, 20046.224, -185.299),
    ["Checkpoint 7"]  = CFrame.new(-413.639, 19802.685, -498.603),
    ["Checkpoint 8"]  = CFrame.new(186.499, 19426.896, -79.000),
    ["Checkpoint 9"]  = CFrame.new(-411.593, 19161.394, -552.936),
    ["Checkpoint 10"] = CFrame.new(286.097, 19117.312, -690.477),
    ["Checkpoint 11"] = CFrame.new(323.138, 18793.757, -281.298),
    ["Checkpoint 12"] = CFrame.new(-297.139, 18721.480, -724.757),
    ["Checkpoint 13"] = CFrame.new(-59.401, 18442.255, -194.886),
    ["Checkpoint 14"] = CFrame.new(-59.435, 17866.949, -795.025)
}

local CheckpointNames = {}
for name, _ in pairs(Checkpoints) do table.insert(CheckpointNames, name) end
table.sort(CheckpointNames, function(a, b) 
    local numA = tonumber(a:match("%d+")) or 0
    local numB = tonumber(b:match("%d+")) or 0
    return numA < numB 
end)

--// UI SECTIONS
local movement = w:CreateFolder("Movement")
movement:Toggle("Enable Slow Falling", function(state) SlowFallEnabled = state end)
movement:Toggle("Emergency Platform", function(state)
    PlatformEnabled = state
    if not state and CurrentPlatform then CurrentPlatform:Destroy(); CurrentPlatform = nil end
end)

local waypointFolder = w:CreateFolder("Waypoints")
waypointFolder:Button("Clear Waypoint", function() WaypointPos = nil; WaypointPart.Parent = nil end)

local tpFolder = w:CreateFolder("Teleports")
local selectedCheckpoint = "Checkpoint 1"
tpFolder:Dropdown("Select Checkpoint", CheckpointNames, function(selected) selectedCheckpoint = selected end)
tpFolder:Button("Teleport to Selected", function()
    local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if root and Checkpoints[selectedCheckpoint] then root.CFrame = Checkpoints[selectedCheckpoint] end
end)

--// PLAYER TP FOLDER
local pvp = w:CreateFolder("Player TP")

-- This function grabs fresh names every time you open the dropdown
local function getPlayerNames()
    local names = {}
    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        if p ~= Player then 
            table.insert(names, p.Name)
        end
    end
    return names
end

pvp:Dropdown("Select Player", getPlayerNames(), function(selected)
    selectedPlayerName = selected -- Correctly stores the string name
end)

pvp:Button("Teleport to Player", function()
    -- We look for the player object using the name stored from the dropdown
    local target = game:GetService("Players"):FindFirstChild(selectedPlayerName or "")
    local targetRoot = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    local myRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    
    if targetRoot and myRoot then
        -- Teleport 3 studs above them to avoid physics glitches
        myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 3, 0)
    else
        warn("Target player or character not found.")
    end
end)

local wings = w:CreateFolder("Get Wings")
wings:Button("Collect All Transmitters", function()
    local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not firetouchinterest then return end
    for _, item in ipairs(workspace:GetDescendants()) do
        if item:IsA("TouchTransmitter") then
            firetouchinterest(item.Parent, root, 0); task.wait(); firetouchinterest(item.Parent, root, 1)
        end
    end
end)

local envFolder = w:CreateFolder("Environment")
--// FULL BRIGHT TOGGLE
envFolder:Toggle("Full Bright", function(state)
    if state then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    else
        Lighting.Brightness = OriginalBrightness
        Lighting.ClockTime = OriginalClockTime
        Lighting.FogEnd = OriginalFogEnd
        Lighting.GlobalShadows = true
        Lighting.Ambient = OriginalAmbient
    end
end)

--// REMOVE FOG TOGGLE
envFolder:Toggle("Remove Fog", function(state)
    if state then
        Lighting.FogEnd = 100000 -- Pushes fog so far back you can't see it
    else
        Lighting.FogEnd = OriginalFogEnd -- Restores original atmosphere
    end
end)

local settings = w:CreateFolder("Settings")
settings:Button("Close", function()
    for _, connection in pairs(Connections) do connection:Disconnect() end
    if CurrentPlatform then CurrentPlatform:Destroy() end
    WaypointPart:Destroy()
    local ui = game:GetService("CoreGui"):FindFirstChild("Abyss World") or Player.PlayerGui:FindFirstChild("Abyss World")
    if ui then ui:Destroy() end
    -- Add this inside your Close button function
    Lighting.Brightness = OriginalBrightness
    Lighting.ClockTime = OriginalClockTime
    Lighting.FogEnd = OriginalFogEnd
    Lighting.GlobalShadows = true
    Lighting.Ambient = OriginalAmbient
end)

--// LOGIC CONNECTIONS
Connections.Input = UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    local char = Player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if input.KeyCode == Enum.KeyCode.T then
        WaypointPos = root.CFrame
        WaypointPart.CFrame = root.CFrame
        WaypointPart.Parent = workspace
    elseif input.KeyCode == Enum.KeyCode.LeftShift then
        if WaypointPos then root.Velocity = Vector3.zero; root.CFrame = WaypointPos end
    elseif input.KeyCode == Enum.KeyCode.LeftControl then
        if PlatformEnabled then TogglePlatform() end -- Fixed the floating elseif error
    end
end)

Connections.SlowFall = RunService.Stepped:Connect(function()
    if SlowFallEnabled then
        local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if root and root.Velocity.Y < FallSpeed then
            root.Velocity = Vector3.new(root.Velocity.X, FallSpeed, root.Velocity.Z)
        end
    end
end)

Connections.PlatformFollow = RunService.Heartbeat:Connect(function()
    if CurrentPlatform and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        local root = Player.Character.HumanoidRootPart
        CurrentPlatform.Position = Vector3.new(root.Position.X, CurrentPlatform.Position.Y, root.Position.Z)
    end
end)