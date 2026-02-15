-- FTAP (Fling Things and People) 올인원 스크립트 (블롭 TP 추가)
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- =============================================
-- [ Infinite Yield 로드 ]
-- =============================================
pcall(function()
    loadstring(game:HttpGet('https://cdn.jsdelivr.net/gh/EdgeIY/infiniteyield@master/source'))()
    task.wait(1)
    if _G and _G.ToggleUI then
        _G.ToggleUI = false
    end
    print("✅ Infinite Yield 로드 완료 (UI 숨김)")
end)

-- =============================================
-- [ Rayfield UI를 항상 최상단으로 유지 ]
-- =============================================
local function bringRayfieldToFront()
    task.spawn(function()
        while task.wait(0.5) do
            for _, gui in ipairs(game:GetService("CoreGui"):GetChildren()) do
                if gui:IsA("ScreenGui") and (gui.Name:find("Rayfield") or gui.Name:find("RayField")) then
                    gui.DisplayOrder = 999999
                    for _, child in ipairs(gui:GetDescendants()) do
                        if child:IsA("Frame") or child:IsA("ScrollingFrame") or child:IsA("TextButton") then
                            child.ZIndex = 999999
                        end
                    end
                end
            end
        end
    end)
end
bringRayfieldToFront()

-- 서비스 로드
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- 로컬 플레이어
local plr = Players.LocalPlayer
local rs = ReplicatedStorage
local inv = Workspace:FindFirstChild(plr.Name.."SpawnedInToys") or Workspace:FindFirstChild("SpawnedInToys")
local Plots = Workspace:WaitForChild("Plots")

-- =============================================
-- [ 리모트 이벤트 찾기 ]
-- =============================================
local GrabEvents = rs:FindFirstChild("GrabEvents")
local CharacterEvents = rs:FindFirstChild("CharacterEvents")
local PlayerEvents = rs:FindFirstChild("PlayerEvents")
local MenuToys = rs:FindFirstChild("MenuToys")
local BombEvents = rs:FindFirstChild("BombEvents")

local SetNetworkOwner = GrabEvents and (GrabEvents:FindFirstChild("SetNetworkOwner") or GrabEvents:FindFirstChild("SetOwner"))
local DestroyGrabLine = GrabEvents and (GrabEvents:FindFirstChild("DestroyGrabLine") or GrabEvents:FindFirstChild("DestroyLine"))
local CreateGrabLine = GrabEvents and (GrabEvents:FindFirstChild("CreateGrabLine") or GrabEvents:FindFirstChild("CreateGrab"))
local ExtendGrabLine = GrabEvents and (GrabEvents:FindFirstChild("ExtendGrabLine") or GrabEvents:FindFirstChild("ExtendGrab"))
local Struggle = CharacterEvents and (CharacterEvents:FindFirstChild("Struggle") or CharacterEvents:FindFirstChild("StruggleRemote"))
local RagdollRemote = CharacterEvents and (CharacterEvents:FindFirstChild("RagdollRemote") or CharacterEvents:FindFirstChild("Ragdoll"))
local SpawnToyRemote = MenuToys and (MenuToys:FindFirstChild("SpawnToyRemoteFunction") or MenuToys:FindFirstChild("SpawnToy"))
local DestroyToy = MenuToys and (MenuToys:FindFirstChild("DestroyToy") or MenuToys:FindFirstChild("DestroyToyRemote"))
local StickyPartEvent = PlayerEvents and (PlayerEvents:FindFirstChild("StickyPartEvent") or PlayerEvents:FindFirstChild("StickyPart"))
local BombExplode = BombEvents and (BombEvents:FindFirstChild("BombExplode") or BombEvents:FindFirstChild("Explode"))

-- =============================================
-- [ 자동완성 함수 ]
-- =============================================
local function findPlayerByPartialName(partial)
    if not partial or partial == "" then return nil end
    
    partial = partial:lower()
    local matches = {}
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= plr then
            local name = player.Name:lower()
            local displayName = player.DisplayName:lower()
            
            if name:find(partial) or displayName:find(partial) then
                table.insert(matches, player)
            end
        end
    end
    
    if #matches > 0 then
        return matches[1]
    end
    return nil
end

-- =============================================
-- [ TP 함수 (raw 기반) ]
-- =============================================
local function TP(target)
    local TCHAR = target.Character
    local THRP = TCHAR and (TCHAR:FindFirstChild("Torso") or TCHAR:FindFirstChild("HumanoidRootPart"))
    local localChar = plr.Character
    local localHRP = localChar and localChar:FindFirstChild("HumanoidRootPart")

    if TCHAR and THRP and localHRP then
        local ping = plr:GetNetworkPing()
        local offset = THRP.Position + (THRP.Velocity * (ping + 0.15))
        localHRP.CFrame = CFrame.new(offset) * THRP.CFrame.Rotation
        return true
    end
    return false
end

-- =============================================
-- [ 안티킥 (Anti-PCLD) 함수 ]
-- =============================================
local AntiPCLDEnabled = false

local function AntiPCLD()
    if not AntiPCLDEnabled then return end
    
    local char = plr.Character
    if not char then return end
    
    local torso = char:FindFirstChild("Torso")
    if not torso then return end
    
    local CF = torso.CFrame
    torso.CFrame = CFrame.new(0,-99,9999)
    task.wait(0.15)
    
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Dead)
    end
    
    local newChar = plr.CharacterAdded:Wait()
    newChar:WaitForChild("Humanoid"):ChangeState(Enum.HumanoidStateType.Dead)
    local newTorso = newChar:WaitForChild("Torso")
    if newTorso then
        newTorso.CFrame = CF
    end
end

local function setupAntiPCLD()
    task.spawn(function()
        while AntiPCLDEnabled do
            for _, obj in ipairs(Workspace:GetChildren()) do
                if obj.Name == "PlayerCharacterLocationDetector" and obj:IsA("BasePart") then
                    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        local hrp = plr.Character.HumanoidRootPart
                        local dist = (obj.Position - hrp.Position).Magnitude
                        if dist < 10 then
                            AntiPCLD()
                            break
                        end
                    end
                end
            end
            task.wait(0.5)
        end
    end)
end

-- =============================================
-- [ 안티 스티키 아우라 함수 ]
-- =============================================
local AntiStickyAuraT = false
local AntiStickyAuraThread = nil

local function AntiStickyAuraF()
    if AntiStickyAuraThread then
        task.cancel(AntiStickyAuraThread)
        AntiStickyAuraThread = nil
    end

    if not AntiStickyAuraT then return end

    local targetNames = { 
        "NinjaKunai", "NinjaShuriken", "NinjaKatana", 
        "ToolCleaver", "ToolDiggingForkRusty", 
        "ToolPencil", "ToolPickaxe" 
    }

    AntiStickyAuraThread = task.spawn(function()
        while AntiStickyAuraT do
            local character = plr.Character
            if character then
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    for _, folder in ipairs(Workspace:GetChildren()) do
                        if folder:IsA("Folder") and folder.Name:match("SpawnedInToys$") and folder.Name ~= (plr.Name .. "SpawnedInToys") then
                            for _, item in ipairs(folder:GetChildren()) do
                                for _, targetName in ipairs(targetNames) do
                                    if item.Name == targetName and item:FindFirstChild("StickyPart") then
                                        local sticky = item.StickyPart
                                        local basePart = item.PrimaryPart or sticky
                                        local dist = (basePart.Position - hrp.Position).Magnitude
                                        if dist <= 30 and SetNetworkOwner then
                                            pcall(function() SetNetworkOwner:FireServer(sticky, sticky.CFrame) end)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            task.wait(0.03)
        end
    end)
end

-- =============================================
-- [ 안티 불 함수 ]
-- =============================================
local AntiBurnV = false
local AntiBurnThread = nil

local function AntiBurn()
    if AntiBurnThread then
        task.cancel(AntiBurnThread)
        AntiBurnThread = nil
    end

    if not AntiBurnV then return end

    AntiBurnThread = task.spawn(function()
        local EP = nil
        for _, child in ipairs(Workspace:GetDescendants()) do
            if child.Name == "ExtinguishPart" and child:IsA("BasePart") then
                EP = child
                break
            end
        end
        if not EP then return end

        local originalSize = EP.Size
        local originalCFrame = EP.CFrame
        local originalTransparency = EP.Transparency

        while AntiBurnV do
            local char = plr.Character
            if char then
                local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
                if head then
                    EP.Transparency = 1
                    EP.Size = Vector3.new(0, 0, 0)
                    EP.CFrame = head.CFrame
                    task.wait()
                    EP.CFrame = head.CFrame * CFrame.new(0, 3, 0)
                end
            end
            task.wait()
        end

        EP.Size = originalSize
        EP.CFrame = originalCFrame
        EP.Transparency = originalTransparency
    end)
