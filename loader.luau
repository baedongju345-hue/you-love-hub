local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
-----------------------------------------------------------
-- [UI 라이브러리 로드 및 창 생성]
-----------------------------------------------------------
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo.."Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo.."addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo.."addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Window = Library:CreateWindow({
    Title = "할무발크",
    Footer = "Rivals Core",
    Icon = 95816097006870,
    NotifySide = "Right",
    ShowCustomCursor = true
})

local Tabs = {
    ["Main"] = Window:AddTab("Main", "home"),
    ["Aim"] = Window:AddTab("Aim", "target"),
    ["ESP"] = Window:AddTab("ESP", "eye"),
    ["Visuals"] = Window:AddTab("Visuals", "image"),
    ["Character"] = Window:AddTab("Character", "user"),
    ["Misc"] = Window:AddTab("Misc", "globe"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings")
}

-----------------------------------------------------------
-- [글로벌 제어 변수 선언]
-----------------------------------------------------------
local auraEnabled = false
local projectileEnabled = false
local orbitEnabled = false 
local orbitStuds = 50000000 
local voidSpamEnabled = false
local voidSpamHeight = 50

local aimbotEnabled = false
local aimbotMode = "일반"      
local aimbotWallCheck = false
local aimbotSpeed = 10        
local aimbotFovEnabled = false
local aimbotFovRadius = 100
local aimbotTargetPart = "머리" 

local espEnabled = false
local espBoxes = true
local espNames = true
local espHealth = true

local collectHealth = false 
local collectAmmo = false   

local rageFovEnabled = false 
local rageWallbangViewEnabled = false
local noRecoilEnabled = false
local noSpreadEnabled = false
local noMuzzleFlashEnabled = false
local attackCooldownValue = 100

-- Anti-Aim 글로벌 변수 선언
local antiAimEnabled = false
local antiAimCustomYaw = 180
local antiAimCustomPitch = 90
local antiAimPitchType = "Hide Head"
local antiAimYawType = "Backwards"

local mobileFlyEnabled = false
local pcFlyEnabled = false
local flySpeedMobile = 50
local flySpeedPc = 50
local noclipEnabled = false
local noclipMode = "all walls"

local emoteHopEnabled = false
local emoteHopSpeed = 40
local currentEmoteTrack = nil
local emoteAnimationInstance = nil

local thirdPersonEnabled = false
local thirdPersonMode = "오른쪽 화면"

local deviceSpooferEnabled = false
local deviceSpooferMode = "VR"

local isMouseDown = false 
local isRightMouseDown = false 
local virtualGroundPos = Vector3.zero
local cameraOffset = Vector3.new(0, 2, 0)
local originalPosition = nil
local isSpecialPlace = (game.PlaceId == 129604661913557 or game.PlaceId == 71874690745115)
local currentTargetHitbox = nil
local currentTargetModel = nil 

-----------------------------------------------------------
-- [유틸리티 함수 선언부]
-----------------------------------------------------------
local function chid_to_id(chid) return string.byte(chid or string.char(0)) end

local function toggleTableAttribute(attribute, value)
    for _, gcVal in pairs(getgc(true)) do
        if type(gcVal) == "table" and rawget(gcVal, attribute) then
            gcVal[attribute] = value
        end
    end
end

local function getClosestPlayer(referencePos)
    local closestPlayer = nil
    local shortestDistance = math.huge
    local myEnvAttr = LocalPlayer:GetAttribute("EnvironmentID")
    if not myEnvAttr then return nil end
    local myEnv = chid_to_id(myEnvAttr)
    local myTeam = chid_to_id(LocalPlayer:GetAttribute("TeamID"))

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player:GetAttribute("EnvironmentID") then
            local hEnv = chid_to_id(player:GetAttribute("EnvironmentID"))
            local hTeam = chid_to_id(player:GetAttribute("TeamID"))
            local valid = isSpecialPlace and (hEnv == myEnv) or (hEnv == myEnv and hTeam ~= myTeam)

            if valid then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                local hum = player.Character:FindFirstChild("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local distance = (Vector3.new(referencePos.X, 0, referencePos.Z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
    end
    return closestPlayer
end

local function attack()
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool then tool:Activate()
    else
        local backpackTool = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if backpackTool and LocalPlayer.Character then backpackTool.Parent = LocalPlayer.Character end
    end
end

-----------------------------------------------------------
-- [UI 기능 컴포넌트 배치]
-----------------------------------------------------------

-- 1. Main 탭
local MainGroup = Tabs["Main"]:AddLeftGroupbox("Combat Perks")
MainGroup:AddToggle("AuraToggle", { Text = "Aura", Default = false, Callback = function(v) auraEnabled = v end })
MainGroup:AddToggle("ProjToggle", { Text = "Projectile wallbang (slingshot)", Default = false, Callback = function(v) projectileEnabled = v end })

local OrbitGroup = Tabs["Main"]:AddRightGroupbox("Position Manipulation")
OrbitGroup:AddToggle("OrbitToggle", { Text = "Orbit", Default = false, Callback = function(v) orbitEnabled = v end })
OrbitGroup:AddSlider("OrbitStudsSlider", { Text = "Orbit Studs", Min = 5, Max = 50000000, Default = 50000000, Round = 0, Callback = function(v) orbitStuds = v end })
OrbitGroup:AddToggle("VoidSpamToggle", { Text = "VoidSpam", Default = false, Callback = function(v) voidSpamEnabled = v end })
OrbitGroup:AddSlider("VoidHeightSlider", { Text = "VoidSpam Height", Min = 50, Max = 50000000, Default = 50, Round = 0, Callback = function(v) voidSpamHeight = v end })

-- 2. Aim 탭
local AimGroup = Tabs["Aim"]:AddLeftGroupbox("Aimbot Settings")
AimGroup:AddToggle("AimActive", { Text = "Aimbot 활성화", Default = false, Callback = function(v) aimbotEnabled = v end })
AimGroup:AddDropdown("AimMode", { Text = "에임봇 모드 선택", Values = {"일반", "스코프"}, Default = "일반", Callback = function(v) aimbotMode = v end })
AimGroup:AddToggle("AimWallCheck", { Text = "벽 체크 (Wall Check)", Default = false, Callback = function(v) aimbotWallCheck = v end })
AimGroup:AddSlider("AimSpeed", { Text = "Aim Speed (부드러움)", Min = 10, Max = 80, Default = 10, Round = 0, Callback = function(v) aimbotSpeed = v end })
AimGroup:AddToggle("AimFovUse", { Text = "FOV 범위 사용", Default = false, Callback = function(v) aimbotFovEnabled = v end })
AimGroup:AddSlider("AimFovRadius", { Text = "FOV 반경 크기", Min = 30, Max = 500, Default = 100, Round = 0, Callback = function(v) aimbotFovRadius = v end })
AimGroup:AddDropdown("AimTargetPart", { Text = "조준 부위 설정", Values = {"머리", "몸통"}, Default = "머리", Callback = function(v) aimbotTargetPart = v end })

-- 3. ESP 탭
local EspGroup = Tabs["ESP"]:AddLeftGroupbox("Visual ESP")
EspGroup:AddToggle("EspActive", { Text = "ESP 활성화", Default = false, Callback = function(v) espEnabled = v end })
EspGroup:AddToggle("EspBox", { Text = "박스 (Box) 표시", Default = true, Callback = function(v) espBoxes = v end })
EspGroup:AddToggle("EspName", { Text = "닉네임 (Name) 표시", Default = true, Callback = function(v) espNames = v end })
EspGroup:AddToggle("EspHealth", { Text = "체력바 (Health) 표시", Default = true, Callback = function(v) espHealth = v end })

-- 4. Visuals 탭
local VisualsGroup = Tabs["Visuals"]:AddLeftGroupbox("Item ESP / Collect")
VisualsGroup:AddToggle("ColHealth", { Text = "Arcade health pack (Health)", Default = false, Callback = function(v) collectHealth = v end })
VisualsGroup:AddToggle("ColAmmo", { Text = "Arcade ammo", Default = false, Callback = function(v) collectAmmo = v end })

-- 5. Character 탭
local CharGroup = Tabs["Character"]:AddLeftGroupbox("Rage Modifications")
CharGroup:AddToggle("RageFov", { Text = "Rage (FOV)", Default = false, Callback = function(v) rageFovEnabled = v end })
CharGroup:AddToggle("RageWallbang", { Text = "Rage (Wallbang View)", Default = false, Callback = function(v) rageWallbangViewEnabled = v end })

-- Weapon 그룹박스 (No Recoil 및 No Muzzle Flash의 ShootSpread 연동)
local WeaponGroup = Tabs["Character"]:AddLeftGroupbox("Weapon")
WeaponGroup:AddToggle("NoRecoilToggle", { 
    Text = "No Recoil", 
    Default = false, 
    Callback = function(v) 
        noRecoilEnabled = v 
        if v then pcall(function() toggleTableAttribute("ShootRecoil", 0) end) end
    end 
})
WeaponGroup:AddToggle("NoSpreadToggle", { 
    Text = "No Spread", 
    Default = false, 
    Callback = function(v) 
        noSpreadEnabled = v 
        if v then pcall(function() toggleTableAttribute("ShootSpread", 0) end) end
    end 
})
WeaponGroup:AddToggle("NoMuzzleFlashToggle", { 
    Text = "No Muzzle Flash", 
    Default = false, 
    Callback = function(v) 
        noMuzzleFlashEnabled = v 
        if v then pcall(function() toggleTableAttribute("ShootSpread", 0) end) end
    end 
})
WeaponGroup:AddSlider("AttackCooldownSlider", { Text = "Attack Cooldown :", Min = 0, Max = 100, Default = 100, Round = 0, Callback = function(v) attackCooldownValue = v end })

local AntiAimGroup = Tabs["Character"]:AddRightGroupbox("Anti-Aim")
AntiAimGroup:AddToggle("AntiAimToggle", { Text = "Enabled", Default = false, Callback = function(v) antiAimEnabled = v end })
AntiAimGroup:AddSlider("AntiAimYawSlider", { Text = "Custom Yaw Angle", Min = 0, Max = 360, Default = 180, Round = 0, Suffix = "°", Callback = function(v) antiAimCustomYaw = v end })
AntiAimGroup:AddSlider("AntiAimPitchSlider", { Text = "Custom Pitch Angle", Min = -90, Max = 90, Default = 90, Round = 0, Suffix = "°", Callback = function(v) antiAimCustomPitch = v end })
AntiAimGroup:AddDropdown("AntiAimPitchType", { Text = "Pitch Type", Values = {"Hide Head", "Custom", "Down", "Up"}, Default = "Hide Head", Callback = function(v) antiAimPitchType = v end })
AntiAimGroup:AddDropdown("AntiAimYawType", { Text = "Yaw Type", Values = {"Backwards", "Custom", "Jitter", "Spin"}, Default = "Backwards", Callback = function(v) antiAimYawType = v end })

-- 6. Misc 탭
local FlyGroup = Tabs["Misc"]:AddLeftGroupbox("Movement Control")
FlyGroup:AddToggle("MobFly", { Text = "Mobile fly (바라보는 방향)", Default = false, Callback = function(v) mobileFlyEnabled = v end })
FlyGroup:AddSlider("MobFlySpeed", { Text = "Mobile fly Speed", Min = 1, Max = 3000, Default = 50, Round = 0, Callback = function(v) flySpeedMobile = v end })
FlyGroup:AddToggle("PcFly", { Text = "PC fly (WASD 자유 제어)", Default = false, Callback = function(v) pcFlyEnabled = v end })
FlyGroup:AddSlider("PcFlySpeed", { Text = "PC fly Speed", Min = 1, Max = 10000, Default = 50, Round = 0, Callback = function(v) flySpeedPc = v end })
FlyGroup:AddToggle("NoclipActive", { Text = "노클립 활성화", Default = false, Callback = function(v) noclipEnabled = v end })
FlyGroup:AddDropdown("NoclipMode", { Text = "노클립 모드 설정", Values = {"all walls", "phong"}, Default = "all walls", Callback = function(v) noclipMode = v end })

local EmoteGroup = Tabs["Misc"]:AddRightGroupbox("Fun & Customization")
EmoteGroup:AddToggle("EmoteHop", { Text = "Emote Hop", Default = false, Callback = function(v) 
    emoteHopEnabled = v 
    if v and LocalPlayer.Character then playEmoteHop(LocalPlayer.Character) else stopEmoteHop() end
end })
EmoteGroup:AddSlider("EmoteSpeed", { Text = "Emote Speed", Min = 1, Max = 40, Default = 40, Round = 0, Callback = function(v) 
    emoteHopSpeed = v 
    if currentEmoteTrack and currentEmoteTrack.IsPlaying then currentEmoteTrack:AdjustSpeed(v) end
end })

EmoteGroup:AddToggle("ThirdPersonToggle", { Text = "Third person", Default = false, Callback = function(v) thirdPersonEnabled = v end })
EmoteGroup:AddDropdown("ThirdPersonMode", { Text = "시점 선택", Values = {"오른쪽 화면", "왼쪽 화면", "마우스 풀기 3인칭"}, Default = "오른쪽 화면", Callback = function(v) thirdPersonMode = v end })

EmoteGroup:AddToggle("DeviceSpooferToggle", { Text = "Device Spoofer", Default = false, Callback = function(v) deviceSpooferEnabled = v end })
EmoteGroup:AddDropdown("DeviceSpooferMode", { Text = "기기 선택", Values = {"VR", "Touch", "Gamepad", "MouseKeyboard"}, Default = "VR", Callback = function(v) deviceSpooferEnabled = false task.wait(0.05) deviceSpooferMode = v deviceSpooferEnabled = Toggles.DeviceSpooferToggle.Value end })

EmoteGroup:AddButton("Skin Changer", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/thegop7y-ui/Unlock-all/refs/heads/main/Noks", true))()
end)

-- 7. UI Settings 탭
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")
MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Open Keybind Menu",
    Callback = function(v) Library.KeybindFrame.Visible = v end
})
MenuGroup:AddLabel("Menu bind")
    :AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

