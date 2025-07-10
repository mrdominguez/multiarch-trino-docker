# MultiArch-Trino-Docker

Build a multi-architecture Trino Docker image (amd64, arm64).

![Alt text](MultiArch-Trino-Docker.png?raw=true)

This project is based on the open source code, which does not provide a way to build a multi-platform image: https://github.com/trinodb/trino/tree/master/core/docker

Trino needs a 64-bit version of Java 24, with a minimum required version of 24.0.1. The recommended JDK distribution is Eclipse Temurin OpenJDK (Adoptium).

## Details about my environment
#### OS: Ubuntu 24.04 on WSL2 (Windows 11)
```
core@core-10920x:~$ wsl.exe --version
WSL version: 2.5.7.0
Kernel version: 6.6.87.1-1
WSLg version: 1.0.66
MSRDC version: 1.2.6074
Direct3D version: 1.611.1-81528511
DXCore version: 10.0.26100.1-240331-1435.ge-release
Windows version: 10.0.26100.3323
```
```
core@core-10920x:~$ uname -i -r -s
Linux 6.6.87.1-microsoft-standard-WSL2 x86_64
```
```
core@core-10920x:~$ cat /etc/lsb-release
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=24.04
DISTRIB_CODENAME=noble
DISTRIB_DESCRIPTION="Ubuntu 24.04.2 LTS"
```

#### Docker components
```
core@core-10920x:~$ docker version
Client:
 Version:           27.5.1
 API version:       1.47
 Go version:        go1.22.2
 Git commit:        27.5.1-0ubuntu3~24.04.2
 Built:             Mon Jun  2 11:51:53 2025
 OS/Arch:           linux/amd64
 Context:           default

Server:
 Engine:
  Version:          27.5.1
  API version:      1.47 (minimum version 1.24)
  Go version:       go1.22.2
  Git commit:       27.5.1-0ubuntu3~24.04.2
  Built:            Mon Jun  2 11:51:53 2025
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          1.7.27
  GitCommit:
 runc:
  Version:          1.2.5-0ubuntu1~24.04.1
  GitCommit:
 docker-init:
  Version:          0.19.0
  GitCommit:
```

#### Buildx CLI plugin
```
core@core-10920x:~$ sudo apt install -y docker-buildx
...
core@core-10920x:~$ docker buildx version
github.com/docker/buildx 0.20.1 0.20.1-0ubuntu1~24.04.2
```
```
core@core-10920x:~$ docker buildx ls
NAME/NODE     DRIVER/ENDPOINT   STATUS    BUILDKIT   PLATFORMS
default*      docker
 \_ default    \_ default       running   v0.18.2    linux/amd64 (+4), linux/386
core@core-10920x:~$ docker buildx inspect
Name:   default
Driver: docker

Nodes:
Name:             default
Endpoint:         default
Status:           running
BuildKit version: v0.18.2
Platforms:        linux/amd64, linux/amd64/v2, linux/amd64/v3, linux/amd64/v4, linux/386
Labels:
 org.mobyproject.buildkit.worker.moby.host-gateway-ip: 172.17.0.1
```

## Usage
```
core@core-10920x:~/multiarch-trino-docker$ ./build.sh -h
Usage: ./build.sh [-h] [-a <ARCHITECTURES>] [-r <VERSION>] [-m]
Builds the Trino Docker image

-h       Display help
-a       Build the specified comma-separated architectures, defaults to amd64
-p       Use the specified server package (artifact id), for example: trino-server (default), trino-server-core
-t       Image tag name, defaults to trino
-r       Build the specified Trino release version, downloads all required artifacts
-m       Build multi-platform image (amd64 <> arm64)
-x       Skip image tests
```

## Build image for `amd64`
```
core@core-10920x:~/multiarch-trino-docker$ ./build.sh
Downloading server and client artifacts for release version 476
Preparing the image build context directory
Downloading temurin/jdk-24.0.1+9
\_ Downloading JDK 24 for amd64
Building the image for amd64 with Java temurin/jdk-24.0.1+9
[+] Building 30.3s (25/25) FINISHED                                     docker:default
...
Cleaning up the build context directory
Testing built images
Validating trino:476-amd64 on platform linux/amd64...
0e31be751d7f3ed45ae5b5a2bb6a4cdd181215033302a52724f33298f9ec4d12
Validated trino:476-amd64 on platform linux/amd64
Built [trino:476-amd64] sha256:a5974a4a789777a7ffd7692c7527ea44fef4a61d62731085238ecf285c60be43
```
```
core@core-10920x:~$ docker image ls
REPOSITORY   TAG         IMAGE ID       CREATED         SIZE
trino        476-amd64   a5974a4a7897   5 minutes ago   1.23GB
```

