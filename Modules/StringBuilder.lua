--[=[
    @class StringBuilder

    A class that allows accumulation of many strings to be built into one combined string later in a way that is faster than compound concatenations.

    In other words: this is a `speed > memory` class

    Written by Turing6.
]=]
local StringBuilder = {}
StringBuilder.__index = StringBuilder

export type StringBuilder = typeof(setmetatable({}, StringBuilder))

export type TextFormatter<T...> = {
    new: (T...) -> TextFormatter<T...>,
    Format: (self: TextFormatter<T...>, s: string) -> string
}

function formatForRichText(s: string): string
    local amp = string.gsub(s, "&", "&amp;")
    local lt = string.gsub(amp, "<", "&lt;")
    local gt = string.gsub(lt, ">", "&gt;")
    local quot = string.gsub(gt, "\"", "&quot;")
    local apos = string.gsub(quot, "'", "&apos;")
    return apos
end

StringBuilder.FontSize = {
    new = function(size: number)
        return setmetatable({Size = size}, {__index = StringBuilder.FontSize})
    end,
    Format = function(self, s: string): string
        return `<font size="{self.Size}">{s}</font>`
    end
} :: TextFormatter<number>

StringBuilder.FontTransparency = {
    new = function(transparency: number)
        return setmetatable({Transparency = transparency}, {__index = StringBuilder.FontSize})
    end,
    Format = function(self, s: string): string
        return `<font transparency="{self.Transparency}">{s}</font>`
    end
} :: TextFormatter<number>

type FontWeight = "thin" | "ExtraLight" | "Thin" | "Light" | "light" | "Heavy" | "heavy" | "Bold" | "bold" | "ExtraBold" | "SemiBold" | "medium" | "Medium" | "regular" | "Regular" | "semiBold" | "extraBold" | "extralight" | "extraLight" | "semibold" | "extrabold"

StringBuilder.FontWeight = {
    new = function(weight: number | FontWeight)
        return setmetatable({Weight = weight}, {__index = StringBuilder.FontSize})
    end,
    Format = function(self, s: string): string
        return `<font weight="{self.Weight}">{s}</font>`
    end
} :: TextFormatter<number | FontWeight>

StringBuilder.FontColor = {
    new = function(color: vector)
        return setmetatable({Color = color}, {__index = StringBuilder.FontSize})
    end,
    Format = function(self, s: string): string
        return `<font color="rgb({self.Color.R * 255},{self.Color.G * 255},{self.Color.B * 255})">{s}</font>`
    end
} :: TextFormatter<vector>

StringBuilder.FontFace = {
    new = function(face: string)
        return setmetatable({Face = face}, {__index = StringBuilder.FontSize})
    end,
    Format = function(self, s: string): string
        return `<font face="{self.Face}">{s}</font>`
    end
} :: TextFormatter<string>

StringBuilder.Bold = {
    new = function()
        return setmetatable({}, {__index = StringBuilder.FontSize})
    end,
    Format = function(self, s: string): string
        return `<b>{s}</b>`
    end
} :: TextFormatter<>

StringBuilder.Itallic = {
    new = function()
        return setmetatable({}, {__index = StringBuilder.FontSize})
    end,
    Format = function(self, s: string): string
        return `<i>{s}</i>`
    end
} :: TextFormatter<>

StringBuilder.Underline = {
    new = function()
        return setmetatable({}, {__index = StringBuilder.FontSize})
    end,
    Format = function(self, s: string): string
        return `<u>{s}</u>`
    end
} :: TextFormatter<>

StringBuilder.Strikethrough = {
    new = function()
        return setmetatable({}, {__index = StringBuilder.FontSize})
    end,
    Format = function(self, s: string): string
        return `<s>{s}</s>`
    end
} :: TextFormatter<>

StringBuilder.Uppercase = {
    new = function()
        return setmetatable({}, {__index = StringBuilder.FontSize})
    end,
    Format = function(self, s: string): string
        return `<uc>{s}</uc>`
    end
} :: TextFormatter<>

StringBuilder.Smallcaps = {
    new = function()
        return setmetatable({}, {__index = StringBuilder.FontSize})
    end,
    Format = function(self, s: string): string
        return `<sc>{s}</sc>`
    end
} :: TextFormatter<>