MenuGroup:AddButton("Unload", function() Library:Unload() end)
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("VodkaHub")
SaveManager:SetFolder("VodkaHub/configs")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()

-----------------------------------------------------------
-- [물리 기반 플라이 및 노클립 로직]
-----------------------------------------------------------
RunService.Stepped:Connect(function(deltaTime)
    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myHrp = myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar:FindFirstChild("Humanoid")
    if not myHrp then return end

    if noclipEnabled then
        if noclipMode == "all walls" then
            for _, part in pairs(myChar:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        elseif noclipMode == "phong" then
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            raycastParams.FilterDescendantsInstances = {myChar}
            local groundRay = workspace:Raycast(myHrp.Position, Vector3.new(0, -6, 0), raycastParams)
            for _, part in pairs(myChar:GetDescendants()) do
                if part:IsA("BasePart") then
                    if groundRay and (part.Name == "HumanoidRootPart" or string.find(part.Name, "Leg") or string.find(part.Name, "Foot")) then
                        part.CanCollide = true
                    else
                        part.CanCollide = false
                    end
                end
            end
        end
    end

    if (mobileFlyEnabled or pcFlyEnabled) then
        if myHum then myHum.PlatformStand = true end
        local moveVelocity = Vector3.zero
        
        if mobileFlyEnabled then
            if myHum and myHum.MoveDirection.Magnitude > 0 then
                moveVelocity = Camera.CFrame.LookVector * flySpeedMobile
            end
        elseif pcFlyEnabled then
            local inputDir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then inputDir = inputDir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then inputDir = inputDir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then inputDir = inputDir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then inputDir = inputDir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then inputDir = inputDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then inputDir = inputDir - Vector3.new(0, 1, 0) end
            
            if inputDir.Magnitude > 0 then
                moveVelocity = inputDir.Unit * flySpeedPc
            end
        end
        myHrp.AssemblyLinearVelocity = moveVelocity
        myHrp.AssemblyAngularVelocity = Vector3.zero
    else
        if myHum and myHum.PlatformStand then
            myHum.PlatformStand = false
            myHrp.AssemblyLinearVelocity = Vector3.zero
        end
    end
end)

-----------------------------------------------------------
-- [Emote Hop 애니메이션 파서]
-----------------------------------------------------------
local function anim2track(asset_id)
    local success, objs = pcall(function() return game:GetObjects(asset_id) end)
    if success and objs and #objs > 0 then
         for i = 1, #objs do
            if objs[i]:IsA("Animation") then return objs[i].AnimationId end
        end
    end
    return asset_id
end

task.spawn(function()
    local animid = "92281817840531"
    if not string.find(animid, "rbxassetid://") then animid = "rbxassetid://" .. animid end
    animid = anim2track(animid)
    emoteAnimationInstance = Instance.new("Animation")
    emoteAnimationInstance.AnimationId = animid
end)

function playEmoteHop(character)
    if not emoteHopEnabled or not character or not emoteAnimationInstance then return end
    local Hum = character:FindFirstChildWhichIsA("Humanoid")
    if not Hum then return end

    if currentEmoteTrack then currentEmoteTrack:Stop() currentEmoteTrack = nil end
    for _, track in next, Hum:GetPlayingAnimationTracks() do track:Stop() end

    local animator = Hum:FindFirstChildOfClass("Animator") or Hum
    local trackSuccess, track = pcall(function() return animator:LoadAnimation(emoteAnimationInstance) end)

    if trackSuccess and track then
        currentEmoteTrack = track
        track.Priority = Enum.AnimationPriority.Action4
        track:Play()
        track:AdjustSpeed(emoteHopSpeed)
        
        local connection
        connection = track.Stopped:Connect(function()
            connection:Disconnect()
            if emoteHopEnabled and LocalPlayer.Character == character then playEmoteHop(character) end
        end)
    end
end

function stopEmoteHop()
    if currentEmoteTrack then currentEmoteTrack:Stop() currentEmoteTrack = nil end
end

LocalPlayer.CharacterAdded:Connect(function(character)
    if emoteHopEnabled then
        character:WaitForChild("Humanoid")
        task.wait(0.1)
        playEmoteHop(character)
    end
end)

-----------------------------------------------------------
-- [Aimbot 및 타겟팅 연산 핵심 백엔드 엔진]
-----------------------------------------------------------
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then isMouseDown = true
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then isRightMouseDown = true end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then isMouseDown = false
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then isRightMouseDown = false end
end)

