rm -f src/LFS_*.img
cd nodemcu-firmware
docker run --rm -ti -v `pwd`:/opt/nodemcu-firmware -v `pwd`/../src:/opt/lua marcelstoer/nodemcu-build lfs-image
mv -f ../src/LFS_*.img ../lfs.img