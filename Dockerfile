# Run build image
#   docker build    -t pirt-image .
FROM ubuntu:jammy
USER root
ARG DEBIAN_FRONTEND=noninteractive
# setup environment
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

ARG ARCH=arm64
#ARG UNAME_R=5.15.0-1029-rasp
# Get latest from: http://ports.ubuntu.com/pool/main/l/linux-raspi/
ARG UNAME_R=5.15.0-1029-raspi
ARG RT_PATCH
ARG triple=aarch64-linux-gnu
ARG KERNEL_VERSION=5.15.0
#ARG UBUNTU_VERSION=focal
ARG UBUNTU_VERSION=jammy
ARG KERNEL_DIR=linux-raspi

# setup timezone
RUN echo 'Asia/Saigon' > /etc/timezone 
RUN ln -s -f /usr/share/zoneinfo/Asia/Saigon    /etc/localtime

RUN sed -i 's|archive.ubuntu.com|vn.archive.ubuntu.com|g' /etc/apt/sources.list \
    && sed -i 's|ports.ubuntu.com|vn.ports.ubuntu.com|g' /etc/apt/sources.list

# install some tool
RUN apt-get update && apt-get install -q -y \
    tzdata apt-utils lsb-release software-properties-common openssh-client vim

# install extra packages needed for the patch handling
RUN apt-get install -q -y \
    wget curl gzip git time

# setup arch
RUN apt-get install -q -y \
    gcc-${triple} \
    && dpkg --add-architecture ${ARCH} \
    && sed -i 's/deb h/deb [arch=amd64] h/g' /etc/apt/sources.list

# add-apt-repository the content is in /etc/apt/sources.list.d
RUN  add-apt-repository -n -s "deb [arch=$ARCH] http://vn.ports.ubuntu.com/ubuntu-ports/ $(lsb_release -s -c) main universe restricted"
RUN  add-apt-repository -n -s "deb [arch=$ARCH] http://vn.ports.ubuntu.com/ubuntu-ports $(lsb_release -s -c)-updates main universe restricted"

# install build deps
RUN apt-get update && apt-get build-dep -q -y linux \
    && apt-get install -q -y \
    libncurses-dev flex bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf fakeroot

RUN apt-get install -q -y build-essential cmake vim-nox python3-dev

#RUN rm -rf /var/lib/apt/lists/*
# do we need remove all content in /var/lib/apt/lists/  ??
# Storage area for state information for each package resource
# specified in sources.list(5) Configuration Item: Dir::State::Lists.

# setup user name: docker_user
RUN apt-get install -q -y sudo
RUN useradd -m -d /home/docker_user -s /bin/bash docker_user
RUN gpasswd -a docker_user sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN echo 'docker_user\ndocker_user\n' | passwd docker_user

# switch to docker_user
USER docker_user

RUN sed -i 's,#force_color_prompt,force_color_prompt,'  /home/docker_user/.bashrc
RUN echo "cd ~" >>  ~/.bashrc
RUN echo "export CROSS_COMPILE=${triple}-" >>  ~/.bashrc
RUN echo "export ARCH=arm64" >>  ~/.bashrc

# Setup user tool
# VIM Vundle, Vim plugin manager.
RUN git clone https://github.com/VundleVim/Vundle.vim.git   /home/docker_user/.vim/bundle/Vundle.vim
COPY ./user_tool_cfg/vimrc.cfg    /home/docker_user/.vimrc
RUN vim +PluginInstall +qall
RUN python3 /home/docker_user/.vim/bundle/youcompleteme/install.py --clang-completer

# start rpi kernel buidl


#0. Init
RUN mkdir -p                /home/docker_user/work/linux_build

# 1. install linux sources from git
RUN git clone -b master --depth 1 --single-branch --progress --verbose \
    https://git.launchpad.net/~ubuntu-kernel/ubuntu/+source/linux-raspi/+git/${UBUNTU_VERSION}  /home/docker_user/work/linux_build/linux-raspi


