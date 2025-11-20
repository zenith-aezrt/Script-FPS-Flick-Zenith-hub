local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Zenith Hub | [FPS] Flick ",
    LoadingTitle = "Zenith",
    LoadingSubtitle = "script loaded!",
})

local MainTab = Window:CreateTab("Main", "target")
local CreditTab = Window:CreateTab("Credit", "info")
local ESPTab = Window:CreateTab("ESP", "box")
local HBTab = Window:CreateTab("Hitbox", "scan")
local MiscTab = Window:CreateTab("Misc", "settings")

-- VARIABLES ---------------------------------------------------

local FlickEnabled = false
local FlickStrength = 0.12
local WallCheck = true
local FOV = 80
local FlickCooldown = 0.13
local MaxDistance = 350
local LastFlick = 0

local HitboxEnabled = false
local HitboxSize = 4

local HighlightESP = false

local AutoReload = false
local BunnyHop = false

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local localPlayer = game.Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ESP HIGHLIGHT ----------------------------------------------

local function applyHighlight(char)
    if not char:FindFirstChild("Highlight_Zenith") then
        local hl = Instance.new("Highlight")
        hl.Name = "Highlight_Zenith"
        hl.FillTransparency = 1
        hl.OutlineColor = Color3.fromRGB(255, 0, 0)
        hl.OutlineTransparency = 0
        hl.Parent = char
    end
end

local function removeHighlight(char)
    local h = char:FindFirstChild("Highlight_Zenith")
    if h then h:Destroy() end
end

local function updateESP()
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p ~= localPlayer and p.Character then
            if HighlightESP then
                applyHighlight(p.Character)
            else
                removeHighlight(p.Character)
            end
        end
    end
end

task.spawn(function()
    while task.wait(0.5) do
        updateESP()
    end
end)

-- HITBOX ------------------------------------------------------

local function expandHitbox(char)
    for _, partName in ipairs({"Head", "HumanoidRootPart"}) do
        local part = char:FindFirstChild(partName)
        if part then
            part.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
            part.Transparency = 0.7
            part.Material = Enum.Material.ForceField
            part.CanCollide = false
        end
    end
end

local function resetHitbox(char)
    for _, partName in ipairs({"Head", "HumanoidRootPart"}) do
        local p = char:FindFirstChild(partName)
        if p then
            p.Size = Vector3.new(2, 1, 1)
            p.Transparency = 0
            p.Material = Enum.Material.Plastic
        end
    end
end

task.spawn(function()
    while task.wait(0.4) do
        for _, plr in ipairs(game.Players:GetPlayers()) do
            if plr ~= localPlayer and plr.Character then
                if HitboxEnabled then
                    expandHitbox(plr.Character)
                else
                    resetHitbox(plr.Character)
                end
            end
        end
    end
end)

-- FLICK AIMBOT -----------------------------------------------

local function isVisible(targetPart)
    if not WallCheck then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = { localPlayer.Character }
    local origin = camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local ray = workspace:Raycast(origin, direction, params)
    if not ray then return true end
    return ray.Instance:IsDescendantOf(targetPart.Parent)
end

local function getClosest()
    local closest = nil
    local shortest = FOV
    for _, plr in ipairs(game.Players:GetPlayers()) do
        if plr ~= localPlayer and plr.Character then
            local head = plr.Character:FindFirstChild("Head") 
            local torso = plr.Character:FindFirstChild("HumanoidRootPart")
            local part = head or torso
            if part then
                if (camera.CFrame.Position - part.Position).Magnitude < MaxDistance then
                    local pos, vis = camera:WorldToViewportPoint(part.Position)
                    if vis and isVisible(part) then
                        local screenCenter = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
                        local targetPos = Vector2.new(pos.X, pos.Y)
                        local mag = (targetPos - screenCenter).Magnitude
                        if mag < shortest then
                            shortest = mag
                            closest = part
                        end
                    end
                end
            end
        end
    end
    return closest
end

task.spawn(function()
    while task.wait(0.01) do
        if FlickEnabled then
            if tick() - LastFlick < FlickCooldown then
                continue
            end
            local target = getClosest()
            if target then
                local aimDir = (target.Position - camera.CFrame.Position).Unit
                local adaptive = FlickStrength + math.clamp(1 - (camera.CFrame.LookVector:Dot(aimDir)), 0, 0.15)
                camera.CFrame = camera.CFrame:Lerp(
                    CFrame.lookAt(camera.CFrame.Position, camera.CFrame.Position + aimDir),
                    adaptive
                )
                LastFlick = tick()
            end
        end
    end
end)

-- AUTO RELOAD -----------------------------------------------

task.spawn(function()
    while task.wait(0.1) do
        if AutoReload then
            local char = localPlayer.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool and tool:FindFirstChild("Ammo") then
                    if tool.Ammo.Value <= 0 then
                        keypress(0x52)
                        task.wait(0.05)
                        keyrelease(0x52)
                    end
                end
            end
        end
    end
end)

-- BUNNY HOP ---------------------------------------------------

RunService.RenderStepped:Connect(function()
    if BunnyHop then
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            local hum = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.FloorMaterial ~= Enum.Material.Air then
                hum.Jump = true
            end
        end
    end
end)

-- UI ----------------------------------------------------------

MainTab:CreateToggle({
    Name = "Enable Flick",
    CurrentValue = false,
    Callback = function(v)
        FlickEnabled = v
    end
})

MainTab:CreateSlider({
    Name = "Flick Strength",
    Range = {0.05, 0.25},
    Increment = 0.01,
    CurrentValue = FlickStrength,
    Callback = function(v)
        FlickStrength = v
    end
})

MainTab:CreateSlider({
    Name = "Flick FOV",
    Range = {20, 200},
    Increment = 5,
    CurrentValue = FOV,
    Callback = function(v)
        FOV = v
    end
})

MainTab:CreateSlider({
    Name = "Flick Cooldown",
    Range = {0.05, 0.25},
    Increment = 0.01,
    CurrentValue = FlickCooldown,
    Callback = function(v)
        FlickCooldown = v
    end
})

MainTab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = true,
    Callback = function(v)
        WallCheck = v
    end
})

ESPTab:CreateToggle({
    Name = "Highlight ESP",
    CurrentValue = false,
    Callback = function(v)
        HighlightESP = v
        updateESP()
    end
})

HBTab:CreateToggle({
    Name = "Enable Hitbox",
    CurrentValue = false,
    Callback = function(v)
        HitboxEnabled = v
    end
})

HBTab:CreateSlider({
    Name = "Hitbox Size",
    Range = {2, 30},
    Increment = 1,
    CurrentValue = HitboxSize,
    Callback = function(v)
        HitboxSize = v
    end
})

MiscTab:CreateToggle({
    Name = "Auto Reload",
    CurrentValue = false,
    Callback = function(v)
        AutoReload = v
    end
})

MiscTab:CreateToggle({
    Name = "Bunny Hop",
    CurrentValue = false,
    Callback = function(v)
        BunnyHop = v
    end
})

-- CREDIT TAB --------------------------------------------------

CreditTab:CreateLabel("Zenith Hub FPS Flick")
CreditTab:CreateLabel("Made by aezrt")
CreditTab:CreateLabel("Tiktok: aezrt_")
CreditTab:CreateLabel("Thanks for using Zenith Hub!")
