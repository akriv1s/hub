-- =====================================================
--  AkrivHub | Script Hub
--  by akriv1s
-- =====================================================

local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local Http    = game:GetService("HttpService")
local LP      = Players.LocalPlayer

-- =====================================================
--  СПИСОК СКРИПТОВ
--  Формат: { name = "Название", url = "RAW-ссылка", desc = "Описание" }
-- =====================================================

local SCRIPTS = {
    -- ==== Универсальные ====
    Universal = {
        {
            name = "Infinite Yield",
            url  = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",
            desc = "Классический админ-скрипт с 200+ командами",
        },
        {
            name = "Dark Dex",
            url  = "https://raw.githubusercontent.com/Babyhamsta/RBLX_Scripts/main/Universal/Dark%20Dex.lua",
            desc = "Просмотр всего дерева игры (Explorer + Properties)",
        },
        {
            name = "Remote Spy",
            url  = "https://raw.githubusercontent.com/exxtremestuffs/SimpleSpySource/master/SimpleSpy.lua",
            desc = "Перехват и вызов RemoteEvent",
        },
        {
            name = "Hydroxide",
            url  = "https://raw.githubusercontent.com/Upbolt/Hydroxide/master/src/hydroxide.lua",
            desc = "Продвинутый Remote Spy с красивым UI",
        },
        {
            name = "Owl Hub",
            url  = "https://raw.githubusercontent.com/OwlHUB/OwlHubScripts/main/OwlHubLoader.lua",
            desc = "Универсальный хаб с кучей функций",
        },
    },

    -- ==== Шутеры ====
    FPS = {
        {
            name = "Universal ESP",
            url  = "https://raw.githubusercontent.com/RegularVynixu/Utilities/main/ESP.lua",
            desc = "Wallhack для большинства шутеров",
        },
        {
            name = "Universal Aimbot",
            url  = "https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Aimbot.lua",
            desc = "Плавный аимбот с FOV и предсказанием",
        },
        {
            name = "Blox Strike Aim",
            url  = "https://raw.githubusercontent.com/RegularVynixu/Utilities/main/BloxStrike.lua",
            desc = "Aim + ESP специально для Blox Strike",
        },
        {
            name = "Silent Aim",
            url  = "https://raw.githubusercontent.com/RegularVynixu/Utilities/main/SilentAim.lua",
            desc = "Пули летят в цель без движения камеры",
        },
    },

    -- ==== Симуляторы / Фарм ====
    Farm = {
        {
            name = "Auto Farm Universal",
            url  = "https://raw.githubusercontent.com/RegularVynixu/Utilities/main/AutoFarm.lua",
            desc = "Автофарм для популярных симуляторов",
        },
        {
            name = "Pet Simulator X",
            url  = "https://raw.githubusercontent.com/Babyhamsta/RBLX_Scripts/main/PSX.lua",
            desc = "Автофарм монет и питомцев",
        },
        {
            name = "Case Clicker Auto",
            url  = "https://raw.githubusercontent.com/RegularVynixu/Utilities/main/CaseClicker.lua",
            desc = "Автооткрытие кейсов и продажа лута",
        },
    },

    -- ==== Визуал ====
    Visual = {
        {
            name = "Fullbright",
            url  = "https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Fullbright.lua",
            desc = "Максимальная яркость карты",
        },
        {
            name = "No Fog",
            url  = "https://raw.githubusercontent.com/RegularVynixu/Utilities/main/NoFog.lua",
            desc = "Убирает туман",
        },
        {
            name = "FPS Booster",
            url  = "https://raw.githubusercontent.com/RegularVynixu/Utilities/main/FPSBooster.lua",
            desc = "Скрывает мусорные объекты, поднимает FPS",
        },
    },
}

-- =====================================================
--  ЗАГРУЗКА СКРИПТА
-- =====================================================

