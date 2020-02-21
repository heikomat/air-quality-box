node.setcpufreq(node.CPU160MHZ)

local pinSDA = 3
local pinSCL = 6
i2c.setup(0, pinSDA, pinSCL, i2c.SLOW)
bme280.setup()

state = {
  wifi = {
    connecting = false,
    connected = false,
    rssi = 0,
    signalStrength = 0,
  },
  mqtt = {
    connecting = false,
    connected = false,
  },
  sensors = {
    temperature = nil,
    pressure = nil,
    humidity = nil,
    tvoc = nil,
  }
}

dofile('wifi.lua')
dofile('mqtt.lua')
dofile('sgp30.lua')
dofile('display.lua')

state.wifi.connecting = initWifi(function()
  state.wifi.connected = true
  state.wifi.connecting = false

  state.mqtt.connecting = connectMqtt(function()
    state.mqtt.connected = true
    state.mqtt.connecting = false
  end)
end)

tmr.create():alarm(350 , tmr.ALARM_AUTO, function(timer)
  temperature, pressure, humidity = bme280.read()
  state.sensors.temperature = temperature
  state.sensors.pressure = pressure
  state.sensors.humidity = humidity
end)

sgp30 = SGP30:new(nil, nil, nil, function(eCO2, TVOC)
  state.sensors.tvoc = TVOC
end);

tmr.create():alarm(350 , tmr.ALARM_AUTO, function(timer)
  updateDisplay(state)
end)

tmr.create():alarm(350 , tmr.ALARM_AUTO, function(timer)
  if state.mqtt.connected then
    local jsonData = sjson.encoder(state.sensors):read()
    publishMqtt("air_quality", jsonData)
  end
end)

tmr.create():alarm(1000 , tmr.ALARM_AUTO, function(timer)
  if not state.wifi.connected then
    return
  end

  local maxSignal = -25
  local minSignal = -80
  state.wifi.rssi = wifi.sta.getrssi()

  if state.wifi.rssi >= maxSignal then
    state.wifi.signalStrength = 100
  elseif state.wifi.rssi <= minSignal then
    state.wifi.signalStrength = 0
  else
    state.wifi.signalStrength = math.floor(((math.abs(state.wifi.rssi) - math.abs(minSignal)) / (math.abs(maxSignal) - math.abs(minSignal)))*100)
  end
end)
