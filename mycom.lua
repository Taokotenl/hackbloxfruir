--========================================================
--            CUSTOM FLUENT LOGGER / INTERCEPTOR
--========================================================

local function log(...)
    local t = {}
    for i,v in ipairs({...}) do table.insert(t, tostring(v)) end
    print("[mycom]", table.concat(t,"   "))
end

-- Function to extract source code from the calling script
local function extractFunctionSource(func)
    local info = debug.getinfo(func, "S")
    if not info then return "Could not get debug info" end
    
    local source = info.source
    local lineStart = info.linedefined
    local lineEnd = info.lastlinedefined
    
    -- Get the script source
    local scriptSource = nil
    
    -- Try to get source from the script that loaded this
    for i = 2, 10 do
        local callerInfo = debug.getinfo(i, "S")
        if callerInfo and callerInfo.source then
            if callerInfo.source:sub(1,1) ~= "@" and callerInfo.source:sub(1,1) ~= "=" then
                scriptSource = callerInfo.source
                break
            end
        end
    end
    
    if not scriptSource then
        return string.format("Source: %s | Lines: %d-%d | (source code not available - compiled or from file)", 
            source, lineStart, lineEnd)
    end
    
    -- Split source into lines
    local lines = {}
    for line in scriptSource:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    
    -- Extract the function lines
    local funcLines = {}
    for i = lineStart, lineEnd do
        if lines[i] then
            table.insert(funcLines, lines[i])
        end
    end
    
    if #funcLines > 0 then
        return table.concat(funcLines, "\n")
    else
        return string.format("Lines %d-%d not found in source", lineStart, lineEnd)
    end
end

-- Better function to capture callback with context
local function captureCallback(callback, name, context)
    if type(callback) ~= "function" then 
        return "Not a function: " .. tostring(callback)
    end
    
    log("==================================================")
    log("REGISTERING CALLBACK:", name)
    log("Context:", context)
    log("--------------------------------------------------")
    
    local source = extractFunctionSource(callback)
    log("SOURCE CODE:")
    log(source)
    log("==================================================\n")
    
    -- Return wrapped function that also logs on execution
    return function(...)
        log(">>> EXECUTING:", name)
        log("Arguments:", ...)
        local results = {pcall(callback, ...)}
        if not results[1] then
            log("ERROR:", results[2])
        end
        return table.unpack(results, 2)
    end
end

local Fluent = {
    Version = "MyCom-Logger",
    Options = {},
    Unloaded = false
}

--========================================================
--                WINDOW OBJECT (FAKE)
--========================================================
local Window = {}
Window.__index = Window

function Fluent:CreateWindow(data)
    log("CreateWindow() CALLED")
    log("Title:", data.Title)
    log("Size:", tostring(data.Size))
    log("Theme:", data.Theme)

    local self = setmetatable({}, Window)
    self._tabs = {}
    return self
end

