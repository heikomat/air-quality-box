# run this from the project root!

# flash the firmware
./tools/esptool.py write_flash -fm dio 0x00000 firmware.bin

# add the LFS partition and upload the lfs image
./tools/nodemcu-partition.py --lfs_size 64k
