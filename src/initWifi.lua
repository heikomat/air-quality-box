function initWifi(callback)
  if config == nil or config.wifi == nil or config.wifi.enabled ~= true then
    return
  end

  wifi.setmode(wifi.STATION)
  wifi.sta.config({ssid=config.wifi.ssid, pwd=config.wifi.password})
  wifi.sta.autoconnect(1)

  -- wait for the wifi connection to be established
  -- this is basically a setTimeout
  tmr.create():alarm(500 , tmr.ALARM_AUTO, function(timer)
    if wifi.sta.getip() ~= nil then
      wifiIsConnected = true
      timer:unregister()
      callback()
    end
  end)

  return true
end

function unregisterWifi()
  initWifi = nil
  unregisterWifi = nil
  wifiIsConnected = nil
end
