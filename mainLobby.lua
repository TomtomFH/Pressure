local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local teleRoot = workspace.Teleporters
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local uiCons = {}
local teleCons = {}

local function connectSet(set, sig, fn)
    local c = sig:Connect(fn)
    table.insert(set, c)
    return c
end

local function cleanup(set)
    for _, c in ipairs(set) do
        c:Disconnect()
    end
    table.clear(set)
end

local exitEvent = game.ReplicatedStorage:WaitForChild("Events"):WaitForChild("ExitMatch")

local screen = Instance.new("ScreenGui")
screen.Name = "TeleporterPlayerUI"
screen.IgnoreGuiInset = true
screen.Parent = playerGui

local holder = Instance.new("Frame")
holder.Size = UDim2.new(0, 260, 0, 380)
holder.Position = UDim2.new(0, 30, 0, 90)
holder.BackgroundColor3 = Color3.fromRGB(25,25,25)
holder.BorderSizePixel = 0
holder.Parent = screen

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,10)
corner.Parent = holder

local bottomDrag = Instance.new("Frame")
bottomDrag.Size = UDim2.new(1, 0, 0, 20)
bottomDrag.Position = UDim2.new(0, 0, 1, -20)
bottomDrag.BackgroundColor3 = Color3.fromRGB(50,50,50)
bottomDrag.BorderSizePixel = 0
bottomDrag.Parent = holder

local dragCorner = Instance.new("UICorner")
dragCorner.CornerRadius = UDim.new(0, 6)
dragCorner.Parent = bottomDrag

local dragging = false
local dragStartPos = nil
local uiStartPos = nil

connectSet(uiCons, bottomDrag.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStartPos = input.Position
        uiStartPos = holder.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

connectSet(uiCons, game:GetService("UserInputService").InputChanged, function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStartPos
        holder.Position = UDim2.new(uiStartPos.X.Scale, uiStartPos.X.Offset + delta.X,
                                     uiStartPos.Y.Scale, uiStartPos.Y.Offset + delta.Y)
    end
end)

local search = Instance.new("TextBox")
search.Size = UDim2.new(1, -20, 0, 32)
search.Position = UDim2.new(0, 10, 0, 10)
search.PlaceholderText = "Search"
search.Text = ""
search.BackgroundColor3 = Color3.fromRGB(35,35,35)
search.TextColor3 = Color3.new(1,1,1)
search.BorderSizePixel = 0
search.Parent = holder

local searchCorner = Instance.new("UICorner")
searchCorner.CornerRadius = UDim.new(0,6)
searchCorner.Parent = search

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -70)
scroll.Position = UDim2.new(0, 10, 0, 50)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.ScrollBarThickness = 6
scroll.ScrollBarImageColor3 = Color3.fromRGB(100,100,100)
scroll.Parent = holder

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = scroll
listLayout.Padding = UDim.new(0,6)

local selectedPlayer = nil

local function matchPlayer(plr)
    local t = search.Text:lower()
    local n1 = plr.Name:lower()
    local n2 = plr.DisplayName:lower()
    return t == "" or n1:find(t) or n2:find(t)
end

local function updateCanvas()
    scroll.CanvasSize = UDim2.new(0,0,0,listLayout.AbsoluteContentSize.Y)
end

local function buildUI()
    for _, c in ipairs(scroll:GetChildren()) do
        if c:IsA("Frame") then
            c:Destroy()
        end
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if matchPlayer(plr) then
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 40)
            row.BackgroundColor3 = plr == selectedPlayer and Color3.fromRGB(0,120,255) or Color3.fromRGB(40,40,40)
            row.BorderSizePixel = 0
            row.Parent = scroll

            local cr = Instance.new("UICorner")
            cr.CornerRadius = UDim.new(0,6)
            cr.Parent = row

            local avatar = Instance.new("ImageLabel")
            avatar.Size = UDim2.new(0, 32, 0, 32)
            avatar.Position = UDim2.new(0, 4, 0.5, -16)
            avatar.BackgroundTransparency = 1
            avatar.Parent = row

            spawn(function()
                avatar.Image = "rbxthumb://type=AvatarHeadShot&id="..plr.UserId.."&w=150&h=150"
            end)

            local name = Instance.new("TextLabel")
            name.BackgroundTransparency = 1
            name.Position = UDim2.new(0, 42, 0, 0)
            name.Size = UDim2.new(1, -42, 1, 0)
            name.Text = plr.DisplayName.." (@"..plr.Name..")"
            name.TextColor3 = Color3.new(1,1,1)
            name.TextXAlignment = Enum.TextXAlignment.Left
            name.Parent = row

            connectSet(uiCons, row.InputBegan, function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    if selectedPlayer == plr then
                        selectedPlayer = nil
                        row.BackgroundColor3 = Color3.fromRGB(40,40,40)
                        print("Deselected "..plr.Name)
                        return
                    end
                    selectedPlayer = plr
                    for _, x in ipairs(scroll:GetChildren()) do
                        if x:IsA("Frame") then
                            x.BackgroundColor3 = Color3.fromRGB(40,40,40)
                        end
                    end
                    row.BackgroundColor3 = Color3.fromRGB(0,120,255)
                    print("Selected "..plr.Name)
                end
            end)
        end
    end

    updateCanvas()
end

connectSet(uiCons, listLayout:GetPropertyChangedSignal("AbsoluteContentSize"), updateCanvas)
connectSet(uiCons, search:GetPropertyChangedSignal("Text"), buildUI)

local function bindTeleporter(t)
    local target = t.Main.BillboardGui.Frame.Frame
    connectSet(teleCons, target.ChildAdded, function(c)
        if selectedPlayer and c.Name == selectedPlayer.Name then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                print("Firing touch from me to "..t.Name.." for "..selectedPlayer.Name)
                firetouchinterest(hrp, t.Main, 1)
            end
        end
    end)
    connectSet(teleCons, target.ChildRemoved, function(c)
        if selectedPlayer and c.Name == selectedPlayer.Name then
            print("Player image removed for "..selectedPlayer.Name..", firing ExitMatch")
            exitEvent:FireServer()
        end
    end)
end

for _, t in ipairs(teleRoot:GetChildren()) do
    bindTeleporter(t)
end

connectSet(uiCons, Players.PlayerAdded, buildUI)
connectSet(uiCons, Players.PlayerRemoving, function(plr)
    if plr == selectedPlayer then
        selectedPlayer = nil
    end
    buildUI()
end)

buildUI()

connectSet(uiCons, screen.AncestryChanged, function(_, parent)
    if not parent then
        cleanup(uiCons)
        cleanup(teleCons)
    end
end)
