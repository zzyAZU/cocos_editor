--[[====================================
=
=             class
=
========================================]]
-- @author:
--     Carl Zhong
-- @desc:
--     lua 面向对象解决方案, 类机制实现
--     类实现不会用到 metatable



--class id generator
local s_nClassID = 0
local function _genClassID()
    s_nClassID = s_nClassID + 1
    return s_nClassID
end

--metatable for class
local s_clsmt = {
    __newindex = function(t, key, value)
        assert(type(value) == 'function')
        rawset(t, key, value)
    end,
    __index = function(t, k) return nil end,
    __add = function(t1, t2) assert(false) end,
    __sub = function(t1, t2) assert(false) end,
    __mul = function(t1, t2) assert(false) end,
    __div = function(t1, t2) assert(false) end,
    __mod = function(t1, t2) assert(false) end,
    __pow = function(t1, t2) assert(false) end,
    __lt = function(t1, t2) assert(false) end,
    __le = function(t1, t2) assert(false) end,
    __concat = function(t1, t2) assert(false) end,
    __call = function(t, ...) assert(false) end,
    __unm = function(t) assert(false) end,
    __len = function(t) assert(false) end,
    -- __eq = function(t1, t2) assert(false) end, 使用地址相等
    -- __gc = function(t)end --__gc is for userdata,
}


function isclass(cls)
    return getmetatable(cls) == s_clsmt
end

function isobject(obj)
    local mt = getmetatable(obj)
    return mt and isclass(mt.__index) or false
end

function isinstance(obj, cls)
    return obj:IsInstance(cls)
end

function issubclass(subCls, parentCls)
    assert(isclass(subCls))
    assert(isclass(parentCls))

    while subCls do
        if subCls == parentCls then
            return true
        end

        subCls = subCls.__clsBase
    end
    return false
end

-- function superclass(cls)
--     return cls.__clsBase
-- end

-- function super(cls, obj)
-- end



local _clsInfo = {} --key:clsID, value:{clsName, clsTemplate}

-- @desc:
--     产生一个类模板
-- @param baseClass:
--     基类模板, if baseClass == nil then 返回的类模板无基类
-- @return:
--     返回新建类的模板
function CreateClass(baseClass)
    local definedMoudule = import_get_self_evn(3, 4)
    if definedMoudule == nil then
        error_msg('must call CreateClass in moudule')
    end

    local clsID = _genClassID()

    local subClass
    if baseClass then
        assert(isclass(baseClass))
        subClass = table.copy(baseClass)  --浅拷贝
    else
        subClass = {}
    end

    --read only
    subClass.__clsID = clsID
    subClass.__clsBase = baseClass
    subClass.__definedMoudule = definedMoudule

    --class has metatable
    setmetatable(subClass, s_clsmt)

    _clsInfo[clsID] = subClass

    --default functions:
    if baseClass == nil then
        -- @desc:
        --    class method
        --     return the object of the class, the returned object has no metatable
        function subClass:New(...)
            local ret = {}
            setmetatable(ret, {__index = self}) --obj 函数引用 class
            ret.__objCls = self

            --auto init
            ret:__init__(...)
            return ret
        end

        -- @desc:
        --     Called when obj is constructed
        function subClass:__init__()
            assert(false, 'not implemented')
        end
        
        -- @desc:
        --     check wether obj / cls is a kind of class
        function subClass:IsInstance(class)
            return issubclass(self.__objCls, class)
        end

        function subClass:GetClsID()
            return self.__clsID
        end

        function subClass:Super()
            return self.__clsBase
        end
    end

    return subClass, baseClass
end

function GetClassInfo()
    return _clsInfo
end