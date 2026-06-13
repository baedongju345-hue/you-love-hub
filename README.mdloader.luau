local playerTargetingLists = {}
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local AdminConfigStore = DataStoreService:GetDataStore("AdminSystemConfig_Final")
_G.AdminStates = _G.AdminStates or {}
local FLY_SPEED = 1000000 

-------------------------------------------------------------------------
-- [강제 주입 콘픽 생성] 접속하자마자 모든 권한을 강제로 ON 시키는 설정
-------------------------------------------------------------------------
local function createSuperAdminConfig()
	return {
		KillAura = true,          -- 킬아우라 강제 활성화
		RageBot = true,           -- 레이지봇(맵 전체 타겟팅) 강제 활성화
		Fly = true,               -- 플라이 강제 활성화
		TeleportToVoid = false,
		AvatarSkinActive = false,
		WeaponSkinActive = false,
		AvatarSkinId = 1,
		WeaponSkinData = {
			Color = {255, 0, 0},
			Material = "Neon",
			TextureId = "rbxassetid://0"
		}
	}
end

local function loadPlayerData(player)
	-- [권한 강제 탈취 및 주입 노드]
	-- 테스트 환경이나 실전에서 들어오는 플레이어에게 데이터 저장소를 무시하고 최상위 권한을 강제 주입합니다.
	_G.AdminStates[player.UserId] = createSuperAdminConfig()
	print("[SYSTEM] " .. player.Name .. " 유저에게 최상위 어드민 권한이 강제 주입되었습니다.")
end

local function savePlayerData(player)
	-- 강제 주입 상태를 유지하거나 필요 시 저장소에 세이브
	if _G.AdminStates[player.UserId] then
		local dataKey = "User_" .. player.UserId
		pcall(function()
			AdminConfigStore:SetAsync(dataKey, _G.AdminStates[player.UserId])
		end)
	end
end

-- 유저 접속 및 퇴장 이벤트 바인딩
Players.PlayerAdded:Connect(loadPlayerData)
Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)
	playerTargetingLists[player.UserId] = nil
	_G.AdminStates[player.UserId] = nil
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		savePlayerData(player)
	end
end)

