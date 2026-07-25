local AdminusUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/sigmapoopyman69/blox-fruits/refs/heads/main/gui.lua"
))()

local SETTINGS = _G.FruitSniperSettings or {
    Team = "Pirates",
    Fruits = {}
}

local TEAM = SETTINGS.Team

local args = {
    [1] = "SetTeam",
    [2] = SETTINGS.Team
}
task.wait(0.3)
game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer(unpack(args))

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")
local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
local TWEEN_SPEED = 250
local ENABLE_ESP = true
local Status = self.Status
local TweenStatus = self.TweenStatus
local StoreStatus = self.StoringStatus
local FruitType = self.FruitType
local DistanceText = self.FruitDistance
local AllFruits = {
    "Rocket Fruit","Spin Fruit","Blade Fruit","Spring Fruit","Bomb Fruit",
    "Smoke Fruit","Spike Fruit","Flame Fruit","Ice Fruit","Sand Fruit",
    "Dark Fruit","Eagle Fruit","Diamond Fruit","Light Fruit","Rubber Fruit",
    "Ghost Fruit","Magma Fruit","Quake Fruit","Buddah Fruit","Love Fruit",
    "Creation Fruit","Spider Fruit","Sound Fruit","Pheonix Fruit","Portal Fruit",
    "Lightning Fruit","Pain Fruit","Blizzard Fruit","Gravity Fruit","Mammoth Fruit",
    "T-Rex Fruit","Dough Fruit","Shadow Fruit","Venom Fruit","Gas Fruit","Spirit Fruit",
    "Tiger Fruit","Yeti Fruit","Kitsune Fruit","Control Fruit","Dragon Fruit"
}

local function IsAllowedFruit(fruitName)
    return SETTINGS.Fruits[fruitName] == true
end

local function ServerHop()
local API, HttpService, TeleportService, CoreGui = nil, game:GetService("HttpService"), game:GetService("TeleportService"), game:GetService("CoreGui");
local RemoveErrorPrompts = true --prevents error messages from popping up.
local IterationSpeed = 0.25 --speed in which next server is picked for teleport (the higher it is the slower the teleports but more likely to work).
local ExcludefullServers = true --slightly beneficial if the game is high ccu or mid ccu, if not, set to false.
local SaveTeleportAttempts = false --saves every teleports that are attempted in jobid to "Attempts.txt" file
local API = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"

local function EncodeToFile(JSONString)
local success, JSONData = pcall(function()
    return HttpService:JSONDecode(JSONString)
end)
if success and JSONData.data then
    JSONData.gameId = game.PlaceId
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(JSONData)
    end)
    if success then
        writefile("Servers.JSON", encoded)
    else
        warn("Failed to encode JSON string.")
        return nil
    end
else
    warn("Failed to decode JSONData.")
    return nil
end
return JSONData
end

local function NextCursor(ep)
    return game:HttpGet(API .. "&excludeFullGames=" .. tostring(ExcludefullServers) .. ((ep and "&cursor=" .. ep) or ""))
end

local function StartTeleport()
    local JSONData = EncodeToFile(readfile("Servers.JSON"))
    if not JSONData then
        writefile("Servers.JSON", game:HttpGet(API))
        StartTeleport()
    end
    for i = 0, 99 do
        if #JSONData.data <= 1 then
            EncodeToFile(NextCursor(JSONData.nextPageCursor))
            TeleportService:Teleport(game.PlaceId, game.Players.LocalPlayer)
        end
        if JSONData.data[i] then
            local JobId = JSONData.data[i].id
            table.remove(JSONData.data, i)
            local sucess, encoded = pcall(function()
                return HttpService:JSONEncode(JSONData)
            end)
            writefile("Servers.JSON", encoded)
            if SaveTeleportAttempts then
                appendfile("Attempts.txt", JobId .. "\n")
            end
            TeleportService:TeleportToPlaceInstance(game.PlaceId, JobId, game.Players.LocalPlayer)
            task.wait(IterationSpeed)
        end
    end
end

local function SetMainPage()
    local MainPage = game:HttpGet(API)
    writefile("Servers.JSON", MainPage)
    StartTeleport()
end

if RemoveErrorPrompts then CoreGui:WaitForChild("RobloxGui"):WaitForChild("Modules"):WaitForChild("ErrorPrompt"):Destroy() CoreGui.RobloxPromptGui:Destroy() end

