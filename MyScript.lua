-- FTAP (Fling Things and People) 올인원 스크립트 (안티 마스리스 + 블롭 킥)
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

local SetNetworkOwner = GrabEvents and (GrabEvents:FindFirstChild("SetNetworkOwner") or GrabEvents:FindFirstChild("SetOwner"))
local DestroyGrabLine = GrabEvents and (GrabEvents:FindFirstChild("DestroyGrabLine") or GrabEvents:FindFirstChild("DestroyLine"))
local Struggle = CharacterEvents and (CharacterEvents:FindFirstChild("Struggle") or CharacterEvents:FindFirstChild("StruggleRemote"))
local RagdollRemote = CharacterEvents and (CharacterEvents:FindFirstChild("RagdollRemote") or CharacterEvents:FindFirstChild("Ragdoll"))
local SpawnToyRemote = MenuToys and (MenuToys:FindFirstChild("SpawnToyRemoteFunction") or MenuToys:FindFirstChild("SpawnToy"))
local DestroyToy = MenuToys and (MenuToys:FindFirstChild("DestroyToy") or MenuToys:FindFirstChild("DestroyToyRemote"))
local StickyPartEvent = PlayerEvents and (PlayerEvents:FindFirstChild("StickyPartEvent") or PlayerEvents:FindFirstChild("StickyPart"))

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
-- [ 블롭 관련 변수 ]
-- =============================================
local playersInLoop1V = {}
local currentBlobS = nil
local blobmanInstanceS = nil
local sitJumpT = false
local AutoGucciT = false
local ragdollLoopD = false

-- =============================================
-- [ 블롭 관련 함수 (raw 기반) ]
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
-- [ 블롭 킥 함수 (raw의 loopPlayerBlobF 기반) ]
-- =============================================
local blobLoopT = false
local blobLoopThread = nil

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
                
                -- 플롯에 있는지 확인 (raw의 PPs 조건)
                if PPs and PPs:FindFirstChild(targetName) then continue end
                if inv and inv:FindFirstChild(targetName) then continue end
                
                local character = player.Character
                if not character then continue end
                
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if not hrp then continue end
                
                -- Massless 체크
                if hrp.Massless == true then continue end
                
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    -- 오너쉽 획득 시도
                    local head = character:FindFirstChild("Head")
                    if head then
                        local tpRunning = true
                        local originCF = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character.HumanoidRootPart.CFrame
                        
                        -- TP 스레드
                        local tpThread = task.spawn(function()
                            while tpRunning do
                                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                                    local targetHRP = player.Character.HumanoidRootPart
                                    local myHRP = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                                    if myHRP and targetHRP then
                                        local ping = plr:GetNetworkPing()
                                        local offset = targetHRP.Position + (targetHRP.Velocity * (ping + 0.15))
                                        myHRP.CFrame = CFrame.new(offset) * targetHRP.CFrame.Rotation
                                    end
                                end
                                task.wait()
                            end
                        end)
                        
                        -- 오너쉽 획득 루프
                        local ownerTag = nil
                        for _ = 1, 30 do
                            if not blobLoopT then break end
                            pcall(function()
                                SetNetworkOwner:FireServer(head, head.CFrame)
                            end)
                            ownerTag = head:FindFirstChild("PartOwner")
                            if ownerTag and ownerTag:IsA("StringValue") and ownerTag.Value == plr.Name then
                                break
                            end
                            task.wait(0.1)
                        end
                        
                        tpRunning = false
                        task.cancel(tpThread)
                        
                        -- 스티키 파트 처리 (raw의 targetNames)
                        if ownerTag and ownerTag.Value == plr.Name then
                            local targetNames = {"NinjaKunai", "NinjaShuriken", "NinjaKatana", "ToolCleaver", "ToolDiggingForkRusty", "ToolPencil", "ToolPickaxe"}
                            for _, child in ipairs(Workspace:GetChildren()) do
                                if child:IsA("Folder") and child.Name:match("SpawnedInToys$") then
                                    for _, item in ipairs(child:GetChildren()) do
                                        if table.find(targetNames, item.Name) and item:FindFirstChild("StickyPart") then
                                            local sticky = item.StickyPart
                                            local weld = sticky:FindFirstChild("StickyWeld")
                                            if weld and weld:IsA("WeldConstraint") and weld.Part1 then
                                                local targetParts = {
                                                    character:FindFirstChild("Head"),
                                                    character:FindFirstChild("Torso"),
                                                    character:FindFirstChild("Left Arm"),
                                                    character:FindFirstChild("Left Leg"),
                                                    character:FindFirstChild("Right Arm"),
                                                    character:FindFirstChild("Right Leg"),
                                                    hrp:FindFirstChild("RagdollTouchedHitbox"),
                                                    hrp:FindFirstChild("FirePlayerPart"),
                                                }
                                                for _, tPart in ipairs(targetParts) do
                                                    if tPart and weld.Part1 == tPart then
                                                        local basePart = item.PrimaryPart or sticky
                                                        if basePart and (basePart.Position - hrp.Position).Magnitude <= 10 then
                                                            pcall(function()
                                                                SetNetworkOwner:FireServer(sticky, sticky.CFrame)
                                                            end)
                                                            sticky.CFrame = CFrame.new(0,9999,0)
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                            
                            -- DestroyGrabLine 호출
                            pcall(function()
                                DestroyGrabLine:FireServer(head, head.CFrame)
                            end)
                            
                            -- 위치 이동
                            local myHrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                            if myHrp then
                                hrp.CFrame = CFrame.new(myHrp.CFrame.X, myHrp.CFrame.Y + 50, myHrp.CFrame.Z)
                                myHrp.CFrame = hrp.CFrame
                            end
                            
                            -- 블롭 매스리스
                            BlobMassless(currentBlobS, hrp, "Right")
                            
                            -- 원래 위치로 복귀
                            if originCF and myHrp then
                                myHrp.CFrame = originCF
                            end
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
-- [ 안티 마스리스 함수 (raw의 masslessF 기반) ]
-- =============================================
local antiMasslessEnabled = false
local antiMasslessThread = nil

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
-- [ 블롭 공격 함수 ]
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
-- [ Anti-Grab 함수 ]
-- =============================================
local antiGrabConn = nil
local isAntiGrabEnabled = false