function Window:AddTab(data)
    log("\n>>> AddTab() <<<")
    log("Tab Name:", data.Title)
    log("Icon:", tostring(data.Icon))

    local tab = {
        _elements = {},
        Name = data.Title
    }

    -- AddParagraph
    function tab:AddParagraph(d)
        log("\n[AddParagraph]", self.Name)
        log("Title:", d.Title)
        log("Content:", d.Content)
        return {}
    end

    -- AddButton
    function tab:AddButton(d)
        log("\n[AddButton]", self.Name)
        log("Title:", d.Title)
        log("Description:", d.Description or "None")
        
        if d.Callback then
            d.Callback = captureCallback(d.Callback, "Button: " .. d.Title, self.Name)
        end
        
        return {
            Click = d.Callback
        }
    end

    -- AddToggle
    function tab:AddToggle(name, d)
        log("\n[AddToggle]", self.Name)
        log("Name:", name)
        log("Title:", d.Title)
        log("Default:", d.Default)

        if d.Callback then
            d.Callback = captureCallback(d.Callback, "Toggle: " .. name, self.Name)
        end

        Fluent.Options[name] = {
            Value = d.Default or false,
            SetValue = function(self, v)
                log("Toggle.SetValue():", name, "=>", v)
                Fluent.Options[name].Value = v
            end,
            OnChanged = function(self, cb)
                log("Toggle.OnChanged() registered for:", name)
                Fluent.Options[name].Changed = captureCallback(cb, "Toggle.OnChanged: " .. name, tab.Name)
            end
        }

        return Fluent.Options[name]
    end

    -- AddSlider
    function tab:AddSlider(name, d)
        log("\n[AddSlider]", self.Name)
        log("Name:", name)
        log("Title:", d.Title)
        log("Range:", d.Min, "to", d.Max)
        log("Default:", d.Default)

        if d.Callback then
            d.Callback = captureCallback(d.Callback, "Slider: " .. name, self.Name)
        end

        local S = {
            Value = d.Default,
            SetValue = function(self, v)
                log("Slider.SetValue():", name, "=>", v)
                S.Value = v
            end,
            OnChanged = function(self, cb)
                log("Slider.OnChanged() registered for:", name)
                S.Changed = captureCallback(cb, "Slider.OnChanged: " .. name, tab.Name)
            end
        }
        return S
    end

    -- AddDropdown
    function tab:AddDropdown(name, d)
        log("\n[AddDropdown]", self.Name)
        log("Name:", name)
        log("Title:", d.Title)
        log("Multi:", d.Multi)
        log("Values:", table.concat(d.Values, ", "))

        if d.Callback then
            d.Callback = captureCallback(d.Callback, "Dropdown: " .. name, self.Name)
        end

        local D = {
            Value = d.Default,
            SetValue = function(self, v)
                log("Dropdown.SetValue():", name, "=>", type(v) == "table" and game:GetService("HttpService"):JSONEncode(v) or v)
                D.Value = v
            end,
            OnChanged = function(self, cb)
                log("Dropdown.OnChanged() registered for:", name)
                D.Changed = captureCallback(cb, "Dropdown.OnChanged: " .. name, tab.Name)
            end
        }
        return D
    end

    -- AddColorpicker
    function tab:AddColorpicker(name, d)
        log("\n[AddColorpicker]", self.Name)
        log("Name:", name)
        log("Title:", d.Title)
        log("Default:", tostring(d.Default))

        if d.Callback then
            d.Callback = captureCallback(d.Callback, "Colorpicker: " .. name, self.Name)
        end

        local C = {
            Value = d.Default,
            Transparency = d.Transparency,
            SetValueRGB = function(self, v)
                log("Colorpicker.SetValueRGB():", name, "=>", tostring(v))
                C.Value = v
            end,
            OnChanged = function(self, cb)
                log("Colorpicker.OnChanged() registered for:", name)
                C.Changed = captureCallback(cb, "Colorpicker.OnChanged: " .. name, tab.Name)
            end
        }
        return C
    end

    -- AddKeybind
    function tab:AddKeybind(name, d)
        log("\n[AddKeybind]", self.Name)
        log("Name:", name)
        log("Title:", d.Title)
        log("Mode:", d.Mode)
        log("Default:", d.Default)

        local wrappedCallback = d.Callback and captureCallback(d.Callback, "Keybind: " .. name, self.Name)
        local wrappedChangedCallback = d.ChangedCallback and captureCallback(d.ChangedCallback, "Keybind.ChangedCallback: " .. name, self.Name)

        local K = {
            Value = d.Default,
            Mode = d.Mode,
            Callback = wrappedCallback,
            ChangedCallback = wrappedChangedCallback,
            OnClick = function(self, cb)
                log("Keybind.OnClick() registered for:", name)
                K.Click = captureCallback(cb, "Keybind.OnClick: " .. name, tab.Name)
            end,
            OnChanged = function(self, cb)
                log("Keybind.OnChanged() registered for:", name)
                K.Changed = captureCallback(cb, "Keybind.OnChanged: " .. name, tab.Name)
            end,
            SetValue = function(self, key, mode)
                log("Keybind.SetValue():", name, "=>", key, mode)
                K.Value = key
                K.Mode = mode
            end,
            GetState = function()
                return false
            end
        }
        return K
    end

    -- AddInput
    function tab:AddInput(name, d)
        log("\n[AddInput]", self.Name)
        log("Name:", name)
        log("Title:", d.Title)
        log("Default:", d.Default)

        if d.Callback then
            d.Callback = captureCallback(d.Callback, "Input: " .. name, self.Name)
        end

        local I = {
            Value = d.Default,
            SetValue = function(self, v)
                log("Input.SetValue():", name, "=>", v)
                I.Value = v
            end,
            OnChanged = function(self, cb)
                log("Input.OnChanged() registered for:", name)
                I.Changed = captureCallback(cb, "Input.OnChanged: " .. name, tab.Name)
            end
        }
        return I
    end

    return tab
end

function Window:Dialog(data)
    log("\n>>> Dialog() <<<")
    log("Title:", data.Title)
    log("Content:", data.Content)
    
    if data.Buttons then
        for i, btn in ipairs(data.Buttons) do
            log("Button", i, ":", btn.Title)
            if btn.Callback then
                btn.Callback = captureCallback(btn.Callback, "Dialog Button: " .. btn.Title, "Dialog")
            end
        end
    end
end

function Window:SelectTab(index)
    log("\n>>> SelectTab() <<<")
    log("Index:", index)
end

--========================================================
--                TOP-LEVEL FLUENT FUNCS
--========================================================
function Fluent:Notify(d)
    log("\n>>> Notify() <<<")
    log("Title:", d.Title)
    log("Content:", d.Content)
    if d.SubContent then
        log("SubContent:", d.SubContent)
    end
    log("Duration:", d.Duration or "nil")
end

return Fluent