local mqttClient

function connectMqtt(callback)
  local server, clientId, username, password
  if file.open('mqtt_credentials.txt') ~= nil then
    server = string.sub(file.readline(), 1, -2) -- to remove newline character
    clientId = string.sub(file.readline(), 1, -2) -- to remove newline character
    username = string.sub(file.readline(), 1, -2) -- to remove newline character
    password = string.sub(file.readline(), 1, -2) -- to remove newline character
    file.close()
  else
      return false
  end

  mqttClient=mqtt.Client(clientId, 60, username, password)
  mqttClient:connect(server, function(mqttClient)
    callback(mqttClient)
  end)

  return true
end

function publishMqtt(channel, message)
  mqttClient:publish(channel, message, 0, 0)
end


return connectMqtt