local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Jujutsu Shenanigans",
   LoadingTitle = "Loading. . .",
   LoadingSubtitle = "kainatbozan",
   ConfigurationSaving = { Enabled = false }
})

-- RAYFIELD GUI SÜRÜKLEME DÜZELTMESİ
task.spawn(function()
   task.wait(1)
   local coreGui = game:GetService("CoreGui")
   local rayfieldGui = coreGui:FindFirstChild("Rayfield") or game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("Rayfield")
   
   if rayfieldGui then
      for _, desc in ipairs(rayfieldGui:GetDescendants()) do
         if desc:IsA("Frame") and desc.Name == "Main" then
            desc.Active = true
            desc.Selectable = false
         end
      end
   end
end)

local MainTab = Window:CreateTab("Auto Combat", 4483362458)
local AdvancedTab = Window:CreateTab("Gelişmiş Özellikler", 4483362458)
local SafetyTab = Window:CreateTab("Güvenlik & Blok", 4483362458)

local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Temel Ayarlar
local targetPlayerName = ""
local useRandomTarget = true
local behindDistance = 2.5
local twinSpeedValue = 200
local m1Count = 4
local comboDelay = 0.20
local m1Delay = 0.10
local gDelay = 2.0

-- Yeni Ayarlar
local selectedCharacterPreset = "Standard" -- Standard, Gojo, Yuji, Mahoraga
local autoGToggle = false
local autoAttackLoop = false
local standaloneAutoM1 = false
local autoBehindLock = false
local autoBlockToggle = false
local healthSafetyToggle = false
local autoGuardBreakToggle = true
local aimbotToggle = false
local twinSpeedToggle = false

-- Gelişmiş Özellik Toggle'ları
local hitboxExtenderToggle = false
local hitboxSize = 10
local antiGrabToggle = false
local autoDodgeToggle = false
local mahoragaAdaptToggle = false

local isEscapeActive = false
local currentTargetPlayer = nil
local isRespawning = false

-- KENDİ KARAKTERİNİN CANLI OLUP OLMADIĞINI BİLDİREN KONTROL
local function isLocalPlayerAlive()
   if isRespawning then return false end
   local char = LocalPlayer.Character
   if not char or not char:IsDescendantOf(Workspace) then return false end

   local hum = char:FindFirstChildOfClass("Humanoid")
   local root = char:FindFirstChild("HumanoidRootPart")

   if not hum or not root then return false end
   if hum.Health <= 0 then return false end

   if char:FindFirstChild("Knocked") or char:FindFirstChild("Ragdoll") or char:FindFirstChild("Dead") then
      return false
   end

   local state = hum:GetState()
   if state == Enum.HumanoidStateType.Dead or state == Enum.HumanoidStateType.Physics then
      return false
   end

   return true
end

-- RAKİP CANLILIK KONTROLÜ
local function isPlayerAlive(player)
   if not player or not player.Parent then return false end
   local char = player.Character
   if not char or not char:IsDescendantOf(Workspace) then return false end

   local hum = char:FindFirstChildOfClass("Humanoid")
   local root = char:FindFirstChild("HumanoidRootPart")

   if not hum or not root then return false end
   if hum.Health <= 0 then return false end

   if char:FindFirstChild("Knocked") or char:FindFirstChild("Ragdoll") or char:FindFirstChild("Dead") then
      return false
   end

   return true
end

-- ÖLÜM VE YENİDEN DOĞMA YÖNETİMİ
LocalPlayer.CharacterAdded:Connect(function(char)
   isRespawning = true
   currentTargetPlayer = nil
   isEscapeActive = false
   
   local root = char:WaitForChild("HumanoidRootPart", 5)
   local hum = char:WaitForChild("Humanoid", 5)
   
   task.wait(1)
   isRespawning = false
end)