end

-- =============================================
-- [ 안티 폭발 함수 ]
-- =============================================
local AntiExplosionT = false
local AntiExplosionC = nil

local function AntiExplosionF()
    if AntiExplosionC then
        AntiExplosionC:Disconnect()
        AntiExplosionC = nil
    end

    if not AntiExplosionT then return end

    local char = plr.Character
    if not char then return end

    local hrp = char:WaitForChild("HumanoidRootPart")
    local hum = char:WaitForChild("Humanoid")

    AntiExplosionC = Workspace.ChildAdded:Connect(function(model)
        if not char or not hrp or not hum or not AntiExplosionT then return end
        if model:IsA("BasePart") and (model.Position - hrp.Position).Magnitude <= 25 then
            hrp.Anchored = true
            task.wait(0.05)
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            hrp.Anchored = false
        end
    end)
end

-- =============================================
-- [ 킥그랩 관련 변수 ]
-- =============================================
local KickGrabState = {
    Target = nil,
    Looping = false,
    AutoRagdoll = false,
    Mode = "Camera",
    DetentionDist = 19,
    SnowBallLooping = false
}

-- =============================================
-- [ 킥그랩 유틸 함수 ]
-- =============================================
local function GetPallet()
    for _, child in pairs(Workspace:GetChildren()) do
        if child.Name:find(plr.Name) and child.Name:find("SpawnedInToys") then
            local pallet = child:FindFirstChild("PalletLightBrown")
            if pallet then 
                return pallet:FindFirstChild("SoundPart") 
            end
        end
    end
    return nil
end

-- =============================================
-- [ 킥그랩 메인 루프 ]
-- =============================================
local function ExecuteKickGrabLoop()
    local lastStrikeTime = tick() 
    local lastSpawnTime = 0 
    local currentPalletRef = nil
    local isPalletOwned = false
    local hasClaimed = false
    local isBlinking = false
    local frameToggle = true

    while KickGrabState.Looping do
        local myChar = plr.Character
        local targetChar = KickGrabState.Target and KickGrabState.Target.Character
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        
        local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        local targetBody = targetChar and (targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("UpperTorso"))
        local cam = Workspace.CurrentCamera 

        if myHrp and targetHrp and cam then
            local rOwner = SetNetworkOwner
            local rDestroy = DestroyGrabLine
            local rSpawn = SpawnToyRemote
            
            local distance = (myHrp.Position - targetHrp.Position).Magnitude
            
            -- 원거리에서는 TP 먼저!
            if distance > 30 then
                local ping = plr:GetNetworkPing()
                local offset = targetHrp.Position + (targetHrp.Velocity * (ping + 0.15))
                myHrp.CFrame = CFrame.new(offset) * targetHrp.CFrame.Rotation
                task.wait(0.1)
                distance = (myHrp.Position - targetHrp.Position).Magnitude
            end
            
            -- A. 원거리 진입 (>20) -> 납치
            if distance > 20 and not hasClaimed and rOwner then
                isBlinking = true
                local originalCFrame = myHrp.CFrame
                myHrp.CFrame = targetHrp.CFrame 
                
                local claimStart = tick()
                while (tick() - claimStart < 0.5) do 
                    if not KickGrabState.Looping then break end
                    myHrp.CFrame = targetHrp.CFrame
                    rOwner:FireServer(targetHrp, targetHrp.CFrame) 
                    if targetBody then rOwner:FireServer(targetBody, targetBody.CFrame) end
                    RunService.Heartbeat:Wait()
                end
                
                targetHrp.CFrame = originalCFrame
                targetHrp.AssemblyLinearVelocity = Vector3.zero 
                
                myHrp.CFrame = originalCFrame
                rOwner:FireServer(targetHrp, originalCFrame)
                
                hasClaimed = true
                isBlinking = false 
            
            -- B. 근거리 진입 (<=20) -> 제자리 고정
            elseif distance <= 20 and not hasClaimed and rOwner then
                local instantClaimStart = tick()
                while (tick() - instantClaimStart < 0.3) do
                    if not KickGrabState.Looping then break end
                    rOwner:FireServer(targetHrp, targetHrp.CFrame)
                    if targetBody then rOwner:FireServer(targetBody, targetBody.CFrame) end
                    RunService.Heartbeat:Wait()
                end
                hasClaimed = true 
            end
            
            -- C. Kick Grab Logic
            if not isBlinking and rOwner and rDestroy then
                local detentionPos
                if KickGrabState.Mode == "Up" then 
                    detentionPos = myHrp.CFrame * CFrame.new(0, 18, 0)
                elseif KickGrabState.Mode == "Down" then 
                    detentionPos = myHrp.CFrame * CFrame.new(0, -10, 0)
                else 
                    detentionPos = cam.CFrame * CFrame.new(0, 0, -KickGrabState.DetentionDist)
                end
                
                if frameToggle then
                    rOwner:FireServer(targetHrp, detentionPos)
                    targetHrp.CFrame = detentionPos
                    targetHrp.AssemblyLinearVelocity = Vector3.zero
                    if targetBody then
                        rOwner:FireServer(targetBody, detentionPos)
                        targetBody.CFrame = detentionPos
                        targetBody.AssemblyLinearVelocity = Vector3.zero
                    end
                else
                    rDestroy:FireServer(targetHrp)
                    if targetBody then rDestroy:FireServer(targetBody) end
                end
                frameToggle = not frameToggle
            end

            -- D. Pallet AI
            if KickGrabState.AutoRagdoll then
                local pallet = GetPallet()
                if not pallet and (tick() - lastSpawnTime > 3.0) then
                    lastSpawnTime = tick()
                    if rSpawn then 
                        task.spawn(function() 
                            rSpawn:InvokeServer("PalletLightBrown") 
                        end) 
                    end
                end
                
                if pallet ~= currentPalletRef then 
                    currentPalletRef = pallet 
                    isPalletOwned = false 
                end

                if pallet then
                    if not isPalletOwned then
                        local rCreate = CreateGrabLine
                        local rExtend = ExtendGrabLine
                        pallet.CFrame = targetHrp.CFrame * CFrame.new(0, 2, 0) 
                        if rCreate then rCreate:FireServer(pallet, pallet.CFrame) end
                        if rExtend then rExtend:FireServer(25) end
                        if rOwner then rOwner:FireServer(pallet, pallet.CFrame) end
                        isPalletOwned = true
                        task.wait(0.1) 
                    else
                        local currentTime = tick()
                        local timeSinceStrike = currentTime - lastStrikeTime
                        local targetPos
                        if timeSinceStrike > 2.0 then
                            targetPos = targetHrp.CFrame 
                            pallet.AssemblyLinearVelocity = Vector3.new(0, 400, 0)
                            pallet.AssemblyAngularVelocity = Vector3.new(1000, 1000, 1000)
                            if timeSinceStrike > 2.15 then lastStrikeTime = currentTime end
                        else
                            local angle = currentTime * 15
                            targetPos = targetHrp.CFrame * CFrame.new(math.cos(angle)*100, 50, math.sin(angle)*100)
                            pallet.AssemblyLinearVelocity = Vector3.zero
                            pallet.AssemblyAngularVelocity = Vector3.new(100, 100, 100)
                        end
                        pallet.CFrame = targetPos
                    end
                end
            end
        end
        RunService.Heartbeat:Wait()
    end
end

-- =============================================
-- [ SnowBall 루프 함수 ]
-- =============================================
local function ExecuteSnowballLoop()
    while KickGrabState.SnowBallLooping do
        local myHrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        local targetChar = KickGrabState.Target and KickGrabState.Target.Character
        local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        
        if myHrp and targetHrp and SpawnToyRemote and SetNetworkOwner and BombExplode then
            task.spawn(function()
                SpawnToyRemote:InvokeServer("BallSnowball", myHrp.CFrame * CFrame.new(0, 10, 20), Vector3.new(0, 0, 0))
            end)
            
            task.wait(0.15)
            
            local invName = plr.Name .. "SpawnedInToys"
            local inv = Workspace:FindFirstChild(invName)
            local ballPart = inv and inv:FindFirstChild("BallSnowball")
            local ballSPart = ballPart and ballPart:FindFirstChild("SoundPart")
            
            if ballPart and ballSPart then
                SetNetworkOwner:FireServer(ballSPart, ballSPart.CFrame)
                ballSPart.CFrame = targetHrp.CFrame
                BombExplode:FireServer({
                    Radius = 0, 
                    Color = Color3.new(0, 0, 0), 
                    TimeLength = 0, 
                    Model = ballPart, 
                    Type = "SnowPoof", 
                    ExplodesByFire = false, 
                    MaxForcePerStudSquared = 0, 
                    Hitbox = ballSPart, 
                    ImpactSpeed = 0, 
                    ExplodesByPointy = false, 
                    DestroysModel = true, 
                    PositionPart = ballSPart
                }, Vector3.new(0, 0, 0))
            end
        end
        task.wait(0.15)
    end
