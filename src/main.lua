--node.setcpufreq(node.CPU160MHZ)

local version = 33;

local pinSDA = 7
local pinSCL = 5
local maxTempDifferenceBetweenInsideAndOutside = 300 -- 3.0°C
local maxTempAdjustment = -290 -- -2.9°C
local maxHumidityDifferenceBetweenInsideAndOutside = 1 -- 3.0°C9°C
local maxHumidityAdjustment = 9000 -- +9%
i2c.setup(0, pinSDA, pinSCL, i2c.SLOW)
bme280.setup();

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
      inside = {
        raw = nil,
        celsius = nil,
        text = nil,
      },
      outside = {
        raw = nil,
        celsius = nil,
        text = nil,
      },
      adjusted = {
        raw = nil,
        celsius = nil,
        text = nil,
      },
    },
    pressure = {
      inside = {
        raw = nil,
        hPa = nil,
        text = nil,
      },
      outside = {
        raw = nil,
        hPa = nil,
        text = nil,
      },
    },
    humidity = {
      inside = {
        raw = nil,
        percent = nil,
        text = nil,
      },
      outside = {
        raw = nil,
        percent = nil,
        text = nil,
      },
      adjusted = {
        raw = nil,
        percent = nil,
        text = nil,
      },
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
    pms5003 = {
      secondsTilNextMeasurementStart = nil,
      secondsTilNextMeasurementEnd = nil,
      isMeasuring = nil,
      forcedOnReason = nil,
    },
  },
  iaq = {
    summary = {
      averageScore = nil,
      minScore = nil,
      maxScore = nil,
      text = nil,
    },
    issues = {},
    mostImportantIssue = nil,
    sensorScores = {
      temperature = nil,
      humidity = nil,
      tvoc = nil,
      co2 = nil,
      pm100 = nil,
    }
  }
}

local old_print = print
require 'initWifi'
require 'connectMqtt'
require 'iaq'
require 'tools'
require 'sgp30'
require 'mh-z19'
--require 'pms5003'
require 'display'

function unrequire(m)
	package.loaded[m] = nil
	_G[m] = nil
end

state.wifi.connecting = initWifi(function()
  state.wifi.connected = true
  state.wifi.connecting = false

  state.mqtt.connecting = connectMqtt(function()
    -- connection acquired
    state.mqtt.connected = true
    state.mqtt.connecting = false
    local clientId = getMqttClientId()
    publishMqtt('air_quality/' .. clientId .. '/connected', version, false)
    subscribeMqtt('air_quality/' .. clientId .. '/command/#')

    -- also send print outputs to mqtt
    print = function(...)
      old_print(...)
      if state.mqtt.connected then
        local jsonData = sjson.encoder({...}):read(2048)
        publishMqtt('air_quality/' .. clientId .. '/console', jsonData, false)
      end
    end
  end, function()
    -- connection lost
    if state == nil then
      return
    end
    state.mqtt.connected = false
    state.mqtt.connecting = true
  end, function(topic, message)
    local clientId = getMqttClientId()
    if topic == 'air_quality/' .. clientId .. '/command/update_lfs' then
      local updateOptions = sjson.decoder():write(message)
      unregisterEverything()
      clientId = nil
      message = nil
      LFS.HTTP_OTA(updateOptions.host, updateOptions.port, updateOptions.dir, updateOptions.imageName)
    elseif topic == 'air_quality/' .. clientId .. '/command/sleep_pms' then
      pms5003:sleep()
    elseif topic == 'air_quality/' .. clientId .. '/command/wakeup_pms' then
      pms5003:wakeup()
    elseif topic == 'air_quality/' .. clientId .. '/command/clear_calibration' then
      sgp30:deleteAQIBaselineFile()
      node.restart()
    elseif topic == 'air_quality/' .. clientId .. '/command/reboot' then
      node.restart()
    end
  end)
end)

