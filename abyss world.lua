local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Abyss World | Rayfield Edition",
    LoadingTitle = "Loading Script...",
    LoadingSubtitle = "by Gemini",
    ConfigurationSaving = {
        Enabled = false
    }
})

--// SERVICES & VARIABLES
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local SlowFallEnabled = false
local FallSpeed = -15
local PlatformEnabled = false
local CurrentPlatform = nil 
local FreecamEnabled = false
local FreecamSpeed = 1.5
local Sensitivity = 0.5
local RotationX, RotationY = 0, 0
local SavedCameraCFrame = nil
local Connections = {}

local SelectedCheckpoint = "1"
local SelectedPlayerName = nil

--// PRECISE CHECKPOINTS
local Checkpoints = {
    ["1"]  = CFrame.new(-11.140132904052734, 21259.896484375, -105.85986328125),
    ["2"]  = CFrame.new(40.798126220703125, 21018.896484375, -166.89073181152344),
    ["3"]  = CFrame.new(-298.2913818359375, 21000.396484375, -412.2913818359375),
    ["4"]  = CFrame.new(-39.2117919921875, 20785.66015625, -595.06103515625),
    ["5"]  = CFrame.new(-82.000244140625, 20348.896484375, -786.1665649414062),
    ["6"]  = CFrame.new(-205.73355102539062, 20046.224609375, -185.29971313476562),
    ["7"]  = CFrame.new(-413.6391296386719, 19802.685546875, -498.60394287109375),
    ["8"]  = CFrame.new(186.49972534179688, 19426.896484375, -79.00022888183594),
    ["9"]  = CFrame.new(-411.5937194824219, 19161.39453125, -552.9361572265625),
    ["10"] = CFrame.new(286.09747314453125, 19117.3125, -690.47705078125),
    ["11"] = CFrame.new(323.13824462890625, 18793.7578125, -281.29815673828125),
    ["12"] = CFrame.new(-297.1396484375, 18721.48046875, -724.7577514648438),
    ["13"] = CFrame.new(-59.4012451171875, 18442.255859375, -194.8866729736328),
    ["14"] = CFrame.new(-59.435054779052734, 17866.94921875, -795.0255737304688)
}

--// HELPER FUNCTIONS
local function TogglePlatform()
    local char = Player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if CurrentPlatform then
        CurrentPlatform:Destroy()
        CurrentPlatform = nil
    else
        CurrentPlatform = Instance.new("Part")
        CurrentPlatform.Name = "EmergencyPlatform"
        CurrentPlatform.Size = Vector3.new(15, 1, 15)
        CurrentPlatform.Anchored = true
        CurrentPlatform.CanCollide = true
        CurrentPlatform.Color = Color3.fromRGB(0, 255, 255)
        CurrentPlatform.Material = Enum.Material.ForceField
        CurrentPlatform.Parent = workspace
        CurrentPlatform.Position = root.Position - Vector3.new(0, 3.5, 0)
    end
end

local function ToggleFreecam()
    FreecamEnabled = not FreecamEnabled
    local char = Player.Character
    if FreecamEnabled then
        SavedCameraCFrame = Camera.CFrame
        local _, y, _ = Camera.CFrame:ToEulerAnglesYXZ()
        RotationY, RotationX = math.degrees(y), 0
        Camera.CameraType = Enum.CameraType.Scriptable
    else
        if SavedCameraCFrame then Camera.CFrame = SavedCameraCFrame end
        Camera.CameraType = Enum.CameraType.Custom
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        if char then
            for _, v in ipairs(char:GetDescendants()) do if v:IsA("BasePart") then v.Anchored = false end end
        end
    end
end

--// TABS
local PlayerTab = Window:CreateTab("Player")
local TeleportTab = Window:CreateTab("Teleport")
local EnvTab = Window:CreateTab("Environment")
local SettingsTab = Window:CreateTab("Settings")

--// PLAYER TAB
PlayerTab:CreateToggle({
    Name = "Slow Falling",
    CurrentValue = false,
    Callback = function(Value) SlowFallEnabled = Value end
})

PlayerTab:CreateToggle({
    Name = "Emergency Platform (Ctrl to Spawn)",
    CurrentValue = false,
    Callback = function(Value) 
        PlatformEnabled = Value 
        if not Value and CurrentPlatform then CurrentPlatform:Destroy(); CurrentPlatform = nil end
    end
})

