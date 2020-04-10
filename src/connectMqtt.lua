local mqttClient
local clientId

function connectMqtt(connectionAcquiredCallback, connectionLostCallback, onMessageCallback)
  local server, username, password
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

  mqttClient:on("offline", function(mqttClient)
    if connectionLostCallback ~= nil then
      connectionLostCallback()
    end
    _connect(mqttClient, server, connectionAcquiredCallback)
  end)

  if onMessageCallback ~= nil then
    mqttClient:on('message', function(mqttClient, topic, message)
      onMessageCallback(topic, message)
    end)
  end

  _connect(mqttClient, server, connectionAcquiredCallback)
  return true
end

function _connect(mqttClient, server, connectionAcquiredCallback)

  local connectionSuccessfulCallback = function(mqttClient)
    if connectionAcquiredCallback ~= nil then
      connectionAcquiredCallback(mqttClient)
    end
  end

  local connectionFailedCallback = function()
    tmr.create():alarm(1000, tmr.ALARM_SINGLE, function()
      _connect(mqttClient, server, connectionAcquiredCallback)
    end)
  end

  mqttClient:connect(server, connectionSuccessfulCallback, connectionFailedCallback)
end

function publishMqtt(channel, message, suffixChannelWithClientId)
  if suffixChannelWithClientId == true then
    channel = channel .. '/' .. clientId
  end
  return mqttClient:publish(channel, message, 0, 0)
end

function subscribeMqtt(topic, onMessageCallback)
  mqttClient:subscribe(topic, 0)
end

function getMqttClientId()
  return clientId
end

function unregisterMqtt()
  connectMqtt = nil
  _connect = nil
  publishMqtt = nil
  subscribeMqtt = nil
  getMqttClientId = nil
  unregisterMqtt = nil
  mqttClient:close()
  mqttClient = nil
end
