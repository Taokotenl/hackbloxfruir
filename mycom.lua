--========================================================
--       FLUENT LOGGER WITH SOURCE CODE EXTRACTION
--========================================================

local HttpService = game:GetService("HttpService")

local function log(...)
    local t = {}
    for i,v in ipairs({...}) do 
        table.insert(t, tostring(v)) 
    end
    print("[FLUENT-LOG]", table.concat(t, " | "))
end

-- Function to extract source code from callback
local function extractFunctionSource(func)
    if type(func) ~= "function" then 
        return "<not a function>" 
    end
    
    local info = debug.getinfo(func, "S")
    if not info then 
        return "<no debug info>" 
    end
    
    local source = info.source or "<unknown>"
    local lineStart = info.linedefined or 0
    local lineEnd = info.lastlinedefined or 0
    
    -- Try to get the actual source code
    local sourceCode = ""
    
    -- If it's from a file
    if source:sub(1,1) == "@" then
        sourceCode = "FILE: " .. source:sub(2) .. " (Lines " .. lineStart .. "-" .. lineEnd .. ")"
    -- If it's from a loadstring
    elseif source:sub(1,1) == "=" then
        sourceCode = "LOADSTRING: " .. source .. " (Lines " .. lineStart .. "-" .. lineEnd .. ")"
    -- If it's inline code
    else
        -- Try to extract the actual code
        local success, result = pcall(function()
            -- Get the source string
            if source and source ~= "" then
                local lines = {}
                for line in source:gmatch("[^\r\n]+") do
                    table.insert(lines, line)
                end
                
                if lineStart > 0 and lineEnd > 0 and lineEnd >= lineStart then
                    local codeLines = {}
                    for i = lineStart, lineEnd do
                        if lines[i] then
                            table.insert(codeLines, lines[i])
                        end
                    end
                    if #codeLines > 0 then
                        return "CODE:\n" .. table.concat(codeLines, "\n")
                    end
                end
            end
            return source
        end)
        
        if success and result then
            sourceCode = result
        else
            sourceCode = "SOURCE: " .. source .. " (Lines " .. lineStart .. "-" .. lineEnd .. ")"
        end
    end
    
    -- Try string.dump to get bytecode info
    local bytecodeInfo = ""
    local dumpSuccess, bytecode = pcall(string.dump, func)
    if dumpSuccess then
        bytecodeInfo = " | Bytecode: " .. #bytecode .. " bytes"
    end
    
    return sourceCode .. bytecodeInfo
end

-- Function to log callback with full details
local function logCallback(context, callback, extraData)
    log("==========================================")
    log("CONTEXT:", context)
    if extraData then
        log("DATA:", HttpService:JSONEncode(extraData))
    end
    log("CALLBACK SOURCE:")
    print(extractFunctionSource(callback))
    log("==========================================")
end

local Fluent = {
    Version = "MyCom-SourceLogger-v2",
    Options = {},
    Unloaded = false
}

--========================================================
--                WINDOW OBJECT
--========================================================
local Window = {}
Window.__index = Window

function Fluent:CreateWindow(data)
    log("CreateWindow", HttpService:JSONEncode(data))
    local self = setmetatable({}, Window)
    self._tabs = {}
    return self
end

