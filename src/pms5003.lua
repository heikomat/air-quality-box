require 'tools'

PMS5003 = {}
PMS5003WarmupSeconds = 30

function PMS5003:new(pmsCallback, infoCallback)
  setmetatable({}, self)
  self.__index = self
  self.warmingUp = true
  self.isAwake = true
  self.isForcedOn = false
  self.forcedOnReason = nil

  self.cycleTotalTime = 1800
  self.cycleMeasureTime = 15
  self.nextScheduledWakeup = 0
  self.nextScheduledSleep = 0

  uart.setup(0, 9600, 8, uart.PARITY_NONE, uart.STOPBITS_1)
  self:wakeup()

  self:runCycle()
  self.runCycleTimer = tmr.create()
  self.runCycleTimer:alarm(self.cycleTotalTime * 1000, tmr.ALARM_AUTO, function()
    self:runCycle()
  end)

  self.updateStateTimer = tmr.create()
  self.updateStateTimer:alarm(500, tmr.ALARM_AUTO, function(timer)
    local now = tmr.time()
    local cycleIsActive = now >= self.nextScheduledWakeup and now <= self.nextScheduledSleep
    local shouldBeOn = self.isForcedOn or cycleIsActive

    if shouldBeOn == true and self.isAwake == false then
      self:wakeup()
    elseif shouldBeOn == false and self.isAwake == true then
      self:sleep()
    end

    if infoCallback ~= nil then
      local nextMeasureStart = self.nextScheduledWakeup + PMS5003WarmupSeconds - now;
      local nextMeasureEnd = self.nextScheduledSleep - now;
      local isInCycleMeasure = now >= (self.nextScheduledWakeup + PMS5003WarmupSeconds) and now <= self.nextScheduledSleep;
      if isInCycleMeasure then
        nextMeasureStart = 0
      elseif nextMeasureStart < 0 then
        nextMeasureStart = nextMeasureStart + self.cycleTotalTime
      end

      local isMeasuring = self.isAwake and self.warmingUp == false
      if isMeasuring == false or nextMeasureEnd < 0 then
        nextMeasureEnd = 0
      end

      infoCallback(nextMeasureStart, nextMeasureEnd, isMeasuring, self.forcedOnReason)
    end
  end)

  self:readPMFromUart(pmsCallback)
  return self
end

function PMS5003:runCycle()
  local now = tmr.time()
  self.nextScheduledWakeup = now
  self.nextScheduledSleep = now + (PMS5003WarmupSeconds + self.cycleMeasureTime)
end

function PMS5003:TwoBytesToNumber(byte1, byte2)
  return bit.bor(bit.lshift(byte1, 8), bit.lshift(byte2, 0))
end

function PMS5003:readPMFromUart(pmsCallback)
  local startByte1 = 0x42
  uart.on('data', string.char(startByte1), function(data)
    uart.on('data', 31, function(data)

      local startByte2 = string.byte(data, 1)
      local framelen = self:TwoBytesToNumber(string.byte(data, 2), string.byte(data, 3))
      local pm10_standard = self:TwoBytesToNumber(string.byte(data, 4), string.byte(data, 5))
      local pm25_standard = self:TwoBytesToNumber(string.byte(data, 6), string.byte(data, 7))
      local pm100_standard = self:TwoBytesToNumber(string.byte(data, 8), string.byte(data, 9))
      local pm10_env = self:TwoBytesToNumber(string.byte(data, 10), string.byte(data, 11))
      local pm25_env = self:TwoBytesToNumber(string.byte(data, 12), string.byte(data, 13))
      local pm100_env = self:TwoBytesToNumber(string.byte(data, 14), string.byte(data, 15))
      local particles_03um = self:TwoBytesToNumber(string.byte(data, 16), string.byte(data, 17))
      local particles_05um = self:TwoBytesToNumber(string.byte(data, 18), string.byte(data, 19))
      local particles_10um = self:TwoBytesToNumber(string.byte(data, 20), string.byte(data, 21))
      local particles_25um = self:TwoBytesToNumber(string.byte(data, 22), string.byte(data, 23))
      local particles_50um = self:TwoBytesToNumber(string.byte(data, 24), string.byte(data, 25))
      local particles_100um = self:TwoBytesToNumber(string.byte(data, 26), string.byte(data, 27))
      local unused = self:TwoBytesToNumber(string.byte(data, 28), string.byte(data, 29))
      local checksum = self:TwoBytesToNumber(string.byte(data, 30), string.byte(data, 31))

      if self.warmingUp == false then
        pmsCallback(pm10_env, pm25_env, pm100_env, checksum)
      end
      self:readPMFromUart(pmsCallback)
    end, 0)
  end, 0)
end

function PMS5003:sleep()
  print('putting pms5003 into sleep mode')
  uart.write(0, string.char(0x42, 0x4d, 0xe4, 0x00, 0x00, 0x01, 0x73))
  self.warmingUp = false
  self.isAwake = false
end

function PMS5003:wakeup(warmupCallback)
  if self.warmingUp == false and self.isAwake == true then
    if self.warmupCallback ~= nil then
      warmupCallback()
    end
    return
  end

  if self.warmingUp == false then
    self.warmingUp = true
    uart.write(0, string.char(0x42, 0x4d, 0xe4, 0x00, 0x01, 0x01, 0x74))
    print('waking up pms5003')
  end

  self.isAwake = true
  tmr.create():alarm(PMS5003WarmupSeconds * 1000, tmr.ALARM_SINGLE, function(timer)
    self.warmingUp = false
    if self.isAwake == true and warmupCallback ~= nil then
      warmupCallback()
    end
  end)
end

function PMS5003:forceOn(reason)
  self.isForcedOn = true
  self.forcedOnReason = reason or 'no reason given'
end

function PMS5003:stopForceOn()
  self.isForcedOn = false
  self.forcedOnReason = nil
end

function PMS5003:unregister()
  self.runCycleTimer:unregister()
  self.updateStateTimer:unregister()
  uart.on('data')
  self = nil
  PMS5003 = nil
  PMS5003WarmupSeconds = nil
  unrequire 'tools'
end