StringBuilder.Mark = {
    new = function(color: vector, transparency: number)
        return setmetatable({Transparency = transparency, Color = color}, {__index = StringBuilder.FontSize})
    end,
    Format = function(self, s: string): string
        return `<mark color="rgb({self.Color.R * 255},{self.Color.G * 255},{self.Color.B * 255})" transparency="{self.Transparency}">{s}</mark>`
    end
} :: TextFormatter<vector, number>

type StrokeSize = "fixed" | "scaled"
type StrokeJoins = "round" | "miter" | "bevel"

StringBuilder.Stroke = {
    new = function(color: vector, thickness: number, transparency: number?, joins: StrokeJoins?, sizing: StrokeSize?)
        transparency = if transparency then transparency else 0
        sizing = if sizing then sizing else "scaled"
        joins = if joins then joins else "round"
        return setmetatable({Color = color, Thickness = thickness, Transparency = transparency, Joins = joins, Sizing = sizing}, {__index = StringBuilder.FontSize})
    end,
    Format = function(self, s: string): string
        return `<stroke color="rgb({self.Color.R * 255},{self.Color.G * 255},{self.Color.B * 255})" th="{self.Thickness}" tr="{self.Transparency}" joins="{self.Joins}" sizing="{self.Sizing}">{s}</stroke>`
    end
} :: TextFormatter<vector, number, number?, StrokeJoins?, StrokeSize?>

--[=[
    Creates a new StringBuilder.

    @param initalCapacity number? -- StringBuilder will pre-allocate a table for this many appends/prepends if present
    @param reusable boolean?
    @return StringBuilder
]=]
function StringBuilder.new(initalCapacity: number?, reusable: boolean?): StringBuilder
    local self: StringBuilder = setmetatable({_strings = if initalCapacity then table.create(initalCapacity) else {}, _prepends = 0, _reuse = reusable}, StringBuilder)
    return self
end

--[[
    Appends the given string to the end of the StringBuilder's string.

    @param s string
    @return StringBuilder
]]
function StringBuilder.Append(self: StringBuilder, s: string): StringBuilder
    table.insert(self._strings, s)
    return self
end

--[[
    Prepends the given string to the begining of the StringBuilder's string.

    @param s string
    @return StringBuilder
]]
function StringBuilder.Prepend(self: StringBuilder, s: string): StringBuilder
    table.insert(self._strings, self._prepends, s)
    self._prepends += 1
    return self
end

--[[
    Appends a whitespace character, then the given string.

    @param s string
    @return StringBuilder
]]
function StringBuilder.AppendWithSpace(self: StringBuilder, s: string): StringBuilder
    return self:Append(" "):Append(s)
end

--[[
    Prepends a whitespace character, then the given string.

    @param s string
    @return StringBuilder
]]
function StringBuilder.PrependWithSpace(self: StringBuilder, s: string): StringBuilder
    return self:Prepend(s):Prepend(" ")
end

--[[
    Appends a new line character (`<br/>` (requires rich text)), then the given string.

    @param s string
    @return StringBuilder
]]
function StringBuilder.AppendNewLine(self: StringBuilder, s: string): StringBuilder
    return self:Append("<br/>"):Append(s)
end

--[=[
    Appends the given string after formatting it using the given formatter.

    @param s string
    @param formatter TextFormatter
    @return StringBuilder
]=]
function StringBuilder.AppendFormatted(self: StringBuilder, s: string, formatter: TextFormatter<>): StringBuilder
    return self:Append(formatter:Format(formatForRichText(s)))
end

--[=[
    Prepends the given string after formatting it using the given formatter.

    @param s string
    @param formatter TextFormatter
    @return StringBuilder
]=]
function StringBuilder.PrependFormatted(self: StringBuilder, s: string, formatter: TextFormatter<>): StringBuilder
    return self:Prepend(formatter:Format(formatForRichText(s)))
end

--[=[
    Builds the current string and returns it, clearing the builder.

    @return string
]=]
function StringBuilder.__tostring(self: StringBuilder): string
    if (self._reuse or self._str == nil) or #self._strings > 0 then
        self._str = table.concat(self._strings, "")
        self._prepends = 0
        table.clear(self._strings)
    end
    return self._str
end

StringBuilder.ToString = StringBuilder.__tostring
StringBuilder.Build = StringBuilder.__tostring

--[=[
    Runs the given callback and passes the built string as an argument.

    @param callback (string) -> ()
]=]
function StringBuilder.BuildAndAccept(self: StringBuilder, callback: (string) -> ())
    callback(tostring(self))
end

return StringBuilder