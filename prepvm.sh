#!/bin/bash -e
# images: https://cloud-images.ubuntu.com/jammy/current/

baseDir="$(dirname $0)"
cd "$baseDir"
. ./settings.vars
srcImg="$1"

arch="amd64" # amd64 arm64

if [ ! -s "$srcImg" ] ; then
  if [ -f "$HDD_PATH" ] ; then
    echo "Boot hdd..."
  else
    echo "Error: no hdd found and no cloud img. file provided!" && exit 1
  fi
else

echo "Init hdd..."
rm -fv "$HDD_PATH" ./arch
#qemu-img create -f qcow2 -F qcow2 -b "$srcImg" "$HDD_PATH" "$HDD_SIZE"
cp -fv "$srcImg" "$HDD_PATH"
qemu-img resize "$HDD_PATH" "$HDD_SIZE"

qemu-img info "$HDD_PATH"

if [[ "$(basename $srcImg)" =~ .*arm64.* ]] ; then
  arch="arm64"
else
  arch="amd64"
fi
echo "$arch">./arch

rm -fv user-data.cfg user-data.img
cat > user-data.cfg << EOF
#cloud-config
users:
  - name: $USERNAME
    shell: /bin/bash
    groups: sudo
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
#    plain_text_passwd: asdfgh
    passwd: $(echo $PASSWORD | mkpasswd -m sha-512 -s)
    lock_passwd: false
    ssh_authorized_keys:
      - $(cat ~/.ssh/id_rsa.pub)
EOF

echo "local-hostname: $VM_NAME" > meta-data.cfg

#cloud-init schema --config-file user-data.cfg   # Note: schema check isn't in sync with its actual implementation
cloud-localds user-data.img user-data.cfg meta-data.cfg
rm -fv user-data.cfg meta-data.cfg

fi

arch=$(cat ./arch)
#reset
if [ "$arch" == "arm64" ] ; then
  qemu-system-aarch64 -cpu cortex-a72 -smp $CPUS -M virt -m "${RAM_SIZE}" -nographic -drive if=pflash,format=raw,file=./arm64_linaro/QEMU_EFI.img -hda "$HDD_PATH" -cdrom ./user-data.img -accel tcg,thread=multi,tb-size=256
#-netdev type=tap,id=net0 -serial mon:stdio
else
  qemu-system-x86_64 -accel kvm -cpu host,migratable=off -m "${RAM_SIZE}" -smp $CPUS -nographic -k en-us -cdrom ./user-data.img -hda "$HDD_PATH"
fi
