require 'tools'

sla = 0x3c
display = u8g2.ssd1306_i2c_128x64_noname(0, sla)
display:setFont(u8g2.font_6x10_tf)

icons = {
  nowifi = '',
  temperature = '',
  voc = '',
  humidity = '',
  wifi1 = '',
  wifi2 = '',
  wifi3 = '',
  wifi4 = '',
  pressure = '',
}

for key, value in pairs(icons) do
  file.open(key .. '.bin', "r")
  icons[key] = file.read()
  file.close()
end

function drawGauge(centerX, centerY, radius, angle)
  display:drawCircle(centerX, centerY, radius, bit.bor(u8g2.DRAW_UPPER_RIGHT, u8g2.DRAW_LOWER_RIGHT))
  display:drawLine(centerX, centerY, centerX + radius*sin(angle*math.pi/180), centerY - radius*cos(angle*math.pi/180))
end

function updateDisplay(state)

  display:clearBuffer()
  drawStaticUI()
  drawWifiStatus(state)

  if state.sensors.temperatureText ~= nil then
    if state.iaq.sensorScores.temperature ~= nil then
      drawGauge(18, 8, 8, 180 - (state.iaq.sensorScores.temperature*36))
    end
    display:drawStr(0, 26, state.sensors.temperatureText)
  end

  if state.sensors.humidityText ~= nil then
    if state.iaq.sensorScores.humidity ~= nil then
      drawGauge(18, 44, 8, 180 - (state.iaq.sensorScores.humidity*36))
    end
    display:drawStr(0, 62, state.sensors.humidityText)
  end

  if state.sensors.tvocppbText ~= nil then
    if state.iaq.sensorScores.tvoc ~= nil then
      drawGauge(60, 8, 8, 180 - (state.iaq.sensorScores.tvoc*36))
    end
    display:drawStr(42, 26, state.sensors.tvocppbText)
  end

  if state.sensors.co2Text ~= nil then
    if state.iaq.sensorScores.co2 ~= nil then
      drawGauge(60, 44, 8, 180 - (state.iaq.sensorScores.co2*36))
    end
    display:drawStr(42, 62, state.sensors.co2Text)
  end

  if state.iaq.summary.minScore ~= nil and state.iaq.summary.averageScore ~= nil then
    drawGauge(102, 44, 8, 180 - (state.iaq.summary.minScore*36))
    drawGauge(102, 44, 8, 180 - (state.iaq.summary.averageScore*36))
    display:drawStr(84, 62, roundFixed(state.iaq.summary.averageScore, 1)..'/'..roundFixed(state.iaq.summary.minScore, 1))
  end

  display:updateDisplayArea(0, 0, 16, 8)
end

function drawStaticUI()
  display:drawXBM(0, 0, 16, 16, icons.temperature)
  display:drawXBM(0, 36, 16, 16, icons.humidity)

  display:drawXBM(42, 0, 16, 16, icons.voc)
end

wifiConnectingBlink = false
function drawWifiStatus(newState)
  if not state.wifi.connected then
    if state.wifi.connecting then
      if wifiConnectingBlink then
        display:drawXBM(112, 0, 16, 16, icons.wifi4)
      end
      wifiConnectingBlink = not wifiConnectingBlink
    else
      display:drawXBM(112, 0, 16, 16, icons.nowifi)
    end
  else
    if state.wifi.signalStrength >= 75 then
      display:drawXBM(112, 0, 16, 16, icons.wifi4)
    elseif state.wifi.signalStrength >= 50 then
      display:drawXBM(112, 0, 16, 16, icons.wifi3)
    elseif state.wifi.signalStrength >= 25 then
      display:drawXBM(112, 0, 16, 16, icons.wifi2)
    else
      display:drawXBM(112, 0, 16, 16, icons.wifi1)
    end
  end
end
