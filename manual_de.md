# Die Anzeige

Es kann einer von zwei Zuständen angezeigt werden:

1. **Es ist alles ok:**  
   Dann wird mitting ein lächelnder Smiley angezeigt
2. **Es ist nicht alles ok:**
   Wenn mind. 1 Sensor Werte misst, die einer Luftqualität von "Schulnote 3 oder schlechter" entsprechen, wird links ein Smiley angezeigt, der das Problem symbolisiert, und rechts ein Icon, dass die zugehörige Lösung darstellt. Unter dem rechten Icon wird zudem live der zugehörige Messwert angezeigt 

# Wichtige Hinweise

**TLDR:**
- Die Box nach Möglichkeit nicht in die pralle Sonne stellen.
- Die Box sollte zur Kalibrierung mindestens alle paar Tage für eine Weile (10 Minuten oder mehr) draußen oder an einem offenen Fenster stehen.
- Probleme, die schlimmer für die Luftqualität sind, haben bei der Anzeige eine höhere Gewichtung als andere (z.b. sind CO2-Probleme wichtiger als Temperatur-Probleme).

## Die Box selbst
- Der Schalter für den Feinstaubsensor muss beim Einschalten der Box auf "an" stehen. Nach dem Einschalten der Box kann er aber bei Bedarf direkt wieder ausgeschaltet werden.

## Feinstaubsensor
- Ist der einzige mit beweglichen Teilen, die Geräusche verursachen können.
- Wird nur beim Start und alle 30 Minuten für 20-30 Sekunden an gemacht, weil Feinstaub innerhalb von Räumen idr. kein Problem ist.
- Ausnahme: Es wird gerade gelüftet. Dann Läuft er so lange wie gelüftet wird.
- Kann über den Schalter neben dem Display abgeschaltet werden (wenn z.b. die Lüftergeräusche stören).





## CO2-Sensor

- Muss sich nach jedem Einschalten neu kalibrieren (passiert automatisch).
- Die Kalibrierung funktioniert so, dass als 400ppm-Basiswert der niedrigste Wert verwendet wird, der in den  letzten 24 Studen gemessen wurde.
- 400ppm entspricht normaler Frischluft von draußen.
- Deshalb sollte die Box nach jedem neuen Einschalten und ab und zu für ein paar Minuten draußen oder an einem offenen Fenster stehen.

## TVOC-Sensor
- Der Basiswert muss initial einmal für 12 Stunden kalibriert werden (passiert automatisch und ist bereits geschehen).
- Danach merkt die Box sich die Kalibrierung (auch wenn sie zwischendurch aus gemacht wird)
- Der Basiswert wird nach der Initialkalibierung automatisch kontinuierlich, langsam weiter kalibiert, weshalb die Box zumindest alle paar Tage ein paar Minuten draußen oder an einem offenen Fenster stehen sollte.

## Genauigkeit
- Die Messungen sind nicht super genau, aber auf jeden Fall genau genug, um die Luftqualität zu beurteilen. (z.b. kann die gemessene Temperatur mal um bis zu 1.5 Grad abweichen).
- Es kann vorkommen, dass in den erste 30 Sekunden nach dem Einschalten viel zu hohe Werte angezeigt werden. Das pendelt sich aber nach kurzer Zeit ein.





















# Messwerte, Bedeutung & Bewertung

Jeder Sensorwert wird intern auf einer Skala von 0.00-5.00 beurteilt. Der Wert gibt an, wie “gut” der Wert für die Luftqualität ist:
- unter 1.00: wirklich übel
- unter 2.00: nicht gut
- unter 3.00: ok
- unter 4.00: ziemlich gut
- über 4.00: hervorragend!

## Temperatur
Die optimale Temperatur ist von Person zu Person und Jahreszeit zu Jahreszeit unterschiedlich. Als ungefähres Mittelmaß wird 20-23 grad als optimal angesehen. (siehe [hier](https://www.iotacommunications.com/blog/indoor-air-quality-parameters/)). Jeder Grad da drüber oder drunter reduziert den Score um 1.00.  
Die Temperatur ist streng genommen kein direktes Luftqualitäts-Kriterium, hat aber auch Einfluss auf das Wohlbefinden.

## Luftfeuchtigkeit
Auch die optimale Luftfeuchtigkeit ist nicht überall und zu jeder Zeit gleich. Hier wird als ungefähres Mittelmaß 30 bis 50% als optimal angesehen (siehe [hier](https://www.iotacommunications.com/blog/indoor-air-quality-parameters/)).  
Die Luftfeuchtigkeit ist streng genommen kein direktes Luftqualitäts-Kriterium, hat aber auch Einfluss auf das Wohlbefinden.

## TVOC
TVOC steht für **T**otal **V**olatile **O**rganic **C**ompounds (= flüchtige organische Verbindungen).  
Das ist ein Sammelbegriff für eine ganze Reihe an Gaßen die bei Raumtemperatur verdampfen, wie z.B: Formaldehyd und Ethanol. Viele Produkte sind Quellen von VOCs, wie z.b. Düfte, neuen Möbel, Farben, Lösemittel, Lufterfrischer usw.

Die meisten davon sind in kleinen Mengen unschädlich, aber je mehr VOCs man ausgesetzt ist, und je länger man ihnen ausgesetzt ist, desto schädlicher sind sie. Hier gilt: je weniger desto besser, weshalb der optimale Wert bei 0 ppb (parts per billion) liegt.  
Welcher TVOC-Wert wie einzustufen ist, ist [hier](https://www.repcomsrl.com/wp-content/uploads/2017/06/Environmental_Sensing_VOC_Product_Brochure_EN.pdf) entnommen.





## CO2

Kohlenstoffdioxid ist das, was Luft “stickig” macht. Je höher der CO2 gehalt, desto weniger frisch wirkt die Luft, und desto schwerer fällt das Atmen, weil weniger frischer Sauerstoff (O2) eingeatmet wird. Die Hauptquelle für CO2 in Gebäuden sind Menschen, die es ausatmen.  
Draußen hat Luft einen relativen konstanten durschnittlichen CO2-Wert von rund 400ppm. Die Für die Box konkret verwendeten Thresholds sind eine Mischung aus ein paar Quellen, die ähnliche Angaben machen (siehe [hier](https://dixellasia.com/download/dixellasia_com/VCP/Datasheet/Air_Quality/duct-air-quality-voc-co2-sensor-bio-2000-duct.pdf) und [hier](http://www.iaquk.org.uk/ESW/Files/IAQ_Rating_Index.pdf))

## Feinstaub
Feinstaub bezeichnet Staubpartikel verschiedener Größen. Häufig wird mit Partikeln < 2.5 Mikrometer (PM2.5) und Partikeln < 10 Mikrometer (PM10) gearbeitet (PM = particulate matter).  
Je kleiner die Staubpartikel, desto tiefer können sie beim einatmen in die Atemwege gelangen, und dadurch schädlicher sein, da sie evtl nicht mehr ausgeatmet werden. An Staubpartikel können Metalle und organische Komponenten hängen, die gesundheitsschädlich sein können. (siehe [hier](https://www.umweltbundesamt.de/themen/gesundheit/umwelteinfluesse-auf-den-menschen/innenraumluft/feinstaub-in-innenraeumen))  
Quellen für Feinstaub sind z.b. Rauchen, Kerzen, Staubsaugen ohne Filter, Bürogeräte, Kochen/Braten usw.

