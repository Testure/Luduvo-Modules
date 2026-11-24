--[=[
    Module that provides utilites for working with bytes and bits.

    Written by Turing6.

    @class ByteUtils
]=]
const ByteUtils = {}

const MIN, MAX = {}, {}
const INT_NAMES = {"Nibble", "Byte", "Short", "Int"}

MAX.U1 = 1

for i = 2, 32 do
    MAX["U"..i] = (2 ^ i) - 1
    MAX["I"..i] = MAX["U"..(i - 1)]
    MIN["I"..i] = -MAX["U"..(i - 1)]
end

type pack2 = (left: number, right: number) -> number
type unpack2 = (x: number) -> (number, number)
type pack3 = (left: number, middle: number, right: number) -> number
type unpack3 = (x: number) -> (number, number, number)
type pack4 = (lleft: number, rleft: number, lright: number, rright: number) -> number
type unpack4 = (x: number) -> (number, number, number, number)
type pack5 = (lleft: number, rleft: number, middle: number, lright: number, rright: number) -> number
type unpack5 = (x: number) -> (number, number, number, number, number)
type pack6 = (lleft: number, rleft: number, lmiddle: number, rmiddle: number, lright: number, rright: number) -> number
type unpack6 = (x: number) -> (number, number, number, number, number, number)
type pack8 = (lleft: number, rleft: number, llmiddle: number, lrmiddle: number, rlmiddle: number, rrmiddle: number, lright: number, rright: number) -> number
type unpack8 = (x: number) -> (number, number, number, number, number, number, number, number)

type ByteUtils = typeof(ByteUtils) & {
    packU1Nibble: pack4,
    unpackU1Nibble: unpack4,
    packU1Byte: pack8,
    unpackU1Byte: unpack8,
    packU2Nibble: pack2,
    unpackU2Nibble: unpack2,
    packI2Nibble: pack2,
    unpackI2Nibble: unpack2,
    packU2Byte: pack4,
    unpackU2Byte: unpack4,
    packI2Byte: pack4,
    unpackI2Byte: unpack4,
    packU2Short: pack8,
    unpackU2Short: unpack8,
    packI2Short: pack8,
    unpackI2Short: unpack8,
    packU3Short: pack5,
    unpackU3Short: unpack5,
    packI3Short: pack5,
    unpackI3Short: unpack5,
    packU4Byte: pack2,
    unpackU4Byte: unpack2,
    packI4Byte: pack2,
    unpackI4Byte: unpack2,
    packU4Short: pack4,
    unpackU4Short: unpack4,
    packI4Short: pack4,
    unpackI4Short: unpack4,
    packU4Int: pack8,
    unpackU4Int: unpack8,
    packI4Int: pack8,
    unpackI4Int: unpack8,
    packU5Short: pack3,
    unpackU5Short: unpack3,
    packI5Short: pack3,
    unpackI5Short: unpack3,
    packU5Int: pack6,
    unpackU5Int: unpack6,
    packI5Int: pack6,
    unpackI5Int: unpack6,
    packU6Short: pack2,
    unpackU6Short: unpack2,
    packI6Short: pack2,
    unpackI6Short: unpack2,
    packU6Int: pack5,
    unpackU6Int: unpack5,
    packI6Int: pack5,
    unpackI6Int: unpack5,
    packU7Short: pack2,
    unpackU7Short: unpack2,
    packI7Short: pack2,
    unpackI7Short: unpack2,
    packU7Int: pack4,
    unpackU7Int: unpack4,
    packI7Int: pack4,
    unpackI7Int: unpack4,
    packU8Short: pack2,
    unpackU8Short: unpack2,
    packI8Short: pack2,
    unpackI8Short: unpack2,
    packU8Int: pack4,
    unpackU8Int: unpack4,
    packI8Int: pack4,
    unpackI8Int: unpack4,
    packU9: pack3,
    unpackU9: unpack3,
    packI9: pack3,
    unpackI9: unpack3,
    packU10: pack3,
    unpackU10: unpack3,
    packI10: pack3,
    unpackI10: unpack3,
    packU11: pack2,
    unpackU11: unpack2,
    packI11: pack2,
    unpackI11: unpack2,
    packU12: pack2,
    unpackU12: unpack2,
    packI12: pack2,
    unpackI12: unpack2,
    packU13: pack2,
    unpackU13: unpack2,
    packI13: pack2,
    unpackI13: unpack2,
    packU14: pack2,
    unpackU14: unpack2,
    packI14: pack2,
    unpackI14: unpack2,
    packU15: pack2,
    unpackU15: unpack2,
    packI15: pack2,
    unpackI15: unpack2,
    packU16: pack2,
    unpackU16: unpack2,
    packI16: pack2,
    unpackI16: unpack2,
}

