-- made with love by yue

if not game:IsLoaded() then 
    game.Loaded:Wait() 
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
                wait(1)
                resetCharacter()
                wait(5)
            end
            wait(0.5)
        else
            wait(0.5)
        end
    end
end

spawn(farmLoop)

for _,player in ipairs(game.Players:GetPlayers()) do
    player.Chatted:Connect(function(msg)
        msg = msg:lower()
        if player ~= lp then
            if msg == ".sp" then
                if player.Character and player.Character.PrimaryPart then
                    savedPos = player.Character.PrimaryPart.Position
                    print("[.setpos] Saved position of " .. player.Name .. ":", savedPos)
                end
            end
            if msg == ".br" then
                if savedPos then
                    teleport(savedPos)
                    print("[.bring] Teleported")
                else
                    print("[.bring] No position saved.")
                end
            end
            if msg == ".fa" then
                if savedPos then
                    farming = true
                    print("[.farm] Started farming loop.")
                else
                    print("[.farm] No position saved.")
                end
            end
            if msg == ".st" then
                farming = false
                print("[.stop] Stopped farming.")
            end   
            if msg == "autopls" then
                if player.Character and player.Character.PrimaryPart then
                    savedPos = player.Character.PrimaryPart.Position
                    print("[.autopls] Saved position of " .. player.Name .. ":", savedPos)
                end
                farming = true
                print("[.autopls] Auto setup.")
            end 
            if msg == ".ra" then
                local UserSettings = UserSettings()
                UserSettings.GameSettings.MasterVolume = 0
                game:GetService("RunService"):Set3dRenderingEnabled(false)
                game:GetService("Players").LocalPlayer.PlayerGui:Destroy()
                game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
                for i,v in next, workspace:GetDescendants() do
                if v:IsA'Seat' then
                v:Destroy()
                end
                end
                loadstring(game:HttpGet("https://raw.githubusercontent.com/evxncodes/mainroblox/main/anti-afk", true))() --anti afk
                print("[.ram] Removed assets & more.")
            end     
        end
    end)
end
