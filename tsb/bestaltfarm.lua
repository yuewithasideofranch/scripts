-- made with love by yue

if not game:IsLoaded() then
    game.Loaded:Wait()
end

do
    if setfpscap then
        pcall(setfpscap, 5)
    else
        pcall(function()
            game:GetService("RunService"):SetFPS(5)
        end)
    end
end

local MAIN_USERNAME = _G.MAIN_USERNAME or "fmp4"
if game.Players.LocalPlayer.Name == MAIN_USERNAME then
    return
end

local mainAccount = game:GetService("Players"):FindFirstChild(MAIN_USERNAME)

if not mainAccount then
    warn("Main account not found.")
    return
end

local lp = game.Players.LocalPlayer
local savedPos = nil
local farming = false

local Services = setmetatable({}, {
    __index = function(_, service)
        return game:GetService(service)
    end
})

local replicatesignal = rawget(_G, "replicatesignal") or nil

local function resetCharacter()
    local speaker = lp
    local humanoid = speaker.Character and speaker.Character:FindFirstChildWhichIsA("Humanoid")
    if replicatesignal and speaker.Kill then
        replicatesignal(speaker.Kill)
    elseif humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Dead)
    else
        speaker.Character:BreakJoints()
    end
end

local function teleport(pos)
    if lp.Character and lp.Character.PrimaryPart then
        lp.Character:SetPrimaryPartCFrame(CFrame.new(pos))
    end
end

local function farmLoop()
    while true do
        if farming and savedPos then
            if lp.Character and lp.Character.PrimaryPart then
                teleport(savedPos)
                task.wait(1.5)
                teleport(savedPos)
                resetCharacter()
                task.wait(5.1)
            end
            task.wait(0.5)
        else
            task.wait(0.5)
        end
    end
end

if not (mainAccount.Character and mainAccount.Character.PrimaryPart) then
    mainAccount.CharacterAdded:Wait()
    mainAccount.Character:WaitForChild("HumanoidRootPart")
end

savedPos = mainAccount.Character.PrimaryPart.Position
print("[.autopls] Saved position of " .. mainAccount.Name .. ":", savedPos)
farming = true
print("[.autopls] Auto setup.")

task.spawn(farmLoop)

local UserSettings = UserSettings()
UserSettings.GameSettings.MasterVolume = 0
game:GetService("RunService"):Set3dRenderingEnabled(false)

if lp:FindFirstChild("PlayerGui") then
    lp.PlayerGui:Destroy()
end

game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")

Players.LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)