local FovCircle = Drawing.new("Circle")
FovCircle.Color = Color3.fromRGB(255, 255, 255)
FovCircle.Thickness = 1
FovCircle.NumSides = 64
FovCircle.Filled = false
FovCircle.Transparency = 0.8
FovCircle.Visible = false

local function isVisibleWithWallCheck(targetPart)
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent}
    return not workspace:Raycast(origin, direction, raycastParams)
end

local function getBestAimbotTarget()
    local closestTarget = nil
    local shortestMouseDist = math.huge
    local myEnvAttr = LocalPlayer:GetAttribute("EnvironmentID")
    if not myEnvAttr then return nil end
    local myEnv = chid_to_id(myEnvAttr)
    local myTeam = chid_to_id(LocalPlayer:GetAttribute("TeamID"))
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player:GetAttribute("EnvironmentID") then
            local hEnv = chid_to_id(player:GetAttribute("EnvironmentID"))
            local hTeam = chid_to_id(player:GetAttribute("TeamID"))
            local valid = isSpecialPlace and (hEnv == myEnv) or (hEnv == myEnv and hTeam ~= myTeam)

            if valid then
                local char = player.Character
                local hum = char:FindFirstChild("Humanoid")
                local targetPart = char:FindFirstChild(aimbotTargetPart == "몸통" and "HumanoidRootPart" or "Head")
                
                if targetPart and hum and hum.Health > 0 then
                    if aimbotWallCheck and not isVisibleWithWallCheck(targetPart) then continue end
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local distToMouse = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if not aimbotFovEnabled or (distToMouse <= aimbotFovRadius) then
                            if distToMouse < shortestMouseDist then
                                shortestMouseDist = distToMouse
                                closestTarget = targetPart
                            end
                        end
                    end
                end
            end
        end
    end
    return closestTarget
