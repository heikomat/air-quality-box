#!/bin/bash
# run this from the project root!

rm -f src/LFS_*.img
#mkdir -p dist
#rm -f dist/*
#luasrcdiet src/*.lua -s '_'
#mv src/*_.lua dist/
#for file in dist/*_.lua; do
#  mv "$file" "${file/_.lua/.lua}" 
#done
cd nodemcu-firmware
#docker run --rm -ti -v `pwd`:/opt/nodemcu-firmware -v `pwd`/../dist:/opt/lua marcelstoer/nodemcu-build lfs-image
#mv -f ../dist/LFS_*.img ../lfs.img
docker run --rm -ti -v `pwd`:/opt/nodemcu-firmware -v `pwd`/../src:/opt/lua marcelstoer/nodemcu-build lfs-image
mv -f ../src/LFS_*.img ../lfs.img
