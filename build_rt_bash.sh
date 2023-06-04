#!/bin/bash

menuconfig() {
    # this variable is in .bashrc
    # ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-
    make  LOCALVERSION=-raspi -j `nproc` menuconfig
}

build_deb() {
    # this variable is in .bashrc
    # ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-
    make LOCALVERSION=-raspi -j `nproc` bindeb-pkg
}

main() {
    pushd /home/docker_user/work/linux_build/linux-raspi
        build_deb $@
    popd
    echo "DONE"
}

main $@
#EOF