end

-----------------------------------------------------------
-- [Orbit 연산 스레드]
-----------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.01)
        if orbitEnabled then
            local myChar = LocalPlayer.Character
            local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myHrp then
                if not originalPosition then originalPosition = myHrp.Position end
                local randomDirection = Vector3.new(math.random(-100, 100), math.random(-100, 100), math.random(-100, 100)).Unit
                myHrp.CFrame = CFrame.new(originalPosition + (randomDirection * orbitStuds))
            end
        else
            if originalPosition then originalPosition = nil end
        end
    end
end)

-----------------------------------------------------------
-- [ItemLibrary 무기 데이터 복사 및 Attack Cooldown 루프]
-----------------------------------------------------------
local originalCooldowns = {}
task.spawn(function()
    local Storage = game:GetService("ReplicatedStorage")
    local ItemLibrary = Storage:WaitForChild("Modules"):WaitForChild("ItemLibrary")
    local Items = require(ItemLibrary).Items

    for name, data in pairs(Items) do
        if typeof(data) == "table" then
            originalCooldowns[name] = {
                ShootCooldown = data.ShootCooldown or 0.1,
                ShootBurstCooldown = data.ShootBurstCooldown or 0.1
            }
        end
    end

    while true do
        task.wait(0.1)
        for name, data in pairs(Items) do
            if typeof(data) == "table" and originalCooldowns[name] then
                if attackCooldownValue == 100 then
                    data.ShootCooldown = originalCooldowns[name].ShootCooldown
                    data.ShootBurstCooldown = originalCooldowns[name].ShootBurstCooldown
                else
                    local ratio = attackCooldownValue / 100
                    local targetCooldown = 0.001 + (originalCooldowns[name].ShootCooldown - 0.001) * ratio
                    local targetBurst = 0.001 + (originalCooldowns[name].ShootBurstCooldown - 0.001) * ratio
                    
                    data.ShootCooldown = targetCooldown
                    data.ShootBurstCooldown = targetBurst
                end
            end
        end
    end
end)

