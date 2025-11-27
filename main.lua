local workspace = game:GetService("Workspace")
local lighting = game:GetService("Lighting")
local players = game:GetService("Players")
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")
local gameplayFolder = workspace:WaitForChild("GameplayFolder", 60)
local roomsFolder = gameplayFolder:WaitForChild("Rooms", 60)
local monstersFolder = gameplayFolder:WaitForChild("Monsters", 60)

local player = players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local char = player.Character or player.CharacterAdded:Wait()

-- FULLBRIGHT
lighting.Brightness = 2
lighting.ClockTime = 14
lighting.FogEnd = 100000
lighting.GlobalShadows = false
lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)

local function splitCamelCase(name)
    return name:gsub("(%l)(%u)", "%1 %2")
end

local function CreateNotification(text, color, duration)
    duration = duration or 2.5
    color = color or Color3.fromRGB(255, 0, 0)

    local gui = Instance.new("ScreenGui")
    gui.Name = "NotificationGui"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 120)
    label.Position = UDim2.new(0, 0, 0.3, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = color
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Text = text
    label.TextStrokeTransparency = 0.5
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.TextTransparency = 1
    label.Parent = gui

    local fadeIn = tweenService:Create(label, TweenInfo.new(0.25), {TextTransparency = 0, TextStrokeTransparency = 0.5})
    fadeIn:Play()

    fadeIn.Completed:Connect(function()
        task.delay(duration, function()
            local fadeOut = tweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = 1, TextStrokeTransparency = 1})
            fadeOut:Play()
            fadeOut.Completed:Connect(function()
                gui:Destroy()
            end)
        end)
    end)
end

local function createESP(target, color, customName)
    local b = Instance.new("BillboardGui")
    b.Name = "ESPBillboard"
    b.Adornee = target
    b.AlwaysOnTop = true
    b.Size = UDim2.new(0, 100, 0, 100)
    b.Parent = target

    local f = Instance.new("Frame")
    f.Parent = b
    f.AnchorPoint = Vector2.new(0.5, 0.5)
    f.BackgroundColor3 = color or Color3.new(1, 1, 1)
    f.Position = UDim2.new(0.5, 0, 0.5, 0)
    f.Size = UDim2.new(0, 10, 0, 10)

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0)
    c.Parent = f

    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.5, 0.5, 0.5))
    g.Rotation = 90
    g.Parent = f

    local s = Instance.new("UIStroke")
    s.Thickness = 2.5
    s.Parent = f

    local l = Instance.new("TextLabel")
    l.Parent = b
    l.AnchorPoint = Vector2.new(0, 0.5)
    l.BackgroundTransparency = 1
    l.Position = UDim2.new(0, 0, 0.5, 24)
    l.Size = UDim2.new(1, 0, 0.2, 0)
    l.Text = customName or splitCamelCase(target.Name)
    l.TextColor3 = color or Color3.new(1, 1, 1)
    l.TextScaled = true

    local ls = Instance.new("UIStroke")
    ls.Thickness = 2.5
    ls.Parent = l

    return b
end

local function createTracer(target, color)
    local function getTargetPosition(obj)
        if obj:IsA("Model") then
            if obj.PrimaryPart then
                return obj.PrimaryPart.Position
            else
                return obj:GetPivot().Position
            end
        elseif obj:IsA("BasePart") then
            return obj.Position
        end
        return nil
    end

    if not Drawing then
        warn("Drawing API not available; tracers disabled")
        return nil, nil
    end

    local tracer = Drawing.new("Line")
    tracer.Color = color
    tracer.Thickness = 2
    tracer.Visible = true

    local connection
    connection = runService.RenderStepped:Connect(function()
        local targetPos = getTargetPosition(target)
        if targetPos then
            local viewportPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(targetPos)
            if viewportPos.Z > 0 then
                local screenCenter = Vector2.new(
                    workspace.CurrentCamera.ViewportSize.X / 2,
                    (workspace.CurrentCamera.ViewportSize.Y / 2) + 30
                )
                tracer.From = screenCenter
                tracer.To = Vector2.new(viewportPos.X, viewportPos.Y)
                tracer.Visible = true
            else
                tracer.Visible = false
            end
        end
    end)

    local ancestryConn
    ancestryConn = target.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if tracer then
                pcall(function() tracer:Remove() end)
            end
            if connection then
                pcall(function() connection:Disconnect() end)
            end
            if ancestryConn then ancestryConn:Disconnect() end
        end
    end)

    return tracer, connection
