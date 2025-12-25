# DockerKVM-openeuler24

## 准备工作

### 1. 准备安装 ISO

将 openeuler 24.04 安装镜像 `openEuler-24.03-LTS-SP2-x86_64-dvd.iso` 放在当前目录（`./openEuler-24.03-LTS-SP2-x86_64-dvd.iso`）。该文件会以只读方式映射到容器中并作为虚拟机的启动光驱。

### 2. 准备磁盘镜像

`start-kvm.sh` 会在当前目录未找到 `openeuler24.qcow2` 时自动调用 `qemu-img` 创建 64G 的 QCOW2 磁盘文件（可通过设置 `DISK_SIZE=128G` 等方式调整容量）。如果更喜欢手动创建，也可以直接运行：

```bash
qemu-img create -f qcow2 openeuler24.qcow2 64G
```

如需自定义文件名或路径，可在运行 `docker compose up` 前设置 `DISK_IMAGE=/vm-data/your-disk.qcow2`。

### 3. 启动容器

使用 Docker Compose 启动 KVM 虚拟机：

```bash
docker compose up
```

虚拟机默认会从 ISO 引导，完成 openeuler 安装后即可直接使用该磁盘镜像启动系统。