## Build image for `arm64`
#### Possible issue: `exec format error`
```
core@core-10920x:~/multiarch-trino-docker$ ./build.sh -a arm64
...
0.251 exec /bin/sh: exec format error
------
Dockerfile:22
--------------------
...
ERROR: failed to solve: process "..." did not complete successfully: exit code: 255
```

#### Enable multi-architecture container execution
```
core@core-10920x:~$ docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
Unable to find image 'multiarch/qemu-user-static:latest' locally
latest: Pulling from multiarch/qemu-user-static
205dae5015e7: Pull complete
816739e52091: Pull complete
30abb83a18eb: Pull complete
0657daef200b: Pull complete
30c9c93f40b9: Pull complete
Digest: sha256:fe60359c92e86a43cc87b3d906006245f77bfc0565676b80004cc666e4feb9f0
Status: Downloaded newer image for multiarch/qemu-user-static:latest
Setting /usr/bin/qemu-alpha-static as binfmt interpreter for alpha
Setting /usr/bin/qemu-arm-static as binfmt interpreter for arm
Setting /usr/bin/qemu-armeb-static as binfmt interpreter for armeb
Setting /usr/bin/qemu-sparc-static as binfmt interpreter for sparc
Setting /usr/bin/qemu-sparc32plus-static as binfmt interpreter for sparc32plus
Setting /usr/bin/qemu-sparc64-static as binfmt interpreter for sparc64
Setting /usr/bin/qemu-ppc-static as binfmt interpreter for ppc
Setting /usr/bin/qemu-ppc64-static as binfmt interpreter for ppc64
Setting /usr/bin/qemu-ppc64le-static as binfmt interpreter for ppc64le
Setting /usr/bin/qemu-m68k-static as binfmt interpreter for m68k
Setting /usr/bin/qemu-mips-static as binfmt interpreter for mips
Setting /usr/bin/qemu-mipsel-static as binfmt interpreter for mipsel
Setting /usr/bin/qemu-mipsn32-static as binfmt interpreter for mipsn32
Setting /usr/bin/qemu-mipsn32el-static as binfmt interpreter for mipsn32el
Setting /usr/bin/qemu-mips64-static as binfmt interpreter for mips64
Setting /usr/bin/qemu-mips64el-static as binfmt interpreter for mips64el
Setting /usr/bin/qemu-sh4-static as binfmt interpreter for sh4
Setting /usr/bin/qemu-sh4eb-static as binfmt interpreter for sh4eb
Setting /usr/bin/qemu-s390x-static as binfmt interpreter for s390x
Setting /usr/bin/qemu-aarch64-static as binfmt interpreter for aarch64
Setting /usr/bin/qemu-aarch64_be-static as binfmt interpreter for aarch64_be
Setting /usr/bin/qemu-hppa-static as binfmt interpreter for hppa
Setting /usr/bin/qemu-riscv32-static as binfmt interpreter for riscv32
Setting /usr/bin/qemu-riscv64-static as binfmt interpreter for riscv64
Setting /usr/bin/qemu-xtensa-static as binfmt interpreter for xtensa
Setting /usr/bin/qemu-xtensaeb-static as binfmt interpreter for xtensaeb
Setting /usr/bin/qemu-microblaze-static as binfmt interpreter for microblaze
Setting /usr/bin/qemu-microblazeel-static as binfmt interpreter for microblazeel
Setting /usr/bin/qemu-or1k-static as binfmt interpreter for or1k
Setting /usr/bin/qemu-hexagon-static as binfmt interpreter for hexagon
```
Make sure that the builder instance supports `linux/arm64`:
```
core@core-10920x:~$ docker buildx ls
NAME/NODE     DRIVER/ENDPOINT   STATUS    BUILDKIT   PLATFORMS
default*      docker
 \_ default    \_ default       running   v0.18.2    linux/amd64 (+4), linux/arm64, linux/arm (+2), linux/ppc64le, (4 more)
core@core-10920x:~$ docker buildx inspect
Name:          default
Driver:        docker
Last Activity: 2025-07-09 19:03:59 +0000 UTC

Nodes:
Name:             default
Endpoint:         default
Status:           running
BuildKit version: v0.18.2
Platforms:        linux/amd64, linux/amd64/v2, linux/amd64/v3, linux/amd64/v4, linux/386, linux/arm64, linux/riscv64, linux/ppc64, linux/ppc64le, linux/s390x, linux/arm/v7, linux/arm/v6
Labels:
 org.mobyproject.buildkit.worker.moby.host-gateway-ip: 172.17.0.1
```
Verify QEMU setup:
```
core@core-10920x:~$ cat /proc/sys/fs/binfmt_misc/qemu-aarch64
enabled
interpreter /usr/bin/qemu-aarch64-static
flags: F
offset 0
magic 7f454c460201010000000000000000000200b700
mask ffffffffffffff00fffffffffffffffffeffffff
```

