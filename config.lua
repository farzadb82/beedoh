-- file : config.lua
local module = {}

module.GPIO = {}
module.GPIO["LED"] = 4   -- GPIO2
module.GPIO["RST"] = 4   -- GPIO2
module.GPIO["MOTOR"] = 3 -- GPIO0

module.ID = node.chipid()

return module
