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
}

for key, value in pairs(icons) do
  print('loading ' .. key)
  file.open(key .. '.bin', "r")
  icons[key] = file.read()
  file.close()
end

print(icons.wifi4)
function updateDisplay(state)

  display:clearBuffer()
  if state.sensors.temperatureText ~= nil then
    display:drawStr(16, 13, state.sensors.temperatureText)
    display:updateDisplayArea(2, 0, 6, 2)
  end
  if state.sensors.humidityText ~= nil then
    display:drawStr(80, 13, state.sensors.humidityText)
    display:updateDisplayArea(10, 0, 4, 2)
  end
  if state.sensors.pressureText ~= nil then
    display:drawStr(16, 29, state.sensors.pressureText)
    display:updateDisplayArea(2, 2, 6, 2)
  end
  if state.sensors.tvocText ~= nil then
    display:drawStr(80, 29, state.sensors.tvocText)
    display:updateDisplayArea(10, 2, 6, 2)
  end

  drawWifiStatus(state)
end

function drawStaticUI()
  display:drawXBM(0, 0, 16, 16, icons.temperature)
  display:drawXBM(64, 0, 16, 16, icons.humidity)
  --display:drawXBM(0, 16, 16, 16, icons.pressure)
  display:drawXBM(64, 16, 16, 16, icons.voc)
  display:updateDisplayArea(0, 0, 16, 8)
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

  display:updateDisplayArea(14, 0, 2, 2)
end

drawStaticUI()