function ByteUtils.unpackBoolean(x: number, depth: number?): ...boolean
    depth = if depth then depth else 32 - bit32.countlz(x)
    local values: {boolean} = {}

    for i = 1, depth do
        table.insert(values, bit32.btest(x, bit32.lshift(1, i - 1)))
    end

    return unpack(values, 1, #values)
end

function ByteUtils.packBoolean(...: boolean): number
    local values = {...}
    local x = 0

    for i,v in values do
        x = bit32.bor(x, bit32.lshift(if v then 1 else 0, i - 1))
    end

    return x
end

function ByteUtils.checkFlags(x: number, ...: number): ...boolean
    local values = {...}
    local flags = {}

    for i,v in values do
        flags[i] = bit32.btest(x, v)
    end

    return unpack(flags, 1, #flags)
end

function ByteUtils.hasFlags(x: number, ...: number): boolean
    local flags = {...}

    for _,v in flags do
        if not bit32.btest(x, v) then
            return false
        end
    end

    return true
end

function signNumber(x: number, bits: number): number
    x = math.clamp(x, MIN["I"..bits], MAX["I"..bits])
    local sign = if x < 0 then 1 else 0
    if x < 0 then x = -x end
    return bit32.bor(x, bit32.lshift(sign, bits - 1))
end

function extractSigned(x: number, from: number, width: number): number
    local num = bit32.extract(x, from, width - 1)
    local sign = bit32.extract(x, from + width - 1, 1)
    if sign == 1 then
        num = -num
    end
    return num
end

function unpackU(bits: number, containerBits: number): (number) -> ...number
    local count = math.floor(containerBits / bits)
    return function(x: number): ...number
        local values = {}
        for i = count, 1, -1 do
            table.insert(values, bit32.extract(x, (bits * (i - 1)) - 1, bits))
        end
        return unpack(values, 1, #values)
    end
end

function unpackI(bits: number, containerBits: number): (number) -> ...number
    local count = math.floor(containerBits / bits)
    return function(x: number): ...number
        local values = {}
        for i = count, 1, -1 do
            table.insert(values, extractSigned(x, bits * (i - 1), bits))
        end
        return unpack(values, 1, #values)
    end
end

function packU(bits: number, containerBits: number): (...number) -> number
    local count = math.floor(containerBits / bits)
    return function(...: number): number
        local values = {...}
        local value = 0
        for i = count, 1, -1 do
            value = bit32.bor(bit32.lshift(values[#values - (i - 1)], (bits * (i - 1)) - 1), value)
        end
        return value
    end
end

function packI(bits: number, containerBits: number): (...number) -> number
    local count = math.floor(containerBits / bits)
    return function(...: number): number
        local values = {...}
        local value = 0
        for i = 1, #values do
            values[i] = signNumber(values[i], bits)
        end
        for i = count, 1, -1 do
            value = bit32.bor(bit32.lshift(values[#values - (i - 1)], bits * (i - 1)), value)
        end
        return value
    end
end

for i,v in INT_NAMES do
    ByteUtils["packU1"..v] = packU(1, i * 4)
    ByteUtils["unpackU1"..v] = unpackU(1, i * 4)
end

for i = 2, 16 do
    local others = false
    for a,v in INT_NAMES do
        local bits = 2 ^ (a + 1)
        local count = math.floor(bits / i)
        if count > 1 then
            if a ~= 4 then
                others = true
            end
            local name = if others then v else ""
            ByteUtils["packU"..i..name] = packU(i, bits)
            ByteUtils["unpackU"..i..name] = packU(i, bits)
            ByteUtils["packI"..i..name] = packI(i, bits)
            ByteUtils["unpackI"..i..name] = unpackI(i, bits)
        end
    end
end

return ByteUtils :: ByteUtils