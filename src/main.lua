node.setcpufreq(node.CPU160MHZ)

local pinSDA = 6
local pinSCL = 5
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
    tvocppbRaw = nil,
    tvocppbText = nil,
    tvocmgm3Raw = nil,
    tvocmgm3Text = nil,
  },
  debug = {
    sgp30Baseline = {
      eCO2 = nil,
      TVOC = nil,
      secondsSinceLastSave = nil,
      secondsTilNextSave = nil,
      lastSaveWasSuccessful = nil,
      lastSaveResult = nil,
    },
  },
}

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

initWifi = require 'initWifi'
connectMqtt = require 'connectMqtt'
require 'sgp30'
require 'display'

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
  if temperature ~= nil then
    state.sensors.temperatureRaw = temperature
    state.sensors.temperatureText = temperature / 100 .. 'C'
  end

  if pressure ~= nil then
    state.sensors.pressureRaw = pressure
    state.sensors.pressureText = round(pressure / 1000, 0) .. 'hpa'
  end

  if humidity ~= nil then
    state.sensors.humidityRaw = humidity
    state.sensors.humidityText = round(humidity / 1000, 1) .. '%'
  end
end)

sgp30 = SGP30:new(nil, nil, function(eCO2, TVOCppb, TVOCmgm3, eCO2Baseline, TVOCBaseline, secondsSincaLastBaselineSave, secondsTilNextBaselineSave, lastBaselineSaveWasSuccessful, lastBaselineSaveResult)
  state.sensors.tvocppbRaw = TVOCppb
  state.sensors.tvocppbText = TVOCppb .. 'ppb'

  state.sensors.tvocmgm3Raw = TVOCmgm3
  state.sensors.tvocmgm3Text = TVOCmgm3 .. 'mg/m3'

  state.debug.sgp30Baseline.eCO2 = eCO2Baseline
  state.debug.sgp30Baseline.TVOC = TVOCBaseline
  state.debug.sgp30Baseline.secondsSincaLastSave = secondsSincaLastBaselineSave
  state.debug.sgp30Baseline.secondsTilNextSave = secondsTilNextBaselineSave
  state.debug.sgp30Baseline.lastSaveWasSuccessful = lastBaselineSaveWasSuccessful
  state.debug.sgp30Baseline.lastSaveResult = lastBaselineSaveResult
end, function()
  if state.sensors.temperatureRaw == nil or state.sensors.humidityRaw == nil then
    return nil, nil
  end

  local temperature = state.sensors.temperatureRaw / 100
  local humidity = state.sensors.humidityRaw / 1000
  return temperature, humidity
end)

tmr.create():alarm(350 , tmr.ALARM_AUTO, function(timer)
  updateDisplay(state)
end)

tmr.create():alarm(350 , tmr.ALARM_AUTO, function(timer)
  if state.mqtt.connected then
    local jsonData = sjson.encoder(state):read()
    publishMqtt("air_quality", jsonData, true)
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