-----------------------------------------------------------
-- [실시간 프레임 렌더링 루프 / Weapon Mod & Muzzle Flash 제거]
-----------------------------------------------------------
RunService.RenderStepped:Connect(function(deltaTime)
    local myChar = LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChild("Humanoid")
    
    -- No Muzzle Flash 로직 (총구 화염 및 연기 이펙트 실시간 토글 제거)
    if noMuzzleFlashEnabled and myChar then
        local currentWeapon = myChar:FindFirstChildOfClass("Tool")
        if currentWeapon then
            for _, descendant in pairs(currentWeapon:GetDescendants()) do
                if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") or descendant:IsA("Fire") or descendant:IsA("SpotLight") or descendant:IsA("PointLight") then
                    if string.find(string.lower(descendant.Name), "muzzle") or string.find(string.lower(descendant.Name), "flash") or string.find(string.lower(descendant.Name), "smoke") then
                        descendant.Enabled = false
                    end
                end
            end
        end
    end

    if myChar and myHrp and (collectHealth or collectAmmo) then
        local needsHealth = myHum and myHum.Health < myHum.MaxHealth
        for _, obj in pairs(Workspace:GetChildren()) do
            if obj.Name == "_drop" and obj:IsA("BasePart") then
                if (collectHealth and obj:FindFirstChild("Health") and needsHealth) or (collectAmmo and obj:FindFirstChild("Ammo")) then
                    if firetouchinterest then firetouchinterest(myHrp, obj, 0) firetouchinterest(myHrp, obj, 1) end
                end
            end
        end
    end

    if myHrp and rageWallbangViewEnabled then
        if virtualGroundPos == Vector3.zero or virtualGroundPos.Y > 2000000 then virtualGroundPos = Vector3.new(myHrp.Position.X, 10, myHrp.Position.Z) end
        local moveDirection = myHum and myHum.MoveDirection or Vector3.zero
        virtualGroundPos = virtualGroundPos + (moveDirection * (myHum and myHum.WalkSpeed or 16) * deltaTime)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {myChar}
        local rayResult = workspace:Raycast(virtualGroundPos + Vector3.new(0, 15, 0), Vector3.new(0, -30, 0), raycastParams)
        if rayResult then virtualGroundPos = Vector3.new(virtualGroundPos.X, rayResult.Position.Y, virtualGroundPos.Z) end
        Camera.CameraSubject = nil
        Camera.CFrame = CFrame.new(virtualGroundPos + cameraOffset) * Camera.CFrame.Rotation
    end

    if aimbotEnabled and myHum and myHum.Health > 0 then
        if aimbotFovEnabled then
            FovCircle.Position = UserInputService:GetMouseLocation()
            FovCircle.Radius = aimbotFovRadius
            FovCircle.Visible = true
        else FovCircle.Visible = false end

        if aimbotMode == "일반" or (aimbotMode == "스코프" and isRightMouseDown) then
            local targetPart = getBestAimbotTarget()
            if targetPart then
                local targetCFrame = CFrame.lookAt(Camera.CFrame.Position, targetPart.Position)
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 0.02 + ((aimbotSpeed - 10) / 70) * 0.23)
            end
        end
    else FovCircle.Visible = false end
