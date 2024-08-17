-- Create a new ScreenGui
local gui = Instance.new("ScreenGui")
gui.Name = "MyGUI"
gui.Parent = game:GetService("Players").LocalPlayer.PlayerGui

-- Create a new Frame
local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.BackgroundColor3 = Color3.new(0, 0, 0)
frame.Size = UDim2.new(0, 500, 0, 300)
frame.Position = UDim2.new(0, 50, 0, 50)
frame.Parent = gui

-- Create Button1 for ESP activation/deactivation
local button1 = Instance.new("TextButton")
button1.Name = "Button1"
button1.Text = "Toggle ESP"
button1.BackgroundColor3 = Color3.new(152/255, 23/255, 153/255)
button1.Size = UDim2.new(0, 100, 0, 30)
button1.Position = UDim2.new(0, 10, 0, 10)
button1.Parent = frame

-- Create Button2 for Aimbot activation/deactivation
local button2 = Instance.new("TextButton")
button2.Name = "Button2"
button2.Text = "Toggle Aimbot"
button2.BackgroundColor3 = Color3.new(23/255, 152/255, 23/255)
button2.Size = UDim2.new(0, 100, 0, 30)
button2.Position = UDim2.new(0, 10, 0, 50)
button2.Parent = frame

-- Variables to track states
local espEnabled = false
local aimbotEnabled = false
local currentTarget = nil

-- Function to create an ESP box around the player's head
local function drawBox(player)
    if player == game.Players.LocalPlayer then return end  -- Don't draw on the local player

    -- Ensure the player has a character
    local character = player.Character
    if not character or not character:FindFirstChild("Head") then return end

    -- Create BillboardGui for ESP
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_" .. player.Name
    billboard.Size = UDim2.new(0, 50, 0, 50)  -- Adjust size for the head
    billboard.AlwaysOnTop = true
    billboard.Adornee = character.Head  -- Attach the BillboardGui to the head
    billboard.Parent = game.Workspace

    -- Create a Frame as the box
    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 0.5
    frame.BackgroundColor3 = Color3.new(1, 0, 0)  -- Red box
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Parent = billboard

    -- Cleanup when player leaves
    player.AncestryChanged:Connect(function()
        if not player:IsDescendantOf(game) then
            billboard:Destroy()
        end
    end)
end

-- Function to activate ESP for all players
local function activateESP()
    -- Add ESP to existing players
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        drawBox(player)
    end

    -- Add ESP to new players when they join
    game:GetService("Players").PlayerAdded:Connect(function(player)
        drawBox(player)
    end)
end

-- Function to deactivate ESP for all players
local function deactivateESP()
    -- Remove all ESP BillboardGuis
    for _, v in pairs(game.Workspace:GetChildren()) do
        if v:IsA("BillboardGui") and v.Name:sub(1, 4) == "ESP_" then
            v:Destroy()
        end
    end
end

-- Function to perform a raycast and check if the player's head is visible
local function isTargetVisible(player)
    local character = player.Character
    if character and character:FindFirstChild("Head") then
        local origin = workspace.CurrentCamera.CFrame.Position
        local target = character.Head.Position

        -- Perform raycast
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {game.Players.LocalPlayer.Character}  -- Ignore the local player
        rayParams.FilterType = Enum.RaycastFilterType.Blacklist

        local rayResult = workspace:Raycast(origin, target - origin, rayParams)

        -- If nothing is hit by the raycast or the hit part is the target's head, the player is visible
        if not rayResult or rayResult.Instance:IsDescendantOf(character) then
            return true
        end
    end
    return false
end

-- Function to get the closest visible player on the enemy team
local function getClosestVisibleEnemyPlayer()
    local closestPlayer = nil
    local closestDistance = math.huge
    local localPlayer = game.Players.LocalPlayer

    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        -- Check if the player is not the local player, is on a different team, and is visible
        if player ~= localPlayer and player.Team ~= localPlayer.Team and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (player.Character.HumanoidRootPart.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
            if distance < closestDistance and isTargetVisible(player) then
                closestDistance = distance
                closestPlayer = player
            end
        end
    end

    return closestPlayer
end

-- Function to rotate the player's character to face the target smoothly
local function aimAtPlayerThirdPerson(player)
    if player and player.Character and player.Character:FindFirstChild("Head") then
        local localPlayer = game.Players.LocalPlayer
        local character = localPlayer.Character

        if character and character:FindFirstChild("HumanoidRootPart") then
            local humanoidRootPart = character.HumanoidRootPart
            local targetPosition = player.Character.Head.Position

            -- Calculate the direction vector from the character to the target
            local direction = (targetPosition - humanoidRootPart.Position).Unit

            -- Smoothly rotate the character towards the target
            local lookAt = CFrame.new(humanoidRootPart.Position, humanoidRootPart.Position + Vector3.new(direction.X, 0, direction.Z))
            humanoidRootPart.CFrame = humanoidRootPart.CFrame:Lerp(lookAt, 0.1)  -- Smoothly rotate the character
        end
    end
end

-- Connect button presses to toggle ESP
button1.MouseButton1Click:Connect(function()
    if espEnabled then
        deactivateESP()
        espEnabled = false
        button1.Text = "Enable ESP"
    else
        activateESP()
        espEnabled = true
        button1.Text = "Disable ESP"
    end
end)

-- Connect button presses to toggle Aimbot
button2.MouseButton1Click:Connect(function()
    if aimbotEnabled then
        aimbotEnabled = false
        currentTarget = nil  -- Reset target
        button2.Text = "Enable Aimbot"
    else
        aimbotEnabled = true
        button2.Text = "Disable Aimbot"
    end
end)

-- Get the camera and user input service
local camera = workspace.CurrentCamera
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")

-- Variable to track mouse button state
local rightMouseButtonDown = false

-- Connect input events for aimbot
userInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        rightMouseButtonDown = true
        if not currentTarget then
            currentTarget = getClosestVisibleEnemyPlayer()  -- Lock on to the closest visible enemy when RMB is first pressed
        end
    end
end)

userInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        rightMouseButtonDown = false
        currentTarget = nil  -- Reset target when RMB is released
    end
end)

-- Run the aimbot during each frame
runService.RenderStepped:Connect(function()
    if aimbotEnabled and rightMouseButtonDown and currentTarget then
        aimAtPlayerThirdPerson(currentTarget)  -- Smoothly rotate the character towards the locked target in third-person
    end
end)
