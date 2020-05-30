require 'tools'

sla = 0x3c
display = u8g2.ssd1306_i2c_128x64_noname(0, sla)
display:setFont(u8g2.font_6x10_tf)
display:setDisplayRotation(u8g2.R2)

local nowifiIcon = '  �g�w�;\�np���p��     '
local temperatureIcon = '����������������'
local vocIcon = '  � ��$tr�q  @�   '
local humidityIcon = '  ���p088888���  '
local wifi1Icon = '                      ��      '
local wifi2Icon = '                �� ��      '
local wifi3Icon = '          ���� ��      '
local wifi4Icon = '  ���?p�g��� ��      '

local smileyIcon = '                                   �?     ���    ��    �  ?    ?  �   �  �  �  �  �  �  p      8          8      p  <  <�  <  <� �~  ~��w  ����  �����ǁ����������`� @ `      p      p      0      0      0      0      0      0      0      0      p      p`    `�    `�  ���  �� ?  � ���?������� � ��    �     �      p      p      8  8      �      �  �  �  �  �  �     �    �  ?    ��    ���     �?                                   '
local cold2Icon = '              �       �\
      �   �? � ����	 ����1�  ?�	�?  �� �  �`�  ��\
 �  �� 0s     9     �    8 @  p `  �  p  � �x  ���  ?���  ���  �����  ����  �` ~  ~ ` ~  ~ p�<  <p�  �0   � 0      0      0      0 ��� 0 ��� 0��  �0`    p`��p`��`p����`0���0��0    ��������������    ��    ��   @�0�   @t �   @t0�   �> 9   � �   �� �  �� �  �c  �  �1    � �  �� ����   ���0   �?                                 '
local warm2Icon = '                    �    � �?  � ��� � �� � �  ? �?  �  �  �  �  �  �Y  � qH   9x      8    \
p    	� �� 8�� p �� � ���������������` ��� `�8�p�0�pb p 0� � 0����0����0	  x 0	     0    0     0     p     p     `     2`     "�     6�     � � �����������x  �     �      p      p      x  8    \  �    _  �  �w  �  �c  �  �    �   �  ?   ��   8���   , �?    $       <                     '
local dry2Icon = '                                   �?     ���    ��    �  ?    ?  �   �  �  �  �  �  �  p      8          8      p      �      � �    ��>  |��  ���c  ƀ� c  ��   �` ~  ~ `�   p�� �	p`  l0     0      0      0      0      0      0      0    p �  p p�  ` ��� ` ��� � �@ � @@  �@  ��@   ��    ��    �     �      p      p      8  8      �      �  �  �  �  �  �     �    �  ?    ��    ���     �?                                   '
local humid2Icon = '                                   �?     ���    �?�    � ?    ? �   �0 �  �( �  �( �  p 8    8 0 @     @8     �p  _   ��  W   �� �s    ��#    �� � ������ �� � `� `���`����p����Gp��  �C0�  �A0     @0     �0    �0    �0    �0    �0     p\
     p     `      `      � >    � �   ���? �� ����  ����   ��     �      �      �      �  8    |  �    o  �  �  �  �  �  �  @  �  @�    @��O  �����  ��?                                   '