local function loadScript(url, name)
    if not url or url == "" then
        warn("[AkrivHub] У скрипта «" .. tostring(name) .. "» нет ссылки")
        return
    end

    print("[AkrivHub] Загружаю: " .. name)

    local ok, err = pcall(function()
        local source = game:HttpGet(url)
        if not source or #source < 10 then
            error("Пустой ответ от сервера (проверь RAW-ссылку)")
        end
        local chunk = loadstring(source)
        if not chunk then
            error("loadstring вернул nil — синтаксис битый")
        end
        chunk()
    end)

    if not ok then
        warn("[AkrivHub] Ошибка загрузки «" .. name .. "»: " .. tostring(err))
    else
        print("[AkrivHub] Успешно: " .. name)
    end
end

-- =====================================================
--  GUI
-- =====================================================

local function makeHub()
    local sg = Instance.new("ScreenGui")
    sg.Name = "AkrivHub"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = LP:WaitForChild("PlayerGui")

    -- Главное окно
    local win = Instance.new("Frame")
    win.Name = "Window"
    win.Size = UDim2.new(0, 560, 0, 400)
    win.Position = UDim2.new(0.5, -280, 0.5, -200)
    win.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    win.BorderSizePixel = 0
    win.Active = true
    win.Draggable = true
    win.Parent = sg

    -- Заголовок
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 38)
    header.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    header.BorderSizePixel = 0
    header.Parent = win

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 14, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "AkrivHub"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 17
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(0, 200, 1, 0)
    subtitle.Position = UDim2.new(0, 90, 0, 0)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "| Script Hub v1.0"
    subtitle.TextColor3 = Color3.fromRGB(120, 120, 150)
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 11
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = header

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -36, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.Parent = header
    closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

    -- Сайдбар с категориями
    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 140, 1, -38)
    sidebar.Position = UDim2.new(0, 0, 0, 38)
    sidebar.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
    sidebar.BorderSizePixel = 0
    sidebar.Parent = win

    -- Область списка скриптов
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -140, 1, -38)
    content.Position = UDim2.new(0, 140, 0, 38)
    content.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    content.BorderSizePixel = 0
    content.Parent = win

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -16, 1, -16)
    scroll.Position = UDim2.new(0, 8, 0, 8)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 120)
    scroll.Parent = content

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 6)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scroll

    -- Кнопки категорий
    local categoryButtons = {}
    local currentCategory = nil

    local function clearContent()
        for _, c in ipairs(scroll:GetChildren()) do
            if c:IsA("TextButton") or c:IsA("Frame") then
                c:Destroy()
            end
        end
    end

    local function showCategory(catName)
        clearContent()
        currentCategory = catName

        -- Подсветка активной кнопки
        for name, btn in pairs(categoryButtons) do
            if name == catName then
                btn.BackgroundColor3 = Color3.fromRGB(50, 50, 75)
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                btn.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
                btn.TextColor3 = Color3.fromRGB(160, 160, 180)
            end
        end

        local list = SCRIPTS[catName]
        if not list or #list == 0 then
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 0, 40)
            lbl.BackgroundTransparency = 1
            lbl.Text = "В этой категории пока нет скриптов"
            lbl.TextColor3 = Color3.fromRGB(140, 140, 160)
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 12
            lbl.Parent = scroll
            return
        end

        for i, script in ipairs(list) do
            -- Карточка скрипта
            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, 0, 0, 72)
            card.BackgroundColor3 = Color3.fromRGB(32, 32, 44)
            card.BorderSizePixel = 0
            card.LayoutOrder = i
            card.Parent = scroll

            local nameL = Instance.new("TextLabel")
            nameL.Size = UDim2.new(1, -100, 0, 22)
            nameL.Position = UDim2.new(0, 12, 0, 8)
            nameL.BackgroundTransparency = 1
            nameL.Text = script.name
            nameL.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameL.Font = Enum.Font.GothamBold
            nameL.TextSize = 14
            nameL.TextXAlignment = Enum.TextXAlignment.Left
            nameL.Parent = card

            local descL = Instance.new("TextLabel")
            descL.Size = UDim2.new(1, -20, 0, 16)
            descL.Position = UDim2.new(0, 12, 0, 32)
            descL.BackgroundTransparency = 1
            descL.Text = script.desc or ""
            descL.TextColor3 = Color3.fromRGB(150, 150, 175)
            descL.Font = Enum.Font.Gotham
            descL.TextSize = 11
            descL.TextXAlignment = Enum.TextXAlignment.Left
            descL.TextWrapped = true
            descL.Parent = card

            local urlL = Instance.new("TextLabel")
            urlL.Size = UDim2.new(1, -20, 0, 12)
            urlL.Position = UDim2.new(0, 12, 0, 50)
            urlL.BackgroundTransparency = 1
            urlL.Text = (script.url or ""):sub(1, 80)
            urlL.TextColor3 = Color3.fromRGB(100, 100, 130)
            urlL.Font = Enum.Font.Code
            urlL.TextSize = 9
            urlL.TextXAlignment = Enum.TextXAlignment.Left
            urlL.TextTruncate = Enum.TextTruncate.AtEnd
            urlL.Parent = card

            -- Кнопка "Запустить"
            local runBtn = Instance.new("TextButton")
            runBtn.Size = UDim2.new(0, 84, 0, 30)
            runBtn.Position = UDim2.new(1, -96, 0.5, -15)
            runBtn.BackgroundColor3 = Color3.fromRGB(55, 140, 70)
            runBtn.BorderSizePixel = 0
            runBtn.Text = "▶ Запуск"
            runBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            runBtn.Font = Enum.Font.GothamBold
            runBtn.TextSize = 12
            runBtn.Parent = card

            runBtn.MouseButton1Click:Connect(function()
                runBtn.Text = "..."
                runBtn.BackgroundColor3 = Color3.fromRGB(180, 150, 60)
                task.spawn(function()
                    loadScript(script.url, script.name)
                    task.wait(0.3)
                    runBtn.Text = "✓ ОК"
                    runBtn.BackgroundColor3 = Color3.fromRGB(55, 140, 70)
                    task.wait(1.2)
                    runBtn.Text = "▶ Запуск"
                end)
            end)
        end
    end

    -- Создаём кнопки категорий
    local catY = 10
    for catName, _ in pairs(SCRIPTS) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -16, 0, 32)
        btn.Position = UDim2.new(0, 8, 0, catY)
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
        btn.BorderSizePixel = 0
        btn.Text = catName
        btn.TextColor3 = Color3.fromRGB(160, 160, 180)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
        btn.Parent = sidebar
        categoryButtons[catName] = btn
        catY = catY + 38

        btn.MouseButton1Click:Connect(function()
            showCategory(catName)
        end)
    end

    -- Показываем первую категорию
    local firstCat = nil
    for name, _ in pairs(SCRIPTS) do
        firstCat = name
        break
    end
    if firstCat then showCategory(firstCat) end

    -- Футер с версией
    local footer = Instance.new("TextLabel")
    footer.Size = UDim2.new(0, 140, 0, 20)
    footer.Position = UDim2.new(0, 0, 1, -22)
    footer.BackgroundTransparency = 1
    footer.Text = "by akriv1s"
    footer.TextColor3 = Color3.fromRGB(90, 90, 120)
    footer.Font = Enum.Font.Gotham
    footer.TextSize = 10
    footer.Parent = sidebar

    return sg
end

-- =====================================================
--  ХОТКЕЙ — открыть/закрыть хаб
-- =====================================================

local hubGui = nil

local function toggleHub()
    if hubGui and hubGui.Parent then
        hubGui:Destroy()
        hubGui = nil
    else
        hubGui = makeHub()
    end
end

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        toggleHub()
    end
end)

-- Открываем сразу при загрузке
hubGui = makeHub()

print("[AkrivHub] Загружен. Клавиша RightShift — открыть/закрыть.")