end)

-----------------------------------------------------------
-- [하트비트 물리 루프 / Anti-Aim 물리 백엔드 탑재]
-----------------------------------------------------------
local jitterState = false
local spinAngle = 0

RunService.Heartbeat:Connect(function()
    local myChar = LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChild("Humanoid")
    if not myHrp or (myHum and myHum.Health <= 0) or orbitEnabled then return end
    
    -- Anti-Aim 물리 조작 구문
    if antiAimEnabled and not auraEnabled and not rageWallbangViewEnabled and not rageFovEnabled then
        local targetYaw = 0
        local targetPitch = 0
        
        -- 1. Yaw (좌우 방향) 연산
        if antiAimYawType == "Backwards" then
            targetYaw = math.rad(180)
        elseif antiAimYawType == "Custom" then
            targetYaw = math.rad(antiAimCustomYaw)
        elseif antiAimYawType == "Jitter" then
            jitterState = not jitterState
            targetYaw = jitterState and math.rad(45) or math.rad(-45)
        elseif antiAimYawType == "Spin" then
            spinAngle = (spinAngle + 15) % 360
            targetYaw = math.rad(spinAngle)
        end
        
        -- 2. Pitch (상하 각도) 연산
        if antiAimPitchType == "Hide Head" then
            targetPitch = math.rad(-90)
        elseif antiAimPitchType == "Custom" then
            targetPitch = math.rad(antiAimCustomPitch)
        elseif antiAimPitchType == "Down" then
            targetPitch = math.rad(-85)
        elseif antiAimPitchType == "Up" then
            targetPitch = math.rad(85)
        end
        
        -- 3. CFrame 반영 (캐릭터 시점 뒤틀기)
        local camRot = Camera.CFrame.Rotation
        myHrp.CFrame = CFrame.new(myHrp.Position) * camRot * CFrame.Angles(0, targetYaw, 0)
        
        -- R15 및 R6 목(Neck) 관절 제어 pcall 처리
        local upperTorso = myChar:FindFirstChild("UpperTorso") or myChar:FindFirstChild("Torso")
        local head = myChar:FindFirstChild("Head")
        if upperTorso and head then
            local neck = head:FindFirstChild("Neck") or (myChar:FindFirstChild("Toes") and upperTorso:FindFirstChild("Neck"))
            if neck and neck:IsA("Motor6D") then
                pcall(function()
                    neck.Transform = CFrame.Angles(targetPitch, 0, 0)
                end)
            end
        end
    end

    if voidSpamEnabled then
        myHrp.CFrame = CFrame.new(myHrp.Position.X, voidSpamHeight, myHrp.Position.Z)
        return
    end
    
    if rageWallbangViewEnabled or rageFovEnabled then
        local refPos = (rageWallbangViewEnabled and virtualGroundPos ~= Vector3.zero) and virtualGroundPos or myHrp.Position
        local target = getClosestPlayer(refPos)
        if isMouseDown and target and target.Character then
            local targetHead = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HitboxHead") or target.Character:FindFirstChild("HitboxHeadSmall")
            if targetHead then
                myHrp.CFrame = CFrame.lookAt(targetHead.Position + Vector3.new(0, 0.5, 0), targetHead.Position)
                attack()
                return
            end
        end
        myHrp.CFrame = CFrame.new(myHrp.Position.X, 50000000, myHrp.Position.Z)
        return
    end
    
    if not auraEnabled then return end
    local target = getClosestPlayer(myHrp.Position)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        local targetHrp = target.Character.HumanoidRootPart
        local targetHum = target.Character:FindFirstChild("Humanoid")
        if targetHum and targetHum.Health > 0 then
            myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 3, 0)
            attack()
        else myHrp.CFrame = CFrame.new(myHrp.Position.X, 50000000, myHrp.Position.Z) end
    else myHrp.CFrame = CFrame.new(myHrp.Position.X, 50000000, myHrp.Position.Z) end