local smell2Icon = '                 �     � � 0��? �������� �  ?  ?  � �  �0�  �0�  �0p    88    8    80    p0�����8������������ >| �1�= 8 ?� 8 ?� 8 x� << pp << �x << �x << �x << �8 << �8 x p0 � x0<��<0����0����0�8����8��\
� 0 ��� p ���`����`����`���p���8��x<<x���8x�<<�<<�=8  ?�yx  ��s������������� �q�?��  �q����  ����{  ����?  ����  ����  ����  �����    ��      �      �                   '
local smell1Icon = '                               � �?   � ���  � ��  ��  ?   ?  �   �  � �  ���  � p     8         80     p  ����� ������    ��  8���  ����  ��#���1��#���1��`��0�` �0� p 8� p >| 0  8  0  0  0  p  0  `  0      0      0 �� 0 �� p �� p  ?�  `  �  `  �  �      �      �    ��    ����������8��   p     p 0    8  8      �      �  �  �  �  �  �     �    �  ?    ��    ���     �?                                   '
local stifling2Icon = '                                   �?     ���    ��    �  ?    ?��   ����  �x��  ���  p �  8 8�   ��8   �?p     �     � ��   ���   ��y   ��   ��  � �  �`  �`�  �p� ��p� ��0�  ��?0~  ��0  ���0 ����0�����0�����00 ����0 �����p ����?p ��� ` �� ` ��? � �� � �� ��� ���� ������������� �����  �� p  �� p  �� 8  8�    ��    � �  �  �  �  �     �    �  ?    ��    ���     �?                                   '
local pollution2Icon = '                                   �?     ���    ��    �  ?    ?  �   �  �  �  �  �  �  p      8          8      p  ���  ����� ���  ���  ���~  ~��|  >�� �  ? � ��w ���������p�`��p�  �s0�    ;08 �? 0p���0����0�  �0�  �0�  �0�    p�    p�    `�    `�    ��    �c    ��o    ��    ��{    ��c    � g    �  n    v  n    v  |    >  �      �  �  ��  �  �����  �����     �    �  ?    ��    ���     �?                                   '
local pollution1Icon = '                                   �?     ���    ��    �  ?    ?  �   �  �  �  �  �  �  p      8          8      p      �      � �    ��    ��    ��    �������������    ��    �p    �p    p0    808 �? 0p���0����0�  �0�  �0�  �0�    p�    p�    `�    `�    ��    �c    ��o    ��    ��{    ��c    � g    �  n    v  n    v  |    >  �      �  �  ��  �  �����  �����     �    �  ?    ��    ���     �?                                   '
local heatIcon = '                                                     �      �     �     ��     �         �     �            �      �8<    �x<   ���~   ���   �? �   x8 �  `8pn   �xl   �8l   �0�   � �   � �   �= �   ��   � ??   <��7   ��1   p   ��`   ���   �} �   � p    � �    ���   x ��   < �   < ?   <�~   |��   ||��   x���   ��   ��0    �                                      '
local coolIcon = '                                                           >     |6     ~>               �     ��m    ��     � ?     >                   �����  �����  8      8  ��    ��                          ���?  ���?  8      �����  �����                 �    �    �               8     0     0    �<    �                                                                          '
local openWindowIcon = "                                  ����   �����  �  �  �  �  p  �  8  �  <  �<  .  �t  '  ��  #  ��  #  ��  #  ��  #  ��  #  ��  #  ��  #  ��  #  ��  #  ��  #  ��  #  ��  �  ��  �  ��  c  ��  3  ��  ;  ��  /  ��  '  ��  #  ��  #  ��  #  ��  #  ��  #�  ��  #�  ��  #�  ��  #�  ��  #�  ��  ������  ������  �p  �  ss  ��  ;;  ��    ��    ��    ��    ��                                         "
local closeWindowIcon = "                                  ����    ����    ���    ���    ���    ���    ���    ���    ���    ���    ���    ���    ���    ���    ���    ���    ���    ���    ���    ����    ���    ���    ���    ���    ���    ���    ���    ���    ���    ���    ���    ���    ���    ���    ���    ���    ����    ����   `    �    8��  pl�6  �p    �?  �  �  �     �                                  "

function getIcon(key)
  if key == 'smiley' then return smileyIcon end
  if key == 'cold2' then return cold2Icon end
  if key == 'cold1' then return cold2Icon end
  if key == 'warm2' then return warm2Icon end
  if key == 'warm1' then return warm2Icon end
  if key == 'dry2' then return dry2Icon end
  if key == 'dry1' then return dry2Icon end
  if key == 'humid2' then return humid2Icon end
  if key == 'humid1' then return humid2Icon end
  if key == 'smell2' then return smell2Icon end
  if key == 'smell1' then return smell1Icon end
  if key == 'stifling2' then return stifling2Icon end
  if key == 'stifling1' then return stifling2Icon end
  if key == 'pollution2' then return pollution2Icon end
  if key == 'pollution1' then return pollution1Icon end
  if key == 'heat' then return heatIcon end
  if key == 'cool' then return coolIcon end
  if key == 'open_window' then return openWindowIcon end
  if key == 'close_window' then return closeWindowIcon end
  return nowifiIcon -- just so the device soesnt crash
end

function drawGauge(centerX, centerY, radius, angle)
  display:drawCircle(centerX, centerY, radius, bit.bor(u8g2.DRAW_UPPER_RIGHT, u8g2.DRAW_LOWER_RIGHT))
  display:drawLine(centerX, centerY, centerX + radius*sin(angle*math.pi/180), centerY - radius*cos(angle*math.pi/180))
end



