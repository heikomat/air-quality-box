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
    temperatureRaw = nil,
    temperatureText = nil,
    pressureRaw = nil,
    pressureText = nil,
    humidityRaw = nil,
    humidityText = nil,
    tvocRaw = nil,
    tvocText = nil,
  },
  debug = {
    sgp30Baseline = {
      eCO2 = nil,
      TVOC = nil,
    },
  },
}

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

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
  state.sensors.temperatureRaw = temperature
  state.sensors.pressureRaw = pressure
  state.sensors.humidityRaw = humidity

  state.sensors.temperatureText = temperature/ 100 .. 'C'
  state.sensors.pressureText = round(pressure / 1000, 0) .. 'hpa'
  state.sensors.humidityText = round(humidity / 1000, 1) .. '%'
end)

sgp30 = SGP30:new(nil, nil, nil, function(eCO2, TVOC, eCO2Baseline, TVOCBaseline)
  state.sensors.tvocRaw = TVOC
  state.sensors.tvocText = TVOC .. 'ppb'
  state.debug.sgp30Baseline.eCO2 = eCO2Baseline
  state.debug.sgp30Baseline.TVOC = TVOCBaseline
end);

tmr.create():alarm(350 , tmr.ALARM_AUTO, function(timer)
  updateDisplay(state)
end)

tmr.create():alarm(350 , tmr.ALARM_AUTO, function(timer)
  if state.mqtt.connected then
    local jsonData = sjson.encoder(state):read()
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