-- DİNAMİK HEDEF SEÇİCİ
local function updateAndGetTarget()
   if not isLocalPlayerAlive() then return nil end

   if isPlayerAlive(currentTargetPlayer) then
      return currentTargetPlayer
   end

   currentTargetPlayer = nil

   if not useRandomTarget and targetPlayerName ~= "" then
      for _, player in ipairs(Players:GetPlayers()) do
         if player ~= LocalPlayer and isPlayerAlive(player) then
            if string.find(string.lower(player.Name), string.lower(targetPlayerName)) or
               string.find(string.lower(player.DisplayName), string.lower(targetPlayerName)) then
               currentTargetPlayer = player
               return currentTargetPlayer
            end
         end
      end
   end

   local closestPlayer = nil
   local shortestDist = math.huge
   local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

   for _, player in ipairs(Players:GetPlayers()) do
      if player ~= LocalPlayer and isPlayerAlive(player) then
         local tRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
         if myRoot and tRoot then
            local dist = (tRoot.Position - myRoot.Position).Magnitude
            if dist < shortestDist then
               shortestDist = dist
               closestPlayer = player
            end
         else
            closestPlayer = player
            break
         end
      end
   end

   currentTargetPlayer = closestPlayer
   return currentTargetPlayer
end

local function isTargetBlocking()
   local target = updateAndGetTarget()
   if target and isPlayerAlive(target) then
      local char = target.Character
      if char:FindFirstChild("Blocking") or char:FindFirstChild("Block") or char:FindFirstChild("Guard") then
         return true
      end
      local hum = char:FindFirstChildOfClass("Humanoid")
      if hum then
         for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
            local animName = string.lower(track.Name)
            if string.find(animName, "block") or string.find(animName, "guard") then
               return true
            end
         end
      end
   end
   return false
end

-- SIRTA IŞINLANMA
local function tpBehindTarget()
   if isEscapeActive or not isLocalPlayerAlive() then return end

   local target = updateAndGetTarget()
   local myChar = LocalPlayer.Character
   local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

   if target and isPlayerAlive(target) and myRoot then
      local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
      if tRoot then
         local behindPosition = tRoot.Position - (tRoot.CFrame.LookVector * behindDistance)
         myRoot.CFrame = CFrame.lookAt(behindPosition, tRoot.Position)
      end
   end
end

-- TUŞ VE FARE GİRDİLERİ
local function pressKey(keyCode, holdTime)
   VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
   task.wait(holdTime or 0.04)
   VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
end

local function clickM1()
   local vp = Camera.ViewportSize
   VirtualInputManager:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, true, game, 0)
   task.wait(0.02)
   VirtualInputManager:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, false, game, 0)
end

local function clickM2()
   local vp = Camera.ViewportSize
   VirtualInputManager:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 1, true, game, 0)
   task.wait(0.04)
   VirtualInputManager:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 1, false, game, 0)
end

-- SMART SKILL PRIORITY (AKILLI KOMBO SIRALAMASI)
local function getSmartSkillSequence()
   if selectedCharacterPreset == "Gojo" then
      return {Enum.KeyCode.Two, Enum.KeyCode.One, Enum.KeyCode.Three, Enum.KeyCode.Four}
   elseif selectedCharacterPreset == "Yuji" then
      return {Enum.KeyCode.Three, Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Four}
   elseif selectedCharacterPreset == "Mahoraga" then
      return {Enum.KeyCode.One, Enum.KeyCode.Three, Enum.KeyCode.Two, Enum.KeyCode.Four}
   else
      return {Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four}
   end
end

