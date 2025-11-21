local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
    Name = "Zenith Hub | [FPS] Flick",
    LoadingTitle = "Zenith",
    LoadingSubtitle = "script loaded!",
})

local MainTab = Window:CreateTab("Main", "target")
local CreditTab = Window:CreateTab("Credit", "info")
local ESPTab = Window:CreateTab("ESP", "box")
local HBTab = Window:CreateTab("Hitbox", "scan")
local MiscTab = Window:CreateTab("Misc", "settings")

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

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

local AimbotEnabled = false
local AimbotFOV = 120
local AimbotSmooth = 0.25

local ShowAimbotFOV = true
local successDrawing, FOVCircle = pcall(function() return Drawing.new("Circle") end)

if not successDrawing then
    FOVCircle = nil
end

if FOVCircle then
    FOVCircle.Visible = false
    FOVCircle.Thickness = 2
    FOVCircle.NumSides = 64
    FOVCircle.Filled = false
    FOVCircle.Color = Color3.fromRGB(0, 0, 0)
end

local function safeFindCharacter(plr)
    if not plr then return nil end
    local ch = plr.Character
    if ch and ch.Parent then return ch end
    return nil
end

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
    for _, p in ipairs(Players:GetPlayers()) do
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

local function expandHitbox(char)
    for _, partName in ipairs({"Head", "HumanoidRootPart"}) do
        local part = char:FindFirstChild(partName)
        if part then
            pcall(function()
                part.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
                part.Transparency = 0.7
                part.Material = Enum.Material.ForceField
                part.CanCollide = false
            end)
        end
    end
end

local function resetHitbox(char)
    for _, partName in ipairs({"Head", "HumanoidRootPart"}) do
        local p = char:FindFirstChild(partName)
        if p then
            p.Size = Vector3.new(2, 2, 1)
            p.Transparency = 0
            p.Material = Enum.Material.Plastic
        end
    end
end

task.spawn(function()
    while task.wait(0.4) do
        for _, plr in ipairs(Players:GetPlayers()) do
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

local function isVisible(targetPart)
    if not WallCheck then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    if localPlayer.Character then
        params.FilterDescendantsInstances = { localPlayer.Character }
    else
        params.FilterDescendantsInstances = {}
    end
    local origin = camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local ray = workspace:Raycast(origin, direction, params)
    if not ray then return true end
    return ray.Instance:IsDescendantOf(targetPart.Parent)
end

local function getClosestFlick()
    local closest = nil
    local shortest = FOV

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= localPlayer and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            local part = head
            if part then
                if (camera.CFrame.Position - part.Position).Magnitude < MaxDistance then
                    local pos, vis = camera:WorldToViewportPoint(part.Position)
                    if vis and isVisible(part) then
                        local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
                        local target = Vector2.new(pos.X, pos.Y)
                        local mag = (target - center).Magnitude
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
            if tick() - LastFlick < FlickCooldown then continue end
            local target = getClosestFlick()
            if target then
                local aimDir = (target.Position - camera.CFrame.Position).Unit
                camera.CFrame = camera.CFrame:Lerp(
                    CFrame.lookAt(camera.CFrame.Position, camera.CFrame.Position + aimDir),
                    FlickStrength
                )
                LastFlick = tick()
            end
        end
    end
end)

local function getAimbotTarget()
    local closest = nil
    local shortest = AimbotFOV
    local screenCenter = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= localPlayer and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            local part = head or root
            if part then
                local pos, vis = camera:WorldToViewportPoint(part.Position)
                if vis then
                    if WallCheck then
                        local params = RaycastParams.new()
                        params.FilterType = Enum.RaycastFilterType.Blacklist
                        params.FilterDescendantsInstances = { localPlayer.Character }

                        local origin = camera.CFrame.Position
                        local dir = (part.Position - origin)
                        local ray = workspace:Raycast(origin, dir, params)

                        if ray and not ray.Instance:IsDescendantOf(part.Parent) then
                            continue
                        end
                    end

                    local dist = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                    if dist < shortest then
                        closest = part
                        shortest = dist
                    end
                end
            end
        end
    end

    return closest
end

RunService.RenderStepped:Connect(function()
    if AimbotEnabled then
        local target = getAimbotTarget()
        if target and target.Parent then
            local aimDir = (target.Position - camera.CFrame.Position).Unit
            camera.CFrame = camera.CFrame:Lerp(
                CFrame.lookAt(camera.CFrame.Position, camera.CFrame.Position + aimDir),
                AimbotSmooth
            )
        end
    end
end)

if FOVCircle then
    RunService.RenderStepped:Connect(function()
        FOVCircle.Visible = ShowAimbotFOV
        FOVCircle.Radius = AimbotFOV
        FOVCircle.Position = Vector2.new(
            camera.ViewportSize.X/2,
            camera.ViewportSize.Y/2
        )
    end)
end

task.spawn(function()
    while task.wait(0.1) do
        if AutoReload then
            local char = localPlayer.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool and tool:FindFirstChild("Ammo") then
                    if tool.Ammo.Value <= 0 then
                        pcall(function()
                            keypress(0x52)
                            task.wait(0.05)
                            keyrelease(0x52)
                        end)
                    end
                end
            end
        end
    end
end)

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

MainTab:CreateToggle({
    Name = "Enable Flick",
    CurrentValue = FlickEnabled,
    Callback = function(v)
        FlickEnabled = v
    end
})

MainTab:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = AimbotEnabled,
    Callback = function(v)
        AimbotEnabled = v
    end
})

MainTab:CreateSlider({
    Name = "Aimbot FOV",
    Range = {20, 300},
    Increment = 5,
    CurrentValue = AimbotFOV,
    Callback = function(v)
        AimbotFOV = v
    end
})

MainTab:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = ShowAimbotFOV,
    Callback = function(v)
        ShowAimbotFOV = v
        if FOVCircle then FOVCircle.Visible = v end
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
    CurrentValue = WallCheck,
    Callback = function(v)
        WallCheck = v
    end
})

ESPTab:CreateToggle({
    Name = "Highlight ESP",
    CurrentValue = HighlightESP,
    Callback = function(v)
        HighlightESP = v
        updateESP()
    end
})

HBTab:CreateToggle({
    Name = "Enable Hitbox",
    CurrentValue = HitboxEnabled,
    Callback = function(v)
        HitboxEnabled = v
    end
})

HBTab:CreateSlider({
    Name = "Hitbox Size",
    Range = {2, 100},
    Increment = 1,
    CurrentValue = HitboxSize,
    Callback = function(v)
        HitboxSize = v
    end
})

MiscTab:CreateToggle({
    Name = "Auto Reload",
    CurrentValue = AutoReload,
    Callback = function(v)
        AutoReload = v
    end
})

MiscTab:CreateToggle({
    Name = "Bunny Hop",
    CurrentValue = BunnyHop,
    Callback = function(v)
        BunnyHop = v
    end
})

CreditTab:CreateLabel("Zenith Hub")
CreditTab:CreateLabel("Made by aezrt")
CreditTab:CreateLabel("TikTok: aezrt_")
CreditTab:CreateLabel("Thanks for using Zenith Hub!")
