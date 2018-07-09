-- file: setup.lua
local module = {}

local alarm_tmr = 3


local function flash_led(flash_int)
  print("Starting blink timer ...")
  if not tmr.alarm(alarm_tmr, flash_int, tmr.ALARM_AUTO,
    function()
      pin = config.GPIO["LED"]
      gpio.write(pin, gpio.HIGH - gpio.read(pin))
    end)
  then
    print("Error creating alarm!")
  end
end

local function stop_led()
  pin = config.GPIO["LED"]
  gpio.write(pin, gpio.LOW)
end

local function end_user_setup()
  --wifi.setmode(wifi.STATIONAP, true)
  --wifi.setphymode(wifi.PHYMODE_N)
  --wifi.sta.clearconfig()
  --wifi.ap.config({ssid="beedoh", auth=wifi.OPEN, hidden=false})
  --wifi.sta.config({auto=true, save=true})

  --print "Wifi AP IP"
  --print(wifi.ap.getip())
  --print "Wifi STA IP"
  --print(wifi.sta.getip())

  print "Starting End User Setup"
  --enduser_setup.manual(true)
  enduser_setup.start(
    function()
      tmr.unregister(alarm_tmr)
      flash_led(250)
      print("Connected to wifi as:" .. wifi.sta.getip())
      wifi.setmode(wifi.STATION, true)
      -- enduser_setup.stop()
      print("Waiting 15s for EUS teardown before starting app")
      tmr.alarm(1, 15000, tmr.ALARM_SINGLE, function()
        tmr.unregister(alarm_tmr)
        stop_led()
        print("Calling app.start()")
        app.start()
      end)
    end,
    function(err, str)
      print("enduser_setup: Err #" .. err .. ": " .. str)
      tmr.unregister(alarm_tmr)
    end,
    print
  );
end

function module.start()
  print("Setup - motor setup")
  -- Setup the motor, default off
  gpio.mode(config.GPIO["MOTOR"], gpio.INPUT)
  gpio.write(config.GPIO["MOTOR"], gpio.HIGH)

  print("Setup - led setup")
  -- Setup the light, default off
  gpio.mode(config.GPIO["LED"], gpio.OUTPUT)
  gpio.write(config.GPIO["LED"], gpio.LOW)

  -- Flash LED to indicate we are setting up
  print("Setup - flash_led")
  flash_led(750)

  -- End User Setup
  print("Setup - EUS")
  end_user_setup()

  -- print("Configuring Wifi ...")
  -- wifi.setmode(wifi.STATION);
  -- wifi.sta.getap(wifi_start)
end

return module