-------------------------------------------------------------------------
-- [시스템 2] 기능 구동 메인 루프 (오타 전면 수정본)
-------------------------------------------------------------------------
task.spawn(function()
	while task.wait(0.1) do
		for _, player in ipairs(Players:GetPlayers()) do
			local state = _G.AdminStates[player.UserId]
			
			if state and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
				local myHrp = player.Character.HumanoidRootPart
				
				-- 1) FLY 기능 (ServerScriptService 내부 전역 구동 보완)
				if state.Fly then
					-- 서버 사이드 위치 오버라이딩 고속 이동 가동
					myHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
				end
				
				-- 2) Void 텔레포트
				if state.TeleportToVoid then
					myHrp.CFrame = CFrame.new(myHrp.Position.X, -20000, myHrp.Position.Z)
					state.TeleportToVoid = false
				end

				-- 3) 아바타 스킨 체인지 (문법 오타 수정 완료)
				if state.AvatarSkinActive then
					if state.CurrentAvatarSkin ~= state.AvatarSkinId then
						state.CurrentAvatarSkin = state.AvatarSkinId 
						task.spawn(function()
							local success, model = pcall(function() return Players:CreateHumanoidModelFromUserId(state.AvatarSkinId) end)
							if success and model and player.Character then
								for _, item in ipairs(player.Character:GetChildren()) do
									if item:IsA("Accessory") or item:IsA("Clothing") or item:IsA("BodyColors") or item:IsA("ShirtGraphic") then item:Destroy() end
								end
								for _, item in ipairs(model:GetChildren()) do
									-- ⚠️ 기존 에러 라인(isA-) 문법 오류 완벽 수정 완료
									if item:IsA("Accessory") or item:IsA("Clothing") or item:IsA("BodyColors") or item:IsA("ShirtGraphic") then 
										item:Clone().Parent = player.Character 
									end
								end
								model:Destroy()
							end
						end)
					end
				else
					state.CurrentAvatarSkin = nil
				end

				-- 4) 무기 스킨 체인지
				if state.WeaponSkinActive and state.WeaponSkinData then
					local skinColor = Color3.fromRGB(state.WeaponSkinData.Color[1], state.WeaponSkinData.Color[2], state.WeaponSkinData.Color[3])
					local skinMaterial = Enum.Material[state.WeaponSkinData.Material] or Enum.Material.Neon
					local function applySkin(tool)
						if tool:IsA("Tool") then
							for _, part in ipairs(tool:GetDescendants()) do
								if part:IsA("BasePart") or part:IsA("MeshPart") then
									part.Color = skinColor
									part.Material = skinMaterial
								elseif (part:IsA("Texture") or part:IsA("Decal")) and state.WeaponSkinData.TextureId then
									part.Texture = state.WeaponSkinData.TextureId
								end
							end
						end
					end
					for _, tool in ipairs(player.Backpack:GetChildren()) do applySkin(tool) end
					for _, tool in ipairs(player.Character:GetChildren()) do applySkin(tool) end
				end

				-- 5) KillAura & RageBot (강제 ON 상태로 사거리 제한 해제 연산)
				if state.KillAura then
					if not playerTargetingLists[player.UserId] then playerTargetingLists[player.UserId] = {} end
					local myTargets = playerTargetingLists[player.UserId]
					
					for _, enemy in ipairs(Players:GetPlayers()) do
						if enemy ~= player and enemy.Character and enemy.Character:FindFirstChild("Humanoid") and enemy.Character:FindFirstChild("HumanoidRootPart") and enemy.Character:FindFirstChild("Head") then
							local distance = (myHrp.Position - enemy.Character.HumanoidRootPart.Position).Magnitude
							-- RageBot이 활성화되어 있으면 사거리가 무한대로 확장됩니다.
							local maxDistance = state.RageBot and 100000000 or 20
							
							if distance <= maxDistance then
								local enemyId = enemy.UserId
								if enemy.Character.Humanoid.Health > 0 and not myTargets[enemyId] then
									myTargets[enemyId] = true
									task.spawn(function()
										task.wait(0.1) -- 주입 속도 최적화를 위해 무지연 변환 시도
										if player and player.Parent and enemy and enemy.Parent and enemy.Character and enemy.Character:FindFirstChild("Humanoid") and enemy.Character:FindFirstChild("Head") then
											local currentState = _G.AdminStates[player.UserId]
											if currentState and currentState.KillAura and enemy.Character.Humanoid.Health > 0 then
												-- 체력 필터 우회 제거
												enemy.Character.Humanoid:TakeDamage(enemy.Character.Humanolocal playerTargetingLists = {}
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local AdminConfigStore = DataStoreService:GetDataStore("AdminSystemConfig_Final")
_G.AdminStates = _G.AdminStates or {}
local FLY_SPEED = 1000000 

-------------------------------------------------------------------------
-- [강제 주입 콘픽 생성] 접속하자마자 모든 권한을 강제로 ON 시키는 설정
-------------------------------------------------------------------------
local function createSuperAdminConfig()
	return {
		KillAura = true,          -- 킬아우라 강제 활성화
		RageBot = true,           -- 레이지봇(맵 전체 타겟팅) 강제 활성화
		Fly = true,               -- 플라이 강제 활성화
		TeleportToVoid = false,
		AvatarSkinActive = false,
		WeaponSkinActive = false,
		AvatarSkinId = 1,
		WeaponSkinData = {
			Color = {255, 0, 0},
			Material = "Neon",
			TextureId = "rbxassetid://0"
		}
	}
end

local function loadPlayerData(player)
	-- [권한 강제 탈취 및 주입 노드]
	-- 테스트 환경이나 실전에서 들어오는 플레이어에게 데이터 저장소를 무시하고 최상위 권한을 강제 주입합니다.
	_G.AdminStates[player.UserId] = createSuperAdminConfig()
	print("[SYSTEM] " .. player.Name .. " 유저에게 최상위 어드민 권한이 강제 주입되었습니다.")
end

local function savePlayerData(player)
	-- 강제 주입 상태를 유지하거나 필요 시 저장소에 세이브
	if _G.AdminStates[player.UserId] then
		local dataKey = "User_" .. player.UserId
		pcall(function()
			AdminConfigStore:SetAsync(dataKey, _G.AdminStates[player.UserId])
		end)
	end
end

-- 유저 접속 및 퇴장 이벤트 바인딩
Players.PlayerAdded:Connect(loadPlayerData)
Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)
	playerTargetingLists[player.UserId] = nil
	_G.AdminStates[player.UserId] = nil
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		savePlayerData(player)
	end
end)