-- RENDERSTEPPED DÖNGÜSÜ & MİKRO MEKANİKLER
RunService.RenderStepped:Connect(function()
   if not isLocalPlayerAlive() then return end

   local myChar = LocalPlayer.Character
   local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
   local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")

   -- 1. HITBOX EXTENDER (IŞINLANMADAN VURMA)
   if hitboxExtenderToggle then
      local target = updateAndGetTarget()
      if target and isPlayerAlive(target) then
         local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
         if tRoot then
            tRoot.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
            tRoot.Transparency = 0.7
            tRoot.BrickColor = BrickColor.new("Really red")
            tRoot.CanCollide = false
         end
      end
   end

   -- 2. ANTI-GRAB / ANTI-COMBO (KOMBODAN KAÇIŞ)
   if antiGrabToggle and myChar then
      if myChar:FindFirstChild("Grabbed") or myChar:FindFirstChild("Stun") or myChar:FindFirstChild("Combo") then
         if myRoot then
            myRoot.CFrame = myRoot.CFrame + Vector3.new(0, 3, 0)
         end
      end
   end

   -- 3. AUTO DODGE / SIDE-DASH PREDICTOR
   if autoDodgeToggle then
      local target = updateAndGetTarget()
      if target and isPlayerAlive(target) then
         local tChar = target.Character
         local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
         if tHum then
            for _, track in ipairs(tHum:GetPlayingAnimationTracks()) do
               local animName = string.lower(track.Name)
               if string.find(animName, "attack") or string.find(animName, "skill") or string.find(animName, "dash") then
                  pressKey(Enum.KeyCode.Q, 0.05)
                  break
               end
            end
         end
      end
   end

   -- 4. TWIN SPEED
   if twinSpeedToggle and hum then
      hum.WalkSpeed = twinSpeedValue
   end

   -- 5. %15 CAN KORUMASI
   if healthSafetyToggle and hum and myRoot then
      local hpPercent = (hum.Health / hum.MaxHealth) * 100

      if hpPercent <= 15 then
         isEscapeActive = true
         myRoot.CFrame = CFrame.new(myRoot.Position.X, 500, myRoot.Position.Z)
      elseif hpPercent >= 30 and isEscapeActive then
         isEscapeActive = false
      end
   end

   -- 6. LOCK BEHIND
   if autoBehindLock and not isEscapeActive and not autoAttackLoop then
      tpBehindTarget()
   end

   -- 7. AIMBOT
   if (aimbotToggle or autoAttackLoop) and not isEscapeActive then
      local target = updateAndGetTarget()
      if target and isPlayerAlive(target) then
         local head = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
         if head then
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, head.Position)
         end
      end
   end
end)

-- MAHORAGA AUTO ADAPTATION
task.spawn(function()
   while true do
      if mahoragaAdaptToggle and isLocalPlayerAlive() then
         local myChar = LocalPlayer.Character
         local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
         if hum and hum.Health < hum.MaxHealth then
            pressKey(Enum.KeyCode.G, 0.1)
         end
      end
      task.wait(1)
   end
end)

-- AUTO G DÖNGÜSÜ
task.spawn(function()
   while true do
      if autoGToggle and not isEscapeActive and isLocalPlayerAlive() then
         pressKey(Enum.KeyCode.G, 0.1)
      end
      task.wait(gDelay)
   end
end)

-- AUTO BLOCK
task.spawn(function()
   while true do
      if autoBlockToggle and not isEscapeActive and isLocalPlayerAlive() then
         VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
      end
      task.wait(0.1)
   end
end)

-- BAĞIMSIZ AUTO M1
task.spawn(function()
   while true do
      if standaloneAutoM1 and not isEscapeActive and isLocalPlayerAlive() then
         if autoGuardBreakToggle and isTargetBlocking() then
            clickM2()
         else
            clickM1()
         end
      end
      task.wait(m1Delay)
   end
end)

