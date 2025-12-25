#!/bin/bash
set -euo pipefail

# Allow overrides for storage paths and Spice port.
DISK_IMAGE=${DISK_IMAGE:-/vm-data/openeuler24.qcow2}
DISK_SIZE=${DISK_SIZE:-1024G}
INSTALL_ISO=${INSTALL_ISO:-/vm-data/openEuler-24.03-LTS-SP2-x86_64-dvd.iso}
SPICE_PORT=${SPICE_PORT:-5900}
SSH_FORWARD_PORT=${SSH_FORWARD_PORT:-2222}

if [[ ! -e "${DISK_IMAGE}" ]]; then
    mkdir -p "$(dirname "${DISK_IMAGE}")"
    echo "Creating disk image ${DISK_IMAGE} (${DISK_SIZE})"
    qemu-img create -f qcow2 "${DISK_IMAGE}" "${DISK_SIZE}"
elif [[ ! -f "${DISK_IMAGE}" ]]; then
    echo "Disk image path exists but is not a regular file: ${DISK_IMAGE}" >&2
    exit 1
fi

/usr/sbin/libvirtd -d || true

QEMU_ARGS=(
    -name guest=openeuler24,debug-threads=on
    -machine pc-q35-8.2,usb=off,vmport=off,dump-guest-core=off,hpet=off,acpi=on
    -accel kvm
    -cpu host,hv-time=on,hv-relaxed=on,hv-vapic=on,hv-spinlocks=0x1fff,hypervisor=on
    -m 4096
    -smp 4,sockets=1,cores=4,threads=1
    -uuid $(uuidgen)
    -rtc base=localtime,driftfix=slew
    -global kvm-pit.lost_tick_policy=delay
    -no-user-config
    -nodefaults
    -boot strict=on,order=cdn
    -drive file="${DISK_IMAGE}",if=virtio,format=qcow2,discard=unmap,cache=none,aio=threads
    -device virtio-balloon-pci
    -device virtio-serial-pci,id=virtio-serial0
    -chardev spicevmc,id=charchannel0,name=vdagent
    -device virtserialport,bus=virtio-serial0.0,nr=1,chardev=charchannel0,id=channel0,name=com.redhat.spice.0
    -device qemu-xhci,id=usb
    -device usb-tablet,bus=usb.0,port=1
    -netdev user,id=net0,hostfwd=tcp::${SSH_FORWARD_PORT}-:22,hostfwd=tcp::3389-:3389
    -device virtio-net-pci,netdev=net0,id=nic0,mac=${MAC_ADDRESS:-$(printf '52:54:00:%02x:%02x:%02x' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))}
    -spice port=${SPICE_PORT},addr=0.0.0.0,disable-ticketing=on,image-compression=off,seamless-migration=on
    -vnc 0.0.0.0:1,password=off
    -audiodev id=audio1,driver=spice
    -device ich9-intel-hda,id=sound0
    -device hda-duplex,id=sound0-codec0,bus=sound0.0,cad=0,audiodev=audio1
    -device qxl-vga,id=video0,max_outputs=1,ram_size=67108864,vram_size=67108864
    -global ICH9-LPC.disable_s3=1
    -global ICH9-LPC.disable_s4=1
    -global ICH9-LPC.noreboot=off
    -watchdog-action reset
    -msg timestamp=on
)

if [[ -f "${INSTALL_ISO}" ]]; then
    QEMU_ARGS+=(
        -drive file="${INSTALL_ISO}",if=none,id=installiso,media=cdrom,readonly=on
        -device ide-cd,bus=ide.1,drive=installiso,id=sata0-0-1
    )
fi

exec /usr/bin/qemu-system-x86_64 "${QEMU_ARGS[@]}"
