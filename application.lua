-- file : mqtt.lua
local module = {}

local HTTP_RESPONSES = {
  ["200"] = "OK",
  ["301"] = "Moved Permanently",
  ["302"] = "Found",
  ["400"] = "Bad Request",
  ["401"] = "Unauthorized",
  ["404"] = "Not Found",
  ["500"] = "Internal Server Error",
  ["501"] = "Not Implemented",
  ["503"] = "Service Unavailable",
  ["505"] = "HTTP Version not supported"
}

local main_page = "<html><body>"..
                  "<h1>Beedoh Beedoh BeeDoh</h1>"..
                  "<p>LED <a href=\"?pin=led&state=on\"><button>ON</button></a>&nbsp;<a href=\"?pin=led&state=off\"><button>OFF</button></a></p>"..
                  "<p>MOTOR <a href=\"?pin=motor&state=on\"><button>ON</button></a>&nbsp;<a href=\"?pin=motor&state=off\"><button>OFF</button></a></p>"..
                  "</body></html>\n"

-- Print contents of `tbl`, with indentation.
-- `indent` sets the initial level of indentation.
local function tprint(tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      tprint(v, indent+1)
    elseif type(v) == 'boolean' then
      print(formatting .. tostring(v))      
    else
      print(formatting .. v)
    end
  end
end

local function send_response(sckt, response_code, message)
  local buf = "HTTP/1.1 "..tostring(response_code).." "..HTTP_RESPONSES[tostring(response_code)].."\n"
  buf = buf.."Content-Type: text/html; charset=UTF-8\n"
  buf = buf.."Content-Length: "..tostring(string.len(message)).."\n"
  buf = buf.."\n"..message.."\n"

  sckt:send(buf, function()
    print("Sent message")
    sckt:close()
    print("Socket closed")
  end)
end

local function do_control_led(sckt, params)
  if (params["on"] ~= nil) then
    print ("params[on]: "..tostring(params["on"]))
    if (params["on"] == "1") then
      print("Turning on LED")
      gpio.write(config.GPIO["LED"], gpio.HIGH)
    else
      print("Turning off LED")
      gpio.write(config.GPIO["LED"], gpio.LOW)
      gpio.write(config.GPIO["MOTOR"], gpio.HIGH)
    end
    send_response(sckt, 200, params["message"] or "OK")
  else
    send_response(sckt, 400, "on param not set")
  end
end

local function do_control_motor(sckt, params)
  if (params["on"] ~= nil) then
    print ("params[on]: "..tostring(params["on"]))
    if (params["on"] == "1") then
      print("Turning on MOTOR")
      gpio.write(config.GPIO["MOTOR"], gpio.LOW)
      gpio.write(config.GPIO["LED"], gpio.HIGH)
    else
      print("Turning off MOTOR")
      gpio.write(config.GPIO["MOTOR"], gpio.HIGH)
      gpio.write(config.GPIO["LED"], gpio.LOW)
    end
    send_response(sckt, 200, params["message"] or "OK")
  else
    send_response(sckt, 400, "on param not set")
  end
end

local function sckt_recv(sckt, request)
  -- print(request)
  -- print("----------")

  -- From: https://randomnerdtutorials.com/esp8266-web-server/
  local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
  if (method == nil) then
    _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
  end
  local _GET = {}
  if (vars ~= nil) then
    for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
      _GET[k] = v
    end
  end

  if (_GET["state"] ~= nil) then
    _GET["on"] = tostring(_GET["state"] == "on" and 1 or 0)
    _GET["message"] = main_page
  end

  print("path: "..path)
  -- print("vars:")
  -- tprint(_GET, 2)

  if (path == "/control/led") or (_GET["pin"] == "led") then
    do_control_led(sckt, _GET)
  elseif (path == "/control/motor") or (_GET["pin"] == "motor") then
    do_control_motor(sckt, _GET)
  elseif (path == "/") then
    send_response(sckt, 200, main_page)
  else
    send_response(sckt, 404, "")
  end
end

local function mdns_start()
  mdns.register("beedoh",
                { description="beedoh light", service="http", port=80 })
end

local function http_start()
  svr = net.createServer(net.TCP, 30)
  if svr then
    svr:listen(80, function(sckt)
      sckt:on("receive", sckt_recv)
    end)
  end
end

function module.start()
  print("Starting Application...")
  mdns_start()
  http_start()
end

return module