end

-- =============================================
-- [ 상대 팔다리 제거 함수 ]
-- =============================================
local selectedDeletePart = "Arm/Leg"

local function teleportParts(player, partName)
    local character = player.Character
    if not character then return end
    
    local targetParts = {}

    if partName == "Arm/Leg" then
        table.insert(targetParts, character:FindFirstChild("Left Leg"))
        table.insert(targetParts, character:FindFirstChild("Right Leg"))
        table.insert(targetParts, character:FindFirstChild("Left Arm"))
        table.insert(targetParts, character:FindFirstChild("Right Arm"))
    elseif partName == "All/Leg" then
        table.insert(targetParts, character:FindFirstChild("Left Leg"))
        table.insert(targetParts, character:FindFirstChild("Right Leg"))
    elseif partName == "All/Arm" then
        table.insert(targetParts, character:FindFirstChild("Left Arm"))
        table.insert(targetParts, character:FindFirstChild("Right Arm"))
    elseif partName == "Leg/왼쪽" then
        table.insert(targetParts, character:FindFirstChild("Left Leg"))
    elseif partName == "Leg/오른쪽" then
        table.insert(targetParts, character:FindFirstChild("Right Leg"))
    elseif partName == "Arm/왼쪽" then
        table.insert(targetParts, character:FindFirstChild("Left Arm"))
    elseif partName == "Arm/오른쪽" then
        table.insert(targetParts, character:FindFirstChild("Right Arm"))
    end

    if RagdollRemote then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            pcall(function()
                RagdollRemote:FireServer(hrp, 1)
            end)
        end
    end

    task.wait(0.3)

    for _, part in ipairs(targetParts) do
        if part then
            part.CFrame = CFrame.new(0, -99999, 0)
        end
    end

    task.wait(0.3)
    
    local torso = character:FindFirstChild("Torso")
    if torso then
        torso.CFrame = CFrame.new(0, -99999, 0)
    end
end

