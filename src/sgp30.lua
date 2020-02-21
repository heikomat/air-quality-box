SGP30 = {}

function SGP30:new(busId, deviceAddress, iaqBaseline, iaqCallback)
  setmetatable({}, self)
  self.__index = self
  self.busId = busId or 0
  self.deviceAddress = deviceAddress or 0x58

  self:initIAQ()
  self.initializedAt = tmr.now()
  local initialBaselineExists = self:readAQIBaselineFromFile()

  -- measure air quality once a scond
  local initFinished = false
  tmr.create():alarm(1000 , tmr.ALARM_AUTO, function(timer)
    tmr.delay(10000)
    local eCO2, TVOC, eCO2Valid, TVOCValid = self:measureIAQ()
    if initFinished == false and eCO2Valid and TVOCValid and (eCO2 > 400 or TVOC > 0) then
      initFinished = true
    end

    if initFinished and eCO2Valid and TVOCValid then
      local baselineCO2, baselineTVOC = self:getIAQBaseline()
      iaqCallback(eCO2, TVOC, baselineCO2, baselineTVOC)
    end
  end)

  -- persist baseline once per hour
  tmr.create():alarm(3600000 , tmr.ALARM_AUTO, function(timer)
    -- If we dont have an initial baseline, and 12 hours have passed (recommended
    -- time to determine a baseline), then store a new baseline
    if initialBaselineExists == false and (tmr.now() - self.initializedAt) >= 43200000000 then
      initialBaselineExists = true
    end

    if initialBaselineExists then
      self:writeAQIBaselineToFile()
    end
  end)
end

function SGP30:TwoBytesToNumber(byte1, byte2)
  return bit.bor(bit.lshift(byte1, 8), bit.lshift(byte2, 0))
end

function SGP30:write(data)
  i2c.start(self.busId)
  i2c.address(self.busId, self.deviceAddress, i2c.TRANSMITTER)
  i2c.write(self.busId, data)
  i2c.stop(self.busId)
end

function SGP30:read(amount)
  i2c.start(self.busId)
  i2c.address(self.busId, self.deviceAddress, i2c.RECEIVER)
  c = i2c.read(self.busId, amount)
  i2c.stop(self.busId)
  return c
end

function SGP30:getBytesFromTwoByteNumber(twoByteNumber)
  local firstByte = bit.rshift(bit.band(twoByteNumber, 0xff00), 8)
  local secondByte = bit.band(twoByteNumber, 0x00ff)
  return firstByte, secondByte
end

function SGP30:calcCRC(twoByteNumber)
  local crc = 0xff
  local firstByte, secondByte = self:getBytesFromTwoByteNumber(twoByteNumber)
  local bytes = {firstByte, secondByte}
  for index, byte in ipairs(bytes) do
      crc = bit.bxor(crc, byte)
      for i=1,8 do
          if bit.band(crc, 0x80) > 0 then
              crc = bit.bxor(bit.lshift(crc, 1), 0x31)
          else
              crc = bit.lshift(crc, 1)
          end
      end
  end
  return bit.band(crc, 0xff)
end

function SGP30:initIAQ()
  self:write({0x20, 0x03});
end

function SGP30:measureIAQ()
  self:write({0x20, 0x08})
  tmr.delay(12000)
  local result = self:read(6)

  local eCO2 = self:TwoBytesToNumber(string.byte(result, 1), string.byte(result, 2))
  local TVOC = self:TwoBytesToNumber(string.byte(result, 4), string.byte(result, 5))
  local eCO2Valid = string.byte(result, 3) == self:calcCRC(eCO2)
  local TVOCValid = string.byte(result, 6) == self:calcCRC(TVOC)
  return eCO2, TVOC, eCO2Valid, TVOCValid
end

function SGP30:getIAQBaseline()
  self:write({0x20, 0x15})
  tmr.delay(10000)
  local result = self:read(6)

  local eCO2 = self:TwoBytesToNumber(string.byte(result, 1), string.byte(result, 2))
  local TVOC = self:TwoBytesToNumber(string.byte(result, 4), string.byte(result, 5))
  local eCO2Valid = string.byte(result, 3) == self:calcCRC(eCO2)
  local TVOCValid = string.byte(result, 6) == self:calcCRC(TVOC)
  return eCO2, TVOC, eCO2Valid, TVOCValid
end

function SGP30:setIAQBaseline(eCO2, TVOC)
  local firstECO2Byte, secondECO2Byte = self:getBytesFromTwoByteNumber(eCO2)
  local firstTVOCByte, secondTVOCByte = self:getBytesFromTwoByteNumber(TVOC)
  local eCO2CRC = self:calcCRC(eCO2)
  local TVOCCRC = self:calcCRC(TVOC)
  self:write({0x20, 0x1e, firstECO2Byte, secondECO2Byte, eCO2CRC, firstTVOCByte, secondTVOCByte, TVOCCRC})
end

function SGP30:readAQIBaselineFromFile()
  if file.open('sgp30_baseline.txt', 'r') ~= nil then
    local persistedValues = file.read(4)
    file.close()
    local eCO2 = self:TwoBytesToNumber(string.byte(persistedValues, 1), string.byte(persistedValues, 2))
    local TVOC = self:TwoBytesToNumber(string.byte(persistedValues, 3), string.byte(persistedValues, 4))
    self:setIAQBaseline(eCO2, TVOC)
    return true
  end

  return false
end

function SGP30:writeAQIBaselineToFile()
  -- todo: ignore baselines older than a week
  local eCO2, TVOC, eCO2Valid, TVOCValid = self:getIAQBaseline()
  if eCO2Valid and TVOCValid and file.open('sgp30_baseline.txt', 'w+') ~= nil then
    local firstECO2Byte, secondECO2Byte = self:getBytesFromTwoByteNumber(eCO2)
    local firstTVOCByte, secondTVOCByte = self:getBytesFromTwoByteNumber(TVOC)
    file.write(string.char(firstECO2Byte, secondECO2Byte, firstTVOCByte, secondTVOCByte))
    file.close()
  end
end
