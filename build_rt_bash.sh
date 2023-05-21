#!/bin/bash

menuconfig() {
    make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- LOCALVERSION=-raspi -j `nproc` menuconfig
}

build_deb() {
    make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- LOCALVERSION=-raspi -j `nproc` bindeb-pkg
}


docker_commit() {
    docker ps # docker container ls
    #docker commit [OPTIONS] CONTAINER [REPOSITORY[:TAG]]
   
    # taihv@RZ9:~$ docker images
    # REPOSITORY   TAG       IMAGE ID       CREATED          SIZE
    # pirt-image   latest    38e0f1e7b180   27 minutes ago   6.57GB
    # taihv@RZ9:~$ docker container ls
    # CONTAINER ID   IMAGE        COMMAND   CREATED          STATUS          PORTS     NAMES
    # 0c07d05d3728   pirt-image   "bash"    26 minutes ago   Up 26 minutes             quirky_noether
    # taihv@RZ9:~$

    docker commit 0c07d05d3728  vohuutai27/build_raspi4_ubuntu_rt_kernal:base_built_removed_lttng

    docker push vohuutai27/build_raspi4_ubuntu_rt_kernal:base_built_removed_lttng

    # taihv@RZ9:~$ docker images
    # REPOSITORY                                 TAG                        IMAGE ID       CREATED          SIZE
    # vohuutai27/build_raspi4_ubuntu_rt_kernal   base_built_removed_lttng   5184795331fa   25 seconds ago   9.03GB
    # pirt-image                                 latest                     38e0f1e7b180   32 minutes ago   6.57GB

}