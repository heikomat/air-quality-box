function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function roundFixed(num, numDecimalPlaces)
local rounded = tostring(round(num, numDecimalPlaces));

local decimalPos = string.find(rounded, '%.')
if decimalPos == nil then
  rounded = rounded .. '.'
  decimalPos = string.len(rounded)
end

local missingZeroes = numDecimalPlaces - (string.len(rounded) - decimalPos)
for i=1,missingZeroes do
  rounded = rounded .. '0'
end

return rounded
end

function sin(x)
  return x - ((x^3)/6) + ((x^5)/120) - ((x^7)/5040) + ((x^9)/362880)
end

function cos(x)
  return 1 - ((x^2)/2) + ((x^4)/24) - ((x^6)/720) + ((x^8)/40320)
end

function unregisterTools()
  round = nil
  roundFixed = nil
  sin = nil
  cos = nil
  unregisterTools = nil
end
