--========================================================
--            CUSTOM FLUENT LOGGER / INTERCEPTOR
--========================================================

local function log(...)
    local t = {}
    for i,v in ipairs({...}) do table.insert(t, tostring(v)) end
    print("[mycom]", table.concat(t,"   "))
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
    log("CreateWindow()", "DATA =", game:GetService("HttpService"):JSONEncode(data))

    local self = setmetatable({}, Window)
    self._tabs = {}
    return self
end

function Window:AddTab(data)
    log("AddTab()", "TAB =", data.Title, "ICON =", tostring(data.Icon))

    local tab = {
        _elements = {},
        Name = data.Title
    }

    -- Fake element-creation functions
    function tab:AddParagraph(d)
        log("AddParagraph()", self.Name, game:GetService("HttpService"):JSONEncode(d))
        return {}
    end

    function tab:AddButton(d)
        log("AddButton()", self.Name, game:GetService("HttpService"):JSONEncode(d))
        return d.Callback
    end

    function tab:AddToggle(name, d)
        log("AddToggle()", self.Name, name, game:GetService("HttpService"):JSONEncode(d))

        Fluent.Options[name] = {
            Value = d.Default or false,
            SetValue = function(_, v)
                log("Toggle:SetValue()", name, v)
                Fluent.Options[name].Value = v
            end,
            OnChanged = function(_, cb)
                log("Toggle:OnChanged()", name)
                Fluent.Options[name].Changed = cb
            end
        }

        return Fluent.Options[name]
    end

    function tab:AddSlider(name, d)
        log("AddSlider()", self.Name, name, game:GetService("HttpService"):JSONEncode(d))

        local S = {
            Value = d.Default,
            SetValue = function(_, v)
                log("Slider:SetValue()", name, v)
                S.Value = v
            end,
            OnChanged = function(_, cb)
                log("Slider:OnChanged()", name)
                S.Changed = cb
            end
        }
        return S
    end

    function tab:AddDropdown(name, d)
        log("AddDropdown()", self.Name, name, game:GetService("HttpService"):JSONEncode(d))

        local D = {
            Value = d.Default,
            SetValue = function(_, v)
                log("Dropdown:SetValue()", name, game:GetService("HttpService"):JSONEncode(v))
                D.Value = v
            end,
            OnChanged = function(_, cb)
                log("Dropdown:OnChanged()", name)
                D.Changed = cb
            end
        }
        return D
    end

    function tab:AddColorpicker(name, d)
        log("AddColorpicker()", self.Name, name, game:GetService("HttpService"):JSONEncode({
            Default = tostring(d.Default),
            Transparency = d.Transparency
        }))

        local C = {
            Value = d.Default,
            Transparency = d.Transparency,
            SetValueRGB = function(_, v)
                log("Colorpicker:SetValueRGB()", name, tostring(v))
                C.Value = v
            end,
            OnChanged = function(_, cb)
                log("Colorpicker:OnChanged()", name)
                C.Changed = cb
            end
        }
        return C
    end

    function tab:AddKeybind(name, d)
        log("AddKeybind()", self.Name, name, game:GetService("HttpService"):JSONEncode(d))

        local K = {
            Value = d.Default,
            Mode = d.Mode,
            Callback = d.Callback,
            ChangedCallback = d.ChangedCallback,
            OnClick = function(_, cb)
                log("Keybind:OnClick()", name)
                K.Click = cb
            end,
            OnChanged = function(_, cb)
                log("Keybind:OnChanged()", name)
                K.Changed = cb
            end,
            SetValue = function(_, key, mode)
                log("Keybind:SetValue()", name, key, mode)
                K.Value = key
                K.Mode = mode
            end,
            GetState = function()
                return false
            end
        }
        return K
    end

    function tab:AddInput(name, d)
        log("AddInput()", self.Name, name, game:GetService("HttpService"):JSONEncode(d))

        local I = {
            Value = d.Default,
            SetValue = function(_, v)
                log("Input:SetValue()", name, v)
                I.Value = v
            end,
            OnChanged = function(_, cb)
                log("Input:OnChanged()", name)
                I.Changed = cb
            end
        }
        return I
    end

    return tab
end

function Window:Dialog(data)
    log("Dialog()", game:GetService("HttpService"):JSONEncode(data))
end

function Window:SelectTab(index)
    log("SelectTab()", index)
end

--========================================================
--                TOP-LEVEL FLUENT FUNCS
--========================================================
function Fluent:Notify(d)
    log("Notify()", game:GetService("HttpService"):JSONEncode(d))
end

return Fluent