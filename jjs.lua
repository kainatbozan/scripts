local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Jujutsu Shenanigans",
   LoadingTitle = "Yükleniyor...",
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
local SafetyTab = Window:CreateTab("Güvenlik & Blok", 4483362458)
local WhitelistTab = Window:CreateTab("Whitelist", 4483362458)

local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Genel Ayarlar
local targetPlayerName = ""
local useRandomTarget = true
local behindDistance = 2.5
local twinSpeedValue = 200
local m1Count = 4
local comboDelay = 0.20
local m1Delay = 0.10
local gDelay = 2.0

local autoAttackLoop = false
local standaloneAutoM1 = false
local autoBehindLock = false
local autoBlockToggle = false
local healthSafetyToggle = false
local autoGuardBreakToggle = true
local aimbotToggle = false
local twinSpeedToggle = false
local autoGToggle = false

-- Yuji Auto Combo Ayarları
local yujiComboToggle = false
local yujiSkillDelay = 0.35

-- Hitbox Ayarları
local hitboxToggle = false
local hitboxSize = 15
local hitboxTransparency = 0.7

-- Whitelist Tablosu
local whitelist = {}
local whitelistInputName = ""

local isEscapeActive = false
local currentTargetPlayer = nil
local isRespawning = false

-- WHITELIST KONTROLÜ
local function isWhitelisted(player)
   if not player then return false end
   for _, name in ipairs(whitelist) do
      if string.lower(player.Name) == string.lower(name) or string.lower(player.DisplayName) == string.lower(name) then
         return true
      end
   end
   return false
end

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

-- RAKİP CANLILIK VE WHITELIST KONTROLÜ
local function isPlayerAlive(player)
   if not player or not player.Parent then return false end
   if isWhitelisted(player) then return false end

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

-- HITBOX SIFIRLAMA
local function resetHitboxes()
   for _, player in ipairs(Players:GetPlayers()) do
      if player ~= LocalPlayer and player.Character then
         local root = player.Character:FindFirstChild("HumanoidRootPart")
         if root then
            root.Size = Vector3.new(2, 2, 1)
            root.Transparency = 1
         end
      end
   end
end

-- ÖLÜM VE YENİDEN DOĞMA YÖNETİMİ (Karakter tam yüklenene kadar bekler)
LocalPlayer.CharacterAdded:Connect(function(char)
   isRespawning = true
   currentTargetPlayer = nil
   isEscapeActive = false
   
   -- Karakterin parçalarının tam yüklenmesi için güvenli bekleme süresi eklendi
   char:WaitForChild("HumanoidRootPart", 5)
   char:WaitForChild("Humanoid", 5)
   
   task.wait(2.5) -- Oyuna tam olarak doğmayı beklemesi için gecikme
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

task.spawn(function()
   task.wait(1.5)
   updateAndGetTarget()
end)

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

-- GELİŞMİŞ UZAY VE LERP IŞINLANMA (SMOOTH TP)
local function tpBehindTarget()
   if isEscapeActive or not isLocalPlayerAlive() then return end

   local target = updateAndGetTarget()
   local myChar = LocalPlayer.Character
   local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

   if target and isPlayerAlive(target) and myRoot then
      local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
      if tRoot then
         local behindPosition = tRoot.Position - (tRoot.CFrame.LookVector * behindDistance)
         local targetCFrame = CFrame.lookAt(behindPosition, tRoot.Position)
         
         local dist = (myRoot.Position - targetCFrame.Position).Magnitude

         if dist > 30 then
            -- Eğer hedef çok uzaktaysa anında ışınlanıp anti-cheat'e yakalanmak yerine ona doğru hızlıca kayar
            myRoot.CFrame = myRoot.CFrame:Lerp(targetCFrame, 0.15)
         else
            -- Eğer hedefe yakınsak anında sırtına yapışır
            myRoot.CFrame = targetCFrame
         end
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

-- RENDERSTEPPED DÖNGÜSÜ
RunService.RenderStepped:Connect(function()
   if hitboxToggle then
      for _, player in ipairs(Players:GetPlayers()) do
         if player ~= LocalPlayer and player.Character and not isWhitelisted(player) then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then
               root.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
               root.Transparency = hitboxTransparency
               root.BrickColor = BrickColor.new("Really red")
               root.Material = Enum.Material.ForceField
               root.CanCollide = false
            end
         elseif isWhitelisted(player) and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root and root.Size.X ~= 2 then
               root.Size = Vector3.new(2, 2, 1)
               root.Transparency = 1
            end
         end
      end
   end

   if not isLocalPlayerAlive() then return end

   local myChar = LocalPlayer.Character
   local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
   local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")

   if twinSpeedToggle and hum then
      hum.WalkSpeed = twinSpeedValue
   end

   if healthSafetyToggle and hum and myRoot then
      local hpPercent = (hum.Health / hum.MaxHealth) * 100
      if hpPercent <= 15 then
         isEscapeActive = true
         myRoot.CFrame = CFrame.new(myRoot.Position.X, 500, myRoot.Position.Z)
      elseif hpPercent >= 30 and isEscapeActive then
         isEscapeActive = false
      end
   end

   if autoBehindLock and not isEscapeActive and not autoAttackLoop and not yujiComboToggle then
      tpBehindTarget()
   end

   if (aimbotToggle or autoAttackLoop or yujiComboToggle) and not isEscapeActive then
      local target = updateAndGetTarget()
      if target and isPlayerAlive(target) then
         local head = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
         if head then
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, head.Position)
         end
      end
   end
end)