-- =============================================
-- [ 가장 가까운 플레이어 찾기 ]
-- =============================================
local function getClosestPlayer(targetPart)
    local closest, distance = nil, math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= plr and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local mag = (targetPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
            if mag < distance then
                distance = mag
                closest = player
            end
        end
    end
    return closest
end

-- =============================================
-- [ 원본 루프그랩 함수 ]
-- =============================================
local AntiStruggleGrabT = false
local antiStruggleThread = nil

local function AntiStruggleGrabF()
    if antiStruggleThread then
        task.cancel(antiStruggleThread)
        antiStruggleThread = nil
    end

    if not AntiStruggleGrabT then return end

    antiStruggleThread = task.spawn(function()
        while AntiStruggleGrabT do
            local grabParts = workspace:FindFirstChild("GrabParts")
            if not grabParts then
                task.wait()
                continue
            end

            local gp = grabParts:FindFirstChild("GrabPart")
            local weld = gp and gp:FindFirstChildOfClass("WeldConstraint")
            local part1 = weld and weld.Part1

            if part1 then
                local ownerPlayer = nil
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl.Character and part1:IsDescendantOf(pl.Character) then
                        ownerPlayer = pl
                        break
                    end
                end

                while AntiStruggleGrabT and workspace:FindFirstChild("GrabParts") do
                    if ownerPlayer then
                        local tgtTorso = ownerPlayer.Character and ownerPlayer.Character:FindFirstChild("HumanoidRootPart")
                        local myTorso = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")

                        if tgtTorso and myTorso then
                            pcall(function()
                                SetNetworkOwner:FireServer(tgtTorso, CFrame.lookAt(myTorso.Position, tgtTorso.Position))
                            end)
                        end
                    else
                        if part1 and part1.Parent then
                            local myTorso = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                            if myTorso then
                                pcall(function()
                                    SetNetworkOwner:FireServer(part1, CFrame.lookAt(myTorso.Position, part1.Position))
                                end)
                            end
                        end
                    end
                    task.wait()
                end
            end
            task.wait()
        end
    end)
end

-- =============================================
-- [ 초고속 안티그랩 함수 ]
-- =============================================
local antiGrabConn = nil
local isAntiGrabEnabled = false

local function AntiGrabF(enable)
    if antiGrabConn then
        antiGrabConn:Disconnect()
        antiGrabConn = nil
    end

    if not enable then return end

    antiGrabConn = RunService.RenderStepped:Connect(function()
        local char = plr.Character
        if not char then return end

        local isHeld = plr:FindFirstChild("IsHeld")
        if not isHeld then return end

        local head = char:FindFirstChild("Head")
        local POR = head and head:FindFirstChild("PartOwner")
        local hrp = char:FindFirstChild("HumanoidRootPart")

        if isHeld.Value == true or (POR and POR.Value ~= "") then
            pcall(function() Struggle:FireServer() end)
            
            local grabParts = Workspace:FindFirstChild("GrabParts")
            if grabParts then
                for _, part in ipairs(grabParts:GetChildren()) do
                    if part.Name == "GrabPart" then
                        local weld = part:FindFirstChildOfClass("WeldConstraint")
                        if weld and weld.Part1 and weld.Part1:IsDescendantOf(char) then
                            pcall(function() DestroyGrabLine:FireServer(weld.Part1) end)
                            if hrp then pcall(function() SetNetworkOwner:FireServer(hrp) end) end
                            break
                        end
                    end
                end
            end
        end
    end)
end

-- =============================================
-- [ 블롭 관련 변수 ]
-- =============================================
local playersInLoop1V = {}
local currentBlobS = nil
local blobmanInstanceS = nil
local sitJumpT = false
local AutoGucciT = false
local ragdollLoopD = false
local blobLoopT = false
local blobLoopThread = nil
local antiMasslessEnabled = false
local antiMasslessThread = nil
local PPs = Workspace:FindFirstChild("PlotItems") and Workspace.PlotItems:FindFirstChild("PlayersInPlots")

-- =============================================
-- [ 블롭 관련 함수 ]
-- =============================================
local function UpdateCurrentBlobman()
    local char = plr.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for _, blobs in Workspace:GetDescendants() do
        if blobs.Name ~= "CreatureBlobman" then continue end
        local seat = blobs:FindFirstChild("VehicleSeat")
        if not seat then continue end
        local weld = seat:FindFirstChild("SeatWeld")
        if not weld then continue end
        if weld.Part1 == hrp then
            currentBlobS = blobs
            break
        end
    end
end

local function spawnBlobmanF()
    local char = plr.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local blob = inv and inv:FindFirstChild("CreatureBlobman")
    if blob then
        blobmanInstanceS = blob
        return
    end

    if SpawnToyRemote then
        task.spawn(function()
            pcall(function()
                SpawnToyRemote:InvokeServer("CreatureBlobman", hrp.CFrame, Vector3.new(0, 0, 0))
            end)
        end)

        local tries = 0
        repeat
            task.wait(0.2)
            blobmanInstanceS = inv and inv:FindFirstChild("CreatureBlobman")
            tries = tries + 1
        until blobmanInstanceS or tries > 25
    end
end

local function BlobGrab(blob, target, side)
    if not blob or not target then return end
    local detector = blob:FindFirstChild(side.."Detector")
    if not detector then return end
    local weld = detector:FindFirstChild(side.."Weld")
    if not weld then return end
    
    local script = blob:FindFirstChild("BlobmanSeatAndOwnerScript")
    if script and script:FindFirstChild("CreatureGrab") then
        pcall(function()
            script.CreatureGrab:FireServer(detector, target, weld)
        end)
    end
end

local function BlobRelease(blob, target, side)
    if not blob or not target then return end
    local detector = blob:FindFirstChild(side.."Detector")
    if not detector then return end
    local weld = detector:FindFirstChild(side.."Weld")
    if not weld then return end
    
    local script = blob:FindFirstChild("BlobmanSeatAndOwnerScript")
    if script and script:FindFirstChild("CreatureRelease") then
        pcall(function()
            script.CreatureRelease:FireServer(weld, target)
        end)
    end
end

local function BlobDrop(blob, target, side)
    if not blob or not target then return end
    local detector = blob:FindFirstChild(side.."Detector")
    if not detector then return end
    local weld = detector:FindFirstChild(side.."Weld")
    if not weld then return end
    
    local script = blob:FindFirstChild("BlobmanSeatAndOwnerScript")
    if script and script:FindFirstChild("CreatureDrop") then
        pcall(function()
            script.CreatureDrop:FireServer(weld, target)
        end)
    end
end

local function BlobMassless(blob, target, side)
    if not blob or not target then return end
    local char = plr.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local detector = blob:FindFirstChild(side.."Detector")
    if not detector then return end
    local weld = detector:FindFirstChild(side.."Weld")
    if not weld then return end
    
    local script = blob:FindFirstChild("BlobmanSeatAndOwnerScript")
    if script then
        pcall(function()
            if script:FindFirstChild("CreatureGrab") then
                script.CreatureGrab:FireServer(detector, hrp, weld)
                task.wait(0.1)
                script.CreatureGrab:FireServer(detector, target, weld)
                task.wait(0.1)
                if script:FindFirstChild("CreatureDrop") then
                    script.CreatureDrop:FireServer(weld, target)
                end
            end
        end)
    end
end

-- =============================================
-- [ 수정된 블롭 공격 함수 (원거리 TP 추가) ]
-- =============================================
local function BlobAttackAll(mode)
    UpdateCurrentBlobman()
    if not currentBlobS then
        Rayfield:Notify({Title = "블롭", Content = "블롭을 타고 있어야 합니다", Duration = 2})
        return
    end
    
    local count = 0
    for _, targetName in ipairs(playersInLoop1V) do
        local player = Players:FindFirstChild(targetName)
        if player and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                -- 원거리면 TP 먼저!
                local myChar = plr.Character
                local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                
                if myHrp then
                    local distance = (myHrp.Position - hrp.Position).Magnitude
                    
                    -- 30스터드 이상 떨어져 있으면 TP
                    if distance > 30 then
                        TP(player)
                        task.wait(0.1)
                    end
                end
                
                if mode == "kill" then
                    BlobGrab(currentBlobS, hrp, "Right")
                    task.wait(0.1)
                    BlobRelease(currentBlobS, hrp, "Right")
                elseif mode == "massless" then
                    BlobMassless(currentBlobS, hrp, "Right")
                elseif mode == "grab" then
                    BlobGrab(currentBlobS, hrp, "Right")
                elseif mode == "release" then
                    BlobRelease(currentBlobS, hrp, "Right")
                elseif mode == "drop" then
                    BlobDrop(currentBlobS, hrp, "Right")
                end
                count = count + 1
            end
        end
        task.wait(0.1)
    end
    
    local modeNames = {kill="킬", massless="매스리스", grab="잡기", release="놓기", drop="드롭"}
    Rayfield:Notify({Title = "블롭 " .. modeNames[mode], Content = count .. "명 처리", Duration = 2})
end

-- =============================================
-- [ 수정된 블롭 자동 킥 함수 (원거리 TP 추가) ]
-- =============================================
local function BlobLoopKick()
    UpdateCurrentBlobman()
    if not currentBlobS then
        Rayfield:Notify({Title = "블롭", Content = "블롭을 타고 있어야 합니다", Duration = 2})
        return
    end
    
    if blobLoopThread then
        task.cancel(blobLoopThread)
        blobLoopThread = nil
    end
    
    blobLoopThread = task.spawn(function()
        while blobLoopT do
            for _, targetName in ipairs(playersInLoop1V) do
                if not blobLoopT then break end
                
                local player = Players:FindFirstChild(targetName)
                if not player then continue end
                
                if PPs and PPs:FindFirstChild(targetName) then continue end
                if inv and inv:FindFirstChild(targetName) then continue end
                
                local character = player.Character
                if not character then continue end
                
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if not hrp then continue end
                
                if hrp.Massless == true then continue end
                
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    -- 원거리면 TP 먼저!
                    local myChar = plr.Character
                    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    
                    if myHrp then
                        local distance = (myHrp.Position - hrp.Position).Magnitude
                        
                        if distance > 30 then
                            TP(player)
                            task.wait(0.1)
                        end
                    end
                    
                    local head = character:FindFirstChild("Head")
                    if head then
                        local tpRunning = true
                        local myChar = plr.Character
                        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                        local originCF = myHrp and myHrp.CFrame
                        
                        local tpThread = task.spawn(function()
                            while tpRunning do
                                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and myHrp then
                                    local targetHRP = player.Character.HumanoidRootPart
                                    local ping = plr:GetNetworkPing()
                                    local offset = targetHRP.Position + (targetHRP.Velocity * (ping + 0.15))
                                    myHrp.CFrame = CFrame.new(offset) * targetHRP.CFrame.Rotation
                                end
                                task.wait()
                            end
                        end)
                        
                        for _ = 1, 30 do
                            if not blobLoopT then break end
                            pcall(function()
                                SetNetworkOwner:FireServer(head, head.CFrame)
                            end)
                            local ownerTag = head:FindFirstChild("PartOwner")
                            if ownerTag and ownerTag:IsA("StringValue") and ownerTag.Value == plr.Name then
                                break
                            end
                            task.wait(0.1)
                        end
                        
                        tpRunning = false
                        task.cancel(tpThread)
                        
                        pcall(function()
                            DestroyGrabLine:FireServer(head, head.CFrame)
                        end)
                        
                        if myHrp then
                            hrp.CFrame = CFrame.new(myHrp.CFrame.X, myHrp.CFrame.Y + 50, myHrp.CFrame.Z)
                            myHrp.CFrame = hrp.CFrame
                        end
                        
                        BlobMassless(currentBlobS, hrp, "Right")
                        
                        if originCF and myHrp then
                            myHrp.CFrame = originCF
                        end
                    end
                end
                task.wait(0.1)
            end
            task.wait(0.3)
        end
    end)
end

-- =============================================
-- [ 안티 마스리스 함수 ]
-- =============================================
local function AntiMasslessF()
    if antiMasslessThread then
        task.cancel(antiMasslessThread)
        antiMasslessThread = nil
    end

    if not antiMasslessEnabled then return end

    antiMasslessThread = task.spawn(function()
        while antiMasslessEnabled do
            local char = plr.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.Massless == true then
                        part.Massless = false
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end

-- =============================================
-- [ PCLD 보이게 하는 함수 ]
-- =============================================
local pcldViewEnabled = false
local pcldBoxes = {}

local function togglePcldView(enable)
    if enable then
        for _, box in pairs(pcldBoxes) do
            pcall(function() box:Destroy() end)
        end
        pcldBoxes = {}
        
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj.Name == "PlayerCharacterLocationDetector" and obj:IsA("BasePart") then
                local box = Instance.new("SelectionBox")
                box.Adornee = obj
                box.LineThickness = 0.05
                box.Color3 = Color3.fromRGB(255, 0, 0)
                box.SurfaceColor3 = Color3.fromRGB(255, 255, 255)
                box.SurfaceTransparency = 0.5
                box.Visible = true
                box.Parent = obj
                pcldBoxes[obj] = box
            end
        end
        
        workspace.DescendantAdded:Connect(function(obj)
            if pcldViewEnabled and obj.Name == "PlayerCharacterLocationDetector" and obj:IsA("BasePart") then
                task.wait(0.1)
                local box = Instance.new("SelectionBox")
                box.Adornee = obj
                box.LineThickness = 0.05
                box.Color3 = Color3.fromRGB(255, 0, 0)
                box.SurfaceColor3 = Color3.fromRGB(255, 255, 255)
                box.SurfaceTransparency = 0.5
                box.Visible = true
                box.Parent = obj
                pcldBoxes[obj] = box
            end
        end)
    else
        for _, box in pairs(pcldBoxes) do
            pcall(function() box:Destroy() end)
        end
        pcldBoxes = {}
    end
end

-- =============================================
-- [ Barrier Noclip 함수 ]
-- =============================================
local BarrierCanCollideT = false

local function BarrierCanCollideF()
    if BarrierCanCollideT then
        for i = 1, 5 do
            local plot = Plots:FindFirstChild("Plot"..i)
            if plot and plot:FindFirstChild("Barrier") then
                for _, barrier in ipairs(plot.Barrier:GetChildren()) do
                    if barrier:IsA("BasePart") then
                        barrier.CanCollide = false
                    end
                end
            end
        end
    else
        for i = 1, 5 do
            local plot = Plots:FindFirstChild("Plot"..i)
            if plot and plot:FindFirstChild("Barrier") then
                for _, barrier in ipairs(plot.Barrier:GetChildren()) do
                    if barrier:IsA("BasePart") then
                        barrier.CanCollide = true
                    end
                end
            end
        end
    end
end

-- =============================================
-- [ Plot Barrier Delete 함수 ]
-- =============================================
local PBDrun = false

local function PlotBarrierDelete()
    if PBDrun then 
        Rayfield:Notify({Title = "베리어", Content = "이미 실행 중", Duration = 2})
        return 
    end
    PBDrun = true

    local char = plr.Character
    if not char then 
        PBDrun = false 
        Rayfield:Notify({Title = "오류", Content = "캐릭터 없음", Duration = 2})
        return 
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then 
        PBDrun = false 
        Rayfield:Notify({Title = "오류", Content = "HumanoidRootPart 없음", Duration = 2})
        return 
    end

    local metal = nil
    local plot1 = Workspace:FindFirstChild("Plots") and Workspace.Plots:FindFirstChild("Plot1")
    if plot1 then
        local teslaCoil = plot1:FindFirstChild("TeslaCoil")
        if teslaCoil then
            metal = teslaCoil:FindFirstChild("Metal")
        end
    end

    if not metal then
        PBDrun = false
        Rayfield:Notify({Title = "오류", Content = "Metal 파트를 찾을 수 없음", Duration = 2})
        return
    end

    local TP = metal.CFrame
    local OCF = hrp.CFrame

    task.spawn(function()
        if SpawnToyRemote then
            pcall(function()
                SpawnToyRemote:InvokeServer("FoodBread", hrp.CFrame, Vector3.new(0,0,0))
            end)
        end
    end)

    task.wait(0.2)

    local foodBread = inv and inv:FindFirstChild("FoodBread")
    if not foodBread then 
        PBDrun = false 
        Rayfield:Notify({Title = "오류", Content = "FoodBread 생성 실패", Duration = 2})
        return 
    end

    if foodBread then
        task.spawn(function()
            local holdPart = foodBread:FindFirstChild("HoldPart")
            if holdPart then
                local holdRemote = holdPart:FindFirstChild("HoldItemRemoteFunction")
                if holdRemote then
                    pcall(function()
                        holdRemote:InvokeServer(foodBread, char)
                    end)
                end
            end
        end)
    end

    task.wait(0.1)
    hrp.CFrame = TP
    task.wait(0.17)

    if foodBread and DestroyToy then
        pcall(function()
            DestroyToy:FireServer(foodBread)
        end)
    end

    hrp.CFrame = OCF
    task.wait(0.4)

    PBDrun = false
    Rayfield:Notify({Title = "✅ 베리어", Content = "부수기 완료", Duration = 2})
end

-- =============================================
-- [ 수동 킬 함수 ]
-- =============================================
local targetList = {}

local function manualKill(mode)
    local char = plr.Character
    if not char then 
        Rayfield:Notify({Title = "오류", Content = "캐릭터 없음", Duration = 2})
        return 
    end
    
    local count = 0
    for _, targetName in ipairs(targetList) do
        local target = Players:FindFirstChild(targetName)
        if target and target.Character then
            local torso = target.Character:FindFirstChild("Torso") or target.Character:FindFirstChild("HumanoidRootPart")
            if torso then
                pcall(function() SetNetworkOwner:FireServer(torso, torso.CFrame) end)
                
                if mode == "kill" then
                    local FallenY = Workspace.FallenPartsDestroyHeight
                    local targetY = (FallenY <= -50000 and -49999) or (FallenY <= -100 and -99) or -100
                    pcall(function() torso.CFrame = CFrame.new(99999, targetY, 99999) end)
                else
                    pcall(function() torso.CFrame = CFrame.new(99999, 99999, 99999) end)
                end
                count = count + 1
            end
        end
        task.wait(0.1)
    end
    
    Rayfield:Notify({Title = mode == "kill" and "Kill" or "Kick", Content = count .. "명 처리", Duration = 2})
end

-- =============================================
-- [ 즉시 해제 함수 ]
-- =============================================
local function ManualRelease()
    local char = plr.Character
    if not char then 
        Rayfield:Notify({Title = "오류", Content = "캐릭터 없음", Duration = 2})
        return 
    end
    
    if DestroyGrabLine then
        local grabParts = Workspace:FindFirstChild("GrabParts")
        if grabParts then
            for _, part in ipairs(grabParts:GetChildren()) do
                if part.Name == "GrabPart" then
                    local weld = part:FindFirstChildOfClass("WeldConstraint")
                    if weld and weld.Part1 and weld.Part1:IsDescendantOf(char) then
                        pcall(function() DestroyGrabLine:FireServer(weld.Part1) end)
                    end
                end
            end
        end
    end
    
    if SetNetworkOwner then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then pcall(function() SetNetworkOwner:FireServer(hrp) end) end
    end
    
    if Struggle then pcall(function() Struggle:FireServer() end) end
    
    Rayfield:Notify({Title = "해제 완료", Duration = 2})
end

-- =============================================
-- [ Auto-Gucci 함수 ]
-- =============================================
local function ragdollLoopF()
    if ragdollLoopD then return end
    ragdollLoopD = true

    while sitJumpT do
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if char and hrp and RagdollRemote then
            RagdollRemote:FireServer(hrp, 0)
        end
        task.wait()
    end
    ragdollLoopD = false
end

local function sitJumpF()
    local char = plr.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if not char or not hum then return end
    local seat = blobmanInstanceS and blobmanInstanceS:FindFirstChildWhichIsA("VehicleSeat")
    if seat and seat.Occupant ~= hum then
        seat:Sit(hum)
        AutoGucciT = false
        sitJumpT = false
    end
end

local function AutoGucciF()
    while AutoGucciT do
        local success = pcall(function()
            spawnBlobmanF()

            local char = plr.Character
            if not char then
                task.wait(0.1)
                return 
            end

            local hrp = char:WaitForChild("HumanoidRootPart")
            local hum = char:WaitForChild("Humanoid")
            local rag = hum:WaitForChild("Ragdolled")
            local held = plr:WaitForChild("IsHeld")

            if not hrp then return end
            local OCF = hrp.CFrame

            if not sitJumpT then
                task.spawn(sitJumpF)
                sitJumpT = true
            end

            task.spawn(ragdollLoopF)
            task.wait(0.3)
            hrp.CFrame = OCF

            local successCheck = true
            sitJumpT = false
            if RagdollRemote then RagdollRemote:FireServer(hrp, 0.001) end

            while successCheck and AutoGucciT do
                if hum.Health <= 0 then
                    if blobmanInstanceS and DestroyToy then
                        DestroyToy:FireServer(blobmanInstanceS)
                    end
                    successCheck = false
                    break
                end

                local seat = blobmanInstanceS and blobmanInstanceS:FindFirstChildWhichIsA("VehicleSeat")
                if seat and seat.Occupant ~= nil then
                    if DestroyToy then DestroyToy:FireServer(blobmanInstanceS) end
                    successCheck = false
                    break
                end

                if rag.Value == true or held.Value == true then
                    while (rag.Value == true or held.Value == true) and AutoGucciT do
                        if Struggle then Struggle:FireServer() end
                        task.wait()
                    end
                    successCheck = false
                    break
                end

                local blobHRP = blobmanInstanceS and blobmanInstanceS:FindFirstChild("HumanoidRootPart")
                if blobHRP then
                    pcall(function() SetNetworkOwner:FireServer(blobHRP, hrp) end)
                    blobHRP.CFrame = CFrame.new(0, 9999, 0)
                end

                task.wait()
            end

            if not successCheck then
                local blobHRP = blobmanInstanceS and blobmanInstanceS:FindFirstChild("HumanoidRootPart")
                Rayfield:Notify({Title = "Gucci", Content = "재시도 대기 중...", Duration = 1})
                if hum then
                    if Struggle then Struggle:FireServer(plr) end
                    hum.Sit = true
                    task.wait(0.1)
                    hum.Sit = false
                    if blobHRP and blobHRP.Position.Y > 9000 and DestroyToy then 
                        DestroyToy:FireServer(blobmanInstanceS) 
                    end
                end
                sitJumpT = false
                task.wait(1)
            end
        end)
        task.wait()
    end
end

-- =============================================
-- [ 킥 알림 함수 ]
-- =============================================
local anchoredCache = {}
local kickNotificationsEnabled = true

local function setupKickNotifications()
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(char)
            local hrp = char:WaitForChild("HumanoidRootPart", 1)
            if hrp then
                anchoredCache[player] = false
            end
        end)
    end)

    Players.PlayerRemoving:Connect(function(player)
        if anchoredCache[player] == true and kickNotificationsEnabled then
            Rayfield:Notify({
                Title = "👢 Kick 감지",
                Content = string.format("%s (@%s) 님이 킥당했습니다", player.DisplayName, player.Name),
                Duration = 5
            })
        end
        anchoredCache[player] = nil
    end)

    task.spawn(function()
        while kickNotificationsEnabled do
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= plr then
                    local char = player.Character
                    if char then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            anchoredCache[player] = hrp.Anchored == true
                        end
                    end
                end
            end
            task.wait()
        end
    end)
