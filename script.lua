-- =====================================================
--  Game Script Finder v2.1 | by akriv1s
--  Поиск игр через roproxy + скрипты из ScriptBlox и RoScripts
--  ааа
-- =====================================================

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local HttpService  = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local LP           = Players.LocalPlayer

-- ==================== СОСТОЯНИЕ ====================
local state = {
    isCollapsed = false,
    mainGui     = nil,
    loadingGui  = nil,
}

-- ==================== УТИЛИТЫ ====================
local function httpGet(url)
    local ok, res = pcall(function()
        return game:HttpGet(url, true)
    end)
    if not ok then
        return nil, "HTTP ошибка: " .. tostring(res)
    end
    return res
end

local function jsonDecode(str)
    local ok, res = pcall(function()
        return HttpService:JSONDecode(str)
    end)
    if not ok then
        return nil, "JSON ошибка: " .. tostring(res)
    end
    return res
end

-- ==================== ПОИСК ИГРЫ (ЧЕРЕЗ ПРОКСИ) ====================
local function searchGameByName(gameName)
    -- URL-энкодинг названия
    local encoded = gameName:gsub(" ", "%%20"):gsub("[^%w%%]", function(c)
        return string.format("%%%02X", string.byte(c))
    end)

    -- Пробуем несколько прокси и эндпоинтов по очереди
    local endpoints = {
        -- 1. Официальный API через roproxy
        "https://apis.roproxy.com/search-api/omni-search?searchQuery=" .. encoded .. "&sessionId=0&pageType=all",
        -- 2. Старый API через roproxy
        "https://games.roproxy.com/v1/games/list?model.keyword=" .. encoded .. "&model.maxRows=10",
        -- 3. Rotunnel (альтернативный прокси, указан в документации)
        "https://apis.rotunnel.com/search-api/omni-search?searchQuery=" .. encoded .. "&sessionId=0&pageType=all",
    }

    for _, url in ipairs(endpoints) do
        local res, err = httpGet(url)
        if res and #res > 10 then
            local data, jerr = jsonDecode(res)
            if data then
                -- Формат omni-search
                if data.searchResults and data.searchResults[1] and data.searchResults[1].contents then
                    for _, item in ipairs(data.searchResults[1].contents) do
                        if item.name and item.placeId then
                            return item.placeId, item.name
                        end
                    end
                end
                -- Старый формат games/list
                if data.games and data.games[1] then
                    return data.games[1].id, data.games[1].name
                end
            end
        end
    end
    return nil, "Игра не найдена (проверь название или попробуй позже)"
end

-- ==================== ПОИСК СКРИПТОВ ====================
local function searchScriptBlox(gameName, placeId)
    local results = {}
    local encoded = gameName:gsub(" ", "%%20")

    -- 1. Поиск по названию игры через официальный API
    local url1 = "https://scriptblox.com/api/script/search?q=" .. encoded .. "&max=15"
    local res1, err1 = httpGet(url1)
    if res1 then
        local data1 = jsonDecode(res1)
        if data1 and data1.result and data1.result.scripts then
            for _, s in ipairs(data1.result.scripts) do
                table.insert(results, {
                    title = s.title,
                    game = s.game and s.game.name or gameName,
                    views = s.views or 0,
                    verified = s.verified or false,
                    script = s.script,
                    source = "ScriptBlox"
                })
            end
        end
    end

    -- 2. Дополнительный поиск по placeId
    if placeId then
        local url2 = "https://scriptblox.com/api/script/search?placeId=" .. tostring(placeId) .. "&max=15"
        local res2 = httpGet(url2)
        if res2 then
            local data2 = jsonDecode(res2)
            if data2 and data2.result and data2.result.scripts then
                for _, s in ipairs(data2.result.scripts) do
                    local exists = false
                    for _, existing in ipairs(results) do
                        if existing.title == s.title then exists = true break end
                    end
                    if not exists then
                        table.insert(results, {
                            title = s.title,
                            game = s.game and s.game.name or gameName,
                            views = s.views or 0,
                            verified = s.verified or false,
                            script = s.script,
                            source = "ScriptBlox (placeId)"
                        })
                    end
                end
            end
        end
    end

    return results
end

