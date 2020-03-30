PMS5003 = {}

function PMS5003:new(pmsCallback)
  setmetatable({}, self)
  self.__index = self

  --uart.setup(0, 9600, 8, uart.PARITY_NONE, uart.STOPBITS_1)
  --self:readPMFromUart(pmsCallback)
  return self
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

      pmsCallback(pm10_env, pm25_env, pm100_env, checksum)
      self:readPMFromUart(pmsCallback)
    end, 0)
  end, 0)
end

function PMS5003:unregister()
  uart.on('data')
  self = nil
  PMS5003 = nil
end

function PMS5003:sleep()
  print('try putting pms5003 into sleep mode')
  uart.write(0, string.char(0x42, 0x4d, 0xe4, 0x00, 0x00, 0x01, 0x73))
  print('finised putting pms5003 into sleep mode')
end

function PMS5003:wakeup()
  print('try waking up pms5003')
  uart.write(0, string.char(0x42, 0x4d, 0xe4, 0x00, 0x01, 0x01, 0x74))
  print('woking up pms5003')
end
