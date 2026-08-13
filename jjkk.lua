local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Jujutsu Shenanigans",
   LoadingTitle = "Loading. . .",
   LoadingSubtitle = "kainatbozanv222",
   ConfigurationSaving = { Enabled = false }
})

local MainTab = Window:CreateTab("Auto Combat", 4483362458)
local SafetyTab = Window:CreateTab("Güvenlik & Blok", 4483362458)

local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Ayarlar
local targetPlayerName = ""
local useRandomTarget = true
local behindDistance = 3
local lerpSpeed = 0.25 -- Yüksek takip/süzülme hızı (0.05 yavaş, 0.5 çok hızlı)
local m1Count = 4
local comboDelay = 0.20
local m1Delay = 0.10

local autoAttackLoop = false
local standaloneAutoM1 = false
local autoBehindLock = false
local autoBlockToggle = false
local healthSafetyToggle = false
local autoGuardBreakToggle = true
local aimbotToggle = false

local isEscapeActive = false
local currentTargetPlayer = nil

-- GÜVENLİ VE KESİN CANLILIK KONTROLÜ
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

-- DİNAMİK HEDEF SEÇİCİ
local function updateAndGetTarget()
   if isPlayerAlive(currentTargetPlayer) then
      return currentTargetPlayer
   end

   currentTargetPlayer = nil

   -- Özel İsim
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

   -- Haritadaki En Yakın Canlı
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

-- IŞINLANMADAN YÜKSEK HIZLA SÜZÜLEREK GİTME (PÜRÜZSÜZ LERP)
local function moveSmoothToTarget()
   if isEscapeActive then return end

   local target = updateAndGetTarget()
   local myChar = LocalPlayer.Character
   local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

   if target and isPlayerAlive(target) and myRoot then
      local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
      if tRoot then
         -- Hedefin arkasındaki konum
         local targetPos = tRoot.Position - (tRoot.CFrame.LookVector * behindDistance)
         local targetCFrame = CFrame.lookAt(targetPos, tRoot.Position)

         -- Ani TP yerine pozisyona yüksek hızda kayar (Lerp)
         myRoot.CFrame = myRoot.CFrame:Lerp(targetCFrame, lerpSpeed)
      end
   end
end

-- TUŞ GİRDİLERİ
local function pressKey(keyCode, holdTime)
   VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
   task.wait(holdTime or 0.04)
   VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
end

local function clickM1()
   VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
   task.wait(0.02)
   VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

local function clickM2()
   VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 0)
   task.wait(0.04)
   VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0)
end

-- RENDERSTEPPED (HER KAREDE ÇALIŞAN HAREKET VE GÜVENLİK)
RunService.RenderStepped:Connect(function()
   local myChar = LocalPlayer.Character
   local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
   local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")

   -- 1. %15 CAN KORUMASI (YUKARI DOĞRU HIZLA YÜKSELME)
   if healthSafetyToggle and hum and myRoot and hum.Health > 0 then
      local hpPercent = (hum.Health / hum.MaxHealth) * 100

      if hpPercent <= 15 then
         isEscapeActive = true
         -- Yukarı doğru yumuşak ama hızlı yükseliş
         local safeCFrame = CFrame.new(myRoot.Position.X, myRoot.Position.Y + 15, myRoot.Position.Z)
         if myRoot.Position.Y < 300 then
            myRoot.CFrame = myRoot.CFrame:Lerp(safeCFrame, 0.3)
         end
      elseif hpPercent >= 30 and isEscapeActive then
         isEscapeActive = false
      end
   end

   -- 2. HAREKET VE TAKİP (TAKILMADAN SÜZÜLME)
   if (autoAttackLoop or autoBehindLock) and not isEscapeActive then
      moveSmoothToTarget()
   end

   -- 3. AIMBOT
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

-- AUTO BLOCK
task.spawn(function()
   while true do
      if autoBlockToggle and not isEscapeActive then
         VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
      end
      task.wait(0.1)
   end
end)

-- BAĞIMSIZ AUTO M1
task.spawn(function()
   while true do
      if standaloneAutoM1 and not isEscapeActive then
         if autoGuardBreakToggle and isTargetBlocking() then
            clickM2()
         else
            clickM1()
         end
      end
      task.wait(m1Delay)
   end
end)

-- AKILLI KOMBO DÖNGÜSÜ
task.spawn(function()
   while true do
      if autoAttackLoop and not isEscapeActive then
         local target = updateAndGetTarget()

         if target and isPlayerAlive(target) then
            if autoGuardBreakToggle and isTargetBlocking() then
               VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
               clickM2()
               task.wait(0.08)
            end

            local keys = {Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four}
            for _, key in ipairs(keys) do
               if not autoAttackLoop or isEscapeActive or not isPlayerAlive(currentTargetPlayer) then break end

               if autoGuardBreakToggle and isTargetBlocking() then
                  clickM2()
               end

               VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
               pressKey(key, 0.06)
               task.wait(comboDelay)
            end

            for i = 1, m1Count do
               if not autoAttackLoop or isEscapeActive or not isPlayerAlive(currentTargetPlayer) then break end

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

-- UI ELEMANLARI (TAB 1)

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

MainTab:CreateToggle({
   Name = "Kamera Aimbot (Hedefe Kilitlen)",
   CurrentValue = false,
   Flag = "AimbotToggleFlag",
   Callback = function(Value)
      aimbotToggle = Value
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
   Name = "Hedefin Sırtına Hızlı Süzül (Smooth Dash)",
   CurrentValue = false,
   Flag = "AutoBehindLockFlag",
   Callback = function(Value)
      autoBehindLock = Value
   end,
})

MainTab:CreateToggle({
   Name = "Tam Otomatik Savaş (Kombo + M1 + Otomatik Yeni Hedef)",
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

-- UI ELEMANLARI (TAB 2)

SafetyTab:CreateToggle({
   Name = "Otomatik Blok Kırma (Auto Guard Break - M2)",
   CurrentValue = true,
   Flag = "AutoGuardBreakFlag",
   Callback = function(Value)
      autoGuardBreakToggle = Value
   end,
})

SafetyTab:CreateToggle({
   Name = "Uzay Koruması (%15 Yukarı Uç / %30 Dön)",
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
   Name = "Takip / Süzülme Hızı",
   Range = {0.05, 0.5},
   Increment = 0.05,
   Suffix = " Lerp",
   CurrentValue = 0.25,
   Flag = "LerpSlider",
   Callback = function(Value)
      lerpSpeed = Value
   end,
})

SafetyTab:CreateSlider({
   Name = "Arka Mesafe (Studs)",
   Range = {1, 10},
   Increment = 0.5,
   Suffix = " Stud",
   CurrentValue = 3,
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