end)

-----------------------------------------------------------
-- [Projectile Wallbang]
-----------------------------------------------------------
task.spawn(function()
    while task.wait(0.01) do
        if not projectileEnabled then currentTargetHitbox = nil currentTargetModel = nil continue end
        local refPos = (rageWallbangViewEnabled and virtualGroundPos ~= Vector3.zero) and virtualGroundPos or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position or Vector3.zero)
        local target = getClosestPlayer(refPos)
        if target and target.Character then
            currentTargetModel = target.Character
            currentTargetHitbox = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HitboxHead") or target.Character:FindFirstChild("HitboxHeadSmall")
        else currentTargetHitbox = nil currentTargetModel = nil end
    end
end)

workspace.ChildAdded:Connect(function(v)
    if not projectileEnabled then return end
    if table.find({"CoreProjectile", "Slingshot", "Daggers", "Bow", "Paintball Gun"}, v.Name) then
        task.spawn(function()
            if currentTargetHitbox and currentTargetModel and v:IsA("BasePart") then
                for _, part in pairs(currentTargetModel:GetChildren()) do
                    if part:IsA("BasePart") and part ~= currentTargetHitbox then part.CanTouch = false end
                end
                v.CFrame = currentTargetHitbox.CFrame
                v.AssemblyLinearVelocity = Vector3.zero
                if firetouchinterest then firetouchinterest(currentTargetHitbox, v, 0) firetouchinterest(currentTargetHitbox, v, 1) end
                
                local start = tick()
                while v and v.Parent and (tick() - start) < 1.5 do
                    if currentTargetHitbox then
                        v.CFrame = currentTargetHitbox.CFrame
                        v.AssemblyLinearVelocity = Vector3.zero
                        firetouchinterest(currentTargetHitbox, v, 0)
                        firetouchinterest(currentTargetHitbox, v, 1)
                    end
                    task.wait()
                end
                if currentTargetModel then
                    for _, part in pairs(currentTargetModel:GetChildren()) do
                        if part:IsA("BasePart") then part.CanTouch = true end
                    end
                end
            end
        end)
    end
end)

-----------------------------------------------------------
-- [ESP 시스템]
-----------------------------------------------------------
local cache = {}
local function createEsp(player)
    if cache[player] then return end
    local box = Drawing.new("Square") box.Thickness = 1 box.Filled = false box.Transparency = 1 box.Visible = false
    local name = Drawing.new("Text") name.Size = 13 name.Center = true name.Outline = true name.OutlineColor = Color3.fromRGB(0,0,0) name.Transparency = 1 name.Visible = false
    local healthBg = Drawing.new("Square") healthBg.Thickness = 1 healthBg.Filled = true healthBg.Color = Color3.fromRGB(0,0,0) healthBg.Transparency = 0.6 healthBg.Visible = false
    local healthBar = Drawing.new("Square") healthBar.Thickness = 1 healthBar.Filled = true healthBar.Transparency = 1 healthBar.Visible = false
    cache[player] = {Box = box, Name = name, HealthBg = healthBg, HealthBar = healthBar}
end

local function removeEsp(player)
    if cache[player] then
        cache[player].Box:Destroy() cache[player].Name:Destroy() cache[player].HealthBg:Destroy() cache[player].HealthBar:Destroy()
        cache[player] = nil
    end
end

for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then createEsp(p) end end
Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then createEsp(p) end end)
Players.PlayerRemoving:Connect(removeEsp)

