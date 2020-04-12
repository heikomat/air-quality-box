require 'tools'

sla = 0x3c
display = u8g2.ssd1306_i2c_128x64_noname(0, sla)
display:setFont(u8g2.font_6x10_tf)

local nowifiIcon = '  �g�w�;\�np���p��     '
local temperatureIcon = '����������������'
local vocIcon = '  � ��$tr�q  @�   '
local humidityIcon = '  ���p088888���  '
local wifi1Icon = '                      ��      '
local wifi2Icon = '                �� ��      '
local wifi3Icon = '          ���� ��      '
local wifi4Icon = '  ���?p�g��� ��      '

function drawGauge(centerX, centerY, radius, angle)
  display:drawCircle(centerX, centerY, radius, bit.bor(u8g2.DRAW_UPPER_RIGHT, u8g2.DRAW_LOWER_RIGHT))
  display:drawLine(centerX, centerY, centerX + radius*sin(angle*math.pi/180), centerY - radius*cos(angle*math.pi/180))
end

function updateDisplay(state)

  display:clearBuffer()
  drawStaticUI()
  drawWifiStatus(state)

  if state.sensors.temperature.text ~= nil then
    if state.iaq.sensorScores.temperature ~= nil then
      drawGauge(18, 8, 8, 180 - (state.iaq.sensorScores.temperature*36))
    end
    display:drawStr(0, 26, state.sensors.temperature.text)
  end

  if state.sensors.humidity.text ~= nil then
    if state.iaq.sensorScores.humidity ~= nil then
      drawGauge(18, 44, 8, 180 - (state.iaq.sensorScores.humidity*36))
    end
    display:drawStr(0, 62, state.sensors.humidity.text)
  end

  if state.sensors.tvoc.ppbText ~= nil then
    if state.iaq.sensorScores.tvoc ~= nil then
      drawGauge(60, 8, 8, 180 - (state.iaq.sensorScores.tvoc*36))
    end
    display:drawStr(42, 26, state.sensors.tvoc.ppbText)
  end

  if state.sensors.co2.text ~= nil then
    if state.iaq.sensorScores.co2 ~= nil then
      drawGauge(60, 44, 8, 180 - (state.iaq.sensorScores.co2*36))
    end
    display:drawStr(42, 62, state.sensors.co2.text)
  end

  if state.iaq.summary.minScore ~= nil and state.iaq.summary.averageScore ~= nil then
    display:drawStr(84, 62, roundFixed(state.iaq.summary.averageScore, 1)..'/'..roundFixed(state.iaq.summary.minScore, 1))
  end

  if state.sensors.pm10.text ~= nil then
    display:drawStr(84, 8, state.sensors.pm10.raw)
  end
  if state.sensors.pm25.text ~= nil then
    display:drawStr(84, 17, state.sensors.pm25.raw)
  end
  if state.sensors.pm100.text ~= nil then
    display:drawStr(84, 26, state.sensors.pm100.raw)
  end

  -- the following call is very slow (~228ms). CPU-Speed does affect it, i2c-bus speed does not
  display:updateDisplayArea(0, 0, 16, 8)
end

function drawStaticUI()
  display:drawXBM(0, 0, 16, 16, temperatureIcon)
  display:drawXBM(0, 36, 16, 16, humidityIcon)

  display:drawXBM(42, 0, 16, 16, vocIcon)
end

wifiConnectingBlink = false
function drawWifiStatus(newState)
  if not state.wifi.connected then
    if state.wifi.connecting then
      if wifiConnectingBlink then
        display:drawXBM(112, 0, 16, 16, wifi4Icon)
      end
      wifiConnectingBlink = not wifiConnectingBlink
    else
      display:drawXBM(112, 0, 16, 16, nowifiIcon)
    end
  else
    if state.wifi.signalStrength >= 75 then
      display:drawXBM(112, 0, 16, 16, wifi4Icon)
    elseif state.wifi.signalStrength >= 50 then
      display:drawXBM(112, 0, 16, 16, wifi3Icon)
    elseif state.wifi.signalStrength >= 25 then
      display:drawXBM(112, 0, 16, 16, wifi2Icon)
    else
      display:drawXBM(112, 0, 16, 16, wifi1Icon)
    end
  end
end

function unregisterDisplay()
  nowifiIcon = nil
  temperatureIcon = nil
  vocIcon = nil
  humidityIcon = nil
  wifi1Icon = nil
  wifi2Icon = nil
  wifi3Icon = nil
  wifi4Icon = nil
  display = nil
  sla = nil
  drawGauge = nil
  updateDisplay = nil
  drawStaticUI = nil
  drawWifiStatus = nil
  unregisterDisplay = nil
  wifiConnectingBlink = nil
  unrequire 'tools'
end
