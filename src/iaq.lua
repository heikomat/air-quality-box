require 'tools'

local tempIssueWeight = 0.2
local humidityIssueWeight = 0.2
local tvocIssueWeight = 0.4
local co2IssueWeight = 0.5
local pm100IssueWeight = 0.5

-- see the iaq rating index from IAQUK.org.uk for more info:
-- http://www.iaquk.org.uk/ESW/Files/IAQ_Rating_Index.pdf
function calculateIaq(sensors, iaq)
  iaq.issues = {}
  local airQualityScores = {}
  local issue = nil
  local solution = nil
  local issueDescription = nil

  -- temperature evaluation
  -- https://www.iotacommunications.com/blog/indoor-air-quality-parameters/
  if sensors.temperature.adjusted.celsius ~= nil then
    if sensors.temperature.adjusted.celsius < 20 then
      iaq.sensorScores.temperature = valueToScore(math.max(5 - (20 - sensors.temperature.adjusted.celsius), 0))
    elseif sensors.temperature.adjusted.celsius > 23 then
      iaq.sensorScores.temperature = valueToScore(math.max(5 - (sensors.temperature.adjusted.celsius - 23), 0))
    else
      iaq.sensorScores.temperature = valueToScore(5)
    end
  
    table.insert(airQualityScores, iaq.sensorScores.temperature)

    issue = nil
    solution = nil
    if sensors.temperature.adjusted.celsius < 14 then
      issue = 'cold2'
      solution = 'heat'
    elseif sensors.temperature.adjusted.celsius < 16 then
      issue = 'cold1'
      solution = 'heat'
    elseif sensors.temperature.adjusted.celsius > 27 then
      issue = 'warm2'
      solution = 'cool'
    elseif sensors.temperature.adjusted.celsius > 25 then
      issue = 'warm1'
      solution = 'cool'
    end

    if issue ~= nil then
      table.insert(iaq.issues, {
        issue = issue,
        solution = solution,
        description = "Temp " .. sensors.temperature.adjusted.text,
        importance = (5 - iaq.sensorScores.temperature) * tempIssueWeight,
      })
    end
  end

  -- humidity evaluation
  -- https://www.iotacommunications.com/blog/indoor-air-quality-parameters/
  if sensors.humidity.adjusted.percent ~= nil then
    if sensors.humidity.adjusted.percent <= 30 then
      iaq.sensorScores.humidity = valueToScore(math.max(5 - ((30 - sensors.humidity.adjusted.percent) / 5), 0))
    elseif sensors.humidity.adjusted.percent > 50 then
      iaq.sensorScores.humidity = valueToScore(math.max(5 - ((sensors.humidity.adjusted.percent - 50) / 10), 0))
    else
      iaq.sensorScores.humidity = valueToScore(5)
    end

    table.insert(airQualityScores, iaq.sensorScores.humidity)

    issue = nil
    solution = nil
    if sensors.humidity.adjusted.percent < 20 then
      issue = 'dry2'
      solution = 'humidify'
    elseif sensors.humidity.adjusted.percent < 25 then
      issue = 'dry1'
      solution = 'humidify'
    elseif sensors.humidity.adjusted.percent > 90 then
      issue = 'humid2'
      solution = 'open_window'
    elseif sensors.humidity.adjusted.percent > 70 then
      issue = 'humid1'
      solution = 'open_window'
    end

    if issue ~= nil then
      table.insert(iaq.issues, {
        issue = issue,
        solution = solution,
        description = "Hum. " .. sensors.humidity.adjusted.text,
        importance = (5 - iaq.sensorScores.humidity) * humidityIssueWeight
      })
    end
  end

  -- tvoc evaluation
  -- https://www.repcomsrl.com/wp-content/uploads/2017/06/Environmental_Sensing_VOC_Product_Brochure_EN.pdf
  if sensors.tvoc.ppbRaw ~= nil then
    thresholds = {0, 65, 220, 660, 2200, 5000}
    for i=1,6 do
      minPoints = 6 - i
      minPointRangeValue = thresholds[i - 1] or nil
      maxPointRangeValue = thresholds[i] or nil
      if sensors.tvoc.ppbRaw <= thresholds[i] then
        break
      end
    end

    if minPointRangeValue ~= nil and maxPointRangeValue ~= nil then
      iaq.sensorScores.tvoc = valueToScore(minPoints + ((maxPointRangeValue - sensors.tvoc.ppbRaw) / (maxPointRangeValue - minPointRangeValue)))
    else
      iaq.sensorScores.tvoc = valueToScore(minPoints)
    end
    table.insert(airQualityScores, iaq.sensorScores.tvoc)

    issue = nil
    solution = nil
    if iaq.sensorScores.tvoc <= 1.5 then
      issue = 'smell2'
      solution = 'open_window'
    elseif iaq.sensorScores.tvoc <= 2.5 then
      issue = 'smell1'
      solution = 'open_window'
    end

    if issue ~= nil then
      table.insert(iaq.issues, {
        issue = issue,
        solution = solution,
        description = "TVOC " .. sensors.tvoc.ppbText,
        importance = (5 - iaq.sensorScores.temperature) * tvocIssueWeight
      })
    end
  end

  -- co2 evaluation
  -- https://dixellasia.com/download/dixellasia_com/VCP/Datasheet/Air_Quality/duct-air-quality-voc-co2-sensor-bio-2000-duct.pdf
  -- http://www.iaquk.org.uk/ESW/Files/IAQ_Rating_Index.pdf
  if sensors.co2.raw ~= nil then
    thresholds = {400, 600, 1000, 1400, 1800, 2000}
    for i=1,6 do
      minPoints = 6 - i
      minPointRangeValue = thresholds[i - 1] or nil
      maxPointRangeValue = thresholds[i] or nil
      if sensors.co2.raw <= thresholds[i] then
        break
      end
    end

    if minPointRangeValue ~= nil and maxPointRangeValue ~= nil then
      iaq.sensorScores.co2 = valueToScore(minPoints + ((maxPointRangeValue - sensors.co2.raw) / (maxPointRangeValue - minPointRangeValue)))
    else
      iaq.sensorScores.co2 = valueToScore(minPoints)
    end
    table.insert(airQualityScores, iaq.sensorScores.co2)

    issue = nil
    solution = nil
    if iaq.sensorScores.co2 <= 1.5 then
      issue = 'stifling2'
      solution = 'open_window'
    elseif iaq.sensorScores.co2 <= 2.5 then
      issue = 'stifling1'
      solution = 'open_window'
    end

    if issue ~= nil then
      table.insert(iaq.issues, {
        issue = issue,
        solution = solution,
        description = "CO2 " .. sensors.co2.text,
        importance = (5 - iaq.sensorScores.co2) * co2IssueWeight,
      })
    end
  end

  -- particulate matter evaluation
  -- http://www.iaquk.org.uk/ESW/Files/IAQ_Rating_Index.pdf
  if sensors.pm100.raw ~= nil then
    thresholds = {0, 23, 41, 53, 64, 75}
    for i=1,6 do
      minPoints = 6 - i
      minPointRangeValue = thresholds[i - 1] or nil
      maxPointRangeValue = thresholds[i] or nil
      if sensors.pm100.raw <= thresholds[i] then
        break
      end
    end

    if minPointRangeValue ~= nil and maxPointRangeValue ~= nil then
      iaq.sensorScores.pm100 = valueToScore(minPoints + ((maxPointRangeValue - sensors.pm100.raw) / (maxPointRangeValue - minPointRangeValue)))
    else
      iaq.sensorScores.pm100 = valueToScore(minPoints)
    end
    table.insert(airQualityScores, iaq.sensorScores.pm100)

    issue = nil
    solution = nil
    if iaq.sensorScores.pm100 <= 1.5 then
      issue = 'pollution2'
      solution = 'close_window'
    elseif iaq.sensorScores.pm100 <= 2.5 then
      issue = 'pollution1'
      solution = 'close_window'
    end

    if issue ~= nil then
      table.insert(iaq.issues, {
        issue = issue,
        solution = solution,
        description = "PM10 " .. sensors.pm100.text,
        importance = (5 - iaq.sensorScores.co2) * pm100IssueWeight,
      })
    end
  end

  -- summarization
  iaq.mostImportantIssue = nil
  for index, value in pairs(iaq.issues) do
    if iaq.mostImportantIssue == nil or value.importance > iaq.mostImportantIssue.importance then
      iaq.mostImportantIssue = value
    end
  end

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

  if iaq.summary.minScore ~= nil then
    if iaq.summary.minScore > 4 then
      iaq.summary.text = 'The air here is excellent! :D'
    elseif iaq.summary.minScore > 3 then
      iaq.summary.text = 'The air here is quite good :)'
    elseif iaq.summary.minScore > 2 then
      iaq.summary.text = 'The air here is ok i guess'
    elseif iaq.summary.minScore > 1 then
      iaq.summary.text = 'The air here is pretty poor'
    else
      iaq.summary.text = 'The air here is really bad! Do something! >:('
    end
  else
    iaq.summary.text = ''
  end
end

function valueToScore(value)
  return round(value, 2)
end

function unregisterIaq()
  valueToScore = nil
  calculateIaq = nil
  unregisterIaq = nil

  tempIssueWeight = nil
  humidityIssueWeight = nil
  tvocIssueWeight = nil
  co2IssueWeight = nil
  particulateMatterIssueWeight = nil
  unrequire 'tools'
end
