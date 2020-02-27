SGP30 = {}

function exp(exponent)
  return 2.7182818284590^exponent
end

function SGP30:new(busId, deviceAddress, iaqCallback, getHumidityCompensationDataCallback)
  setmetatable({}, self)
  self.__index = self
  self.busId = busId or 0
  self.deviceAddress = deviceAddress or 0x58

  self:initIAQ()
  self:updateHumidityCompensation(getHumidityCompensationDataCallback)
  self.initializedAt = tmr.time()

  local oneHour = 3600
  local twelveHours = oneHour * 12

  local lastBaselineSave = nil
  local nextBaselineSave = self.initializedAt + twelveHours
  local initialBaselineExists = self:readAQIBaselineFromFile()
  if initialBaselineExists then
    nextBaselineSave = self.initializedAt + oneHour
  end

  local lastBaselineSaveWasSuccessful = nil
  local lastBaselineSaveResult = nil

  -- measure air quality once a second
  local initFinished = false
  tmr.create():alarm(1000 , tmr.ALARM_AUTO, function(timer)
    local eCO2, TVOCppb, eCO2Valid, TVOCValid = self:measureIAQ()
    self:updateHumidityCompensation(getHumidityCompensationDataCallback)
    if initFinished == false and eCO2Valid and TVOCValid and (eCO2 > 400 or TVOCppb > 0) then
      initFinished = true
    end

    if initFinished and eCO2Valid and TVOCValid then
      baselineCO2, baselineTVOC = self:getIAQBaseline()
      TVOCmgm3 = TVOCppb / 218.77 -- see https://forum.digikey.com/t/sensirion-gas-sensors-faq/5205
      
      local now = tmr.time()
      local secondsSinceLastSave = nil
      local secondsTilNextSave = nextBaselineSave - now
      if lastBaselineSave ~= nil then
        secondsSinceLastSave = now - lastBaselineSave
      end

      iaqCallback(eCO2, TVOCppb, TVOCmgm3, baselineCO2, baselineTVOC, secondsSinceLastSave, secondsTilNextSave, lastBaselineSaveWasSuccessful, lastBaselineSaveResult)
    end
  end)

  -- check once a minute if the baseline needs to be saved
  tmr.create():alarm(oneHour * 1000 , tmr.ALARM_AUTO, function(timer)
    local now = tmr.time()
    if now >= nextBaselineSave then
      lastBaselineSave = now
      nextBaselineSave = lastBaselineSave + oneHour
      lastBaselineSaveWasSuccessful, lastBaselineSaveResult = self:writeAQIBaselineToFile()
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

function SGP30:getBytesFromFloat(floatNumber)
  local partBeforeDecimalPoint = math.floor(floatNumber)
  local partAfterDecimalPoint = floatNumber - partBeforeDecimalPoint

  local firstByte = partBeforeDecimalPoint
  local secondByte = bit.band(math.floor(partAfterDecimalPoint * 256), 0xff)
  return partBeforeDecimalPoint, secondByte
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
  local fd = file.open('sgp30_baseline.txt', 'r')
  if fd ~= nil then
    local persistedValues = fd:read(4)
    fd:close()
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
  if eCO2Valid == false or TVOCValid == false then
    return false, 'baseline reading invalid'
  end

  local firstECO2Byte, secondECO2Byte = self:getBytesFromTwoByteNumber(eCO2)
  local firstTVOCByte, secondTVOCByte = self:getBytesFromTwoByteNumber(TVOC)
  local baselineBytes = string.char(firstECO2Byte, secondECO2Byte, firstTVOCByte, secondTVOCByte)

  fdWrite = file.open('sgp30_baseline.txt', 'w+')
  if fdWrite == nil then
    return false, 'couldnt open sgp30_baseline.txt for writing'
  end

  local writeSuccessful = fdWrite:write(string.char(firstECO2Byte, secondECO2Byte, firstTVOCByte, secondTVOCByte))
  fdWrite:close()

  if writeSuccessful ~= true then
    return false, 'writing baseline to file failed'
  end

  -- validate the baseline was persisted correctly
  local fdRead = file.open('sgp30_baseline.txt', 'r')
  if fdRead == nil then
    return false, 'couldnt open sgp30_baseline.txt for reading'
  end

  local persistedValues = fdRead:read(4)
  fdRead:close()

  if persistedValues ~= baselineBytes then
    return false, 'read baseline bytestring does not match persisted baseline bytestring. baselineBytes: "'..baselineBytes..'", persistedBytes: "'..persistedValues..'"'
  end

  local readeCO2 = self:TwoBytesToNumber(string.byte(persistedValues, 1), string.byte(persistedValues, 2))
  local readTVOC = self:TwoBytesToNumber(string.byte(persistedValues, 3), string.byte(persistedValues, 4))
  if readeCO2 ~= eCO2 or readTVOC ~= TVOC then
    return false, 'baselineValues from file do not match baselineValues from sensor reading. sensoreCO2: '..eCO2..', sensorTVOC: '..TVOC..', fileeCO2: '..readeCO2..', fileTVOC: '..readTVOC
  end

  return true, 'baseline sucessfully saved'
end

function SGP30:updateHumidityCompensation(getHumidityCompensationDataCallback)
  if getHumidityCompensationDataCallback == nil then
    return
  end

  local temperature, relativeHumidity = getHumidityCompensationDataCallback()
  if temperature ~= nil and relativeHumidity ~= nil then
    SGP30:setHumidityCompensation(temperature, relativeHumidity)
  end
end

function SGP30:setHumidityCompensation(temperature, relativeHumidity)
  local absoluteHumidity = 216.7*(((relativeHumidity/100)*6.112 * exp((17.62*temperature)/(243.12+temperature)))/(273.15+temperature))

  absoluteHumidity = 70.58
  -- the first byte represents the part in front of the decimal point.
  -- the second byte represents the part after the decimal point.
  -- to correctly take both bytes into account when calculating the crc we need to
  -- act as if though these were the two bytes of a 16-bit integer, because calcCRC
  -- expects a 16bit integer, not a float
  local firstHumidtiyByte, secondHumidtiyByte = self:getBytesFromFloat(absoluteHumidity)
  local crc = self:calcCRC(self:TwoBytesToNumber(firstHumidtiyByte, secondHumidtiyByte))
  self:write({0x20, 0x61, firstHumidtiyByte, secondHumidtiyByte, crc})
end

function SGP30:disableHumidityCompensation()
  local absoluteHumidity = 0.0

  local firstHumidtiyByte, secondHumidtiyByte = self:getBytesFromFloat(absoluteHumidity)
  local crc = self:calcCRC(self:TwoBytesToNumber(absoluteHumidity))
  self:write({0x20, 0x61, firstHumidtiyByte, secondHumidtiyByte, crc})
end