PlayerTab:CreateSection("Spectator Mode")
PlayerTab:CreateToggle({
    Name = "Freecam (Press H)",
    CurrentValue = false,
    Callback = function(Value) if Value ~= FreecamEnabled then ToggleFreecam() end end
})

PlayerTab:CreateSlider({
    Name = "Fly Speed",
    Range = {1, 20},
    Increment = 0.5,
    CurrentValue = 1.5,
    Callback = function(Value) FreecamSpeed = Value end
})

PlayerTab:CreateSection("Get Wings")
PlayerTab:CreateButton({
    Name = "Collect All Transmitters",
    Callback = function()
        local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not firetouchinterest then return end
        for _, item in ipairs(workspace:GetDescendants()) do
            if item:IsA("TouchTransmitter") then
                firetouchinterest(item.Parent, root, 0); task.wait(); firetouchinterest(item.Parent, root, 1)
            end
        end
    end
})

--// TELEPORT TAB
TeleportTab:CreateSection("Checkpoints Teleport")
local CheckpointOptions = {"1","2","3","4","5","6","7","8","9","10","11","12","13","14"}
TeleportTab:CreateDropdown({
    Name = "Select Checkpoint",
    Options = CheckpointOptions,
    CurrentOption = "1",
    Callback = function(Option) SelectedCheckpoint = Option[1] end
})

TeleportTab:CreateButton({
    Name = "Teleport to Selected Checkpoint",
    Callback = function()
        local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if root and Checkpoints[SelectedCheckpoint] then
            root.Velocity = Vector3.zero
            root.CFrame = Checkpoints[SelectedCheckpoint]
        end
    end
})

TeleportTab:CreateSection("Player Teleport")
local function GetPlayerList()
    local tbl = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player then table.insert(tbl, p.Name) end
    end
    return tbl
end

TeleportTab:CreateDropdown({
    Name = "Select Player",
    Options = GetPlayerList(),
    CurrentOption = "",
    Callback = function(Option) SelectedPlayerName = Option[1] end
})

TeleportTab:CreateButton({
    Name = "Teleport to Selected Player",
    Callback = function()
        local target = Players:FindFirstChild(SelectedPlayerName or "")
        local targetRoot = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        local myRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot and myRoot then myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 3, 0) end
    end
})

--// ENVIRONMENT TAB
EnvTab:CreateToggle({
    Name = "Full Bright",
    CurrentValue = false,
    Callback = function(state)
        if state then
            Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 100000; Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        else
            Lighting.Brightness = 1; Lighting.ClockTime = 12; Lighting.FogEnd = 1000; Lighting.GlobalShadows = true
            Lighting.Ambient = Color3.fromRGB(0, 0, 0)
        end
    end
})

EnvTab:CreateToggle({
    Name = "Remove Fog",
    CurrentValue = false,
    Callback = function(state)
        Lighting.FogEnd = state and 100000 or 1000
    end
})

--// SETTINGS TAB
SettingsTab:CreateButton({
    Name = "Destroy GUI",
    Callback = function()
        for _, connection in pairs(Connections) do connection:Disconnect() end
        if CurrentPlatform then CurrentPlatform:Destroy() end
        local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if root then root.Anchored = false end
        Camera.CameraType = Enum.CameraType.Custom
        Rayfield:Destroy()
    end
})

--// LOGIC CONNECTIONS
Connections.FreecamMove = RunService.RenderStepped:Connect(function()
    if FreecamEnabled then
        local char = Player.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") and not p.Anchored then p.Anchored = true end end
        end
        if Camera.CameraType ~= Enum.CameraType.Scriptable then Camera.CameraType = Enum.CameraType.Scriptable end

        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        local delta = UserInputService:GetMouseDelta()
        RotationY = RotationY - (delta.X * Sensitivity)
        RotationX = math.clamp(RotationX - (delta.Y * Sensitivity), -80, 80)
        
        Camera.CFrame = CFrame.new(Camera.CFrame.Position) * CFrame.Angles(0, math.rad(RotationY), 0) * CFrame.Angles(math.rad(RotationX), 0, 0)

        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.yAxis end

        if move.Magnitude > 0 then Camera.CFrame += (move.Unit * FreecamSpeed) end
    end
end)

Connections.Input = UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.H then ToggleFreecam()
    elseif input.KeyCode == Enum.KeyCode.LeftControl and PlatformEnabled then TogglePlatform() end
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