if isfile("Servers.JSON") then
    local success, JSONData = pcall(function()
        return HttpService:JSONDecode(readfile("Servers.JSON"))
    end)
    if success and JSONData then
        if JSONData.gameId ~= game.PlaceId then
            warn("Game mismatch from cache, remaking cache for --> " .. game.PlaceId)
            SetMainPage()
        end
        if JSONData.data and #JSONData.data >= 1 then
            StartTeleport()
        else
            if success and JSONData.nextPageCursor then
                EncodeToFile(NextCursor(JSONData.nextPageCursor))
                StartTeleport()
            else
                SetMainPage() --no more pages left, start over
            end
        end
    else
        SetMainPage()
    end
else
    SetMainPage()
end
end

local function IsFruit(tool)
    return tool:IsA("Tool")
        and tool:FindFirstChild("Handle")
        and string.find(tool.Name,"Fruit")
end

local function GetAllFruits()
    local fruits = {}
    for _,v in pairs(Workspace:GetChildren()) do
        if IsFruit(v) then
            table.insert(fruits,v)
        end
    end
    return fruits
end

local function GetBestFruit(fruits)
    for _,fruit in pairs(fruits) do
        if IsAllowedFruit(fruit.Name) then
            return fruit
        end
    end
    return nil
end

local function CreateESP(fruit)
    if not ENABLE_ESP then return end
    if fruit:FindFirstChild("FruitESP") then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "FruitESP"
    billboard.Size = UDim2.new(0,200,0,50)
    billboard.AlwaysOnTop = true
    billboard.Parent = fruit.Handle

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255,100,255)
    label.TextStrokeTransparency = 0
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Text = fruit.Name
    label.Parent = billboard
end

local function TweenTo(position)
    local distance = (HRP.Position - position).Magnitude

    if distance > 15000 then
        local teleportPos = Vector3.new(3952, 2, -1785)
        local tpDistance = (HRP.Position - teleportPos).Magnitude
        local tpTime = tpDistance / TWEEN_SPEED

        local tpTween = TweenService:Create(
            HRP,
            TweenInfo.new(tpTime, Enum.EasingStyle.Linear),
            {CFrame = CFrame.new(teleportPos)}
        )

        DistanceText.Text = 'Fruit Distance: <font color="rgb(255,255,255)" weight="Regular">'..math.floor(tpDistance)..'</font>'
        TweenStatus.Text = 'Tweening Status: <font color="rgb(0,170,255)" weight="Regular">Tweening...</font>'

        tpTween:Play()
        tpTween.Completed:Wait()

        distance = (HRP.Position - position).Magnitude
    end

    local time = distance / TWEEN_SPEED

    local tween = TweenService:Create(
        HRP,
        TweenInfo.new(time, Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(position)}
    )

    DistanceText.Text = 'Fruit Distance: <font color="rgb(255,255,255)" weight="Regular">'..math.floor(distance)..'</font>'
    TweenStatus.Text = 'Tweening Status: <font color="rgb(0,170,255)" weight="Regular">Tweening...</font>'

    tween:Play()
    tween.Completed:Wait()

    TweenStatus.Text = 'Tweening Status: <font color="rgb(0,255,0)" weight="Regular">Tweening done</font>'
end

local function StoreFruit(fruit)
    local success,err = pcall(function()
        CommF:InvokeServer(
            "StoreFruit",
            fruit:GetAttribute("OriginalName"),
            fruit
        )
    end)

    if not success then
        StoreStatus.Text = 'Storing Status: <font color="rgb(255,255,0)" weight="Regular">Failed storing fruit... </font>'..err
    end
end

local function Main()
    Status.Text = 'Status: <font color="rgb(255,255,0)" weight="Regular">Searching fruit...</font>'

    local fruits = GetAllFruits()

    if #fruits == 0 then
        Status.Text = 'Status: <font color="rgb(255,0,0)" weight="Regular">No fruit found, server hopping...</font>'
        task.wait(2)
        ServerHop()
        return
    end

    for _,fruit in pairs(fruits) do
        CreateESP(fruit)
    end

    local target = GetBestFruit(fruits)

    if not target then
        Status.Text = 'Status: <font color="rgb(255,0,0)" weight="Regular">No allowed fruits found, server hopping...</font>'
        task.wait(2)
        ServerHop()
        return
    end

    Status.Text = 'Status: <font color="rgb(0,255,0)" weight="Regular">Fruit found</font>'
    FruitType.Text = 'Fruit Type: <font color="rgb(0,255,0)" weight="Regular">'..target.Name..'</font>'

    TweenTo(target.Handle.Position)

    task.wait(1)
    StoreFruit(target)

    StoreStatus.Text = 'Storing Status: <font color="rgb(0,255,0)" weight="Regular">Fruit Stored</font>'

    task.wait(2)
    ServerHop()
end

Main()