function Window:AddTab(data)
    log("AddTab", "Title=" .. tostring(data.Title), "Icon=" .. tostring(data.Icon))
    
    local tab = {
        _elements = {},
        Name = data.Title
    }
    
    -- AddParagraph
    function tab:AddParagraph(d)
        log("AddParagraph", self.Name, HttpService:JSONEncode(d))
        return {}
    end
    
    -- AddButton with source logging
    function tab:AddButton(d)
        log("AddButton", self.Name, "Title=" .. tostring(d.Title))
        
        if d.Callback then
            logCallback("BUTTON: " .. tostring(d.Title), d.Callback, {
                Title = d.Title,
                Description = d.Description
            })
            
            -- Wrap callback to log when executed
            local originalCallback = d.Callback
            d.Callback = function(...)
                log(">>> EXECUTING BUTTON:", d.Title)
                logCallback("BUTTON EXECUTION: " .. d.Title, originalCallback)
                return originalCallback(...)
            end
        end
        
        return d.Callback
    end
    
    -- AddToggle with source logging
    function tab:AddToggle(name, d)
        log("AddToggle", self.Name, "Name=" .. name)
        
        if d.Callback then
            logCallback("TOGGLE: " .. name, d.Callback, d)
        end
        
        Fluent.Options[name] = {
            Value = d.Default or false,
            SetValue = function(_, v)
                log("Toggle:SetValue", name, v)
                Fluent.Options[name].Value = v
            end
        }
        
        function Fluent.Options[name]:OnChanged(cb)
            log("Toggle:OnChanged", name)
            if cb then
                logCallback("TOGGLE OnChanged: " .. name, cb)
            end
            Fluent.Options[name].Changed = cb
        end
        
        return Fluent.Options[name]
    end
    
    -- AddSlider with source logging
    function tab:AddSlider(name, d)
        log("AddSlider", self.Name, "Name=" .. name)
        
        if d.Callback then
            logCallback("SLIDER: " .. name, d.Callback, d)
            
            local originalCallback = d.Callback
            d.Callback = function(...)
                log(">>> EXECUTING SLIDER:", name)
                return originalCallback(...)
            end
        end
        
        local S = {
            Value = d.Default,
            SetValue = function(_, v)
                log("Slider:SetValue", name, v)
                S.Value = v
            end
        }
        
        function S:OnChanged(cb)
            log("Slider:OnChanged", name)
            if cb then
                logCallback("SLIDER OnChanged: " .. name, cb)
            end
            S.Changed = cb
        end
        
        return S
    end
    
    -- AddDropdown with source logging
    function tab:AddDropdown(name, d)
        log("AddDropdown", self.Name, "Name=" .. name)
        
        if d.Callback then
            logCallback("DROPDOWN: " .. name, d.Callback, d)
        end
        
        local D = {
            Value = d.Default,
            SetValue = function(_, v)
                log("Dropdown:SetValue", name, HttpService:JSONEncode(v))
                D.Value = v
            end
        }
        
        function D:OnChanged(cb)
            log("Dropdown:OnChanged", name)
            if cb then
                logCallback("DROPDOWN OnChanged: " .. name, cb)
            end
            D.Changed = cb
        end
        
        return D
    end
    
    -- AddColorpicker with source logging
    function tab:AddColorpicker(name, d)
        log("AddColorpicker", self.Name, "Name=" .. name)
        
        local C = {
            Value = d.Default,
            Transparency = d.Transparency,
            SetValueRGB = function(_, v)
                log("Colorpicker:SetValueRGB", name, tostring(v))
                C.Value = v
            end
        }
        
        function C:OnChanged(cb)
            log("Colorpicker:OnChanged", name)
            if cb then
                logCallback("COLORPICKER OnChanged: " .. name, cb)
            end
            C.Changed = cb
        end
        
        return C
    end
    
    -- AddKeybind with source logging
    function tab:AddKeybind(name, d)
        log("AddKeybind", self.Name, "Name=" .. name)
        
        if d.Callback then
            logCallback("KEYBIND Callback: " .. name, d.Callback, d)
        end
        if d.ChangedCallback then
            logCallback("KEYBIND ChangedCallback: " .. name, d.ChangedCallback)
        end
        
        local K = {
            Value = d.Default,
            Mode = d.Mode,
            Callback = d.Callback,
            ChangedCallback = d.ChangedCallback
        }
        
        function K:OnClick(cb)
            log("Keybind:OnClick", name)
            if cb then
                logCallback("KEYBIND OnClick: " .. name, cb)
            end
            K.Click = cb
        end
        
        function K:OnChanged(cb)
            log("Keybind:OnChanged", name)
            if cb then
                logCallback("KEYBIND OnChanged: " .. name, cb)
            end
            K.Changed = cb
        end
        
        function K:SetValue(key, mode)
            log("Keybind:SetValue", name, key, mode)
            K.Value = key
            K.Mode = mode
        end
        
        function K:GetState()
            return false
        end
        
        return K
    end
    
    -- AddInput with source logging
    function tab:AddInput(name, d)
        log("AddInput", self.Name, "Name=" .. name)
        
        if d.Callback then
            logCallback("INPUT: " .. name, d.Callback, d)
            
            local originalCallback = d.Callback
            d.Callback = function(...)
                log(">>> EXECUTING INPUT:", name, ...)
                return originalCallback(...)
            end
        end
        
        local I = {
            Value = d.Default,
            SetValue = function(_, v)
                log("Input:SetValue", name, v)
                I.Value = v
            end
        }
        
        function I:OnChanged(cb)
            log("Input:OnChanged", name)
            if cb then
                logCallback("INPUT OnChanged: " .. name, cb)
            end
            I.Changed = cb
        end
        
        return I
    end
    
    return tab
end

function Window:Dialog(data)
    log("Dialog", HttpService:JSONEncode({
        Title = data.Title,
        Content = data.Content,
        ButtonCount = data.Buttons and #data.Buttons or 0
    }))
    
    if data.Buttons then
        for i, btn in ipairs(data.Buttons) do
            if btn.Callback then
                logCallback("DIALOG BUTTON: " .. btn.Title, btn.Callback, {
                    DialogTitle = data.Title,
                    ButtonTitle = btn.Title
                })
            end
        end
    end
end

function Window:SelectTab(index)
    log("SelectTab", index)
end

--========================================================
--                TOP-LEVEL FLUENT FUNCS
--========================================================
function Fluent:Notify(d)
    log("Notify", HttpService:JSONEncode(d))
end

return Fluent