end

-- =============================================
-- [ 블롭 알림 함수 ]
-- =============================================
local blobNotificationsEnabled = true
local notifyCooldowns = {}
local AntiBlobConnection = nil

local function CheckBlob(blob, myHRP, myAttach, source)
    local script = blob:FindFirstChild("BlobmanSeatAndOwnerScript")
    if not script then return end

    for _, side in ipairs({"Left", "Right"}) do
        local detector = blob:FindFirstChild(side .. "Detector")
        if not detector then continue end

        local weld = detector:FindFirstChild(side .. "Weld")
        if weld and weld:IsA("AlignPosition") and weld.Attachment0 == myAttach then
            local msg = source .. " → " .. side .. " Grab"
            local now = tick()

            if not notifyCooldowns[msg] or (now - notifyCooldowns[msg]) >= 2 then
                notifyCooldowns[msg] = now
                Rayfield:Notify({
                    Title = "🦠 블롭 감지",
                    Content = msg,
                    Duration = 3
                })
            end

            if Struggle then
                pcall(function() Struggle:FireServer() end)
            end
            if RagdollRemote and myHRP then
                pcall(function() RagdollRemote:FireServer(myHRP, 0) end)
            end
        end
    end
end

local function setupBlobNotifications()
    if AntiBlobConnection then 
        AntiBlobConnection:Disconnect() 
        AntiBlobConnection = nil
    end

    AntiBlobConnection = RunService.Stepped:Connect(function()
        if not blobNotificationsEnabled then 
            if AntiBlobConnection then 
                AntiBlobConnection:Disconnect() 
                AntiBlobConnection = nil
            end
            return 
        end

        local myChar = plr.Character
        if not myChar then return end
        local myHRP = myChar:FindFirstChild("HumanoidRootPart")
        local myAttach = myHRP and myHRP:FindFirstChild("RootAttachment")

        if not (myHRP and myAttach) then return end

        if inv then
            for _, blob in ipairs(inv:GetChildren()) do
                if blob.Name == "CreatureBlobman" then
                    local occupantName = "{me}"
                    local vehicleSeat = blob:FindFirstChild("VehicleSeat")
                    if vehicleSeat and vehicleSeat.Occupant then
                        local character = vehicleSeat.Occupant.Parent
                        if character then
                            local player = Players:GetPlayerFromCharacter(character)
                            if player then occupantName = player.Name end
                        end
                    end
                    CheckBlob(blob, myHRP, myAttach, occupantName)
                end
            end
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= plr then
                local invs = Workspace:FindFirstChild(player.Name .. "SpawnedInToys")
                if invs then
                    for _, blob in ipairs(invs:GetChildren()) do
                        if blob.Name == "CreatureBlobman" then
                            local occupantName = player.Name
                            local vehicleSeat = blob:FindFirstChild("VehicleSeat")
                            if vehicleSeat and vehicleSeat.Occupant then
                                local character = vehicleSeat.Occupant.Parent
                                if character then
                                    local occupantPlayer = Players:GetPlayerFromCharacter(character)
                                    if occupantPlayer then occupantName = occupantPlayer.Name end
                                end
                            end
                            CheckBlob(blob, myHRP, myAttach, occupantName)
                        end
                    end
                end
            end
        end

        local plots = Workspace:FindFirstChild("PlotItems")
        if plots then
            for i = 1, 5 do
                local plot = plots:FindFirstChild("Plot" .. i)
                if plot then
                    for _, blob in ipairs(plot:GetChildren()) do
                        if blob.Name == "CreatureBlobman" then
                            local occupantName = "Plot " .. i
                            local vehicleSeat = blob:FindFirstChild("VehicleSeat")
                            if vehicleSeat and vehicleSeat.Occupant then
                                local character = vehicleSeat.Occupant.Parent
                                if character then
                                    local player = Players:GetPlayerFromCharacter(character)
                                    if player then occupantName = player.Name end
                                end
                            end
                            CheckBlob(blob, myHRP, myAttach, occupantName)
                        end
                    end
                end
            end
        end
    end)
