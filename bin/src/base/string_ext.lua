--[[====================================
=
=         extending lua string API
=
========================================]]
string._htmlspecialchars_set = {}
string._htmlspecialchars_set["&"] = "&amp;"
string._htmlspecialchars_set["\""] = "&quot;"
string._htmlspecialchars_set["'"] = "&#039;"
string._htmlspecialchars_set["<"] = "&lt;"
string._htmlspecialchars_set[">"] = "&gt;"

function string.htmlspecialchars(input)
    for k, v in pairs(string._htmlspecialchars_set) do
        input = string.gsub(input, k, v)
    end
    return input
end

function string.restorehtmlspecialchars(input)
    for k, v in pairs(string._htmlspecialchars_set) do
        input = string.gsub(input, v, k)
    end
    return input
end

function string.nl2br(input)
    return string.gsub(input, "\n", "<br />")
end

function string.text2html(input)
    input = string.gsub(input, "\t", "    ")
    input = string.htmlspecialchars(input)
    input = string.gsub(input, " ", "&nbsp;")
    input = string.nl2br(input)
    return input
end

function string.split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    -- for each divider found
    for st,sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

function string.ltrim(input)
    return string.gsub(input, "^[ \t\n\r]+", "")
end

function string.rtrim(input)
    return string.gsub(input, "[ \t\n\r]+$", "")
end

function string.trim(input)
    input = string.gsub(input, "^[ \t\n\r]+", "")
    return string.gsub(input, "[ \t\n\r]+$", "")
end

function string.ucfirst(input)
    return string.upper(string.sub(input, 1, 1)) .. string.sub(input, 2)
end

local function urlencodechar(char)
    return "%" .. string.format("%02X", string.byte(char))
end
function string.urlencode(input)
    -- convert line endings
    input = string.gsub(tostring(input), "\n", "\r\n")
    -- escape all characters but alphanumeric, '.' and '-'
    input = string.gsub(input, "([^%w%.%- ])", urlencodechar)
    -- convert spaces to "+" symbols
    return string.gsub(input, " ", "+")
end

function string.urldecode(input)
    input = string.gsub(input, "+", " ")
    input = string.gsub(input, "%%(%x%x)", function(h)
        return string.char(tonumber('0x'..h))
    end)
    input = string.gsub(input, "\r\n", "\n")
    return input
end