-- YUJI SPECIAL COMBO LOOP (MESAFE KONTROLLÜ)
task.spawn(function()
   while true do
      if yujiComboToggle and not isEscapeActive and isLocalPlayerAlive() then
         local target = updateAndGetTarget()

         if target and isPlayerAlive(target) then
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local tRoot = target.Character:FindFirstChild("HumanoidRootPart")

            -- MESAFE GÜVENLİK KİLİDİ
            if myRoot and tRoot then
               local dist = (myRoot.Position - tRoot.Position).Magnitude
               if dist > 15 then
                  tpBehindTarget() -- Sadece hedefe doğru kay/ışınlan
                  task.wait(0.05)
                  continue -- Uzaksak skill atmasını ENGELLER ve döngüyü başa sarar.
               end
            end

            tpBehindTarget()

            if autoGuardBreakToggle and isTargetBlocking() then
               clickM2()
               task.wait(0.1)
            end

            for i = 1, 3 do
               if not yujiComboToggle or not isLocalPlayerAlive() or not isPlayerAlive(target) then break end
               tpBehindTarget()
               clickM1()
               task.wait(m1Delay)
            end

            if yujiComboToggle and isLocalPlayerAlive() and isPlayerAlive(target) then
               tpBehindTarget()
               pressKey(Enum.KeyCode.One, 0.05)
               task.wait(yujiSkillDelay)
            end

            if yujiComboToggle and isLocalPlayerAlive() and isPlayerAlive(target) then
               tpBehindTarget()
               pressKey(Enum.KeyCode.Two, 0.05)
               task.wait(yujiSkillDelay)
            end

            if yujiComboToggle and isLocalPlayerAlive() and isPlayerAlive(target) then
               tpBehindTarget()
               pressKey(Enum.KeyCode.Three, 0.05)
               task.wait(yujiSkillDelay)
            end

            if yujiComboToggle and isLocalPlayerAlive() and isPlayerAlive(target) then
               tpBehindTarget()
               pressKey(Enum.KeyCode.Four, 0.05)
               task.wait(yujiSkillDelay)
            end
         else
            task.wait(0.1)
         end
      else
         task.wait(0.1)
      end
   end
end)

-- AUTO G
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

-- BAĞIMSIZ AUTO M1 (MESAFE KONTROLLÜ)
task.spawn(function()
   while true do
      if standaloneAutoM1 and not isEscapeActive and isLocalPlayerAlive() then
         local target = updateAndGetTarget()
         if target and isPlayerAlive(target) then
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
            
            if myRoot and tRoot and (myRoot.Position - tRoot.Position).Magnitude > 15 then
               tpBehindTarget()
               task.wait(0.05)
               continue
            end

            if autoGuardBreakToggle and isTargetBlocking() then
               clickM2()
            else
               clickM1()
            end
         end
      end
      task.wait(m1Delay)
   end
end)