local bme280Timer = tmr.create()
bme280Timer:alarm(350 , tmr.ALARM_AUTO, function(timer)

  temperatureOutside, pressureOutside, humidityOutside = bme280.read()
  temperatureInside, pressureInside, humidityInside = bme280.read(nil, true)
  if temperatureOutside ~= nil then
    state.sensors.temperature.outside.raw = temperatureOutside
    state.sensors.temperature.outside.celsius = state.sensors.temperature.outside.raw / 100
    state.sensors.temperature.outside.text = roundFixed(state.sensors.temperature.outside.celsius, 1) .. 'C'
  end
  if temperatureInside ~= nil then
    state.sensors.temperature.inside.raw = temperatureInside
    state.sensors.temperature.inside.celsius = state.sensors.temperature.inside.raw / 100
    state.sensors.temperature.inside.text = roundFixed(state.sensors.temperature.inside.celsius, 1) .. 'C'
  end

  if pressureOutside ~= nil then
    state.sensors.pressure.outside.raw = pressureOutside
    state.sensors.pressure.outside.hPa = state.sensors.pressure.outside.raw / 1000
    state.sensors.pressure.outside.text = round(state.sensors.pressure.outside.hPa) .. 'hpa'
  end
  if pressureInside ~= nil then
    state.sensors.pressure.inside.raw = pressureInside
    state.sensors.pressure.inside.hPa = state.sensors.pressure.inside.raw / 1000
    state.sensors.pressure.inside.text = round(state.sensors.pressure.inside.hPa) .. 'hpa'
  end

  if humidityOutside ~= nil then
    state.sensors.humidity.outside.raw = humidityOutside
    state.sensors.humidity.outside.percent = state.sensors.humidity.outside.raw / 1000
    state.sensors.humidity.outside.text = roundFixed(state.sensors.humidity.outside.percent, 1) .. '%'
  end
  if humidityInside ~= nil then
    state.sensors.humidity.inside.raw = humidityInside
    state.sensors.humidity.inside.percent = state.sensors.humidity.inside.raw / 1000
    state.sensors.humidity.inside.text = roundFixed(state.sensors.humidity.inside.percent, 1) .. '%'
  end

  if temperatureOutside ~= nil and temperatureInside ~= nil then
    local tempDifference = temperatureInside - temperatureOutside;
    if tempDifference < 0 then
      state.sensors.temperature.adjusted.raw = temperatureInside
    else
      if tempDifference > maxTempDifferenceBetweenInsideAndOutside then
        tempDifference = maxTempDifferenceBetweenInsideAndOutside
      end

      state.sensors.temperature.adjusted.raw = temperatureOutside + ((tempDifference / maxTempDifferenceBetweenInsideAndOutside) * maxTempAdjustment)
    end

    state.sensors.temperature.adjusted.celsius = state.sensors.temperature.adjusted.raw / 100
    state.sensors.temperature.adjusted.text = roundFixed(state.sensors.temperature.adjusted.celsius, 1) .. 'C'
  end

  if humidityOutside ~= nil and humidityInside ~= nil then
    local humidityDifference = humidityInside - humidityOutside;
    if humidityDifference < 0 then
      humidityDifference = 0
    end
    if humidityDifference > maxHumidityDifferenceBetweenInsideAndOutside then
      humidityDifference = maxHumidityDifferenceBetweenInsideAndOutside
    end
    state.sensors.humidity.adjusted.raw = humidityOutside + ((humidityDifference / maxHumidityDifferenceBetweenInsideAndOutside) * maxHumidityAdjustment)
    state.sensors.humidity.adjusted.percent = state.sensors.humidity.adjusted.raw / 1000
    state.sensors.humidity.adjusted.text = roundFixed(state.sensors.humidity.adjusted.percent, 1) .. '%'
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
  checkPmsForceOn()
end, function()
  if state == nil then
    return
  end

  if state.sensors.temperature.adjusted.celsius == nil or state.sensors.humidity.adjusted.percent == nil then
    return nil, nil
  end

  local temperature = state.sensors.temperature.adjusted.celsius
  local humidity = state.sensors.humidity.adjusted.percent
  return temperature, humidity
end)

mhz19 = MHZ19:new(2, function(co2)
  if state == nil then
    return
  end

  state.sensors.co2.raw = co2
  state.sensors.co2.ppm = co2
  state.sensors.co2.text = co2 .. 'ppm'
  checkPmsForceOn()
end)

