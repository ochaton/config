local log = require 'log'
local json = require 'json'
local yaml = require 'yaml'
local fiber = require 'fiber'
json.cfg{ encode_invalid_as_nil = true }
yaml.cfg{ encode_invalid_as_nil = true }

local under_tarantoolctl = fiber.name() == 'tarantoolctl'
if rawget(_G,'TARANTOOLCTL') == nil then
	local from_env = os.getenv('TARANTOOLCTL')
	if from_env ~= nil then
		TARANTOOLCTL = from_env
	else
		TARANTOOLCTL = fiber.name() == 'tarantoolctl'
	end
end
log.info("TARANTOOL = %s; TARANTOOLCTL = %s", _TARANTOOL, TARANTOOLCTL)

local function lookaround(fun)
	local vars = {}
	local i = 1
	while true do
		local n,v = debug.getupvalue(fun,i)
		if not n then break end
		vars[n] = v
		i = i + 1
	end
	i = 1
	
	return vars, i - 1
end

function peek_vars()
	local peek = {
		dynamic_cfg   = true;
		upgrade_cfg   = true;
		translate_cfg = true;
		-- log           = true;
	}
	
	local steps = {}
	local peekf = box.cfg
	local allow_lock_unwrap = true
	local allow_ctl_unwrap = true
	while true do
		local prevf = peekf
		local mt = debug.getmetatable(peekf)
		if type(peekf) == 'function' then
			-- pass
			table.insert(steps,"func")
		elseif mt and mt.__call then
			peekf = mt.__call
			table.insert(steps,"mt_call")
		else
			error(string.format("Neither function nor callable argument %s after steps: %s", peekf, table.concat(steps, ", ")))
		end
		
		local vars, count = lookaround(peekf)
		if allow_ctl_unwrap and vars.orig_cfg then
			-- It's a wrap of tarantoolctl, unwrap and repeat
			peekf = vars.orig_cfg
			allow_ctl_unwrap = false
			table.insert(steps,"ctl-orig")
		elseif not vars.dynamic_cfg and vars.lock and vars.f and type(vars.f) == 'function' then
			peekf = vars.f
			table.insert(steps,"lock-unwrap")
		elseif not vars.dynamic_cfg and vars.old_call and type(vars.old_call) == 'function' then
			peekf = vars.old_call
			table.insert(steps,"ctl-oldcall")
		elseif vars.dynamic_cfg then
			log.info("Found config by steps: %s", table.concat(steps, ", "))
			for k,v in pairs(peek) do
				if vars[k] ~= nil then
					peek[k] = vars[k]
				else
					peek[k] = nil
				end
			end
			break
		else
			for k,v in pairs(vars) do log.info("var %s=%s",k,v) end
			error(string.format("Bad vars for %s after steps: %s", peekf, table.concat(steps, ", ")))
		end
		if prevf == peekf then
			error(string.format("Recursion for %s after steps: %s", peekf, table.concat(steps, ", ")))
		end
	end
	return peek
end

do
	local peek = peek_vars()
	assert(type(peek.dynamic_cfg)=='table',"have dynamic_cfg")
	log.info("1st run: %s",json.encode(peek))
end

box.cfg{ log_level = 2 }

do
	print("Do run 2")
	local peek = peek_vars()
	print("2nd run: ",json.encode(peek))
	log.error("2nd run: %s",json.encode(peek))
	assert(type(peek.dynamic_cfg)=='table',"have dynamic_cfg")
end

if not TARANTOOLCTL then
	os.exit()
end
