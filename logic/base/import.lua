local string = string
local setmetatable = setmetatable
local loadfile = loadfile
local assert = assert
local rawget = rawget
local type = type
local pairs = pairs
local string_format = string.format
local debug_traceback = debug.traceback
--------------

_G.__loadModule__ = _G.__loadModule__ or {}
local __loadModule__ = _G.__loadModule__

_G.__importModule__ = _G.__importModule__ or {}
local __importModule__ = _G.__importModule__

local function doLoadModule(name, pathFile, new)
	setmetatable(new, {__index = _G})
	local func, err = loadfile(pathFile, "bt", new)
	if not func then
		print(string_format("ERROR!!!\n%s\n%s", err, debug_traceback()))
		return func, err
	end
	func()
	__loadModule__[pathFile] = new
	__importModule__[name] = new
	new.__FILE__ = pathFile
	new.__NAME__ = name
	new.__INIT__ = true
	if rawget(new, "__read_only__") then
		new.__read_only__()
	end
	if rawget(new, "__init__") then
		new.__init__()
	end
	return new
end

local function genLoadModuleTable(name)
	local new = {}
	new.__NAME__ = name
	new.__INIT__ = false
	setmetatable(new, {
		__index = function()
			assert(false, string.format("attempt __index not load module name=%s, debug=%s!!", new.__NAME__, debug_traceback()))
		end,
		__newindex = function() 
			assert(false, string.format("attempt __newindex not load module name=%s, debug=%s!!", new.__NAME__, debug_traceback()))
		end,
		__pairs = function() 
			assert(false, string.format("attempt __pairs not load module name=%s, debug=%s!!", new.__NAME__, debug_traceback()))
		end,
	})
	__importModule__[name] = new
	return new
end

local function safeImport(name)
	local old = __importModule__[name]
	if old then
		return old
	end
	local new = genLoadModuleTable(name)
	return new
end

local function checkModule(name, pathFile)
	local mod1 = __importModule__[name]
	local mod2 = __loadModule__[pathFile]
	if mod2 then
		assert(mod2 == mod1, string.format("ErrorImportModuleByDiffName,pathFile=%s,name=%s,oname=%s",pathFile,name,mod2.__NAME__))
	end
	if mod1 then
		local ofile = rawget(mod1, "__FILE__")
		if ofile then
			assert(pathFile == ofile, string.format("ErrorImportModuleByDiffFile,name=%s,pathFile=%s,ofile=%s",name,pathFile,ofile))
		end
	end
end

local function safeLoadModule(name, pathFile)
	checkModule(name, pathFile)
	local old = __loadModule__[pathFile]
	if old then
		return old
	end
	local new = safeImport(name)
	return doLoadModule(name, pathFile, new)
end

function LoadModule(name, pathFile)
	local module, err = safeLoadModule(name, pathFile)
	assert(module, err)
	return module 
end

function Import(name)
	assert(name)
	local module, err = safeImport(name)
	assert(module, err)
	return module 
end

function LocalEnvDoFile(env, fileName)
	local func, err = loadfile(fileName, "bt", env)
	if not func then
		print(string_format("ERROR!!!\n%s\n%s", err, debug.traceback()))
		return
	end
	func()
end

function CheckImportModule()
	for name, mod in pairs(__importModule__) do
		local init = rawget(mod, "__INIT__")
		assert(init, string_format("ImportNoLoadFile,name=%s",name))
	end
end

function ReadOnlyTable(input)
	local ret = {}
	local _read_only = function(tbl)
		if not ret[tbl] then
			local tbl_mt = getmetatable(tbl)
			if not tbl_mt then
				tbl_mt = {}
				setmetatable(tbl, tbl_mt)
			end
			local proxy = tbl_mt.__read_only_proxy
			if not proxy then
				proxy = {}
				setmetatable(proxy, {
					__index = tbl,
					__newindex = function(obj, k, v) 
						assert(false, "Read Only Table!! attempt __newindex")
					end,
					__pairs = function(t) return pairs(tbl) end,
					__read_only_proxy = proxy,
					__len = function() 
						return #tbl
					end,
				})
			end
			ret[tbl] = proxy
			for k, v in pairs(tbl) do
				if type(v) == "table" then
					tbl[k] = ReadOnlyTable(v)
				end
			end
			return ret[tbl]
		end
	end
	return _read_only(input)
end

local function getClassTbl(module)
	local classTbl = {}
	for k, v in pairs(module) do
		if type(v) == "table" and v.__IsClass then
			classTbl[k] = v
		end
	end
	return classTbl
end

local function refreshSubClassFunc(newClass, oldClassFunc, depth)
	assert(depth <= 20)
	for idx, subClass in pairs(newClass.__SubClass) do
		for k, v in pairs(newClass) do
			if type(v) == "function" then
				if not subClass[k] or (subClass[k] == oldClassFunc[k]) then
					subClass[k] = v
				end
			end
		end
		if subClass.__SubClass then
			refreshSubClassFunc(subClass, oldClassFunc, depth + 1)
		end
	end
end

local function updateModule(pathFile)
	local old = __loadModule__[pathFile]
	if not old then
		return false
	end
	local oldClassTbl = getClassTbl(old) 
	local oldModuleData = nil
	if old.saveDataOnUpdate then
		oldModuleData = old.saveDataOnUpdate()
	end
	local func, err = loadfile(pathFile, "bt", old)
	if not func then
		print(string_format("ERROR!!!\n%s\n%s", err, debug.traceback()))
		return false
	end
	func()
	local newClassTbl = getClassTbl(old) 
	for newClassName, newClassIml in pairs(newClassTbl) do
		local oldClassIml = oldClassTbl[newClassName]
		if oldClassIml then
			local oldClassFunc = {}
			newClassTbl[newClassName] = oldClassIml
			for k, v in pairs(oldClassIml) do
				if type(v) == "function" then
					oldClassIml[k] = nil
					oldClassFunc[k] = v
				end
			end
			for k, v in pairs(newClassIml) do
				if type(v) == "function" then
					oldClassIml[k] = v
				end
			end
			if oldClassIml.__SubClass then
				refreshSubClassFunc(oldClassIml, oldClassFunc, 0)
			end
		end
	end
	for k, v in pairs(newClassTbl) do
		old[k] = v
	end
	if old.loadDataOnUpdate and oldModuleData then
		old.loadDataOnUpdate(oldModuleData)
	end
	if rawget(old, "__read_only__") then
		old.__read_only__()
	end
	if rawget(old, "__init__") then
		old.__init__()
	end
	if rawget(old, "afterModuleUpdate") then
		old.afterModuleUpdate()
	end
	return true 
end

function UpdateLuaFile(pathFile)
	local ret = updateModule(pathFile)
	return ret
end