-- GENEL SALDIRI DÖNGÜSÜ (MESAFE KONTROLLÜ)
task.spawn(function()
   while true do
      if autoAttackLoop and not yujiComboToggle and not isEscapeActive and isLocalPlayerAlive() then
         local target = updateAndGetTarget()

         if target and isPlayerAlive(target) then
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local tRoot = target.Character:FindFirstChild("HumanoidRootPart")

            -- MESAFE GÜVENLİK KİLİDİ
            if myRoot and tRoot then
               local dist = (myRoot.Position - tRoot.Position).Magnitude
               if dist > 15 then
                  tpBehindTarget() -- Sadece hedefe doğru kay/ışınlan
                  task.wait(0.05)
                  continue -- Uzaksak skill atmasını ENGELLER ve döngüyü başa sarar.
               end
            end

            tpBehindTarget()

            if autoGuardBreakToggle and isTargetBlocking() then
               VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
               clickM2()
               task.wait(0.08)
            end

            local keys = {Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four}
            for _, key in ipairs(keys) do
               if not autoAttackLoop or isEscapeActive or not isLocalPlayerAlive() or not isPlayerAlive(currentTargetPlayer) then break end
               tpBehindTarget()

               if autoGuardBreakToggle and isTargetBlocking() then
                  clickM2()
               end

               VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
               pressKey(key, 0.06)
               task.wait(comboDelay)
            end

            for i = 1, m1Count do
               if not autoAttackLoop or isEscapeActive or not isLocalPlayerAlive() or not isPlayerAlive(currentTargetPlayer) then break end
               tpBehindTarget()

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

-- UI ELEMANLARI (Aynı Kalıyor)
-- ... (MainTab, SafetyTab, WhitelistTab Kodları)

MainTab:CreateSection("Yuji Itadori Özel Kombo")

MainTab:CreateToggle({
   Name = "Yuji Auto Combo (3x M1 -> 1 -> 2 -> 3 -> 4)",
   CurrentValue = false,
   Flag = "YujiComboFlag",
   Callback = function(Value)
      yujiComboToggle = Value
      if Value then
         autoAttackLoop = false
      end
   end,
})

MainTab:CreateSlider({
   Name = "Yuji Yetenek Bekleme Süresi (Sn)",
   Range = {0.1, 1},
   Increment = 0.05,
   Suffix = " sn",
   CurrentValue = 0.35,
   Flag = "YujiDelaySlider",
   Callback = function(Value)
      yujiSkillDelay = Value
   end,
})

MainTab:CreateSection("Hitbox Ayarları")

MainTab:CreateToggle({
   Name = "Hitbox Büyütücü (Hitbox Expander)",
   CurrentValue = false,
   Flag = "HitboxToggleFlag",
   Callback = function(Value)
      hitboxToggle = Value
      if not Value then
         resetHitboxes()
      end
   end,
})

MainTab:CreateSlider({
   Name = "Hitbox Boyutu (Stud)",
   Range = {2, 50},
   Increment = 1,
   Suffix = " Stud",
   CurrentValue = 15,
   Flag = "HitboxSizeFlag",
   Callback = function(Value)
      hitboxSize = Value
   end,
})

MainTab:CreateSlider({
   Name = "Hitbox Saydamlığı",
   Range = {0, 1},
   Increment = 0.1,
   Suffix = "",
   CurrentValue = 0.7,
   Flag = "HitboxTransFlag",
   Callback = function(Value)
      hitboxTransparency = Value
   end,
})

MainTab:CreateSection("Savaş & Hedefleme")

MainTab:CreateInput({
   Name = "Hedef Oyuncu Adı (Boşsa En Yakın)",
   PlaceholderText = "İsim yaz veya boş bırak...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      targetPlayerName = Text
      currentTargetPlayer = nil
      useRandomTarget = (Text == "")
      updateAndGetTarget()
   end,
})

MainTab:CreateToggle({
   Name = "Otomatik G Bas (Auto Awakening/Ultimate)",
   CurrentValue = false,
   Flag = "AutoGToggleFlag",
   Callback = function(Value)
      autoGToggle = Value
   end,
})

MainTab:CreateToggle({
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
   Name = "Hedefin Sırtına Anında Işınlan (Instant TP Lock)",
   CurrentValue = false,
   Flag = "AutoBehindLockFlag",
   Callback = function(Value)
      autoBehindLock = Value
   end,
})

MainTab:CreateToggle({
   Name = "Genel Auto Combat",
   CurrentValue = false,
   Flag = "AutoAttackLoopFlag",
   Callback = function(Value)
      autoAttackLoop = Value
      if Value then
         yujiComboToggle = false
         currentTargetPlayer = nil
         updateAndGetTarget()
      end
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

WhitelistTab:CreateInput({
   Name = "Oyuncu Adı (Username / DisplayName)",
   PlaceholderText = "Eklenecek adı yazın...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      whitelistInputName = Text
   end,
})

WhitelistTab:CreateButton({
   Name = "Whitelist'e Ekle (Dost Ekle)",
   Callback = function()
      if whitelistInputName ~= "" then
         table.insert(whitelist, whitelistInputName)
         Rayfield:Notify({
            Title = "Whitelist",
            Content = whitelistInputName .. " whitelist listesine eklendi!",
            Duration = 3,
            Image = 4483362458,
         })
         currentTargetPlayer = nil
         updateAndGetTarget()
      end
   end,
})

WhitelistTab:CreateButton({
   Name = "Whitelist'ten Çıkar",
   Callback = function()
      if whitelistInputName ~= "" then
         for i, name in ipairs(whitelist) do
            if string.lower(name) == string.lower(whitelistInputName) then
               table.remove(whitelist, i)
               Rayfield:Notify({
                  Title = "Whitelist",
                  Content = whitelistInputName .. " listeden çıkarıldı!",
                  Duration = 3,
                  Image = 4483362458,
               })
               break
            end
         end
      end
   end,
})

WhitelistTab:CreateButton({
   Name = "Tüm Whitelist'i Temizle",
   Callback = function()
      whitelist = {}
      Rayfield:Notify({
         Title = "Whitelist",
         Content = "Tüm dost listesi temizlendi!",
         Duration = 3,
         Image = 4483362458,
      })
   end,
})
