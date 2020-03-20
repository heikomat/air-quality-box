MHZ19 = {}

function MHZ19:new(gpioPin, co2Callback)
  setmetatable({}, self)
  self.__index = self

  local lastLevel
  local lastTimestamp
  gpio.trig(gpioPin, 'both', function(level, timestamp)
    if lastLevel == level then
      lastTimestamp = timestamp
      return
    end

    if lastTimestamp == nil then
      lastTimestamp = timestamp
      return
    end

    if level == 0 and timestamp > lastTimestamp then
      local timeHighMilliseconds = (timestamp - lastTimestamp) / 1000;
      co2 = self:calculateCo2(timeHighMilliseconds)
      co2Callback(co2)
    end

    lastLevel = level
    lastTimestamp = timestamp
  end)
end

function MHZ19:calculateCo2(timeHigh)
  -- see here for why 5000 and not 2000:
  -- https://electronics.stackexchange.com/questions/262473/mh-z19-co2-sensor-giving-diferent-values-using-uart-and-pwm
  return math.floor(5000 * (timeHigh-2) / 1000);
end