end

-- DISABLE SHARKS (figure out how to do this :pensive:)
local function handleShark(shark)
    local eyefest = shark:WaitForChild("Eyefestation")
    if not eyefest then
        return
    end
    local active = eyefest:WaitForChild("Active")
    if active then
        active.Value = false
    end
end

local function handleDoor(door)
    local esp = createESP(door, Color3.fromRGB(0, 0, 255), "Door")
    local tracer, connection = createTracer(door, Color3.fromRGB(0, 0, 255))
    local openValue = door:WaitForChild("OpenValue", 5)
    if not openValue then
        return
    end
    if openValue.Value == true then
        esp:Destroy()
        tracer:Remove()
        connection:Disconnect()
        return
    end
    openValue:GetPropertyChangedSignal("Value"):Connect(function()
        if openValue.Value == true then
            esp:Destroy()
            tracer:Remove()
            connection:Disconnect()
        end
    end)
end

local function processEntrance(door)
    task.spawn(function()
        handleDoor(door)
    end)
end

local function detectItem(v)
    if v:WaitForChild("ProxyPart", 5) then
        local interactionType = v:GetAttribute("InteractionType")

        if interactionType == "CurrencyBase" then
            local amount = v:GetAttribute("Amount")
            local name = "$" .. amount
            local color

            if amount < 25 then
                color = Color3.fromRGB(0, 100, 0)
            elseif amount < 50 then
                color = Color3.fromRGB(255, 150, 0)
            elseif amount < 100 then
                color = Color3.fromRGB(255, 255, 100)
            elseif amount < 500 then
                color = Color3.fromRGB(255, 255, 100)
            else
                color = Color3.fromRGB(255, 0, 255)
            end

            createESP(v, color, name)
        elseif interactionType == "KeyCard" then
            createESP(v, Color3.fromRGB(0, 150, 200), "Keycard")
        elseif interactionType == "PasswordPaper" then
            createESP(v, Color3.fromRGB(0, 150, 200), "Password")
        elseif interactionType == "InnerKeyCard" then
            createESP(v, Color3.fromRGB(0, 150, 200), "Purple Keycard")
        elseif interactionType == "ItemBase" then
            createESP(v, Color3.fromRGB(150, 255, 100))
        elseif interactionType == "Battery" then
            createESP(v, Color3.fromRGB(125, 100, 50), "Battery")
        else
            createESP(v)
        end
    end
end

local function handleSpawn(spawn)
    for _,v in ipairs(spawn:GetChildren()) do
        detectItem(v)
    end
    spawn.ChildAdded:Connect(function(v)
        detectItem(v)
    end)
end

local function handleSpawnLocation(spawnLocation)
    for _,v in ipairs(spawnLocation:GetChildren()) do
        handleSpawn(v)
    end
    spawnLocation.ChildAdded:Connect(function(v)
        handleSpawn(v)
    end)
end

local function handleRoom(room)
    local entrancesFolder = room:WaitForChild("Entrances")
    for _, door in ipairs(entrancesFolder:GetChildren()) do
        processEntrance(door)
    end
    entrancesFolder.ChildAdded:Connect(function(child)
        processEntrance(child)
    end)
    for _,v in ipairs(room:GetDescendants()) do
        if v.Name == "SpawnLocations" and v:IsA("Folder") then
            handleSpawnLocation(v)
        end
    end
    room.DescendantAdded:Connect(function(v)
        if v.Name == "SpawnLocations" and v:IsA("Folder") then
            handleSpawnLocation(v)
        end
    end)
