
local byte = string.byte
local char = string.char
local bit_xor = bit.bxor
local bit_and = bit.band
local bit_rshift = bit.rshift

hash_str = luaext_hash_str2id
if not is_function(hash_str) then
    function hash_str(s)
        local h, seed = 0, 131
        for i = 1, #s do
            local ch = byte(s, i)
            h = seed * h + ch
            h = bit_and(0xffffffff, h)
        end
        h = bit_and(h, 0x7fffffff)
        return char(bit_and(0xff, bit_rshift(h, 24)), bit_and(0xff, bit_rshift(h, 16)), bit_and(0xff, bit_rshift(h, 8)), bit_and(0xff, h))
    end
end

-- cipher object
XOREncrypt = CreateClass()

function XOREncrypt:__init__(cipherKey)
    self:set_cipher_key(cipherKey)
end

function XOREncrypt:set_cipher_key(cipherKey)
    assert(is_valid_str(cipherKey))

    self._listCipherKey = {}
    for i = 1, #cipherKey do
        table.insert(self._listCipherKey, byte(cipherKey, i))
    end
    self._listCipherKeyLen = #self._listCipherKey
    print('cipherKey md5', utils_get_md5_from_string(cipherKey))
end

function XOREncrypt:xor_cipher(s)
    local ret = {}
    local sLen = #s
    if sLen <= self._listCipherKeyLen then
        for i = 1, sLen do
            table.insert(ret, char(bit_xor(byte(s, i), self._listCipherKey[i])))
        end
    else
        local i = 1
        local idx = 1
        while i <= sLen do
            table.insert(ret, char(bit_xor(byte(s, i), self._listCipherKey[idx])))
            i = i + 1
            idx = idx + 1
            if idx > self._listCipherKeyLen then
                idx = 1
            end
        end
    end

    return table.concat(ret)
end


local cipherKey = [[hello world! this is test encrypt key!]]
local defCipherObj = XOREncrypt:New(cipherKey)

function xor_cipher(s)
    return defCipherObj:xor_cipher(s)
end
