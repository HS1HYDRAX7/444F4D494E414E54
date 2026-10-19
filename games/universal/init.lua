--[[
  Universal — tudo nativo no Dominant.
  ESP + Aimbot (combat), movement, screen (incl. better first person),
  background, explorer, misc.
  Os .txt antigos (AxisHub / AirHub / Fly / FP) foram integrados e removidos.
]]

local M = {
    Name = "Universal",
    Version = "1.4.0",
    VersionKey = "universal_version",
    Options = { builtInFly = true },
}

local FEATURE_ORDER = { "combat", "movement", "screen", "background", "explorer", "misc" }

local TABS = {
    { "tab_combat", "Lucide:crosshair", { "combat" } },
    { "tab_player", "Lucide:user", { "movement", "screen" } },
    { "tab_visuals", "Lucide:eye", { "background" } },
    { "tab_misc", "Lucide:wrench", { "explorer", "misc" } },
}

M.errors = {}
M.features = {}

local function note(ctx, text)
    table.insert(M.errors, text)
    if ctx and type(ctx.warn) == "function" then
        pcall(ctx.warn, "[Universal] " .. text)
    end
end

local function guarded(ctx, label, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        note(ctx, label .. " failed: " .. tostring(err))
    end
    return ok
end

function M.Init(ctx)
    M.errors = {}
    M.features = {}
    ctx.gameKey = "universal"
    ctx.game = "Universal"

    pcall(function()
        local en = {
            universal_version = "1.4.0",
            tab_combat = "Combat",
            sec_esp = "ESP",
            sec_aimbot = "Aimbot",
            sec_firstperson = "First Person",
            esp = "Enable ESP",
            esp_d = "Boxes, names, distance, tracers and health bars",
            esp_box = "Boxes",
            esp_name = "Names",
            esp_distance = "Distance",
            esp_tracer = "Tracers",
            esp_health = "Health bar",
            esp_teamcheck = "Team check",
            esp_max_distance = "Max distance",
            esp_text_size = "Text size",
            esp_tracers = "Tracers",
            esp_outline_only = "Outline only",
            esp_fill = "Fill opacity",
            esp_tracer_thickness = "Tracer thickness",
            aimbot = "Enable Aimbot",
            aimbot_d = "Hold RMB or E to lock on closest target in FOV",
            aimbot_fov = "FOV",
            aimbot_smooth = "Smoothness",
            aimbot_teamcheck = "Team check",
            aimbot_wallcheck = "Wall check",
            aimbot_show_fov = "Show FOV circle",
            aimbot_part = "Aim part",
            hotkey_esp = "Toggle ESP",
            hotkey_aimbot = "Toggle Aimbot",
            fp_smooth = "Smooth first person",
            fp_smooth_d = "Head bob, camera offset and light shake (from the old FP script)",
            fp_hide_head = "Hide head in FP",
            fp_bob = "Bob amount",
            fp_offset_y = "Offset Y",
            fp_offset_z = "Offset Z",
        }
        local pt = {
            universal_version = "1.4.0",
            tab_combat = "Combate",
            sec_esp = "ESP",
            sec_aimbot = "Aimbot",
            sec_firstperson = "Primeira Pessoa",
            esp = "Ativar ESP",
            esp_d = "Caixas, nomes, distância, tracers e barra de vida",
            esp_box = "Caixas",
            esp_name = "Nomes",
            esp_distance = "Distância",
            esp_tracer = "Tracers",
            esp_health = "Barra de vida",
            esp_teamcheck = "Team check",
            esp_max_distance = "Distância máx.",
            esp_text_size = "Tamanho do texto",
            esp_tracers = "Tracers",
            esp_outline_only = "Só contorno",
            esp_fill = "Opacidade do fill",
            esp_tracer_thickness = "Espessura do tracer",
            aimbot = "Ativar Aimbot",
            aimbot_d = "Segure RMB ou E para travar no alvo no FOV",
            aimbot_fov = "FOV",
            aimbot_smooth = "Suavidade",
            aimbot_teamcheck = "Team check",
            aimbot_wallcheck = "Wall check",
            aimbot_show_fov = "Mostrar círculo FOV",
            aimbot_part = "Parte mirada",
            hotkey_esp = "Alternar ESP",
            hotkey_aimbot = "Alternar Aimbot",
            fp_smooth = "Primeira pessoa suave",
            fp_smooth_d = "Bob da cabeça, offset da câmera e shake leve",
            fp_hide_head = "Esconder cabeça no FP",
            fp_bob = "Quantidade de bob",
            fp_offset_y = "Offset Y",
            fp_offset_z = "Offset Z",
        }
        for _, code in ipairs({ "en", "es", "ru" }) do
            ctx.addStrings(code, en)
        end
        ctx.addStrings("pt", pt)
    end)

    local loadPaths = {
        combat = "shared/features/combat",
        movement = "shared/features/movement",
        screen = "shared/features/screen",
        background = "shared/features/background",
        explorer = "shared/features/explorer",
        misc = "shared/features/misc",
    }

    for _, name in ipairs(FEATURE_ORDER) do
        local ok, feature = pcall(function()
            return ctx.modules:require(loadPaths[name])
        end)
        if ok and type(feature) == "table" then
            if type(feature.Register) == "function" then
                pcall(feature.Register, ctx)
            end
            M.features[name] = feature
        else
            note(ctx, "feature load failed (" .. name .. "): " .. tostring(feature))
        end
    end

    return true
end

function M.Build(window, ctx)
    local function addTab(labelKey, icon, featureNames)
        local label = ctx.L(labelKey)
        if type(label) ~= "string" or label == "" or label == labelKey then
            local fallback = {
                tab_combat = "Combat",
                tab_player = "Player",
                tab_visuals = "Visuals",
                tab_misc = "Misc",
            }
            label = fallback[labelKey] or labelKey
        end

        local okTab, tab = pcall(function()
            return window:AddTab({ Name = label, Icon = icon })
        end)
        if not okTab or tab == nil then
            note(ctx, "tab failed (" .. tostring(labelKey) .. "): " .. tostring(tab))
            return
        end

        for _, name in ipairs(featureNames) do
            local feature = M.features[name]
            if not feature or type(feature.Build) ~= "function" then
                note(ctx, "feature missing for tab (" .. name .. ")")
            else
                guarded(ctx, name, feature.Build, tab, ctx)
            end
        end
    end

    for _, entry in ipairs(TABS) do
        addTab(entry[1], entry[2], entry[3])
    end
end

return M
