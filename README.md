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