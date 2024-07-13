#!/bin/bash -ex
# Tested on Windows host and WSL2 host
if [ $# -ne 1 ]; then
    echo "Usage: $0 path/to/iso" && exit 1
fi
iso="$1"
accel=""
if [ `uname -o` = 'GNU/Linux' ] ; then
  accel="kvm -cpu host"
elif [ `uname -o` = 'Msys' ] ; then
  accel="whpx -cpu Haswell"
else
  accel="tcg,thread=multi,tb-size=256"
fi
qemu-system-x86_64 -accel $accel -smp 4 -m 4096 -nic user,model=virtio-net-pci -cdrom "$iso" -device virtio-vga-gl -display sdl,gl=on  -usb -device usb-tablet