local function searchRoScripts(gameName)
    local results = {}
    local encoded = gameName:gsub(" ", "%%20")
    local url = "https://api.roscripts.io/v1/scripts/search?q=" .. encoded .. "&max=15"
    local res = httpGet(url)
    if not res then return results end

    local data = jsonDecode(res)
    if data and data.result and data.result.scripts then
        for _, s in ipairs(data.result.scripts) do
            table.insert(results, {
                title = s.title,
                game = s.game and s.game.name or gameName,
                views = s.views or 0,
                verified = s.verified or false,
                script = s.loadstring,
                source = "RoScripts",
                isLoadstring = true
            })
        end
    end
    return results
end

-- ==================== ОБЪЕДИНЕНИЕ РЕЗУЛЬТАТОВ ====================
local function findScripts(gameName)
    -- Сначала ищем игру через прокси
    local placeId, foundName = searchGameByName(gameName)
    if not placeId then
        return nil, "Игра не найдена. Проверь название или попробуй позже."
    end

    -- Собираем скрипты из обоих источников
    local allScripts = {}

    local sbScripts = searchScriptBlox(gameName, placeId)
    for _, s in ipairs(sbScripts) do table.insert(allScripts, s) end

    local rsScripts = searchRoScripts(gameName)
    for _, s in ipairs(rsScripts) do table.insert(allScripts, s) end

    -- Сортировка
    table.sort(allScripts, function(a, b)
        if a.verified and not b.verified then return true end
        if not a.verified and b.verified then return false end
        return (a.views or 0) > (b.views or 0)
    end)

    return allScripts, foundName or gameName
end

-- ==================== ЗАПУСК СКРИПТА ====================
local function runScript(scriptData, name)
    if not scriptData or scriptData == "" then
        warn("[Finder] Пустой скрипт: " .. tostring(name))
        return false
    end

    print("[Finder] Запускаю: " .. tostring(name))

    local ok, err = pcall(function()
        local code
        if type(scriptData) == "table" and scriptData.isLoadstring then
            code = scriptData.script
            if not code then error("Нет loadstring-ссылки") end
            loadstring(game:HttpGet(code))()
        else
            code = scriptData
            local chunk = loadstring(code)
            if not chunk then error("loadstring вернул nil") end
            chunk()
        end
    end)

    if not ok then
        warn("[Finder] Ошибка «" .. tostring(name) .. "»: " .. tostring(err))
        return false
    end
    return true
end

-- ==================== ПАРТИКЛЫ ЗАГРУЗКИ ====================
local function createLoadingParticles(parent)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.ZIndex = 2
    container.Parent = parent

    for i = 1, 40 do
        local p = Instance.new("ImageLabel")
        p.Size = UDim2.new(0, math.random(4, 12), 0, math.random(4, 12))
        p.Position = UDim2.new(math.random(), 0, math.random(), 0)
        p.BackgroundTransparency = 1
        p.Image = "rbxasset://textures/particles/sparkles_main.dds"
        p.ImageColor3 = Color3.fromRGB(100, 180, 255)
        p.ImageTransparency = math.random(30, 80) / 100
        p.ZIndex = 2
        p.Parent = container

        task.spawn(function()
            while p.Parent do
                TweenService:Create(p, TweenInfo.new(
                    math.random(15, 35) / 10,
                    Enum.EasingStyle.Sine,
                    Enum.EasingDirection.InOut
                ), {
                    Position = UDim2.new(math.random(), 0, math.random(), 0),
                    ImageTransparency = math.random(40, 90) / 100,
                    Rotation = math.random(-180, 180)
                }):Play()
                task.wait(math.random(15, 35) / 10)
            end
        end)
    end
end