local _utf8Num = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
function string.utf8len(input)
    local len  = string.len(input)
    local left = len
    local cnt  = 0
    while left ~= 0 do
        local tmp = string.byte(input, -left)
        local i = #_utf8Num
        while true do
            if tmp >= _utf8Num[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        cnt = cnt + 1
    end
    return cnt
end

function string.utf8_chsize(char)
    local i = #_utf8Num
    while true do
        if char >= _utf8Num[i] then
            return i
        end
        i = i - 1
    end
end

function string.utf8_sub(str, startChar, numChars)
    local startIndex = 1
    while startChar > 1 do
        local char = string.byte(str, startIndex)
        startIndex = startIndex + string.utf8_chsize(char)
        startChar = startChar - 1
    end

    local currentIndex = startIndex
    local strLen = #str
    while numChars > 0 and currentIndex <= strLen do
        local char = string.byte(str, currentIndex)
        currentIndex = currentIndex + string.utf8_chsize(char)
        numChars = numChars - 1
    end
    
    return str:sub(startIndex, currentIndex - 1)
end

function string.utf82unicode(utf8str)
    local len = #utf8str
    local bytes = {}
    for i = 1, len do
        table.insert(bytes, string.byte(string.sub(utf8str, i, i)))
    end

    -- utf8 有效性
    assert(len == string.utf8_chsize(bytes[1]))

    local unicode = 0
    local mul = 1
    for i = len, 1, -1 do
        if i == 1 then
            unicode = unicode + bit.band(bytes[1], bit.bnot(_utf8Num[len])) * mul
        else
            -- 0x3f
            -- 0011 1111
            unicode = unicode + bit.band(bytes[i], 0x3f) * mul
            mul = mul * 2^6
        end
    end

    return unicode
end


local unicodeScope = {0x007f, 0x07ff, 0xffff, 0x1fffff, 0x3ffffff, 0x7fffffff}
local unicode_left_code = {0x00, 0x1f, 0x0f, 0x07, 0x03, 0x01}
function string.unicode_chsize(unicode)
    for index = 1, #unicodeScope do
        if unicode < unicodeScope[index] then
            return index
        end
    end
    return #unicodeScope
end

function string.unicode2utf8(unicode)  

    local char_array = {} 
    local chSize = string.unicode_chsize(unicode)
    local rshift_num = 0
    for index = chSize, 1, -1 do
        if index == 1 then
            if chSize == 1 then
                table.insert(char_array, string.char(bit.band(unicode,0x7f)))
            else
                table.insert(char_array, string.char(bit.bor(0x80,bit.band(unicode,0x3f))))
            end
        else
            rshift_num = (index - 1) * 6
            if index == chSize then
                table.insert(char_array, string.char(bit.bor(_utf8Num[index],bit.band(bit.rshift(unicode,rshift_num),unicode_left_code[index]))))
            else
                table.insert(char_array, string.char(bit.bor(0x80,bit.band(bit.rshift(unicode,rshift_num),0x3f))))
            end
        end
    end
    return table.concat(char_array)  

end  

function string.formatnumberthousands(num)
    local formatted = tostring(checknumber(num))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

function string.utf8_cut_string(oldString, length ,extString)
        extString = extString  or ".."
        if string.utf8len(oldString) > length then 
            oldString = string.utf8_sub(oldString, 1, length)
            oldString = oldString .. extString
        end
        return oldString
end

-- 判断单个字符是否是emoji
function string.is_emoji_character(u8str)
    local codePoint = string.utf82unicode(u8str)
    local ret = (codePoint >= 0x1F601 and codePoint <= 0X1F64F)
            or (codePoint >= 0x1F300 and codePoint <= 0X1F64F)
            or (codePoint >= 0x1F680 and codePoint <= 0X1F6FF)
            or (codePoint >= 0x2600 and codePoint <= 0X26FF)
            or (codePoint >= 0x2700 and codePoint <= 0X27BF)
            or (codePoint >= 0x1F100 and codePoint <= 0X1F1FF)
            or (codePoint >= 0x2B00 and codePoint <= 0X2BFF)
            or (codePoint >= 0x2900 and codePoint <= 0X297F)
            or (codePoint >= 0x2300 and codePoint <= 0X23FF)
            or (codePoint >= 0x2B00 and codePoint <= 0X2BFF)
            or (codePoint >= 0x2702 and codePoint <= 0x27B0)
            or (codePoint >= 0x1F680 and codePoint <= 0x1F6C0)
            or (codePoint >= 0X1F600 and codePoint <= 0x1F636)
            or (codePoint >= 0x1F681 and codePoint <= 0x1F6C5)
            or (codePoint >= 0x1F30D and codePoint <= 0x1F567)
    return ret
end

-- 判断单个字符是中文
function string.u32_is_chinese(u8str)
    local ch = string.utf82unicode(u8str) 
    local is_chinese = (ch >= 0X4E00 and ch <= 0X9FA5) 
                        or ch == 0x3002 -- 标点符号
                        or ch == 0XFF1F
                        or ch == 0XFF01
                        or ch == 0xFF0C
                        or ch == 0X3001
                        or ch == 0XFF1B
                        or ch == 0XFF1A
                        or ch == 0X300C
                        or ch == 0X300D
                        or ch == 0x300E
                        or ch == 0x2018
                        or ch == 0x300F
                        or ch == 0x2019
                        or ch == 0x201C
                        or ch == 0x201D
                        or ch == 0xFF08
                        or ch == 0xFF09
                        or ch == 0x3014
                        or ch == 0x3015
                        or ch == 0x3010
                        or ch == 0x3011
                        or ch == 0x2014
                        or ch == 0x2026
                        or ch == 0x2013
                        or ch == 0xFF0E
                        or ch == 0x300A
                        or ch == 0x300B
                        or ch == 0x3008
                        or ch == 0x3009
    return is_chinese
end

--中文名字和间隔符
function string.u32_is_chinese_name(u8str)
    local ch = string.utf82unicode(u8str) 
    local is_chinese = (ch >= 0X4E00 and ch <= 0X9FA5) or ch == 0xB7
    return is_chinese
end

-- 判断单个字符是阿拉伯语
function string.u32_is_arabic(u8str)
    local ch = string.utf82unicode(u8str) 
    return (ch >= 0X0600 and ch <= 0X06FF) or (ch >= 0XFB50 and ch <= 0XFDFF) or (ch >= 0XFE70 and ch <= 0XFEFF)
end

-- 判断ascii 是否是可以显示字符
function string.u32_is_display_char(u8str)
    local ch = string.byte(u8str)
    return ch < 127 and ch >= string.byte(' ') and ch ~= string.byte('#') and ch ~= string.byte('&')
end

--屏蔽4字节长的utf8字符
function string.filter_four_utf_char(str)
    local char_array = {}
    local startIndex = 1
    local currentIndex = 1
    for index = 1, string.utf8len(str) do
        local char = string.byte(str, startIndex)
        local char_size = string.utf8_chsize(char)
        currentIndex = startIndex + char_size
        local compelete_char = str:sub(startIndex, currentIndex - 1)
        if char_size ~= 4 and not string.is_emoji_character(compelete_char) then
            char_array[#char_array + 1] = str:sub(startIndex, currentIndex - 1)
        end
        startIndex = currentIndex
    end
    return table.concat(char_array)
end

--尝试替换四字节为emoj表情
-- utf8字符直接转成#C[emoj]1f642#n
function string.replace_four_utf_char_emoj(str)
    local char_array = {}
    local startIndex = 1
    local currentIndex = 1
    str = string.gsub(str, '#', '##')
    for index = 1, string.utf8len(str) do
        local char = string.byte(str, startIndex)
        local char_size = string.utf8_chsize(char)
        currentIndex = startIndex + char_size
        if char_size ~= 4 then
            local compelete_char = str:sub(startIndex, currentIndex - 1)
            if not string.is_emoji_character(compelete_char) then
                char_array[#char_array + 1] = compelete_char
            end
        else
            local unicode_value = string.utf82unicode(str:sub(startIndex, currentIndex - 1))
            local hex_unicode_value = string.format("%02x", unicode_value)
            if utils_is_exist_emoj(hex_unicode_value) then
                char_array[#char_array + 1] = string.format('#C[emoj]%s#n', hex_unicode_value)
            end
        end
        startIndex = currentIndex
    end
    return table.concat(char_array)
end 


--  [emoj/1f642]===>#C[emoj]1f642#n
function string.change_input_to_rich_label_emoj(text)
    local ret = text
    ret = string.gsub(ret, '#', '##')
    for word, number in string.gmatch (ret, '(%[emoj/([%d|%l|%u]+)%])') do
        number = string.lower(number)
        if utils_is_exist_emoj(number) then
            local new_word = string.format('#C[emoj]%s#n', number)
            local format_word = string.format('%%[emoj/%s%%]', number)
            ret = string.gsub(ret, format_word, new_word)
        end
    end
    return ret
end

--  #C[emoj]1f642#n ===> [emoj/1f642]
function string.change_rich_label_emoj_to_input(text)
    local ret = text
    for word, number in string.gmatch(ret,'(#C%[emoj%]([%d|%l|%u]+)#n)') do
        number = string.lower(number)
        local new_word = string.format('[emoj/%s]', number)
        local format_word = string.format('#C%%[emoj%%]%s#n', number)
        ret = string.gsub(ret, format_word, new_word)
    end
    ret = string.gsub(ret, '##', '#')
    return ret
end

--  #C[emoj]1f642#n ===> utf8字符
function string.change_rich_label_emoj_to_utf8(text)
    local ret = text
    for word, number in string.gmatch(ret, '(#C%[emoj%]([%d|%l|%u]+)#n)') do
        number = string.lower(number)
        local unicode_value = tonumber('0x'..number)
        local new_word = string.unicode2utf8(unicode_value)
        local format_word = string.format('#C%%[emoj%%]%s#n', number)
        ret = string.gsub(ret, format_word, new_word)
    end
    ret = string.gsub(ret, '##', '#')
    return ret
end

--包含#C[emoj]1f642#n的长度
function string.emojlen(text)
    local ret = string.utf8len(text)
    for word, number in string.gmatch(text,'(#C%[emoj%]([%d|%l|%u]+)#n)') do
        local word_len = string.utf8len(word)
        ret = ret - word_len + 1
    end
    return ret
end

local phone_num_match_pattern = {'13[0-9]', '14[579]', '15[0-3, 5-9]', '17[0, 1, 3, 5-8]', '18[0-9]', '166', '198', '199'}
function string.isMatchCellPhoneNumber(str)
    if #str ~= 11 then
        return false
    end
    local firstLen = 3
    local first = string.sub(str, 1, firstLen)
    local isFirstMatch = false
    for _, pattern in ipairs(phone_num_match_pattern) do
        if string.match(first, pattern) then
            isFirstMatch = true
            break
        end
    end
    if not isFirstMatch then
        return false
    end
    local secondStr = string.sub(str, firstLen + 1, 11)
    if not string.match(secondStr, '^[0-9]+$') then
        return false
    end
    return true
end

local function _isMatch15PersonNumber(str)
    --地址
    local address = string.sub(str, 1, 6)
    local isAddressMatch = string.match(address, '^[1-9][0-9]+$')
    if not isAddressMatch then
        return false
    end
    local year = string.sub(str, 7, 8)
    local isYearMatch = string.match(year,'^[0-9]+$')
    if not isYearMatch then
        return false
    end
    local month = tonumber(string.sub(str, 9, 10))
    if not month or month <= 0 or month > 12 then
        return false
    end
    local day = tonumber(string.sub(str, 11, 12))
    if not day or day <= 0 or day > 31 then
        return false
    end
    local code = string.sub(str, 13, 15)
    return string.match(code, '^[0-9]+[0-9]$')
end

local validCodeWeight = {7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2}
local validCodeModel = { '1','0','X','9','8','7','6','5','4','3','2'}
local function _isMatch18PersonNumber(str)
    --地址
    local address = string.sub(str, 1, 6)
    local isAddressMatch = string.match(address, '^[1-9][0-9]+$')
    if not isAddressMatch then
        return false
    end
    local year = string.sub(str, 7, 10)
    local isYearMatch = string.match(year,'^[18, 19, 20][0-9]+$')
    if not isYearMatch then
        return false
    end
    local month = tonumber(string.sub(str, 11, 12))
    if not month or month <= 0 or month > 12 then
        return false
    end
    local day = tonumber(string.sub(str, 13, 14))
    if not day or day <= 0 or day > 31 then
        return false
    end
    local code = string.sub(str, 15, 18)
    local isCodeMatch = string.match(code, '^[0-9]+[0-9xX]$')
    if not isCodeMatch then
        return false
    end

    local sum_num = 0
    for index = 1, 17 do
        local char = string.sub(str, index, index)
        local char_num = tonumber(char)
        sum_num = sum_num + char_num * validCodeWeight[index]
    end
    local valid_index = sum_num % (#validCodeModel)
    local code18 = string.sub(str, 18, 18)
    return code18 == validCodeModel[valid_index + 1]
end

function string.isMatchPersonIDNumber(str)
    local len = #str
    if len ~= 15 and len ~= 18 then
        return false
    end
    if len == 15 then
        return _isMatch15PersonNumber(str)
    end
    return _isMatch18PersonNumber(str)
end

-- string.match_ex = luaext_string_match
-- string.search_ex = luaext_string_search
-- string.gmatch_ex = luaext_string_gmatch
-- string.gsub_ex = luaext_string_gsub
