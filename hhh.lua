local Aimbot = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CurrentCamera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

Aimbot.MouseLockEnabled = false
Aimbot.MouseLockMode = "Toggle"
Aimbot.ClosestPlayer = nil
Aimbot.SmoothFactor = 0.1
Aimbot.PredictionMultiplier = 0.1
Aimbot.AimPartName = "Head"
Aimbot.MaxAimDistance = 180

local lastToggleTime = 0
local toggleDebounce = 0.2
local OverrideKey = Enum.KeyCode.T

local function IsPlayerAlive(p)
    if not p or not p.Character then return false end
    local hum = p.Character:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function FindClosestPlayer()
    local best, bestDist = nil, 200
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild(Aimbot.AimPartName) then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp and not hrp:FindFirstChild("TeammateLabel") then
                if IsPlayerAlive(plr) then
                    local aimPart = plr.Character[Aimbot.AimPartName]
                    local screenPos, onScreen = CurrentCamera:WorldToScreenPoint(aimPart.Position)
                    local dist = (Vector2.new(LocalPlayer:GetMouse().X, LocalPlayer:GetMouse().Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                    if dist < bestDist and onScreen then
                        bestDist = dist
                        best = plr
                    end
                end
            end
        end
    end
    return best
end

local function PredictPosition(part)
    if not part then return end
    return part.Position + part.Velocity * Aimbot.PredictionMultiplier
end

local function AimAt(part)
    if part then
        local predicted = PredictPosition(part)
        if predicted then
            local scrPos = CurrentCamera:WorldToScreenPoint(predicted)
            local dx = (scrPos.X - LocalPlayer:GetMouse().X) * Aimbot.SmoothFactor
            local dy = (scrPos.Y - LocalPlayer:GetMouse().Y) * Aimbot.SmoothFactor
            if dx and dy then
                mousemoverel(dx, dy)
            end
        end
    end
end

local function CheckTargetHealth()
    if Aimbot.ClosestPlayer and (not IsPlayerAlive(Aimbot.ClosestPlayer) or not Aimbot.ClosestPlayer.Character) then
        print("Cible morte => on cherche un autre…")
        Aimbot.ClosestPlayer = FindClosestPlayer()
    end
end

RunService.RenderStepped:Connect(function()
    Aimbot.SmoothFactor = (Settings.Sliders["Smoothness"] and (Settings.Sliders["Smoothness"] / 100)) or 0.1
    Aimbot.PredictionMultiplier = (Settings.Sliders["Prediction"] and (Settings.Sliders["Prediction"] / 100)) or 0.1

    if Aimbot.MouseLockEnabled then
        if Aimbot.ClosestPlayer and Aimbot.ClosestPlayer.Character then
            CheckTargetHealth()
            local part = Aimbot.ClosestPlayer.Character:FindFirstChild(Aimbot.AimPartName)
            if part then
                AimAt(part)
            else
                Aimbot.ClosestPlayer = FindClosestPlayer()
            end
        else
            Aimbot.ClosestPlayer = FindClosestPlayer()
        end
    end
end)

local function ConvertToKeyCode(value)
    print("[DEBUG ConvertToKeyCode] raw =>", value)
    if typeof(value) == "EnumItem" and value.EnumType == Enum.KeyCode then
        return value
    end
    if type(value) == "string" then
        local up = value:upper()
        if Enum.KeyCode[up] then
            return Enum.KeyCode[up]
        end
        local fromLib = value:match("Enum%.KeyCode%.(%w+)")
        if fromLib and Enum.KeyCode[fromLib] then
            return Enum.KeyCode[fromLib]
        end
    end
    return Enum.KeyCode.K
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if Aimbot.MouseLockMode ~= "Toggle" then return end

    if input.KeyCode == OverrideKey then
        local now = tick()
        if now - lastToggleTime < toggleDebounce then
            return
        end
        lastToggleTime = now

        Aimbot.MouseLockEnabled = not Aimbot.MouseLockEnabled
        if Aimbot.MouseLockEnabled then
            print("MouseLock ON (Toggle) => via", OverrideKey.Name)
            Aimbot.ClosestPlayer = FindClosestPlayer()
        else
            print("MouseLock OFF (Toggle)")
            Aimbot.ClosestPlayer = nil
        end
    end
end)

return Aimbot