-- ==================== ЭКРАН ЗАГРУЗКИ ====================
local function showLoading()
    local sg = Instance.new("ScreenGui")
    sg.Name = "FinderLoading"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = LP:WaitForChild("PlayerGui")
    state.loadingGui = sg

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    bg.BorderSizePixel = 0
    bg.Parent = sg

    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 400, 0, 200)
    container.Position = UDim2.new(0.5, -200, 0.5, -100)
    container.BackgroundTransparency = 1
    container.ZIndex = 3
    container.Parent = sg

    local logo = Instance.new("TextLabel")
    logo.Size = UDim2.new(1, 0, 0, 60)
    logo.Position = UDim2.new(0, 0, 0, 20)
    logo.BackgroundTransparency = 1
    logo.Text = "Game Script Finder"
    logo.TextColor3 = Color3.fromRGB(255, 255, 255)
    logo.Font = Enum.Font.GothamBlack
    logo.TextSize = 32
    logo.ZIndex = 3
    logo.Parent = container

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, 0, 0, 24)
    sub.Position = UDim2.new(0, 0, 0, 78)
    sub.BackgroundTransparency = 1
    sub.Text = "v2.1 by akriv1s"
    sub.TextColor3 = Color3.fromRGB(120, 120, 160)
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 14
    sub.ZIndex = 3
    sub.Parent = container

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(0, 300, 0, 6)
    barBg.Position = UDim2.new(0.5, -150, 0, 130)
    barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    barBg.BorderSizePixel = 0
    barBg.ZIndex = 3
    barBg.Parent = container

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 0, 1, 0)
    bar.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
    bar.BorderSizePixel = 0
    bar.ZIndex = 3
    bar.Parent = barBg

    local barGrad = Instance.new("UIGradient")
    barGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 180, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 100, 255))
    }
    barGrad.Parent = bar

    createLoadingParticles(sg)

    TweenService:Create(bar, TweenInfo.new(2.5, Enum.EasingStyle.Quart), {
        Size = UDim2.new(1, 0, 1, 0)
    }):Play()

    task.delay(3, function()
        if sg and sg.Parent then
            local fadeOut = TweenService:Create(bg, TweenInfo.new(0.5), { BackgroundTransparency = 1 })
            fadeOut:Play()
            fadeOut.Completed:Connect(function()
                sg:Destroy()
                state.loadingGui = nil
                if showMainGui then showMainGui() end
            end)
        end
    end)
end

