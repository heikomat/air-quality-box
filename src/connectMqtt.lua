local mqttClient

function connectMqtt(connectionAcquiredCallback, connectionLostCallback, onMessageCallback)
  if config == nil or config.mqtt == nil then
    return
  end

  mqttClient=mqtt.Client(config.mqtt.clientId, 60, config.mqtt.username, config.mqtt.password)

  mqttClient:on('offline', function(mqttClient)
    if connectionLostCallback ~= nil then
      connectionLostCallback()
    end
    _connect(mqttClient, connectionAcquiredCallback)
  end)

  if onMessageCallback ~= nil then
    mqttClient:on('message', function(mqttClient, topic, message)
      onMessageCallback(topic, message)
    end)
  end

  _connect(mqttClient, connectionAcquiredCallback)
  return true
end

function _connect(mqttClient, connectionAcquiredCallback)

  local connectionSuccessfulCallback = function(mqttClient)
    if connectionAcquiredCallback ~= nil then
      connectionAcquiredCallback(mqttClient)
    end
  end

  local connectionFailedCallback = function()
    tmr.create():alarm(1000, tmr.ALARM_SINGLE, function()
      _connect(mqttClient, config.mqtt.server, connectionAcquiredCallback)
    end)
  end

  mqttClient:connect(config.mqtt.server, connectionSuccessfulCallback, connectionFailedCallback)
end

function publishMqtt(channel, message, suffixChannelWithClientId)
  if suffixChannelWithClientId == true then
    channel = channel .. '/' .. config.mqtt.clientId
  end
  return mqttClient:publish(channel, message, 0, 0)
end

function subscribeMqtt(topic, onMessageCallback)
  mqttClient:subscribe(topic, 0)
end

function unregisterMqtt()
  connectMqtt = nil
  _connect = nil
  publishMqtt = nil
  subscribeMqtt = nil
  unregisterMqtt = nil
  mqttClient:close()
  mqttClient = nil
end