local function AntiGrabF(enable)
    if antiGrabConn then
        antiGrabConn:Disconnect()
        antiGrabConn = nil
    end

    if not enable then return end

    antiGrabConn = RunService.Heartbeat:Connect(function()
        local char = plr.Character
        if not char then return end
        local isHeld = plr:FindFirstChild("IsHeld")
        if not isHeld then return end
        if isHeld.Value == true and Struggle then
            pcall(function() Struggle:FireServer() end)
        end
    end)
end

-- =============================================
-- [ 수동 킬 함수 ]
-- =============================================
local targetList = {}
local Whitelist = {}
local WhiteListMode = false
local PPs = Workspace:FindFirstChild("PlotItems") and Workspace.PlotItems:FindFirstChild("PlayersInPlots")

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
    Name = "FTAP 올인원 (안티 마스리스 + 블롭 킥)",
    LoadingTitle = "블롭 + PCLD + 보안 + 베리어 + 알림 + 자동완성 + 마스리스 + 블롭킥",
    ConfigurationSaving = { Enabled = false }
})

-- 탭 생성
local MainTab = Window:CreateTab("메인", 4483362458)
local BlobTab = Window:CreateTab("블롭", 4483362458)
local GrabTab = Window:CreateTab("그랩", 4483362458)
local SecurityTab = Window:CreateTab("보안", 4483362458)
local TargetTab = Window:CreateTab("킬 플레이어 정하기", 4483362458)
local NotifyTab = Window:CreateTab("🔔 알림", 4483362458)
local SettingsTab = Window:CreateTab("설정", 4483362458)

-- =============================================
-- [ 메인 탭 ]
-- =============================================
MainTab:CreateSection("🛡️ 기본 방어")