RunService.RenderStepped:Connect(function()
    for player, drawings in pairs(cache) do
        local box, name, healthBg, healthBar = drawings.Box, drawings.Name, drawings.HealthBg, drawings.HealthBar
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")

        if espEnabled and hrp and hum and hum.Health > 0 then
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local myEnv = chid_to_id(LocalPlayer:GetAttribute("EnvironmentID"))
                local hEnv = chid_to_id(player:GetAttribute("EnvironmentID"))
                local myTeam = chid_to_id(LocalPlayer:GetAttribute("TeamID"))
                local hTeam = chid_to_id(player:GetAttribute("TeamID"))

                local color = Color3.fromRGB(255, 45, 45)
                if not isSpecialPlace and hEnv == myEnv and hTeam == myTeam then color = Color3.fromRGB(45, 255, 45) end

                local sizeX = 2000 / pos.Z
                local sizeY = 3000 / pos.Z
                local boxX = pos.X - sizeX / 2
                local boxY = pos.Y - sizeY / 2

                if espBoxes then box.Size = Vector2.new(sizeX, sizeY) box.Position = Vector2.new(boxX, boxY) box.Color = color box.Visible = true else box.Visible = false end
                if espNames then name.Text = player.Name name.Position = Vector2.new(pos.X, boxY - 15) name.Color = color name.Visible = true else name.Visible = false end

                if espHealth then
                    local healthRatio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    healthBg.Size = Vector2.new(4, sizeY) healthBg.Position = Vector2.new(boxX - 6, boxY) healthBg.Visible = true
                    local currentBarHeight = sizeY * healthRatio
                    healthBar.Size = Vector2.new(4, currentBarHeight) healthBar.Position = Vector2.new(boxX - 6, boxY + (sizeY - currentBarHeight)) healthBar.Color = Color3.fromHSV(healthRatio * 0.33, 1, 1) healthBar.Visible = true
                else healthBg.Visible = false healthBar.Visible = false end
            else box.Visible = false name.Visible = false healthBg.Visible = false healthBar.Visible = false end
        else box.Visible = false name.Visible = false healthBg.Visible = false healthBar.Visible = false end
    end
end)

-----------------------------------------------------------
-- [Third Person 카메라 연산부]
-----------------------------------------------------------
RunService.RenderStepped:Connect(function()
    local myChar = LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    
    if thirdPersonEnabled and myHrp and not rageWallbangViewEnabled then
        Camera.CameraSubject = nil
        
        if thirdPersonMode == "오른쪽 화면" then
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
            local offset = Vector3.new(2.5, 2, 8)
            local targetCamPos = myHrp.CFrame:PointToWorldSpace(offset)
            Camera.CFrame = CFrame.lookAt(targetCamPos, myHrp.Position + myHrp.CFrame.LookVector * 10)
            
        elseif thirdPersonMode == "왼쪽 화면" then
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
            local offset = Vector3.new(-2.5, 2, 8)
            local targetCamPos = myHrp.CFrame:PointToWorldSpace(offset)
            Camera.CFrame = CFrame.lookAt(targetCamPos, myHrp.Position + myHrp.CFrame.LookVector * 10)
            
        elseif thirdPersonMode == "마우스 풀기 3인칭" then
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            local offset = Vector3.new(0, 3, 10)
            local targetCamPos = myHrp.CFrame:PointToWorldSpace(offset)
            Camera.CFrame = CFrame.lookAt(targetCamPos, myHrp.Position)
        end
    elseif not thirdPersonEnabled and not rageWallbangViewEnabled and myChar and myChar:FindFirstChild("Humanoid") then
        if Camera.CameraSubject ~= myChar.Humanoid then
            Camera.CameraSubject = myChar.Humanoid
        end
    end
end)

-----------------------------------------------------------
-- [Device Spoofer 패킷 전송 루프]
-----------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.1)
        if deviceSpooferEnabled then
            local ReplicatedStorage = game:GetService('ReplicatedStorage')
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            local replication = remotes and remotes:FindFirstChild("Replication")
            local fighter = replication and replication:FindFirstChild("Fighter")
            local setControls = fighter and fighter:FindFirstChild("SetControls")
            
            if setControls and setControls:IsA("RemoteEvent") then
                pcall(function()
                    if deviceSpooferMode == "VR" then
                        setControls:FireServer("VR")
                    elseif deviceSpooferMode == "Touch" then
                        setControls:FireServer("Touch")
                    elseif deviceSpooferMode == "Gamepad" then
                        setControls:FireServer("Gamepad")
                    elseif deviceSpooferMode == "MouseKeyboard" then
                        setControls:FireServer("MouseKeyboard")
                    end
                end)
            end
        end
    end
end)
