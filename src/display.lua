sla = 0x3c
display = u8g2.ssd1306_i2c_128x64_noname(0, sla)
display:setFont(u8g2.font_6x10_tf)
display:drawStr(0, 10, 'temp    :')
display:drawStr(0, 20, 'pressure:')
display:drawStr(0, 30, 'humidity:')
display:drawStr(0, 40, 'TVOC    :')
display:updateDisplayArea(0, 0, 16, 8)

local lastState = {}
wifiDots = 0
lastWifiStatus = ''
function updateDisplay(state)

  display:clearBuffer()
  if state.sensors.temperature ~= nil then
    display:drawStr(56, 10, state.sensors.temperature / 100 .. 'C')
  end
  if state.sensors.pressure ~= nil then
    display:drawStr(56, 20, state.sensors.pressure / 1000 .. 'hpa')
  end
  if state.sensors.humidity ~= nil then
    display:drawStr(56, 30, state.sensors.humidity / 1000 .. '%')
  end
  display:updateDisplayArea(7, 0, 9, 4)

  if state.sensors.tvoc ~= nil then
    display:drawStr(56, 40, state.sensors.tvoc .. 'ppb') 
    display:updateDisplayArea(7, 4, 9, 1)
  end

  local wifiStatus = ''
  if not state.wifi.connected then
    if state.wifi.connecting then
      wifiStatus = 'wifi is connecting'
      for i=1,wifiDots do
        wifiStatus = wifiStatus .. '.'
      end
      wifiDots = wifiDots + 1
      if wifiDots == 4 then
        wifiDots = 0
      end
    end
  else
    wifiStatus = 'wifi: ' .. state.wifi.signalStrength .. ' %'
  end

  if wifiStatus ~= lastWifiStatus then
    display:drawStr(0, 50, wifiStatus)
    display:updateDisplayArea(0, 5, 16, 2)
    lastWifiStatus = wifiStatus
  end
  lastState = state
end
