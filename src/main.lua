node.setcpufreq(node.CPU160MHZ)

local pinSDA = 7
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
    temperature = {
      raw = nil,
      celsius = nil,
      text = nil,
    },
    pressure = {
      raw = nil,
      hPa = nil,
      text = nil,
    },
    humidity = {
      raw = nil,
      percent = nil,
      text = nil,
    },
    tvoc = {
      ppbRaw = nil,
      ppbText = nil,
      mgm3Raw = nil,
      mgm3Text = nil,
    },
    co2 = {
      raw = nil,
      ppm = nil,
      text = nil,
    },
    pm10 = {
      raw = nil,
      mgm3 = nil,
      text = nil,
    },
    pm25 = {
      raw = nil,
      mgm3 = nil,
      text = nil,
    },
    pm100 = {
      raw = nil,
      mgm3 = nil,
      text = nil,
    },
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
  iaq = {
    summary = {
      averageScore = nil,
      minScore = nil,
      maxScore = nil,
      text = nil,
    },
    recommendations = nil,
    sensorScores = {
      temperature = nil,
      humidity = nil,
      tvoc = nil,
      co2 = nil,
      pm10 = nil,
      pm25 = nil,
      pm100 = nil,
    }
  }
}

local initWifi = require 'initWifi'
local connectMqtt = require 'connectMqtt'
local updateIaq = require 'iaq'
require 'tools'
require 'sgp30'
require 'mh-z19'
require 'pms5003'
require 'display'

state.wifi.connecting = initWifi(function()
  state.wifi.connected = true
  state.wifi.connecting = false

  state.mqtt.connecting = connectMqtt(function()
    -- connection acquired
    state.mqtt.connected = true
    state.mqtt.connecting = false
  end, function()
    -- connection lost
    state.mqtt.connected = false
    state.mqtt.connecting = true
  end)
end)

tmr.create():alarm(350 , tmr.ALARM_AUTO, function(timer)
  temperature, pressure, humidity = bme280.read()
  if temperature ~= nil then
    state.sensors.temperature.raw = temperature
    state.sensors.temperature.celsius = state.sensors.temperature.raw / 100
    state.sensors.temperature.text =  roundFixed(state.sensors.temperature.celsius, 1) .. 'C'
  end

  if pressure ~= nil then
    state.sensors.pressure.raw = pressure
    state.sensors.pressure.hPa = state.sensors.pressure.raw / 1000
    state.sensors.pressure.text = round(state.sensors.pressure.hPa) .. 'hpa'
  end

  if humidity ~= nil then
    state.sensors.humidity.raw = humidity
    state.sensors.humidity.percent = state.sensors.humidity.raw / 1000
    state.sensors.humidity.text = roundFixed(state.sensors.humidity.raw / 1000, 1) .. '%'
  end
end)

sgp30 = SGP30:new(nil, nil, function(eCO2, TVOCppb, TVOCmgm3, eCO2Baseline, TVOCBaseline, secondsSincaLastBaselineSave, secondsTilNextBaselineSave, lastBaselineSaveWasSuccessful, lastBaselineSaveResult)
  state.sensors.tvoc.ppbRaw = TVOCppb
  state.sensors.tvoc.ppbText = TVOCppb .. 'ppb'

  state.sensors.tvoc.mgm3Raw = TVOCmgm3
  state.sensors.tvoc.mgm3Text = TVOCmgm3 .. 'mg/m3'

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

mhz19 = MHZ19:new(2, function(co2)
  state.sensors.co2.raw = co2
  state.sensors.co2.ppm = co2
  state.sensors.co2.text = co2 .. 'ppm'
end)

pms5003 = PMS5003:new(function(pm10, pm25, pm100)
  state.sensors.pm10.raw = pm10;
  state.sensors.pm10.mgm3 = pm10;
  state.sensors.pm10.text = pm10 .. 'μg/m3';

  state.sensors.pm25.raw = pm25;
  state.sensors.pm25.mgm3 = pm25;
  state.sensors.pm25.text = pm25 .. 'μg/m3';

  state.sensors.pm100.raw = pm100;
  state.sensors.pm100.mgm3 = pm100;
  state.sensors.pm100.text = pm100 .. 'μg/m3';
end)

-- don't refresh too often, as it is slow (~230ms) and might result in gpio-interrupt-callbacks not being fired
tmr.create():alarm(1000 , tmr.ALARM_AUTO, function(timer)
    updateDisplay(state)
end)

tmr.create():alarm(350 , tmr.ALARM_AUTO, function(timer)
  calculateIaq(state.sensors, state.iaq)
end)

tmr.create():alarm(10000 , tmr.ALARM_AUTO, function(timer)
  if state.mqtt.connected then
    local jsonData = sjson.encoder(state):read(2048)
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