end

for _, room in ipairs(roomsFolder:GetChildren()) do
    task.spawn(function()
        handleRoom(room)
    end)
end

roomsFolder.ChildAdded:Connect(function(newRoom)
    task.spawn(function()
        handleRoom(newRoom)
    end)
end)

local workspaceTargetList = {
    { Name = "Angler", Color = Color3.fromRGB(255, 0, 0), Label = "Angler" },
    { Name = "RidgeAngler", Color = Color3.fromRGB(255, 0, 0), Label = "Angler" },
    { Name = "Pinkie", Color = Color3.fromRGB(255, 0, 0), Label = "Pinkie" },
    { Name = "RidgePinkie", Color = Color3.fromRGB(255, 0, 0), Label = "Pinkie" },
    { Name = "Chainsmoker", Color = Color3.fromRGB(255, 0, 0), Label = "Chainsmoker" },
    { Name = "RidgeChainsmoker", Color = Color3.fromRGB(255, 0, 0), Label = "Chainsmoker" },
    { Name = "Froger", Color = Color3.fromRGB(255, 0, 0), Label = "Froger" },
    { Name = "RidgeFroger", Color = Color3.fromRGB(255, 0, 0), Label = "Froger" },
    { Name = "Blitz", Color = Color3.fromRGB(255, 0, 0), Label = "Blitz" },
    { Name = "RidgeBlitz", Color = Color3.fromRGB(255, 0, 0), Label = "Blitz" },
    { Name = "Pandemonium", Color = Color3.fromRGB(255, 0, 0), Label = "Pandemonium", remove = true },
    { Name = "RidgePandemonium", Color = Color3.fromRGB(255, 0, 0), Label = "Pandemonium", remove = true },
    { Name = "A60", Color = Color3.fromRGB(255, 0, 0), Label = "A60" },
    { Name = "RidgeA60", Color = Color3.fromRGB(255, 0, 0), Label = "A60" },
    { Name = "Pipsqueak", Color = Color3.fromRGB(255, 0, 0), Label = "Pipsqueak", remove = true },
    { Name = "Parasite", Color = Color3.fromRGB(255, 0, 0), Label = "Parasite", remove = true },
    { Name = "Mirage", Color = Color3.fromRGB(255, 0, 0), Label = "Mirage", CustomLabel = "Keep fucking moving dumbass" },
    { Name = "RidgeMirage", Color = Color3.fromRGB(255, 0, 0), Label = "Mirage", CustomLabel = "Keep fucking moving dumbass"  },
    { Name = "Harbinger", Color = Color3.fromRGB(255, 0, 0), Label = "Harbinger", CustomLabel = "ur cooked. give up" },
    { Name = "RidgeHarbinger", Color = Color3.fromRGB(255, 0, 0), Label = "Harbinger", CustomLabel = "ur cooked. give up" },
}

local function normalizeName(str)
    return str:lower():gsub("%s+", "")
end

local function findTarget(target, childName, callback)
    task.spawn(function()
        local found = childName and target:WaitForChild(childName, 1) or target
        callback(found)
    end)
end

workspace.ChildAdded:Connect(function(child)
    task.spawn(function()
        if not (child:IsA("BasePart") or child:IsA("Model")) then return end
        for _, target in ipairs(workspaceTargetList) do
            if normalizeName(child.Name) == normalizeName(target.Name) then
                local txt = target.CustomLabel or target.Label
                CreateNotification(txt, target.Color, 2.5)
                if target.remove then
                    child:Destroy()
                    return
                end
                findTarget(child, target.ChildName, function(targetchild)
                    if targetchild then
                        createESP(targetchild, target.Color, target.Label)
                        createTracer(targetchild, target.Color)
                    end
                end)
                return
            end
        end
    end)
end)

-- TODO: fix existing items not getting an esp