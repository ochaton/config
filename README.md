Having conf.lua

```lua
box = {
	work_dir           = '.';
	pid_file           = 'box.pid';
	custom_proc_title  = 'm1';
	background         = false;
	slab_alloc_arena   = 0.1;
	--- Networking. Dynamic ---
		listen = '127.0.0.1:3013',
		readahead           = 65536,
}
console = {
	listen = '127.0.0.1:3016'
}
include 'app.lua'
```

and app.lua:

```lua
app = {
	pool = {
		{ uri = '127.0.0.1:3013', zone = '1' };
		{ uri = '127.0.0.2:3013', zone = '2' };
		{ uri = '127.0.0.3:3013', zone = '3' };
	}
}

```

in init.lua

```lua
local conf = require 'config' ('conf.lua') -- call to conf loads config

local pool = conf.get('app.pool',{})
```

or anywhere in application module

```lua
local conf = require 'config'

local pool = conf.get('app.pool',{})
```

then we could run

```sh
tarantool init.lua
# runs tarantool with conf.lua
```

or

```sh
tarantool -c cf1.lua init.lua
# runs tarantool with cf1.lua
```
