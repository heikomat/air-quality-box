wifiIsConnected = false
mqttClient = nil
mqttIsConnected = false

node.setcpufreq(node.CPU160MHZ)

function initWifi(callback)
  local ssid, password
  if file.open('wifi_credentials.txt') ~= nil then
      ssid = string.sub(file.readline(), 1, -2) -- to remove newline character
      password = string.sub(file.readline(), 1, -2) -- to remove newline character
      file.close()
  else
      return false, nil
  end

  print("connecting to wifi")
  wifi.setmode(wifi.STATION)
  wifi.sta.config({ssid=ssid, pwd=password})
  wifi.sta.autoconnect(1)

  -- wait for the wifi connection to be established
  -- this is basically a setTimeout
  tmr.create():alarm(500 , tmr.ALARM_AUTO, function(timer)
    if wifi.sta.getip() ~= nil then
      wifiIsConnected = true
      timer:stop()
      callback()
    end
  end)
end

function connectMqtt(callback)
  local server, clientId, username, password
  if file.open('mqtt_credentials.txt') ~= nil then
    server = string.sub(file.readline(), 1, -2) -- to remove newline character
    clientId = string.sub(file.readline(), 1, -2) -- to remove newline character
    username = string.sub(file.readline(), 1, -2) -- to remove newline character
    password = string.sub(file.readline(), 1, -2) -- to remove newline character
    file.close()
  else
      return false, nil
  end

  print("connecting to mqtt server")
  mqttClient=mqtt.Client(clientId, 60, username, password)
  mqttClient:connect(server, function(mqttClient)
    print("connection to mqtt server established")
    mqttIsConnected = true
    callback(mqttClient);
  end, function(mqttClient, reason)
    print("mqtt connection failed")
  end)
end


gpio.mode(0, gpio.OUTPUT)
gpio.write(0, gpio.LOW)
initWifi(function()
  connectMqtt(function()
  end)
end)


local pinSDA = 3
local pinSCL = 6
i2c.setup(0, pinSDA, pinSCL, i2c.SLOW)
bme280.setup()

sla = 0x3c
display = u8g2.ssd1306_i2c_128x64_noname(0, sla)
display:setFont(u8g2.font_6x10_tf)
display:drawStr(0, 10, "temp    :")
display:drawStr(0, 20, "pressure:")
display:drawStr(0, 30, "humidity:")
display:drawStr(0, 40, "TVOC    :")
display:updateDisplayArea(0, 0, 16, 8)

temperature = nil
pressure = nil
humidity = nil
bmeReadingWasSuccessful = false
tmr.create():alarm(350 , tmr.ALARM_AUTO, function(timer)
  temperature, pressure, humidity = bme280.read()
  bmeReadingWasSuccessful = temperature ~= nil and pressure ~= nil and humidity ~= nil
end)


dofile("sgp30.lua")
TVOC = nil
sgp30 = SGP30:new(nil, nil, nil, function(eCO2, TVOCReadout)
  TVOC = TVOCReadout
end);

wifiDots = 0
lastRenderedPressure = 0
lastWifiStatus = ""

tmr.create():alarm(350 , tmr.ALARM_AUTO, function(timer)
  display:clearBuffer()
  if bmeReadingWasSuccessful then
    display:drawStr(56, 10, temperature / 100 .. "C")
    display:drawStr(56, 20, pressure / 1000 .. "hpa")
    display:drawStr(56, 30, humidity / 1000 .. "%")
    display:updateDisplayArea(7, 0, 9, 4)
  end

  if TVOC ~= nil then
    display:drawStr(56, 40, TVOC .. "ppb") 
    display:updateDisplayArea(7, 4, 9, 1)
  end

  local wifiStatus = "wifi is connected :)"
  if not wifiIsConnected then
    wifiStatus = "wifi is connecting"
    for i=1,wifiDots do
      wifiStatus = wifiStatus .. "."
    end
    wifiDots = wifiDots + 1
    if wifiDots == 4 then
      wifiDots = 0
    end
  end

  if wifiStatus ~= lastWifiStatus then
    display:drawStr(0, 50, wifiStatus)
    display:updateDisplayArea(0, 5, 16, 2)
    lastWifiStatus = wifiStatus
  end
end)

tmr.create():alarm(350 , tmr.ALARM_AUTO, function(timer)
  if mqttIsConnected and bmeReadingWasSuccessful then
    mqttClient:publish("air_quality", "{\"temperature\":\"" .. temperature / 100 .. " °C\",\n\"pressure\":\"" .. pressure / 1000 .. " hpa\",\n\"humidity\":\"" .. humidity / 1000 .. " %\"}", 0, 0)
  end
end)
