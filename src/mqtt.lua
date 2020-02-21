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

  print('connecting to mqtt server')
  mqttClient=mqtt.Client(clientId, 60, username, password)
  mqttClient:connect(server, function(mqttClient)
    print('connection to mqtt server established')
    callback(mqttClient)
  end, function(mqttClient, reason)
    print('mqtt connection failed')
  end)

  return true
end

function publishMqtt(channel, message)
  mqttClient:publish(channel, message, 0, 0)
end