```
core@core-10920x:~/multiarch-trino-docker$ ./build.sh -a arm64
Downloading server and client artifacts for release version 476
Preparing the image build context directory
Downloading temurin/jdk-24.0.1+9
\_ Downloading JDK 24 for arm64
Building the image for arm64 with Java temurin/jdk-24.0.1+9
[+] Building 84.6s (25/25) FINISHED                                     docker:default
...
Cleaning up the build context directory
Testing built images
Validating trino:476-arm64 on platform linux/arm64...
5502746e9c27e7dea81dc7049ed34f3f92494d509a3efc2a11a2d9a33edbe204
Validated trino:476-arm64 on platform linux/arm64
Built [trino:476-arm64] sha256:f8bd5e5f59ff2537586d6fadb9dc7493c5b482d42255e27adc04629d4c859f49
```
```
core@core-10920x:~$ docker image ls
REPOSITORY                   TAG         IMAGE ID       CREATED          SIZE
trino                        476-arm64   f8bd5e5f59ff   5 minutes ago    1.24GB
trino                        476-amd64   a5974a4a7897   33 minutes ago   1.23GB
multiarch/qemu-user-static   latest      3539aaa87393   2 years ago      305MB
```

## Build multi-platform image for `amd64`/`arm64`
#### Possible issue: `docker exporter does not currently support exporting manifest lists`
```
core@core-10920x:~/multiarch-trino-docker$ ./build.sh -m
...                                                                                                                                       docker:default
ERROR: docker exporter does not currently support exporting manifest lists
```

#### Enable containerd image store
https://docs.docker.com/engine/storage/containerd/#enable-containerd-image-store-on-docker-engine

> Switching to containerd snapshotters causes you to temporarily lose images and containers created using the classic storage drivers. Those resources still exist on your filesystem, and you can retrieve them by turning off the containerd snapshotters feature.

```
core@core-10920x:~$ docker info -f '{{ .DriverStatus }}'
[[Backing Filesystem extfs] [Supports d_type true] [Using metacopy false] [Native Overlay Diff true] [userxattr false]]
```
```
core@core-10920x:~$ cat /etc/docker/daemon.json
{
  "features": {
    "containerd-snapshotter": true
  }
}
core@core-10920x:~$ sudo systemctl restart docker
core@core-10920x:~$ docker info -f '{{ .DriverStatus }}'
[[driver-type io.containerd.snapshotter.v1]]
```

```
core@core-10920x:~/multiarch-trino-docker$ ./build.sh -m
Downloading server and client artifacts for release version 476
Preparing the image build context directory
Downloading temurin/jdk-24.0.1+9
\_ Downloading JDK 24 for amd64
\_ Downloading JDK 24 for arm64
Building multi-platform image with Java 24.0.1_9
[+] Building 125.0s (44/44) FINISHED                                    docker:default
...
Cleaning up the build context directory
Testing built images
Validating trino:476 on platform linux/amd64...
e2630a5c22d7a318c8a451b67ae11a986e146f765b573938fb56eeaaca04e385
Validated trino:476 on platform linux/amd64
Built [trino:476] sha256:e317e4560abb2e11b36e2e2d58b9c4a625bcd95e09e78fd355d3a77f63222bd5
```
```
core@core-10920x:~$ docker image ls
REPOSITORY   TAG       IMAGE ID       CREATED         SIZE
trino        476       e317e4560abb   7 minutes ago   3.08GB
```
```
core@core-10920x:~$ docker run -it --rm --platform linux/amd64 trino:476 arch
x86_64
core@core-10920x:~$ docker run -it --rm --platform linux/arm64 trino:476 arch
aarch64
```
