# run this from the project root!

cd nodemcu-firmware
rm -f bin/nodemcu_*.bin
docker run --rm -ti -v `pwd`:/opt/nodemcu-firmware marcelstoer/nodemcu-build build
mv -f bin/nodemcu_*.bin ../firmware.bin