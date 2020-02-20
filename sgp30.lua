SGP30 = {}

function SGP30:new(busId, deviceAddress, iaqBaseline, iaqCallback)
  setmetatable({}, self)
  self.__index = self
  self.busId = busId or 0
  self.deviceAddress = deviceAddress or 0x58

  self:initIAQ()
  tmr.create():alarm(1000 , tmr.ALARM_AUTO, function(timer)
    local eCO2, TVOC, eCO2Valid, TVOCValid = self:measureIAQ()
    if eCO2Valid and TVOCValid then
      iaqCallback(eCO2, TVOC)
    end
  end)
end

function SGP30:TwoBytesToNumber(byte1, byte2)
  return bit.bor(bit.lshift(byte1, 8), bit.lshift(byte2, 0))
end

function SGP30:write(command, params)
  i2c.start(self.busId)
  i2c.address(self.busId, self.deviceAddress, i2c.TRANSMITTER)
  i2c.write(self.busId, command)
  if data ~= nil then
    c = i2c.write(self.busId, params)
  end
  i2c.stop(self.busId)
end

function SGP30:read(amount)
  i2c.start(self.busId)
  i2c.address(self.busId, self.deviceAddress, i2c.RECEIVER)
  c = i2c.read(self.busId, amount)
  i2c.stop(self.busId)
  return c
end

function SGP30:getBytesFromToByteNumber(twoByteNumber)
  local firstByte = bit.rshift(bit.band(twoByteNumber, 0xff00), 8)
  local secondByte = bit.band(twoByteNumber, 0x00ff)
  return firstByte, secondByte
end

function SGP30:calcCRC(twoByteNumber)
  local crc = 0xff
  local firstByte, secondByte = self:getBytesFromToByteNumber(twoByteNumber)
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
  return eCO2, TVOC
end

function SGP30:setIAQBaseline(eCO2, TVOC)
  local firstECO2Byte, secondECO2Byte = self:getBytesFromToByteNumber(eCO2)
  local firstTVOCByte, secondTVOCByte = self:getBytesFromToByteNumber(TVOC)
  local eCO2CRC = self:calcCRC(eCO2)
  local TVOCCRC = self:calcCRC(TVOC)
  self:write({0x20, 0x1e}, {firstECO2Byte, secondECO2Byte, eCO2CRC, firstTVOCByte, secondTVOCByte, TVOCCRC})
end