pms5003 = PMS5003:new(function(pm10, pm25, pm100)
  if state == nil then
    return
  end

  state.sensors.pm10.raw = pm10;
  state.sensors.pm10.mgm3 = pm10;
  state.sensors.pm10.text = pm10 .. 'μg/m3';

  state.sensors.pm25.raw = pm25;
  state.sensors.pm25.mgm3 = pm25;
  state.sensors.pm25.text = pm25 .. 'μg/m3';

  state.sensors.pm100.raw = pm100;
  state.sensors.pm100.mgm3 = pm100;
  state.sensors.pm100.text = pm100 .. 'μg/m3';
end, function(secondsTilNextMeasurementStart, secondsTilNextMeasurementEnd, isMeasuring, forcedOnReason)
  state.debug.pms5003.secondsTilNextMeasurementStart = secondsTilNextMeasurementStart
  state.debug.pms5003.secondsTilNextMeasurementEnd = secondsTilNextMeasurementEnd
  state.debug.pms5003.isMeasuring = isMeasuring
  state.debug.pms5003.forcedOnReason = forcedOnReason
end)

function checkPmsForceOn()
  if state == nil or pms5003 == nil then
    return
  end

  local windowOpen = state.sensors.co2.ppm ~= nil and state.sensors.co2.ppm < 450 and state.sensors.tvoc.ppbRaw ~= nil and state.sensors.tvoc.ppbRaw < 100
  if windowOpen then
    pms5003:forceOn('window is open')
  else
    pms5003:stopForceOn()
  end
end

-- don't refresh too often, as it is slow (~230ms) and might result in gpio-interrupt-callbacks not being fired
displayTimer = tmr.create()
displayTimer:alarm(1000 , tmr.ALARM_AUTO, function(timer)
  if state == nil then
    return
  end
  updateDisplay(state)
end)

iaqTimer = tmr.create()
iaqTimer:alarm(350 , tmr.ALARM_AUTO, function(timer)
  if state == nil then
    return
  end
  calculateIaq(state.sensors, state.iaq)
end)

mqttTimer = tmr.create()
mqttTimer:alarm(10000 , tmr.ALARM_AUTO, function(timer)
  if state == nil then
    return
  end

  if state.mqtt.connected then
    local jsonData = sjson.encoder(state):read(2048)
    publishMqtt('air_quality', jsonData, true)
  end
end)

wifiTimer = tmr.create()
wifiTimer:alarm(1000 , tmr.ALARM_AUTO, function(timer)
  if state == nil then
    return
  end

  if not state.wifi.connected then
    return
  end

  local maxSignal = -25
  local minSignal = -80
  state.wifi.rssi = wifi.sta.getrssi()

  if state.wifi.rssi ~= nil then
    if state.wifi.rssi >= maxSignal then
      state.wifi.signalStrength = 100
    elseif state.wifi.rssi <= minSignal then
      state.wifi.signalStrength = 0
    else
      state.wifi.signalStrength = math.floor(((math.abs(state.wifi.rssi) - math.abs(minSignal)) / (math.abs(maxSignal) - math.abs(minSignal)))*100)
    end
  end
end)

function unregisterEverything()
  wifiTimer:unregister()
  wifiTimer = nil
  displayTimer:unregister()
  displayTimer = nil
  iaqTimer:unregister()
  iaqTimer = nil
  mqttTimer:unregister()
  mqttTimer = nil
  bme280Timer:unregister()
  bme280Timer = nil
  print = old_print
  state = nil
  initWifi = nil
  connectMqtt = nil
  updateIaq = nil
  checkPmsForceOn = nil
  sgp30:unregister()
  sgp30 = nil
  mhz19:unregister()
  mhz19 = nil
  pms5003:unregister()
  pms5003 = nil
  unregisterDisplay()
  unregisterWifi()
  unregisterIaq()
  unregisterMqtt()
  unregisterTools()
  unregisterEverything = nil
  loadfile = nil
  dofile = nil
  unrequire 'initWifi'
  unrequire 'connectMqtt'
  unrequire 'iaq'
  unrequire 'tools'
  unrequire 'sgp30'
  unrequire 'mh-z19'
  unrequire 'pms5003'
  unrequire 'display'
  unrequire '_init'
  unrequire 'main'
  unrequire = nil
  collectgarbage()
end