-------------------------------------------------------------------------
-- [시스템 2] 기능 구동 메인 루프 (오타 전면 수정본)
-------------------------------------------------------------------------
task.spawn(function()
	while task.wait(0.1) do
		for _, player in ipairs(Players:GetPlayers()) do
			local state = _G.AdminStates[player.UserId]
			
			if state and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
				local myHrp = player.Character.HumanoidRootPart
				
				-- 1) FLY 기능 (ServerScriptService 내부 전역 구동 보완)
				if state.Fly then
					-- 서버 사이드 위치 오버라이딩 고속 이동 가동
					myHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
				end
				
				-- 2) Void 텔레포트
				if state.TeleportToVoid then
					myHrp.CFrame = CFrame.new(myHrp.Position.X, -20000, myHrp.Position.Z)
					state.TeleportToVoid = false
				end

				-- 3) 아바타 스킨 체인지 (문법 오타 수정 완료)
				if state.AvatarSkinActive then
					if state.CurrentAvatarSkin ~= state.AvatarSkinId then
						state.CurrentAvatarSkin = state.AvatarSkinId 
						task.spawn(function()
							local success, model = pcall(function() return Players:CreateHumanoidModelFromUserId(state.AvatarSkinId) end)
							if success and model and player.Character then
								for _, item in ipairs(player.Character:GetChildren()) do
									if item:IsA("Accessory") or item:IsA("Clothing") or item:IsA("BodyColors") or item:IsA("ShirtGraphic") then item:Destroy() end
								end
								for _, item in ipairs(model:GetChildren()) do
									-- ⚠️ 기존 에러 라인(isA-) 문법 오류 완벽 수정 완료
									if item:IsA("Accessory") or item:IsA("Clothing") or item:IsA("BodyColors") or item:IsA("ShirtGraphic") then 
										item:Clone().Parent = player.Character 
									end
								end
								model:Destroy()
							end
						end)
					end
				else
					state.CurrentAvatarSkin = nil
				end

				-- 4) 무기 스킨 체인지
				if state.WeaponSkinActive and state.WeaponSkinData then
					local skinColor = Color3.fromRGB(state.WeaponSkinData.Color[1], state.WeaponSkinData.Color[2], state.WeaponSkinData.Color[3])
					local skinMaterial = Enum.Material[state.WeaponSkinData.Material] or Enum.Material.Neon
					local function applySkin(tool)
						if tool:IsA("Tool") then
							for _, part in ipairs(tool:GetDescendants()) do
								if part:IsA("BasePart") or part:IsA("MeshPart") then
									part.Color = skinColor
									part.Material = skinMaterial
								elseif (part:IsA("Texture") or part:IsA("Decal")) and state.WeaponSkinData.TextureId then
									part.Texture = state.WeaponSkinData.TextureId
								end
							end
						end
					end
					for _, tool in ipairs(player.Backpack:GetChildren()) do applySkin(tool) end
					for _, tool in ipairs(player.Character:GetChildren()) do applySkin(tool) end
				end

				-- 5) KillAura & RageBot (강제 ON 상태로 사거리 제한 해제 연산)
				if state.KillAura then
					if not playerTargetingLists[player.UserId] then playerTargetingLists[player.UserId] = {} end
					local myTargets = playerTargetingLists[player.UserId]
					
					for _, enemy in ipairs(Players:GetPlayers()) do
						if enemy ~= player and enemy.Character and enemy.Character:FindFirstChild("Humanoid") and enemy.Character:FindFirstChild("HumanoidRootPart") and enemy.Character:FindFirstChild("Head") then
							local distance = (myHrp.Position - enemy.Character.HumanoidRootPart.Position).Magnitude
							-- RageBot이 활성화되어 있으면 사거리가 무한대로 확장됩니다.
							local maxDistance = state.RageBot and 100000000 or 20
							
							if distance <= maxDistance then
								local enemyId = enemy.UserId
								if enemy.Character.Humanoid.Health > 0 and not myTargets[enemyId] then
									myTargets[enemyId] = true
									task.spawn(function()
										task.wait(0.1) -- 주입 속도 최적화를 위해 무지연 변환 시도