end

-- =============================================
-- [ Rayfield UI 설정 ]
-- =============================================
local Window = Rayfield:CreateWindow({
    Name = "FTAP 올인원 (블롭 TP 추가)",
    LoadingTitle = "킥그랩 + 안티불 + 안티폭발 + 안티스티키 + 안티킥 + 블롭TP",
    ConfigurationSaving = { Enabled = false }
})

-- 탭 생성
local MainTab = Window:CreateTab("메인", 4483362458)
local BlobTab = Window:CreateTab("블롭", 4483362458)
local GrabTab = Window:CreateTab("그랩", 4483362458)
local SecurityTab = Window:CreateTab("보안", 4483362458)
local AuraTab = Window:CreateTab("아우라", 4483362458)
local TargetTab = Window:CreateTab("킬 플레이어 정하기", 4483362458)
local NotifyTab = Window:CreateTab("🔔 알림", 4483362458)
local KickGrabTab = Window:CreateTab("👢 킥그랩", 4483362458)
local SettingsTab = Window:CreateTab("설정", 4483362458)

-- =============================================
-- [ 메인 탭 ]
-- =============================================
MainTab:CreateSection("🛡️ 기본 방어")

local AntiGrabToggle = MainTab:CreateToggle({
    Name = "⚡ 초고속 Anti-Grab",
    CurrentValue = false,
    Callback = function(Value)
        isAntiGrabEnabled = Value
        AntiGrabF(Value)
    end
})

MainTab:CreateButton({
    Name = "🔓 즉시 해제",
    Callback = ManualRelease
})

local PcldViewToggle = MainTab:CreateToggle({
    Name = "👁️ PCLD 보이게",
    CurrentValue = false,
    Callback = function(Value)
        pcldViewEnabled = Value
        togglePcldView(Value)
    end
})

local BarrierNoclipToggle = MainTab:CreateToggle({
    Name = "🧱 Barrier Noclip",
    CurrentValue = false,
    Callback = function(Value)
        BarrierCanCollideT = Value
        BarrierCanCollideF()
    end
})

MainTab:CreateButton({
    Name = "💥 집 베리어 부수기",
    Callback = PlotBarrierDelete
})

local AntiPCLDToggle = MainTab:CreateToggle({
    Name = "🛡️ Anti-Kick (PCLD 방어)",
    CurrentValue = false,
    Callback = function(Value)
        AntiPCLDEnabled = Value
        if Value then
            setupAntiPCLD()
            Rayfield:Notify({Title = "안티킥", Content = "활성화 - PCLD 감지 시 자동 방어", Duration = 2})
        else
            Rayfield:Notify({Title = "안티킥", Content = "비활성화", Duration = 2})
        end
    end
})

MainTab:CreateSection("📊 상태")

local StatusLabel = MainTab:CreateLabel("상태: 확인 중...", 4483362458)

spawn(function()
    while task.wait(0.5) do
        local char = plr.Character
        local isHeld = plr:FindFirstChild("IsHeld")
        local head = char and char:FindFirstChild("Head")
        local por = head and head:FindFirstChild("PartOwner")
        
        if isHeld and isHeld.Value then
            StatusLabel:Set("상태: 🟡 잡힘")
        elseif por and por.Value ~= "" then
            StatusLabel:Set("상태: 🟠 오너쉽 있음 (" .. por.Value .. ")")
        else
            StatusLabel:Set("상태: 🟢 안전")
        end
    end
end)

-- =============================================
-- [ 블롭 탭 (TP 추가됨) ]
-- =============================================
BlobTab:CreateSection("🦠 블롭 공격 대상")

local BlobTargetDropdown = BlobTab:CreateDropdown({
    Name = "List",
    Options = playersInLoop1V,
    CurrentOption = {"OPEN"},
    MultipleOptions = true,
    Flag = "BlobTargetDropdown",
    Callback = function(Options)
        playersInLoop1V = Options
    end
})

BlobTab:CreateInput({
    Name = "Add (자동완성)",
    PlaceholderText = "닉네임 일부 입력",
    RemoveTextAfterFocusLost = true,
    Callback = function(Value)
        if not Value or Value == "" then return end
        
        local target = findPlayerByPartialName(Value)
        if not target then
            Rayfield:Notify({Title = "블롭", Content = "플레이어를 찾을 수 없음", Duration = 2})
            return
        end
        
        for _, name in ipairs(playersInLoop1V) do
            if name == target.Name then
                Rayfield:Notify({Title = "블롭", Content = "이미 목록에 있음", Duration = 2})
                return
            end
        end
        
        table.insert(playersInLoop1V, target.Name)
        BlobTargetDropdown:Refresh(playersInLoop1V, true)
        Rayfield:Notify({Title = "블롭", Content = "추가: " .. target.Name, Duration = 2})
    end
})

