./tools/build_firmware.sh
./tools/build_lfs.sh
./tools/flash_firmware_and_configure_lfs_partition.sh
./tools/flash_lfs.sh
sleep 8
nodemcu-tool upload icons_bin/* src/init.lua src/_init.lua