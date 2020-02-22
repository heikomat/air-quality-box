function initWifi(callback)
  local ssid, password
  if file.open('wifi_credentials.txt') ~= nil then
      ssid = string.sub(file.readline(), 1, -2) -- to remove newline character
      password = string.sub(file.readline(), 1, -2) -- to remove newline character
      file.close()
  else
      return false
  end

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

  return true
end

return initWifi