-- AKILLI SALDIRI DÖNGÜSÜ (SMART PRIORITY INTEGRATED)
task.spawn(function()
   while true do
      if autoAttackLoop and not isEscapeActive and isLocalPlayerAlive() then
         local target = updateAndGetTarget()

         if target and isPlayerAlive(target) then
            if not hitboxExtenderToggle then
               tpBehindTarget()
            end

            if autoGuardBreakToggle and isTargetBlocking() then
               VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
               clickM2()
               task.wait(0.08)
            end

            -- Smart Skill Priority tuş sırası alınıyor
            local keys = getSmartSkillSequence()
            for _, key in ipairs(keys) do
               if not autoAttackLoop or isEscapeActive or not isLocalPlayerAlive() or not isPlayerAlive(currentTargetPlayer) then break end
               if not hitboxExtenderToggle then tpBehindTarget() end

               if autoGuardBreakToggle and isTargetBlocking() then
                  clickM2()
               end

               VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
               pressKey(key, 0.06)
               task.wait(comboDelay)
            end

            for i = 1, m1Count do
               if not autoAttackLoop or isEscapeActive or not isLocalPlayerAlive() or not isPlayerAlive(currentTargetPlayer) then break end
               if not hitboxExtenderToggle then tpBehindTarget() end

               if autoGuardBreakToggle and isTargetBlocking() then
                  clickM2()
               else
                  clickM1()
               end
               task.wait(m1Delay)
            end
         else
            task.wait(0.05)
         end
      else
         task.wait(0.1)
      end
   end
end)

-- ================= Uİ ELEMANLARI =================

-- TAB 1: AUTO COMBAT
MainTab:CreateInput({
   Name = "Hedef Oyuncu Adı (Boşsa Rastgele)",
   PlaceholderText = "İsim yaz veya boş bırak...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      targetPlayerName = Text
      currentTargetPlayer = nil
      useRandomTarget = (Text == "")
   end,
})

MainTab:CreateDropdown({
   Name = "Smart Skill Priority (Karakter Preset)",
   Options = {"Standard (1-2-3-4)", "Gojo (2-1-3-4)", "Yuji (3-1-2-4)", "Mahoraga (1-3-2-4)"},
   CurrentOption = "Standard (1-2-3-4)",
   Flag = "SkillPriorityDropdown",
   Callback = function(Option)
      if string.find(Option, "Gojo") then
         selectedCharacterPreset = "Gojo"
      elseif string.find(Option, "Yuji") then
         selectedCharacterPreset = "Yuji"
      elseif string.find(Option, "Mahoraga") then
         selectedCharacterPreset = "Mahoraga"
      else
         selectedCharacterPreset = "Standard"
      end
   end,
})

MainTab:CreateToggle({
   Name = "Tam Otomatik Savaş (Akıllı Kombo + Target Lock)",
   CurrentValue = false,
   Flag = "AutoAttackLoopFlag",
   Callback = function(Value)
      autoAttackLoop = Value
      if Value then
         currentTargetPlayer = nil
         updateAndGetTarget()
      end
   end,
})

MainTab:CreateToggle({
   Name = "Sürekli Auto M1 (Aralıksız Tıkla)",
   CurrentValue = false,
   Flag = "StandaloneM1Flag",
   Callback = function(Value)
      standaloneAutoM1 = Value
   end,
})

MainTab:CreateToggle({
   Name = "Otomatik G Bas (Auto Awakening)",
   CurrentValue = false,
   Flag = "AutoGToggleFlag",
   Callback = function(Value)
      autoGToggle = Value
   end,
})

-- TAB 2: GELİŞMİŞ ÖZELLİKLER
AdvancedTab:CreateToggle({
   Name = "Hitbox Extender (Işınlanmadan Uzaktan Vurma)",
   CurrentValue = false,
   Flag = "HitboxExtenderFlag",
   Callback = function(Value)
      hitboxExtenderToggle = Value
   end,
})

AdvancedTab:CreateSlider({
   Name = "Hitbox Boyutu",
   Range = {2, 30},
   Increment = 1,
   Suffix = " Stud",
   CurrentValue = 10,
   Flag = "HitboxSizeSlider",
   Callback = function(Value)
      hitboxSize = Value
   end,
})

AdvancedTab:CreateToggle({
   Name = "Anti-Grab / Anti-Combo (Kombodan Kaçış)",
   CurrentValue = false,
   Flag = "AntiGrabFlag",
   Callback = function(Value)
      antiGrabToggle = Value
   end,
})