function updateDisplay(state)
  display:clearBuffer()

  if state.iaq.mostImportantIssue == nil then
    display:drawXBM(32, 0, 64, 64, getIcon('smiley'))
  else
    print(state.iaq.mostImportantIssue.issue, state.iaq.mostImportantIssue.solution)
    display:drawXBM(0, 0, 64, 64, getIcon(state.iaq.mostImportantIssue.issue))
    display:drawXBM(64, 0, 64, 54, getIcon(state.iaq.mostImportantIssue.solution))
    display:drawStr(64, 60, state.iaq.mostImportantIssue.description)
  end

  display:updateDisplayArea(0, 0, 16, 8)
end

--[[
function updateDisplay(state)

  display:clearBuffer()
  drawStaticUI()
  drawWifiStatus(state)

  if state.sensors.temperature.adjusted.text ~= nil then
    if state.iaq.sensorScores.temperature ~= nil then
      drawGauge(18, 8, 8, 180 - (state.iaq.sensorScores.temperature*36))
    end
    display:drawStr(0, 26, state.sensors.temperature.adjusted.text)
  end

  if state.sensors.humidity.adjusted.text ~= nil then
    if state.iaq.sensorScores.humidity ~= nil then
      drawGauge(18, 44, 8, 180 - (state.iaq.sensorScores.humidity*36))
    end
    display:drawStr(0, 62, state.sensors.humidity.adjusted.text)
  end

  if state.sensors.tvoc.ppbText ~= nil then
    if state.iaq.sensorScores.tvoc ~= nil then
      drawGauge(60, 8, 8, 180 - (state.iaq.sensorScores.tvoc*36))
    end
    display:drawStr(42, 26, state.sensors.tvoc.ppbText)
  end

  if state.sensors.co2.text ~= nil then
    if state.iaq.sensorScores.co2 ~= nil then
      drawGauge(60, 44, 8, 180 - (state.iaq.sensorScores.co2*36))
    end
    display:drawStr(42, 62, state.sensors.co2.text)
  end

  if state.iaq.summary.minScore ~= nil and state.iaq.summary.averageScore ~= nil then
    display:drawStr(84, 62, roundFixed(state.iaq.summary.averageScore, 1)..'/'..roundFixed(state.iaq.summary.minScore, 1))
  end

  if state.sensors.pm10.text ~= nil then
    display:drawStr(84, 8, state.sensors.pm10.raw)
  end
  if state.sensors.pm25.text ~= nil then
    display:drawStr(84, 17, state.sensors.pm25.raw)
  end
  if state.sensors.pm100.text ~= nil then
    display:drawStr(84, 26, state.sensors.pm100.raw)
  end

  -- the following call is very slow (~228ms). CPU-Speed does affect it, i2c-bus speed does not
  display:updateDisplayArea(0, 0, 16, 8)
end
--]]

function drawStaticUI()
  display:drawXBM(0, 0, 16, 16, temperatureIcon)
  display:drawXBM(0, 36, 16, 16, humidityIcon)

  display:drawXBM(42, 0, 16, 16, vocIcon)
end

wifiConnectingBlink = false
function drawWifiStatus(newState)
  if not state.wifi.connected then
    if state.wifi.connecting then
      if wifiConnectingBlink then
        display:drawXBM(112, 0, 16, 16, wifi4Icon)
      end
      wifiConnectingBlink = not wifiConnectingBlink
    else
      display:drawXBM(112, 0, 16, 16, nowifiIcon)
    end
  else
    if state.wifi.signalStrength >= 75 then
      display:drawXBM(112, 0, 16, 16, wifi4Icon)
    elseif state.wifi.signalStrength >= 50 then
      display:drawXBM(112, 0, 16, 16, wifi3Icon)
    elseif state.wifi.signalStrength >= 25 then
      display:drawXBM(112, 0, 16, 16, wifi2Icon)
    else
      display:drawXBM(112, 0, 16, 16, wifi1Icon)
    end
  end
end

function unregisterDisplay()
  nowifiIcon = nil
  temperatureIcon = nil
  vocIcon = nil
  humidityIcon = nil
  wifi1Icon = nil
  wifi2Icon = nil
  wifi3Icon = nil
  wifi4Icon = nil

  smileyIcon = nil
  cold2Icon = nil
  warm2Icon = nil
  dry2Icon = nil
  humid2Icon = nil
  smell2Icon = nil
  smell1Icon = nil
  stifling2Icon = nil
  pollution2Icon = nil
  pollution1Icon = nil
  heatIcon = nil
  coolIcon = nil
  openWindowIcon = nil
  closeWindowIcon = nil
  

  display = nil
  sla = nil
  drawGauge = nil
  updateDisplay = nil
  drawStaticUI = nil
  drawWifiStatus = nil
  unregisterDisplay = nil
  wifiConnectingBlink = nil
  unrequire 'tools'
end