BlobTab:CreateInput({
    Name = "Remove",
    PlaceholderText = "닉네임 입력",
    RemoveTextAfterFocusLost = true,
    Callback = function(Value)
        if not Value or Value == "" then return end
        
        for i, name in ipairs(playersInLoop1V) do
            if name:lower() == Value:lower() then
                table.remove(playersInLoop1V, i)
                BlobTargetDropdown:Refresh(playersInLoop1V, true)
                Rayfield:Notify({Title = "블롭", Content = "제거: " .. name, Duration = 2})
                return
            end
        end
        Rayfield:Notify({Title = "블롭", Content = "없는 이름", Duration = 2})
    end
})

BlobTab:CreateSection("🦠 블롭 컨트롤")

BlobTab:CreateButton({
    Name = "🪑 블롭 앉기",
    Callback = function()
        local char = plr.Character
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        
        local myBlob = inv and inv:FindFirstChild("CreatureBlobman")
        if myBlob then
            local seat = myBlob:FindFirstChildOfClass("VehicleSeat")
            if seat and seat.Occupant == nil then
                seat:Sit(humanoid)
                Rayfield:Notify({Title = "블롭", Content = "앉기 성공", Duration = 2})
            end
        else
            spawnBlobmanF()
            task.wait(0.5)
            local newBlob = inv and inv:FindFirstChild("CreatureBlobman")
            if newBlob then
                local seat = newBlob:FindFirstChildOfClass("VehicleSeat")
                if seat then
                    seat:Sit(humanoid)
                    Rayfield:Notify({Title = "블롭", Content = "생성 후 앉기", Duration = 2})
                end
            end
        end
    end
})

BlobTab:CreateButton({
    Name = "🔄 블롭 생성",
    Callback = function()
        spawnBlobmanF()
        Rayfield:Notify({Title = "블롭", Content = "생성 시도", Duration = 2})
    end
})

BlobTab:CreateButton({
    Name = "🗑️ 블롭 제거",
    Callback = function()
        if blobmanInstanceS and DestroyToy then
            DestroyToy:FireServer(blobmanInstanceS)
            blobmanInstanceS = nil
            Rayfield:Notify({Title = "블롭", Content = "제거됨", Duration = 2})
        end
    end
})

BlobTab:CreateSection("⚔️ 블롭 공격 (List 대상)")

BlobTab:CreateButton({
    Name = "💀 블롭 킬 (Grab+Release) [TP 자동]",
    Callback = function() BlobAttackAll("kill") end
})

BlobTab:CreateButton({
    Name = "⚡ 블롭 매스리스 [TP 자동]",
    Callback = function() BlobAttackAll("massless") end
})

BlobTab:CreateButton({
    Name = "🤚 블롭 잡기 (Grab) [TP 자동]",
    Callback = function() BlobAttackAll("grab") end
})

BlobTab:CreateButton({
    Name = "✋ 블롭 놓기 (Release) [TP 자동]",
    Callback = function() BlobAttackAll("release") end
})

BlobTab:CreateButton({
    Name = "⬇️ 블롭 드롭 (Drop) [TP 자동]",
    Callback = function() BlobAttackAll("drop") end
})

BlobTab:CreateSection("🔄 블롭 자동 킥")

local BlobLoopKickToggle = BlobTab:CreateToggle({
    Name = "🔄 블롭 자동 킥 (루프) [TP 자동]",
    CurrentValue = false,
    Callback = function(Value)
        blobLoopT = Value
        if blobLoopT then
            BlobLoopKick()
            Rayfield:Notify({Title = "블롭 킥", Content = "자동 루프 시작 (원거리 TP)", Duration = 2})
        else
            if blobLoopThread then
                task.cancel(blobLoopThread)
                blobLoopThread = nil
            end
            Rayfield:Notify({Title = "블롭 킥", Content = "자동 루프 종료", Duration = 2})
        end
    end
})

BlobTab:CreateSection("✨ 구찌 설정")

local AutoGucciToggle = BlobTab:CreateToggle({
    Name = "Auto-Gucci (y=9999)",
    CurrentValue = false,
    Callback = function(Value)
        AutoGucciT = Value
        if AutoGucciT then
            task.spawn(AutoGucciF)
            Rayfield:Notify({Title = "Gucci", Content = "활성화 (y=9999)", Duration = 2})
        else
            if plr.Character and plr.Character:FindFirstChild("Humanoid") then
                plr.Character.Humanoid.Sit = true
                task.wait(0.1)
                plr.Character.Humanoid.Sit = false
            end
            sitJumpT = false
            if blobmanInstanceS and DestroyToy then
                DestroyToy:FireServer(blobmanInstanceS)
                blobmanInstanceS = nil
            end
        end
    end
})

-- =============================================
-- [ 그랩 탭 ]
-- =============================================
GrabTab:CreateSection("🔄 그랩 공격")

local LoopGrabToggle = GrabTab:CreateToggle({
    Name = "🔄 Loop Grab (raw 기반)",
    CurrentValue = false,
    Callback = function(Value)
        AntiStruggleGrabT = Value
        AntiStruggleGrabF()
        Rayfield:Notify({Title = "Loop Grab", Content = Value and "활성화" or "비활성화", Duration = 2})
    end
})

-- =============================================
-- [ 아우라 탭 ]
-- =============================================
AuraTab:CreateSection("🌀 안티 스티키 아우라")

local AntiStickyAuraToggle = AuraTab:CreateToggle({
    Name = "Anti-Sticky Aura",
    CurrentValue = false,
    Callback = function(Value)
        AntiStickyAuraT = Value
        AntiStickyAuraF()
        Rayfield:Notify({Title = "안티 스티키", Content = Value and "활성화" or "비활성화", Duration = 2})
    end
})

AuraTab:CreateParagraph({
    Title = "설명",
    Content = "주변 30스터드 내의 스티키 파트 오너쉽 자동 획득"
})

-- =============================================
-- [ 보안 탭 ]
-- =============================================
SecurityTab:CreateSection("🔰 방어 설정")

local AntiVoidToggle = SecurityTab:CreateToggle({
    Name = "Anti-Void",
    CurrentValue = true,
    Callback = function(Value)
        if Value then
            Workspace.FallenPartsDestroyHeight = -50000
        else
            Workspace.FallenPartsDestroyHeight = -100
        end
    end
})
AntiVoidToggle:Set(true)

local AntiMasslessToggle = SecurityTab:CreateToggle({
    Name = "⚖️ Anti-Massless",
    CurrentValue = false,
    Callback = function(Value)
        antiMasslessEnabled = Value
        AntiMasslessF()
        Rayfield:Notify({Title = "안티 마스리스", Content = Value and "활성화" or "비활성화", Duration = 2})
    end
})

local AntiBurnToggle = SecurityTab:CreateToggle({
    Name = "🔥 Anti-Burn",
    CurrentValue = false,
    Callback = function(Value)
        AntiBurnV = Value
        AntiBurn()
        Rayfield:Notify({Title = "안티 불", Content = Value and "활성화" or "비활성화", Duration = 2})
    end
})

local AntiExplodeToggle = SecurityTab:CreateToggle({
    Name = "💥 Anti-Explosion",
    CurrentValue = false,
    Callback = function(Value)
        AntiExplosionT = Value
        if Value then
            AntiExplosionF()
            Rayfield:Notify({Title = "안티 폭발", Content = "활성화", Duration = 2})
        else
            if AntiExplosionC then
                AntiExplosionC:Disconnect()
                AntiExplosionC = nil
            end
            Rayfield:Notify({Title = "안티 폭발", Content = "비활성화", Duration = 2})
        end
    end
})

-- =============================================
-- [ 킥그랩 탭 ]
-- =============================================
KickGrabTab:CreateSection("🎯 대상 선택")

local TargetList = {}
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= plr then
        table.insert(TargetList, player.Name)
    end
end

local TargetDropdown = KickGrabTab:CreateDropdown({
    Name = "대상 선택",
    Options = TargetList,
    CurrentOption = {"선택하세요"},
    MultipleOptions = false,
    Callback = function(Options)
        local targetName = Options[1]
        if targetName and targetName ~= "선택하세요" then
            KickGrabState.Target = Players:FindFirstChild(targetName)
            Rayfield:Notify({Title = "킥그랩", Content = "대상: " .. targetName, Duration = 2})
        end
    end
})

KickGrabTab:CreateInput({
    Name = "대상 입력 (자동완성)",
    PlaceholderText = "닉네임 일부 입력",
    RemoveTextAfterFocusLost = true,
    Callback = function(Value)
        if not Value or Value == "" then return end
        local target = findPlayerByPartialName(Value)
        if target then
            KickGrabState.Target = target
            Rayfield:Notify({Title = "킥그랩", Content = "대상: " .. target.Name, Duration = 2})
        else
            Rayfield:Notify({Title = "오류", Content = "플레이어를 찾을 수 없음", Duration = 2})
        end
    end
})