AdvancedTab:CreateToggle({
   Name = "Auto Dodge / Side-Dash Predictor (Saldırıdan Kaç)",
   CurrentValue = false,
   Flag = "AutoDodgeFlag",
   Callback = function(Value)
      autoDodgeToggle = Value
   end,
})

AdvancedTab:CreateToggle({
   Name = "Mahoraga Auto Adaptation (Otomatik Uyum)",
   CurrentValue = false,
   Flag = "MahoragaAdaptFlag",
   Callback = function(Value)
      mahoragaAdaptToggle = Value
   end,
})

-- TAB 3: GÜVENLİK & AYARLAR
SafetyTab:CreateToggle({
   Name = "Twin Speed (200 Yüksek Hız)",
   CurrentValue = false,
   Flag = "TwinSpeedToggleFlag",
   Callback = function(Value)
      twinSpeedToggle = Value
      if not Value then
         local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
         if hum then hum.WalkSpeed = 16 end
      end
   end,
})

SafetyTab:CreateToggle({
   Name = "Kamera Aimbot (Hedefe Kilitlen)",
   CurrentValue = false,
   Flag = "AimbotToggleFlag",
   Callback = function(Value)
      aimbotToggle = Value
   end,
})

SafetyTab:CreateToggle({
   Name = "Otomatik Blok Kırma (Auto Guard Break - M2)",
   CurrentValue = true,
   Flag = "AutoGuardBreakFlag",
   Callback = function(Value)
      autoGuardBreakToggle = Value
   end,
})

SafetyTab:CreateToggle({
   Name = "Uzay Koruması (%15 Göğe TP / %30 Dön)",
   CurrentValue = false,
   Flag = "SpaceSafetyFlag",
   Callback = function(Value)
      healthSafetyToggle = Value
      if not Value then
         isEscapeActive = false
      end
   end,
})

SafetyTab:CreateToggle({
   Name = "Auto Block (Sürekli F Bas/Tut)",
   CurrentValue = false,
   Flag = "AutoBlockFlag",
   Callback = function(Value)
      autoBlockToggle = Value
      if not Value then
         VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
      end
   end,
})

SafetyTab:CreateSection("Ayar & Gecikmeler")

SafetyTab:CreateSlider({
   Name = "Auto G Basma Sıklığı (Sn)",
   Range = {0.5, 10},
   Increment = 0.5,
   Suffix = " sn",
   CurrentValue = 2.0,
   Flag = "GDelaySlider",
   Callback = function(Value)
      gDelay = Value
   end,
})

SafetyTab:CreateSlider({
   Name = "Twin Speed Hız Değeri",
   Range = {16, 500},
   Increment = 10,
   Suffix = " Speed",
   CurrentValue = 200,
   Flag = "TwinSpeedSlider",
   Callback = function(Value)
      twinSpeedValue = Value
   end,
})

SafetyTab:CreateSlider({
   Name = "Arka Mesafe (Studs)",
   Range = {1, 10},
   Increment = 0.5,
   Suffix = " Stud",
   CurrentValue = 2.5,
   Flag = "DistanceSlider",
   Callback = function(Value)
      behindDistance = Value
   end,
})

SafetyTab:CreateSlider({
   Name = "M1 Vuruş Hızı (Sn)",
   Range = {0.05, 0.5},
   Increment = 0.01,
   Suffix = " sn",
   CurrentValue = 0.10,
   Flag = "M1DelaySlider",
   Callback = function(Value)
      m1Delay = Value
   end,
})

SafetyTab:CreateSlider({
   Name = "Yetenek Gecikmesi (Sn)",
   Range = {0.1, 1},
   Increment = 0.05,
   Suffix = " sn",
   CurrentValue = 0.20,
   Flag = "DelaySlider",
   Callback = function(Value)
      comboDelay = Value
   end,
})
