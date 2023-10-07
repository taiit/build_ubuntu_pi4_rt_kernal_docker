# build_ubuntu_pi4_rt_kernal_docker


### Run docker build image
``` bash
# Login to docker hub
$ docker login
# Build images
$ docker build -t pirt-image .
# Listing all docker images
$ docker images
# Run container
docker run -t -i pirt-image bash
$ docker container ls

```
### Run build
``` bash
$ docker images
REPOSITORY                                 TAG                        IMAGE ID       CREATED        SIZE
vohuutai27/build_raspi4_ubuntu_rt_kernel   base_built_removed_lttng   421f694b9558   4 months ago   9.05GB
$ docker run -t -i 421f694b9558 bash

# inside docker
docker_user@93690276f814:~/$ cd ~/work/linux_build/linux-raspi/
$ export ARCH=arm64
$ export CROSS_COMPILE=aarch64-linux-gnu-
$ make  LOCALVERSION=-raspi -j `nproc` menuconfig
$ make LOCALVERSION=-raspi -j `nproc` bindeb-pkg
```

The ouput is .deb file
```
docker_user@93690276f814:~/work/linux_build$ ll
total 73192
drwxr-xr-x 1 docker_user docker_user     4096 Oct  7 20:14 ./
drwxr-xr-x 1 docker_user docker_user     4096 Jun  4 11:35 ../
-rw-r--r-- 1 docker_user docker_user   523768 Apr 26 01:44 linux-buildinfo-5.15.0-1029-raspi_5.15.0-1029.31_arm64.deb
-rw-r--r-- 1 docker_user docker_user  8363012 Jun  4 11:53 linux-headers-5.15.98-rt62-raspi_5.15.98-rt62-raspi-1_arm64.deb
-rw-r--r-- 1 docker_user docker_user 64423024 Jun  4 11:55 linux-image-5.15.98-rt62-raspi_5.15.98-rt62-raspi-1_arm64.deb
-rw-r--r-- 1 docker_user docker_user  1226212 Jun  4 11:53 linux-libc-dev_5.15.98-rt62-raspi-1_arm64.deb
```
copy these file to raspberry

install it

### Commit docker (optional)
``` bash
# Hints: docker commit [OPTIONS] CONTAINER [REPOSITORY[:TAG]]

$ docker images
    REPOSITORY   TAG       IMAGE ID       CREATED          SIZE
    pirt-image   latest    38e0f1e7b180   27 minutes ago   6.57GB
$ docker container ls
    CONTAINER ID   IMAGE        COMMAND   CREATED          STATUS          PORTS     NAMES
    0c07d05d3728   pirt-image   "bash"    26 minutes ago   Up 26 minutes             quirky_noether

$ docker commit 0c07d05d3728  vohuutai27/build_raspi4_ubuntu_rt_kernal:base_built_removed_lttng

$ docker push vohuutai27/build_raspi4_ubuntu_rt_kernal:base_built_removed_lttng

``
