require 'tools'

-- see the iaq rating index from IAQUK.org.uk for more info:
-- http://www.iaquk.org.uk/ESW/Files/IAQ_Rating_Index.pdf
function calculateIaq(sensors, iaq)
  iaq.recommendations = {}
  local airQualityScores = {}

  -- temperature evaluation
  if sensors.temperatureCelsius ~= nil then
    if sensors.temperatureCelsius < 18 then
      iaq.sensorScores.temperature = valueToScore(math.max(5 - (18 - sensors.temperatureCelsius), 0))
    elseif sensors.temperatureCelsius > 21 then
      iaq.sensorScores.temperature = valueToScore(math.max(5 - (sensors.temperatureCelsius - 21), 0))
    else
      iaq.sensorScores.temperature = valueToScore(5)
    end
  
    table.insert(airQualityScores, iaq.sensorScores.temperature)

    if sensors.temperatureCelsius < 14 then
      table.insert(iaq.recommendations, "It's freezing! Turn the heat up!")
    elseif sensors.temperatureCelsius < 16 then
      table.insert(iaq.recommendations, "Kinda chill in here. You might want to turn on the heating")
    elseif sensors.temperatureCelsius > 25 then
      table.insert(iaq.recommendations, "It's really hot! Try to cool the room if you can")
    elseif sensors.temperatureCelsius > 23 then
      table.insert(iaq.recommendations, "Kinda warm in here. Consider cooling the room if possible")
    end
  end

  -- humidity evaluation
  if sensors.humidityPercent ~= nil then
    if sensors.humidityPercent <= 40 then
      iaq.sensorScores.humidity = valueToScore(math.max(5 - ((40 - sensors.humidityPercent) / 10), 0))
    elseif sensors.humidityPercent > 60 then
      iaq.sensorScores.humidity = valueToScore(math.max(5 - ((sensors.humidityPercent - 60) / 10), 0))
    else
      iaq.sensorScores.humidity = valueToScore(5)
    end

    table.insert(airQualityScores, iaq.sensorScores.humidity)

    if sensors.humidityPercent < 10 then
      table.insert(iaq.recommendations, "The air is super dry! Get a humidifier now!")
    elseif sensors.humidityPercent < 30 then
      table.insert(iaq.recommendations, "The air is pretty dry. Consider humidifying it.")
    elseif sensors.humidityPercent > 90 then
      table.insert(iaq.recommendations, "The air is super wet! Open a window to let the water out!")
    elseif sensors.humidityPercent > 70 then
      table.insert(iaq.recommendations, "It's pretty humid. You should open a window for some airflow.")
    end
  end

  -- tvoc evaluation (see https://www.repcomsrl.com/wp-content/uploads/2017/06/Environmental_Sensing_VOC_Product_Brochure_EN.pdf )
  if sensors.tvocppbRaw ~= nil then
    thresholds = {0, 65, 220, 660, 2200, 5000}
    for i=1,5 do
      minPoints = 6 - i
      minPointRangeValue = thresholds[i - 1] or nil
      maxPointRangeValue = thresholds[i] or nil
      if sensors.tvocppbRaw <= thresholds[i] then
        break
      end
    end

    if minPointRangeValue ~= nil and maxPointRangeValue ~= nil then
      iaq.sensorScores.tvoc = valueToScore(minPoints + ((maxPointRangeValue - sensors.tvocmgm3Raw) / (maxPointRangeValue - minPointRangeValue)))
    else
      iaq.sensorScores.tvoc = valueToScore(minPoints)
    end

    if iaq.sensorScores.tvoc <= 2.5 then
      table.insert(iaq.recommendations, "The air is really polluted. Open a window now!")
    elseif iaq.sensorScores.tvoc <= 3.5 then
      table.insert(iaq.recommendations, "The air isn't really the freshest. You might want to open a window")
    end

    table.insert(airQualityScores, iaq.sensorScores.tvoc)
  end

  -- summarization
  iaq.summary.minScore = nil
  iaq.summary.maxScore = nil
  local sumScore = 0
  for index, value in pairs(airQualityScores) do
    if iaq.summary.minScore == nil or value < iaq.summary.minScore then
      iaq.summary.minScore = value
    end
    if iaq.summary.maxScore == nil or value > iaq.summary.maxScore then
      iaq.summary.maxScore = valueToScore(value)
    end
    sumScore = sumScore + value
  end
  
  iaq.summary.averageScore = round(sumScore / table.getn(airQualityScores), 2)

  if iaq.summary.minScore > 4 then
    iaq.summary.text = "The air here is excellent! :D"
  elseif iaq.summary.minScore > 3 then
    iaq.summary.text = "The air here is quite good :)"
  elseif iaq.summary.minScore > 2 then
    iaq.summary.text = "The air here is ok i guess"
  elseif iaq.summary.minScore > 1 then
    iaq.summary.text = "The air here is pretty poor"
  else
    iaq.summary.text = "The air here is really bad! Do something! >:("
  end
end

function valueToScore(value)
  return round(value, 2)
end

return calculateIaq