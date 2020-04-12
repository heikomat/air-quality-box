MHZ19 = {}

-- The MH-Z19B self-calibrates every 24 hours by setting the lowest seen value in these 24 Hours as 400ppm baseline.
-- Disabling this and manually triggering the calibration requires a uart connection
function MHZ19:new(gpioPin, co2Callback)
  setmetatable({}, self)
  self.__index = self
  self.gpioPin = gpioPin

  local measueStartTimestamp

  gpio.mode(gpioPin, gpio.INT)
  gpio.trig(self.gpioPin, 'both', function(level, timestamp, eventcount)
    local isMeasurementEnd = level == 0

    local eventWasMissed = eventcount > 1
    local timerWrapped = measueStartTimestamp ~= nil and measueStartTimestamp > timestamp
    local missingMeasurementStart = isMeasurementEnd and measueStartTimestamp == nil
    if eventWasMissed then
      print('MHZ19 gpio event missed', eventcount)
    end
    local abortMeasurement = eventWasMissed or timerWrapped or missingMeasurementStart
    if abortMeasurement then
      measueStartTimestamp = nil
      return
    end

    local isMeasurementStart = level == 1
    if isMeasurementStart then
      measueStartTimestamp = timestamp
      return
    end

    local timeHighMilliseconds = (timestamp - measueStartTimestamp) / 1000;
    co2 = self:calculateCo2(timeHighMilliseconds)
    co2Callback(co2)
  end)

  return self
end

function MHZ19:calculateCo2(timeHigh)
  -- see here for why 5000 and not 2000:
  -- https://electronics.stackexchange.com/questions/262473/mh-z19-co2-sensor-giving-diferent-values-using-uart-and-pwm
  return math.floor(5000 * (timeHigh-2) / 1000);
end

function MHZ19:unregister()
  gpio.trig(self.gpioPin, 'none')
  self = nil
  MHZ19 = nil
end
