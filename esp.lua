local ESP = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CurrentCamera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

ESP.drawingChamsEnabled = false
ESP.drawings = {}
ESP.distanceTexts = {}
ESP.maxDistance = 250

local function createDrawing(player)
    if ESP.drawings[player] then return end

    local box = Drawing.new("Square")
    box.Visible = false
    box.Thickness = 1
    box.Color = Color3.fromRGB(0, 255, 0)
    box.Filled = false
    ESP.drawings[player] = box

    local distanceText = Drawing.new("Text")
    distanceText.Visible = false
    distanceText.Size = 16
    distanceText.Color = Color3.fromRGB(255, 255, 255)
    distanceText.Center = true
    distanceText.Outline = true
    ESP.distanceTexts[player] = distanceText
end

local function removeDrawing(player)
    if ESP.drawings[player] then
        ESP.drawings[player]:Remove()
        ESP.drawings[player] = nil
    end
    if ESP.distanceTexts[player] then
        ESP.distanceTexts[player]:Remove()
        ESP.distanceTexts[player] = nil
    end
end

local function updateESP()
    for player, text in pairs(ESP.distanceTexts) do
        if not Players:FindFirstChild(player.Name) or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            text:Remove()
            ESP.distanceTexts[player] = nil
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if ESP.teamCheckEnabled and player.Character.HumanoidRootPart:FindFirstChild("TeammateLabel") then
                -- Skip teammates
            else
                local rootPart = player.Character.HumanoidRootPart
                local humanoid = player.Character:FindFirstChild("Humanoid")

                if humanoid and humanoid.Health > 0 then
                    local screenPosition, onScreen = CurrentCamera:WorldToViewportPoint(rootPart.Position)
                    local distance = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and (LocalPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude) or math.huge

                    if onScreen and distance <= ESP.maxDistance then
                        if not ESP.distanceTexts[player] then
                            ESP.distanceTexts[player] = Drawing.new("Text")
                            ESP.distanceTexts[player].Size = 16
                            ESP.distanceTexts[player].Color = Color3.fromRGB(255, 255, 255)
                            ESP.distanceTexts[player].Outline = true
                            ESP.distanceTexts[player].Center = true
                            ESP.distanceTexts[player].Visible = false
                        end

                        local text = ESP.distanceTexts[player]
                        text.Visible = true
                        text.Text = string.format("%dm | HP: %d", math.floor(distance), math.floor(humanoid.Health))
                        text.Position = Vector2.new(screenPosition.X, screenPosition.Y - 20)
                    elseif ESP.distanceTexts[player] then
                        ESP.distanceTexts[player].Visible = false
                    end
                elseif ESP.distanceTexts[player] then
                    ESP.distanceTexts[player].Visible = false
                end
            end
        elseif ESP.distanceTexts[player] then
            ESP.distanceTexts[player].Visible = false
        end
    end
end

function ESP.enableDrawingChams()
    ESP.drawingChamsEnabled = true
    RunService.RenderStepped:Connect(function()
        if ESP.drawingChamsEnabled then
            updateESP()
        end
    end)
end

function ESP.disableDrawingChams()
    ESP.drawingChamsEnabled = false
    for _, text in pairs(ESP.distanceTexts) do
        text:Remove()
    end
    ESP.distanceTexts = {}
end

Players.PlayerRemoving:Connect(function(player)
    removeDrawing(player)
end)

return ESP
