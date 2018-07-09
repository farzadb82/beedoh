-- file : init.lua
config = require("config")
setup = require("setup")
app = require("application")

local btn_cntr = 0
local btn_hold = 0

local function init_bootstrap_pins()
  gpio.mode(config.GPIO["MOTOR"], gpio.INPUT)
  gpio.write(config.GPIO["MOTOR"], gpio.HIGH)

  gpio.mode(config.GPIO["RST"], gpio.INPUT, gpio.PULLUP)
end

local function init_app_pins()
  gpio.mode(config.GPIO["MOTOR"], gpio.INPUT)
  gpio.write(config.GPIO["MOTOR"], gpio.HIGH)

  gpio.mode(config.GPIO["LED"], gpio.OUTPUT)
  gpio.write(config.GPIO["LED"], gpio.LOW)
end


local function do_bootstrap()
  init_bootstrap_pins()

  tmr.alarm(1, 1000, tmr.ALARM_AUTO, function()
    btn_cntr = btn_cntr + 1
    --print("GPIO[RST]: "..tostring(gpio.read(config.GPIO["RST"])))
    if (gpio.read(config.GPIO["RST"]) == 0) then
      btn_hold = btn_hold + 1
    end

    print("Waiting "..tostring(btn_cntr)..", btn_hold:"..tostring(btn_hold))
    if (btn_cntr >= 5) then
      tmr.unregister(1)
      init_app_pins()
      if (btn_hold >= 5) then
        print("Resetting wifi state")
        wifi.sta.clearconfig()
      end
      print("Starting App ...")
      setup.start()
    end
  end)
end

do_bootstrap()
