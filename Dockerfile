FROM registry.seadee.com.cn:5000/openeuler/openeuler:24.03-lts-sp2

RUN dnf -y update && \
    dnf install -y qemu-kvm libvirt libvirt-daemon libvirt-client virt-install edk2-ovmf && \
    dnf clean all

COPY rpm/*.rpm /tmp/
RUN dnf install -y /tmp/*.rpm && \
    rm -f /tmp/*.rpm

COPY start-kvm.sh /usr/local/bin/start-kvm.sh
RUN chmod +x /usr/local/bin/start-kvm.sh

CMD ["/usr/local/bin/start-kvm.sh"]
