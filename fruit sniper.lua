local AdminusUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/sigmapoopyman69/blox-fruits/refs/heads/main/gui.lua"
))()

local SETTINGS = _G.FruitSniperSettings or {
    Team = "Pirates",
    Fruits = {}
}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer
local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

-- Team Selection Retry
local targetTeamName = SETTINGS.Team or "Pirates"
local attempts = 0
repeat
    pcall(function()
        CommF:InvokeServer("SetTeam", targetTeamName)
    end)
    task.wait(0.5)
    attempts = attempts + 1
until (Player.Team and Player.Team.Name == targetTeamName) or attempts >= 10

local Character = Player.Character or Player.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")

local TWEEN_SPEED = 250
local ENABLE_ESP = true

-- Reverted to self.Status / self references from original
local self = AdminusUI or {}
local Status = self.Status
local TweenStatus = self.TweenStatus
local StoreStatus = self.StoringStatus
local FruitType = self.FruitType
local DistanceText = self.FruitDistance

local function IsAllowedFruit(fruitName)
    return SETTINGS.Fruits[fruitName] == true
end

local function ServerHop()
    local HttpService, TeleportService, CoreGui = game:GetService("HttpService"), game:GetService("TeleportService"), game:GetService("CoreGui")
    local IterationSpeed = 0.25
    local ExcludefullServers = true
    local SaveTeleportAttempts = false
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
                return nil
            end
        else
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
                TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
            end
            if JSONData.data[i] then
                local JobId = JSONData.data[i].id
                table.remove(JSONData.data, i)
                local success, encoded = pcall(function()
                    return HttpService:JSONEncode(JSONData)
                end)
                writefile("Servers.JSON", encoded)
                if SaveTeleportAttempts then
                    appendfile("Attempts.txt", JobId .. "\n")
                end
                TeleportService:TeleportToPlaceInstance(game.PlaceId, JobId, Players.LocalPlayer)
                task.wait(IterationSpeed)
            end
        end
    end

    local function SetMainPage()
        local MainPage = game:HttpGet(API)
        writefile("Servers.JSON", MainPage)
        StartTeleport()
    end

    pcall(function()
        CoreGui:WaitForChild("RobloxGui"):WaitForChild("Modules"):WaitForChild("ErrorPrompt"):Destroy()
        CoreGui.RobloxPromptGui:Destroy()
    end)

    if isfile("Servers.JSON") then
        local success, JSONData = pcall(function()
            return HttpService:JSONDecode(readfile("Servers.JSON"))
        end)
        if success and JSONData then
            if JSONData.gameId ~= game.PlaceId then
                SetMainPage()
            end
            if JSONData.data and #JSONData.data >= 1 then
                StartTeleport()
            else
                if success and JSONData.nextPageCursor then
                    EncodeToFile(NextCursor(JSONData.nextPageCursor))
                    StartTeleport()
                else
                    SetMainPage()
                end
            end
        else
            SetMainPage()
        end
    else
        SetMainPage()
    end
end

-- STUCK WATCHDOG
local STUCK_TEXT = 'Status: <font color="rgb(255,0,0)" weight="Regular">No allowed fruits found, server hopping...</font>'
task.spawn(function()
    local timer = 0
    while task.wait(1) do
        if Status and Status.Text == STUCK_TEXT then
            timer = timer + 1
            if timer >= 10 then
                timer = 0
                ServerHop()
            end
        else
            timer = 0
        end
    end
end)

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

        if DistanceText then DistanceText.Text = 'Fruit Distance: <font color="rgb(255,255,255)" weight="Regular">'..math.floor(tpDistance)..'</font>' end
        if TweenStatus then TweenStatus.Text = 'Tweening Status: <font color="rgb(0,170,255)" weight="Regular">Tweening...</font>' end

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

    if DistanceText then DistanceText.Text = 'Fruit Distance: <font color="rgb(255,255,255)" weight="Regular">'..math.floor(distance)..'</font>' end
    if TweenStatus then TweenStatus.Text = 'Tweening Status: <font color="rgb(0,170,255)" weight="Regular">Tweening...</font>' end

    tween:Play()
    tween.Completed:Wait()

    if TweenStatus then TweenStatus.Text = 'Tweening Status: <font color="rgb(0,255,0)" weight="Regular">Tweening done</font>' end
end

local function StoreFruit(fruit)
    local success,err = pcall(function()
        CommF:InvokeServer(
            "StoreFruit",
            fruit:GetAttribute("OriginalName"),
            fruit
        )
    end)

    if not success and StoreStatus then
        StoreStatus.Text = 'Storing Status: <font color="rgb(255,255,0)" weight="Regular">Failed storing fruit... </font>'..err
    end
end

local function Main()
    if Status then Status.Text = 'Status: <font color="rgb(255,255,0)" weight="Regular">Searching fruit...</font>' end

    local fruits = GetAllFruits()

    if #fruits == 0 then
        if Status then Status.Text = 'Status: <font color="rgb(255,0,0)" weight="Regular">No fruit found, server hopping...</font>' end
        task.wait(2)
        ServerHop()
        return
    end

    for _,fruit in pairs(fruits) do
        CreateESP(fruit)
    end

    local target = GetBestFruit(fruits)

    if not target then
        if Status then Status.Text = 'Status: <font color="rgb(255,0,0)" weight="Regular">No allowed fruits found, server hopping...</font>' end
        task.wait(2)
        ServerHop()
        return
    end

    if Status then Status.Text = 'Status: <font color="rgb(0,255,0)" weight="Regular">Fruit found</font>' end
    if FruitType then FruitType.Text = 'Fruit Type: <font color="rgb(0,255,0)" weight="Regular">'..target.Name..'</font>' end

    TweenTo(target.Handle.Position)

    task.wait(1)
    StoreFruit(target)

    if StoreStatus then StoreStatus.Text = 'Storing Status: <font color="rgb(0,255,0)" weight="Regular">Fruit Stored</font>' end

    task.wait(2)
    ServerHop()
end

Main()
