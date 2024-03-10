#!/bin/bash -e
baseDir="$(dirname $0)"
cd "$baseDir"
. ./settings.vars

if [ ! -f "./arch" ] ; then
  echo "Prepare VM with ./runvm.sh first!" && exit 1
fi

if [ -z `which qemu-system-x86_64` ] && [ -x "/c/Program Files/qemu/qemu-system-x86_64" ] ; then # for win32/msys
  PATH="/c/Program Files/qemu:$PATH"
fi

arch=$(cat ./arch)
tcg="tcg,thread=multi,tb-size=256"
if [ "$arch" == "arm64" ] ; then
  qemu-system-aarch64 -cpu cortex-a72 -smp $CPUS -M virt -m "${RAM_SIZE}" -nographic -drive if=pflash,format=raw,file=./arm64_linaro/QEMU_EFI.img -hda "$HDD_PATH" -cdrom ./user-data.img -accel $tcg
#-netdev type=tap,id=net0 -serial mon:stdio
else
  accel=""
  if [ `uname -o` = 'GNU/Linux' ] ; then
    accel="kvm"
  elif [ `uname -o` = 'Msys' ] ; then
    accel="whpx"
  else
    accel="$tcg"
  fi
  qemu-system-x86_64 -accel $accel -m "${RAM_SIZE}" -smp $CPUS -nographic -serial mon:stdio -k en-us -cdrom ./user-data.img -hda "$HDD_PATH"
fi