#2. find the latest UNAME_R and store it locally for the later usage
# if $UNAME_R is set via --build-arg, take it
RUN   if test -z $UNAME_R; then UNAME_R=`curl -s http://ports.ubuntu.com/pool/main/l/linux-raspi/ | grep linux-buildinfo | grep -o -P '(?<=<a href=").*(?=">l)' | grep ${ARCH} | grep ${KERNEL_VERSION} | sort | tail -n 1 | cut -d '-' -f 3-4`-raspi; fi \
    && echo "Using kernel: $UNAME_R"    \
    && echo $UNAME_R > /home/docker_user/work/linux_build/pi_kernel.txt


#3. checkout necessary tag
RUN  cd /home/docker_user/work/linux_build/linux-raspi \
    && git fetch --tag \
    && git tag -l *`cat /home/docker_user/work/linux_build/pi_kernel.txt | cut -d '-' -f 2`* | sort -V | tail -1 > /home/docker_user/work/linux_build/pi_kernel_tag.txt \
    && git checkout `cat /home/docker_user/work/linux_build/pi_kernel_tag.txt`

COPY ./getpatch.sh         /home/docker_user/work/
COPY ./build_rt_bash.sh    /home/docker_user/work/
COPY ./.config-fragment    /home/docker_user/work/

#4. install buildinfo to retieve `raspi` kernel config
RUN  cd /home/docker_user/work/linux_build \
    && wget http://ports.ubuntu.com/pool/main/l/linux-raspi/linux-buildinfo-${KERNEL_VERSION}-`cat /home/docker_user/work/linux_build/pi_kernel.txt | cut -d '-' -f 2`-raspi_${KERNEL_VERSION}-`cat /home/docker_user/work/linux_build/pi_kernel_tag.txt | cut -d '-' -f 4`_${ARCH}.deb \
    && dpkg -X *.deb   /home/docker_user/work/linux_build

#5.  get the nearest RT patch to the kernel SUBLEVEL
# if $RT_PATCH is set via --build-arg, take it
RUN cd /home/docker_user/work/linux_build/linux-raspi \
    && if test -z $RT_PATCH; then /home/docker_user/work/getpatch.sh `make kernelversion` > /home/docker_user/work/linux_build/rt_patch.txt ; else  echo $RT_PATCH > /home/docker_user/work/linux_build/rt_patch.txt; fi

    # download and unzip RT patch
RUN cd /home/docker_user/work/linux_build \
    && wget http://cdn.kernel.org/pub/linux/kernel/projects/rt/`echo ${KERNEL_VERSION} | cut -d '.' -f 1-2`/older/patch-`cat /home/docker_user/work/linux_build/rt_patch.txt`.patch.gz  \
    && gunzip patch-`cat /home/docker_user/work/linux_build/rt_patch.txt`.patch.gz

# patch kernel, do not fail if some patches are skipped
RUN cd /home/docker_user/work/linux_build/linux-raspi \
    && OUT="$(patch -p1 --forward < ../patch-`cat /home/docker_user/work/linux_build/rt_patch.txt`.patch)" || echo "${OUT}" | grep "Skipping patch" -q || (echo "$OUT" && false);

# setup build environment
RUN cd /home/docker_user/work/linux_build/linux-raspi \
    && export $(dpkg-architecture -a${ARCH}) \
    && export CROSS_COMPILE=${triple}- \
    && fakeroot debian/rules clean \
    && LANG=C fakeroot debian/rules printenv

# config RT kernel and merge config fragment
#. e.g: /home/docker_user/work/linux_build/usr/lib/linux/5.15.0-1029-raspi/config
RUN cp  /home/docker_user/work/linux_build/usr/lib/linux/`cat /home/docker_user/work/linux_build/pi_kernel.txt`/config  /home/docker_user/work/linux_build/linux-raspi/.config

# /home/docker_user/work/.config-fragment (user seting)
RUN cd /home/docker_user/work/linux_build/linux-raspi \
    && ARCH=${ARCH} CROSS_COMPILE=${triple}-   ./scripts/kconfig/merge_config.sh    .config /home/docker_user/work/.config-fragment

RUN cd /home/docker_user/work/linux_build/linux-raspi \
    && fakeroot debian/rules clean
