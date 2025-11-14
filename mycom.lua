--==============================
-- MYCOM CALLBACK INTERCEPTOR
-- Hook mọi callback của Fluent
--==============================

local OriginalLoadstring = loadstring

getgenv().mycom_data = {}

-- function to serialize ANY Lua value safely
local function serialize(value, depth)
    depth = depth or 0
    if depth > 3 then return '"<max-depth>"' end

    local t = typeof(value)
    if t == "string" then
        return '"' .. value .. '"'
    elseif t == "number" or t == "boolean" then
        return tostring(value)
    elseif t == "Color3" then
        return ("Color3.new(%s,%s,%s)"):format(value.R, value.G, value.B)
    elseif t == "Vector2" then
        return ("Vector2.new(%s,%s)"):format(value.X, value.Y)
    elseif t == "Vector3" then
        return ("Vector3.new(%s,%s,%s)"):format(value.X, value.Y, value.Z)
    elseif t == "table" then
        local s = "{ "
        for k, v in next, value do
            s = s .. "[" .. serialize(k, depth+1) .. "]=" .. serialize(v, depth+1) .. ", "
        end
        return s .. " }"
    elseif t == "Instance" then
        return ('"<Instance %s>"'):format(value:GetFullName())
    end
    return ('"<%s>"'):format(t)
end

--==============================
-- HOOK Loadstring để thay URL
--==============================

function loadstring(input)
    if type(input) == "string" 
       and input:find("github.com/dawid%-scripts/Fluent/releases") then
        
        warn("MYCOM: Replacing Fluent main.lua with mycom hooks")

        local code = game:HttpGet("https://raw.githubusercontent.com/yourname/mycom/main/mycom.txt")
        return OriginalLoadstring(code)
    end

    return OriginalLoadstring(input)
end

--==============================
-- THIS IS WHERE WE HOOK FLUENT
--==============================

getgenv().Fluent_Hooked = function(Fluent)
    local oldAddButton = Fluent.AddButton
    local oldAddToggle = Fluent.AddToggle
    local oldAddSlider = Fluent.AddSlider
    local oldAddDropdown = Fluent.AddDropdown
    local oldAddKeybind = Fluent.AddKeybind
    local oldAddInput = Fluent.AddInput
    local oldAddColorpicker = Fluent.AddColorpicker

    --------------------------------------
    -- UNIVERSAL HOOK FACTORY
    --------------------------------------
    local function wrap(orig, typeName)
        return function(tab, id, data)
            local originalCallback = data.Callback
            data.Callback = function(...)
                print("========== ".. typeName .." Triggered ==========")
                print("ID: ", id)
                print("VALUE: ", serialize(...))
                print("==========================================")

                if originalCallback then
                    originalCallback(...)
                end
            end
            return orig(tab, id, data)
        end
    end

    --------------------------------------
    -- APPLY HOOKS
    --------------------------------------
    Fluent.AddButton       = wrap(oldAddButton, "BUTTON")
    Fluent.AddToggle       = wrap(oldAddToggle, "TOGGLE")
    Fluent.AddSlider       = wrap(oldAddSlider, "SLIDER")
    Fluent.AddDropdown     = wrap(oldAddDropdown, "DROPDOWN")
    Fluent.AddKeybind      = wrap(oldAddKeybind, "KEYBIND")
    Fluent.AddInput        = wrap(oldAddInput, "INPUT")
    Fluent.AddColorpicker  = wrap(oldAddColorpicker, "COLORPICKER")

    warn("MYCOM: ALL FLUENT CALLBACKS HOOKED")
end

return getgenv().Fluent_Hooked