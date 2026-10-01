-- =====================================================
--  AkrivHub v2.0 | Script Hub with Animation
--  by akriv1s & Assistant
-- =====================================================

local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LP      = Players.LocalPlayer

-- =====================================================
--  СПИСОК СКРИПТОВ (ИСТОЧНИКИ)
--  Формат: { name = "Название", url = "RAW-ссылка", desc = "Описание" }
-- =====================================================

local SCRIPTS = {
    ["Infinite Yield (Universal)"] = {
        url = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",
        desc = "Классический админ-скрипт с 200+ командами"
    },
    ["Dark Dex (Universal)"] = {
        url = "https://raw.githubusercontent.com/Babyhamsta/RBLX_Scripts/main/Universal/Dark%20Dex.lua",
        desc = "Просмотр всего дерева игры (Explorer + Properties)"
    },
    ["SimpleSpy (Universal)"] = {
        url = "https://raw.githubusercontent.com/exxtremestuffs/SimpleSpySource/master/SimpleSpy.lua",
        desc = "Перехват и вызов RemoteEvent"
    },
    ["Hydroxide (Universal)"] = {
        url = "https://raw.githubusercontent.com/Upbolt/Hydroxide/master/src/hydroxide.lua",
        desc = "Продвинутый Remote Spy с красивым UI"
    },
    -- Сюда можно добавлять другие скрипты по аналогии
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
--  GUI С ПЛАВНОЙ АНИМАЦИЕЙ
-- =====================================================

local function makeHub()
    local sg = Instance.new("ScreenGui")
    sg.Name = "AkrivHub"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = LP:WaitForChild("PlayerGui")

    -- Главное окно (начинаем с анимации)
    local win = Instance.new("Frame")
    win.Name = "Window"
    win.Size = UDim2.new(0, 560, 0, 400)
    win.Position = UDim2.new(0.5, -280, 0.5, -200)
    win.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    win.BorderSizePixel = 0
    win.Active = true
    win.Draggable = true
    win.Parent = sg

    -- Анимация открытия (появление)
    win.BackgroundTransparency = 1
    local openTween = TweenService:Create(win, 
        TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), 
        { BackgroundTransparency = 0 }
    )
    openTween:Play()

    -- Заголовок с названием места
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 38)
    header.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    header.BorderSizePixel = 0
    header.Parent = win

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 14, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "AkrivHub | " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    -- Кнопка закрытия с анимацией
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
    closeBtn.MouseButton1Click:Connect(function()
        -- Анимация закрытия
        local closeTween = TweenService:Create(win, 
            TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), 
            { BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 0) }
        )
        closeTween:Play()
        closeTween.Completed:Connect(function()
            sg:Destroy()
        end)
    end)

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

    -- Функция для обновления списка скриптов
    local function updateScriptList()
        for _, c in ipairs(scroll:GetChildren()) do
            if c:IsA("TextButton") or c:IsA("Frame") then
                c:Destroy()
            end
        end

        for name, script in pairs(SCRIPTS) do
            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, 0, 0, 72)
            card.BackgroundColor3 = Color3.fromRGB(32, 32, 44)
            card.BorderSizePixel = 0
            card.Parent = scroll

            local nameL = Instance.new("TextLabel")
            nameL.Size = UDim2.new(1, -100, 0, 22)
            nameL.Position = UDim2.new(0, 12, 0, 8)
            nameL.BackgroundTransparency = 1
            nameL.Text = name
            nameL.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameL.Font = Enum.Font.GothamBold
            nameL.TextSize = 14
            nameL.TextXAlignment = Enum.TextXAlignment.Left
            nameL.Parent = card

            local descL = Instance.new("TextLabel")
            descL.Size = UDim2.new(1, -20, 0, 16)
            descL.Position = UDim2.new(0, 12, 0, 32)
            descL.BackgroundTransparency = 1
            descL.Text = script.desc
            descL.TextColor3 = Color3.fromRGB(150, 150, 175)
            descL.Font = Enum.Font.Gotham
            descL.TextSize = 11
            descL.TextXAlignment = Enum.TextXAlignment.Left
            descL.TextWrapped = true
            descL.Parent = card

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
                    loadScript(script.url, name)
                    task.wait(0.3)
                    runBtn.Text = "✓ ОК"
                    runBtn.BackgroundColor3 = Color3.fromRGB(55, 140, 70)
                    task.wait(1.2)
                    runBtn.Text = "▶ Запуск"
                end)
            end)
        end
    end

    -- Выпадающий список для выбора источника скрипта
    local sourceDropdown = Instance.new("TextButton")
    sourceDropdown.Size = UDim2.new(1, -16, 0, 30)
    sourceDropdown.Position = UDim2.new(0, 8, 0, 8)
    sourceDropdown.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    sourceDropdown.BorderSizePixel = 0
    sourceDropdown.Text = "Выберите источник скрипта..."
    sourceDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    sourceDropdown.Font = Enum.Font.Gotham
    sourceDropdown.TextSize = 12
    sourceDropdown.Parent = sidebar

    -- Создаём список источников (все ключи из SCRIPTS)
    local sourceList = Instance.new("ScrollingFrame")
    sourceList.Size = UDim2.new(1, -16, 0, 200)
    sourceList.Position = UDim2.new(0, 8, 0, 46)
    sourceList.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    sourceList.BorderSizePixel = 0
    sourceList.Visible = false
    sourceList.CanvasSize = UDim2.new(0, 0, 0, 0)
    sourceList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sourceList.ScrollBarThickness = 4
    sourceList.Parent = sidebar

    local sourceLayout = Instance.new("UIListLayout")
    sourceLayout.Padding = UDim.new(0, 2)
    sourceLayout.Parent = sourceList

    for name, _ in pairs(SCRIPTS) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 26)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 54)
        btn.BorderSizePixel = 0
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(220, 220, 220)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 11
        btn.Parent = sourceList
        btn.MouseButton1Click:Connect(function()
            loadScript(SCRIPTS[name].url, name)
            sourceDropdown.Text = "Загружено: " .. name
            sourceList.Visible = false
        end)
    end

    -- Открытие/закрытие списка источников
    sourceDropdown.MouseButton1Click:Connect(function()
        sourceList.Visible = not sourceList.Visible
    end)

    -- Изначально показываем все скрипты в основном списке
    updateScriptList()

    return sg
end

-- =====================================================
--  ХОТКЕЙ — открыть/закрыть хаб
-- =====================================================

local hubGui = nil

local function toggleHub()
    if hubGui and hubGui.Parent then
        -- Анимация закрытия
        local closeTween = TweenService:Create(hubGui.Window, 
            TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), 
            { BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 0) }
        )
        closeTween:Play()
        closeTween.Completed:Connect(function()
            hubGui:Destroy()
            hubGui = nil
        end)
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