local AntiGrabToggle = MainTab:CreateToggle({
    Name = "Anti-Grab",
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
-- [ 블롭 탭 ]
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
    Name = "💀 블롭 킬 (Grab+Release)",
    Callback = function() BlobAttackAll("kill") end
})

BlobTab:CreateButton({
    Name = "⚡ 블롭 매스리스",
    Callback = function() BlobAttackAll("massless") end
})

BlobTab:CreateButton({
    Name = "🤚 블롭 잡기 (Grab)",
    Callback = function() BlobAttackAll("grab") end
})

BlobTab:CreateButton({
    Name = "✋ 블롭 놓기 (Release)",
    Callback = function() BlobAttackAll("release") end
})

BlobTab:CreateButton({
    Name = "⬇️ 블롭 드롭 (Drop)",
    Callback = function() BlobAttackAll("drop") end
})

BlobTab:CreateSection("🔄 블롭 자동 킥")

local BlobLoopKickToggle = BlobTab:CreateToggle({
    Name = "🔄 블롭 자동 킥 (루프)",
    CurrentValue = false,
    Callback = function(Value)
        blobLoopT = Value
        if blobLoopT then
            BlobLoopKick()
            Rayfield:Notify({Title = "블롭 킥", Content = "자동 루프 시작", Duration = 2})
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
    Name = "Loop Grab",
    CurrentValue = false,
    Callback = function(Value)
        -- Loop Grab 기능
    end
})

local KickGrabToggle = GrabTab:CreateToggle({
    Name = "Kick Grab",
    CurrentValue = false,
    Callback = function(Value)
        -- Kick Grab 기능
    end
})

-- =============================================
-- [ 보안 탭 ]
-- =============================================
SecurityTab:CreateSection("🔰 방어 설정")

local AntiKickToggle = SecurityTab:CreateToggle({
    Name = "Anti-Kick",
    CurrentValue = false,
    Callback = function(Value)
        -- Anti-Kick 기능
    end
})

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

-- 안티 마스리스 토글 추가
local AntiMasslessToggle = SecurityTab:CreateToggle({
    Name = "⚖️ Anti-Massless (raw 기반)",
    CurrentValue = false,
    Callback = function(Value)
        antiMasslessEnabled = Value
        AntiMasslessF()
        Rayfield:Notify({Title = "안티 마스리스", Content = Value and "활성화" or "비활성화", Duration = 2})
    end
})

-- =============================================
-- [ 킬 플레이어 정하기 탭 ]
-- =============================================
TargetTab:CreateSection("🎯 킬 플레이어 정하기")

local TargetDropdown = TargetTab:CreateDropdown({
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
        TargetDropdown:Refresh(targetList, true)
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
                TargetDropdown:Refresh(targetList, true)
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
SettingsTab:CreateSection("⌨️ 단축키")

SettingsTab:CreateKeybind({
    Name = "PCLD 토글",
    CurrentKeybind = "F7",
    HoldToInteract = false,
    Callback = function()
        pcldViewEnabled = not pcldViewEnabled
        togglePcldView(pcldViewEnabled)
        PcldViewToggle:Set(pcldViewEnabled)
    end
})

SettingsTab:CreateKeybind({
    Name = "Barrier Noclip",
    CurrentKeybind = "F3",
    HoldToInteract = false,
    Callback = function()
        BarrierCanCollideT = not BarrierCanCollideT
        BarrierCanCollideF()
        BarrierNoclipToggle:Set(BarrierCanCollideT)
    end
})

SettingsTab:CreateKeybind({
    Name = "베리어 부수기",
    CurrentKeybind = "F4",
    HoldToInteract = false,
    Callback = PlotBarrierDelete
})

SettingsTab:CreateKeybind({
    Name = "IY UI 토글",
    CurrentKeybind = "F10",
    HoldToInteract = false,
    Callback = function()
        if _G and _G.ToggleUI then
            _G.ToggleUI = not _G.ToggleUI
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
    Content = "안티 마스리스 + 블롭 킥 추가됨",
    Duration = 5
})