-- ==================== ГЛАВНЫЙ GUI ====================
function showMainGui()
    local sg = Instance.new("ScreenGui")
    sg.Name = "GameScriptFinder"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = LP:WaitForChild("PlayerGui")
    state.mainGui = sg

    local win = Instance.new("Frame")
    win.Size = UDim2.new(0, 620, 0, 480)
    win.Position = UDim2.new(0.5, -310, 0.5, -240)
    win.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    win.BorderSizePixel = 0
    win.Active = true
    win.Draggable = true
    win.Parent = sg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = win

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 60, 90)
    stroke.Thickness = 1.5
    stroke.Parent = win

    win.Size = UDim2.new(0, 0, 0, 0)
    win.Position = UDim2.new(0.5, 0, 0.5, 0)
    TweenService:Create(win, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 620, 0, 480),
        Position = UDim2.new(0.5, -310, 0.5, -240)
    }):Play()

    -- ===== ЗАГОЛОВОК =====
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 44)
    header.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    header.BorderSizePixel = 0
    header.Parent = win

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 16)
    headerCorner.Parent = header

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -120, 1, 0)
    title.Position = UDim2.new(0, 18, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Game Script Finder"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(0, 200, 1, 0)
    subtitle.Position = UDim2.new(0, 170, 0, 0)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "| Search & Run"
    subtitle.TextColor3 = Color3.fromRGB(100, 100, 140)
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 11
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = header

    local collapseBtn = Instance.new("TextButton")
    collapseBtn.Size = UDim2.new(0, 28, 0, 28)
    collapseBtn.Position = UDim2.new(1, -70, 0, 8)
    collapseBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    collapseBtn.BorderSizePixel = 0
    collapseBtn.Text = "−"
    collapseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    collapseBtn.Font = Enum.Font.GothamBold
    collapseBtn.TextSize = 16
    collapseBtn.Parent = header

    local collapseCorner = Instance.new("UICorner")
    collapseCorner.CornerRadius = UDim.new(0, 8)
    collapseCorner.Parent = collapseBtn

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -36, 0, 8)
    closeBtn.BackgroundColor3 = Color3.fromRGB(160, 50, 60)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.Parent = header

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        local closeTween = TweenService:Create(win, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 1
        })
        closeTween:Play()
        closeTween.Completed:Connect(function() sg:Destroy() end)
    end)

    -- ===== ПОИСК =====
    local searchFrame = Instance.new("Frame")
    searchFrame.Size = UDim2.new(1, -30, 0, 44)
    searchFrame.Position = UDim2.new(0, 15, 0, 56)
    searchFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    searchFrame.BorderSizePixel = 0
    searchFrame.Parent = win

    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 10)
    searchCorner.Parent = searchFrame

    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -130, 1, 0)
    searchBox.Position = UDim2.new(0, 14, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.Text = ""
    searchBox.PlaceholderText = "Введи название игры (например, Drive a Kukirin)..."
    searchBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 130)
    searchBox.TextColor3 = Color3.fromRGB(230, 230, 240)
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 13
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = searchFrame

    local searchBtn = Instance.new("TextButton")
    searchBtn.Size = UDim2.new(0, 110, 0, 32)
    searchBtn.Position = UDim2.new(1, -120, 0.5, -16)
    searchBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 90)
    searchBtn.BorderSizePixel = 0
    searchBtn.Text = "🔍 Найти"
    searchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBtn.Font = Enum.Font.GothamBold
    searchBtn.TextSize = 11
    searchBtn.Parent = searchFrame

    local searchBtnCorner = Instance.new("UICorner")
    searchBtnCorner.CornerRadius = UDim.new(0, 8)
    searchBtnCorner.Parent = searchBtn

    -- ===== СТАТУС =====
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -30, 0, 20)
    statusLabel.Position = UDim2.new(0, 15, 0, 106)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Введи название игры и нажми «Найти»"
    statusLabel.TextColor3 = Color3.fromRGB(140, 140, 170)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 11
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = win

    -- ===== СПИСОК СКРИПТОВ =====
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -30, 1, -190)
    scroll.Position = UDim2.new(0, 15, 0, 132)
    scroll.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    scroll.BorderSizePixel = 0
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollBarThickness = 5
    scroll.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 90)
    scroll.Parent = win

    local scrollCorner = Instance.new("UICorner")
    scrollCorner.CornerRadius = UDim.new(0, 10)
    scrollCorner.Parent = scroll

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 6)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scroll

    local footer = Instance.new("TextLabel")
    footer.Size = UDim2.new(1, -30, 0, 22)
    footer.Position = UDim2.new(0, 15, 1, -28)
    footer.BackgroundTransparency = 1
    footer.Text = "by akriv1s  •  Right Shift — свернуть/развернуть"
    footer.TextColor3 = Color3.fromRGB(80, 80, 110)
    footer.Font = Enum.Font.Gotham
    footer.TextSize = 10
    footer.Parent = win

    -- ===== ЛОГИКА =====
    local function clearList()
        for _, c in ipairs(scroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
    end

    local function showScripts(scripts, foundGameName)
        clearList()

        if not scripts or #scripts == 0 then
            local empty = Instance.new("TextLabel")
            empty.Size = UDim2.new(1, 0, 0, 60)
            empty.BackgroundTransparency = 1
            empty.Text = "Скрипты не найдены.\nПопробуй другое название или universal-скрипты."
            empty.TextColor3 = Color3.fromRGB(160, 160, 190)
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 12
            empty.TextWrapped = true
            empty.Parent = scroll
            return
        end

        for i, script in ipairs(scripts) do
            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, 0, 0, 72)
            card.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
            card.BorderSizePixel = 0
            card.LayoutOrder = i
            card.Parent = scroll

            local cardCorner = Instance.new("UICorner")
            cardCorner.CornerRadius = UDim.new(0, 10)
            cardCorner.Parent = card

            local title = Instance.new("TextLabel")
            title.Size = UDim2.new(1, -110, 0, 22)
            title.Position = UDim2.new(0, 14, 0, 8)
            title.BackgroundTransparency = 1
            title.Text = script.title or "Без названия"
            title.TextColor3 = Color3.fromRGB(255, 255, 255)
            title.Font = Enum.Font.GothamBold
            title.TextSize = 13
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.TextTruncate = Enum.TextTruncate.AtEnd
            title.Parent = card

            local info = Instance.new("TextLabel")
            info.Size = UDim2.new(1, -110, 0, 14)
            info.Position = UDim2.new(0, 14, 0, 30)
            info.BackgroundTransparency = 1
            info.Text = (script.source or "?") .. "  •  👁 " .. tostring(script.views or 0) .. "  •  " .. (script.verified and "✅" or "❌")
            info.TextColor3 = Color3.fromRGB(130, 130, 160)
            info.Font = Enum.Font.Gotham
            info.TextSize = 10
            info.TextXAlignment = Enum.TextXAlignment.Left
            info.TextTruncate = Enum.TextTruncate.AtEnd
            info.Parent = card

            local runBtn = Instance.new("TextButton")
            runBtn.Size = UDim2.new(0, 90, 0, 30)
            runBtn.Position = UDim2.new(1, -102, 0.5, -15)
            runBtn.BackgroundColor3 = Color3.fromRGB(55, 140, 70)
            runBtn.BorderSizePixel = 0
            runBtn.Text = "▶ Запустить"
            runBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            runBtn.Font = Enum.Font.GothamBold
            runBtn.TextSize = 11
            runBtn.Parent = card

            local runCorner = Instance.new("UICorner")
            runCorner.CornerRadius = UDim.new(0, 8)
            runCorner.Parent = runBtn

            runBtn.MouseButton1Click:Connect(function()
                runBtn.Text = "..."
                runBtn.BackgroundColor3 = Color3.fromRGB(180, 150, 60)
                task.spawn(function()
                    local ok = runScript(script, script.title)
                    task.wait(0.3)
                    if ok then
                        runBtn.Text = "✓ ОК"
                        runBtn.BackgroundColor3 = Color3.fromRGB(55, 140, 70)
                    else
                        runBtn.Text = "✕ Ошибка"
                        runBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
                    end
                    task.wait(1.5)
                    runBtn.Text = "▶ Запустить"
                    runBtn.BackgroundColor3 = Color3.fromRGB(55, 140, 70)
                end)
            end)
        end
    end

    searchBtn.MouseButton1Click:Connect(function()
        local query = searchBox.Text
        if query == "" then
            statusLabel.Text = "⚠ Введи название игры"
            statusLabel.TextColor3 = Color3.fromRGB(255, 180, 60)
            return
        end

        statusLabel.Text = "🔍 Ищу игру: " .. query .. "..."
        statusLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
        searchBtn.Text = "..."
        searchBtn.BackgroundColor3 = Color3.fromRGB(180, 150, 60)
        clearList()

        task.spawn(function()
            local scripts, foundName = findScripts(query)
            if not scripts then
                statusLabel.Text = "❌ " .. tostring(foundName)
                statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                searchBtn.Text = "🔍 Найти"
                searchBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 90)
                return
            end

            statusLabel.Text = "✅ Найдено " .. #scripts .. " скриптов для «" .. foundName .. "»"
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 160)
            showScripts(scripts, foundName)

            searchBtn.Text = "🔍 Найти"
            searchBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 90)
        end)
    end)

    -- ===== СВОРАЧИВАНИЕ =====
    local isCollapsed = false
    local fullSize = UDim2.new(0, 620, 0, 480)
    local fullPos = UDim2.new(0.5, -310, 0.5, -240)

    local function setCollapsed(collapsed)
        isCollapsed = collapsed
        if collapsed then
            TweenService:Create(win, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 180, 0, 50),
                Position = UDim2.new(0, 20, 0, 20)
            }):Play()
            collapseBtn.Text = "+"
            searchFrame.Visible = false
            statusLabel.Visible = false
            scroll.Visible = false
            footer.Visible = false
            subtitle.Text = "• свёрнуто"
        else
            TweenService:Create(win, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = fullSize,
                Position = fullPos
            }):Play()
            collapseBtn.Text = "−"
            searchFrame.Visible = true
            statusLabel.Visible = true
            scroll.Visible = true
            footer.Visible = true
            subtitle.Text = "| Search & Run"
        end
    end

    collapseBtn.MouseButton1Click:Connect(function()
        setCollapsed(not isCollapsed)
    end)

    UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            setCollapsed(not isCollapsed)
        end
    end)
end

-- ==================== СТАРТ ====================
task.wait(0.5)
showLoading()

print("[Game Script Finder v2.1] Загружен. Ищи игры через поле ввода.")