KickGrabTab:CreateSection("⚙️ 모드 설정")

local ModeDropdown = KickGrabTab:CreateDropdown({
    Name = "모드 선택",
    Options = {"Camera", "Up", "Down"},
    CurrentOption = {"Camera"},
    MultipleOptions = false,
    Callback = function(Options)
        KickGrabState.Mode = Options[1]
        Rayfield:Notify({Title = "킥그랩", Content = "모드: " .. Options[1], Duration = 2})
    end
})

local DistInput = KickGrabTab:CreateInput({
    Name = "Camera 거리",
    CurrentValue = "19",
    PlaceholderText = "거리 (기본 19)",
    RemoveTextAfterFocusLost = false,
    Callback = function(Value)
        local num = tonumber(Value)
        if num then
            KickGrabState.DetentionDist = num
        end
    end
})

KickGrabTab:CreateSection("🎮 실행")

local KickGrabToggle = KickGrabTab:CreateToggle({
    Name = "👢 Kick Grab",
    CurrentValue = false,
    Callback = function(Value)
        if Value and not KickGrabState.Target then
            Rayfield:Notify({Title = "오류", Content = "대상을 먼저 선택하세요", Duration = 2})
            KickGrabToggle:Set(false)
            return
        end
        KickGrabState.Looping = Value
        if Value then
            task.spawn(ExecuteKickGrabLoop)
            Rayfield:Notify({Title = "킥그랩", Content = "활성화 (원거리 TP)", Duration = 2})
        else
            Rayfield:Notify({Title = "킥그랩", Content = "비활성화", Duration = 2})
        end
    end
})

local AutoRagdollToggle = KickGrabTab:CreateToggle({
    Name = "🔄 Auto Ragdoll",
    CurrentValue = false,
    Callback = function(Value)
        KickGrabState.AutoRagdoll = Value
        Rayfield:Notify({Title = "오토 래그돌", Content = Value and "활성화" or "비활성화", Duration = 2})
    end
})

local SnowBallToggle = KickGrabTab:CreateToggle({
    Name = "❄️ SnowBall Ragdoll",
    CurrentValue = false,
    Callback = function(Value)
        if Value and not KickGrabState.Target then
            Rayfield:Notify({Title = "오류", Content = "대상을 먼저 선택하세요", Duration = 2})
            SnowBallToggle:Set(false)
            return
        end
        KickGrabState.SnowBallLooping = Value
        if Value then
            task.spawn(ExecuteSnowballLoop)
            Rayfield:Notify({Title = "스노우볼", Content = "활성화", Duration = 2})
        else
            Rayfield:Notify({Title = "스노우볼", Content = "비활성화", Duration = 2})
        end
    end
})

-- =============================================
-- [ 킬 플레이어 정하기 탭 ]
-- =============================================
TargetTab:CreateSection("🎯 킬 플레이어 정하기")

local TargetListDropdown = TargetTab:CreateDropdown({
    Name = "Target List",
    Options = targetList,
    CurrentOption = {"OPEN"},
    MultipleOptions = true,
    Callback = function(Options)
        targetList = Options
    end
})

TargetTab:CreateInput({
    Name = "Add (자동완성)",
    PlaceholderText = "닉네임 일부 입력",
    RemoveTextAfterFocusLost = true,
    Callback = function(Value)
        if not Value or Value == "" then return end
        
        local target = findPlayerByPartialName(Value)
        if not target then
            Rayfield:Notify({Title = "대상", Content = "플레이어를 찾을 수 없음", Duration = 2})
            return
        end
        
        for _, name in ipairs(targetList) do
            if name == target.Name then
                Rayfield:Notify({Title = "대상", Content = "이미 목록에 있음", Duration = 2})
                return
            end
        end
        
        table.insert(targetList, target.Name)
        TargetListDropdown:Refresh(targetList, true)
        Rayfield:Notify({Title = "대상", Content = "추가: " .. target.Name, Duration = 2})
    end
})

TargetTab:CreateInput({
    Name = "Remove",
    PlaceholderText = "닉네임 입력",
    RemoveTextAfterFocusLost = true,
    Callback = function(Value)
        if not Value or Value == "" then return end
        
        for i, name in ipairs(targetList) do
            if name:lower() == Value:lower() then
                table.remove(targetList, i)
                TargetListDropdown:Refresh(targetList, true)
                Rayfield:Notify({Title = "대상", Content = "제거: " .. name, Duration = 2})
                return
            end
        end
        Rayfield:Notify({Title = "대상", Content = "없는 이름", Duration = 2})
    end
})

TargetTab:CreateSection("⚔️ 실행")

TargetTab:CreateButton({
    Name = "💀 Kill",
    Callback = function() manualKill("kill") end
})

TargetTab:CreateButton({
    Name = "👢 Kick",
    Callback = function() manualKill("kick") end
})

-- 팔다리 제거 드롭다운
local DeletePartDropdown = TargetTab:CreateDropdown({
    Name = "🦴 제거할 부위 선택",
    Options = {"Arm/Leg", "All/Leg", "All/Arm", "Leg/왼쪽", "Leg/오른쪽", "Arm/왼쪽", "Arm/오른쪽"},
    CurrentOption = {"Arm/Leg"},
    MultipleOptions = false,
    Callback = function(Options)
        selectedDeletePart = Options[1]
    end
})

TargetTab:CreateButton({
    Name = "🦴 선택된 대상 팔다리 제거",
    Callback = function()
        local count = 0
        for _, targetName in ipairs(targetList) do
            local target = Players:FindFirstChild(targetName)
            if target then
                teleportParts(target, selectedDeletePart)
                count = count + 1
            end
            task.wait(0.2)
        end
        Rayfield:Notify({Title = "팔다리 제거", Content = count .. "명 처리 (" .. selectedDeletePart .. ")", Duration = 3})
    end
})

TargetTab:CreateButton({
    Name = "🎯 현재 그랩한 대상 팔다리 제거",
    Callback = function()
        local beamPart = Workspace:FindFirstChild("GrabParts") and Workspace.GrabParts:FindFirstChild("BeamPart")
        if beamPart then
            local targetPlayer = getClosestPlayer(beamPart)
            if targetPlayer then
                teleportParts(targetPlayer, selectedDeletePart)
                Rayfield:Notify({Title = "팔다리 제거", Content = targetPlayer.Name .. " (" .. selectedDeletePart .. ")", Duration = 2})
            else
                Rayfield:Notify({Title = "오류", Content = "대상을 찾을 수 없음", Duration = 2})
            end
        else
            Rayfield:Notify({Title = "오류", Content = "그랩한 대상이 없음", Duration = 2})
        end
    end
})

TargetTab:CreateSection("📋 선택된 플레이어")

local SelectedLabel = TargetTab:CreateLabel("선택됨: 0명", 4483362458)

spawn(function()
    while task.wait(0.5) do
        SelectedLabel:Set("선택됨: " .. #targetList .. "명")
    end
end)

-- =============================================
-- [ 알림 탭 ]
-- =============================================
NotifyTab:CreateSection("🔔 알림 설정")

local KickNotifyToggle = NotifyTab:CreateToggle({
    Name = "👢 킥 알림",
    CurrentValue = true,
    Callback = function(Value)
        kickNotificationsEnabled = Value
    end
})
KickNotifyToggle:Set(true)

local BlobNotifyToggle = NotifyTab:CreateToggle({
    Name = "🦠 블롭 알림",
    CurrentValue = true,
    Callback = function(Value)
        blobNotificationsEnabled = Value
        if Value then
            setupBlobNotifications()
        else
            if AntiBlobConnection then
                AntiBlobConnection:Disconnect()
                AntiBlobConnection = nil
            end
        end
    end
})
BlobNotifyToggle:Set(true)

-- =============================================
-- [ 설정 탭 ]
-- =============================================
SettingsTab:CreateSection("⚙️ 설정")

SettingsTab:CreateToggle({
    Name = "IY UI 숨기기",
    CurrentValue = true,
    Callback = function(Value)
        if _G and _G.ToggleUI then
            _G.ToggleUI = not Value
        end
    end
})

-- =============================================
-- [ 자동 실행 ]
-- =============================================
task.wait(1)
isAntiGrabEnabled = true
AntiGrabF(true)
AntiGrabToggle:Set(true)

setupKickNotifications()
setupBlobNotifications()

bringRayfieldToFront()

Rayfield:Notify({
    Title = "🚀 로드 완료",
    Content = "블롭 TP 추가 | 원거리에서도 집 안 사람 잡기 가능",
    Duration = 5
})
