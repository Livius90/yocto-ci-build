#docker build . -t yocto-ci-build
#docker run -it --rm -v${PWD}:/home/build/yocto yocto-ci-build
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND noninteractive
ENV TERM=linux

RUN apt-get update --fix-missing && apt-get -y upgrade

# Install apt-utils before anything else
RUN apt-get install apt-utils software-properties-common -y

RUN add-apt-repository universe && apt-get update --fix-missing && apt-get -y upgrade

# Required Packages for the Host Development System
# http://www.yoctoproject.org/docs/latest/mega-manual/mega-manual.html#required-packages-for-the-host-development-system
RUN apt-get install -y gawk wget git-core diffstat unzip texinfo gcc-multilib g++-multilib gcc-multilib g++-multilib \
     build-essential chrpath socat cpio python3 python3-pip python3-pexpect \
     apt-utils tmux xz-utils debianutils iputils-ping libncurses5-dev vim \
     liblz4-tool zstd zstd iproute2 iptables file \
     python3-git python3-jinja2 \
     libsdl1.2-dev xterm python3-subunit mesa-common-dev

# Install kas
RUN pip3 install kas

# Pull in gcc-8 as it's been removed from 22.04
RUN wget http://mirrors.kernel.org/ubuntu/pool/universe/g/gcc-8/gcc-8_8.4.0-3ubuntu2_amd64.deb
RUN wget http://mirrors.kernel.org/ubuntu/pool/universe/g/gcc-8/gcc-8-base_8.4.0-3ubuntu2_amd64.deb
RUN wget http://mirrors.kernel.org/ubuntu/pool/universe/g/gcc-8/libgcc-8-dev_8.4.0-3ubuntu2_amd64.deb
RUN wget http://mirrors.kernel.org/ubuntu/pool/universe/g/gcc-8/cpp-8_8.4.0-3ubuntu2_amd64.deb
RUN wget http://mirrors.kernel.org/ubuntu/pool/universe/g/gcc-8/libmpx2_8.4.0-3ubuntu2_amd64.deb
RUN wget http://mirrors.kernel.org/ubuntu/pool/main/i/isl/libisl22_0.22.1-1_amd64.deb
RUN apt install -y ./libisl22_0.22.1-1_amd64.deb ./libmpx2_8.4.0-3ubuntu2_amd64.deb ./cpp-8_8.4.0-3ubuntu2_amd64.deb ./libgcc-8-dev_8.4.0-3ubuntu2_amd64.deb ./gcc-8-base_8.4.0-3ubuntu2_amd64.deb ./gcc-8_8.4.0-3ubuntu2_amd64.deb

# libc6-dev files are also missing
RUN apt install -y libc6-dev

# Additional recommended packages
RUN apt-get install -y coreutils python2.7 libsdl1.2-dev xterm libssl-dev libelf-dev \
     ca-certificates whiptail # openjdk-11-jre 

# Additional host packages required by poky/scripts/wic
RUN apt-get install -y curl dosfstools mtools parted syslinux tree zip

RUN apt-get install -y nano

RUN update-ca-certificates

# Create a non-root user that will perform the actual build
RUN id github 2>/dev/null || useradd --uid 1000 --create-home github
RUN apt-get install -y sudo
RUN echo "github ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers
RUN adduser github kvm

# Fix error "Please use a locale setting which supports utf-8."
# See https://wiki.yoctoproject.org/wiki/TipsAndTricks/ResolvingLocaleIssues
RUN apt-get install -y locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
        echo 'LANG="en_US.UTF-8"'>/etc/default/locale && \
        dpkg-reconfigure --frontend=noninteractive locales && \
        update-locale LANG=en_US.UTF-8


RUN update-alternatives --install /bin/sh sh /bin/bash 100

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

USER github
WORKDIR /home/github

# Setup a default git user for clone/checkout
RUN git config --global user.email "yocto@github.cc"
RUN git config --global user.name "yocto"
RUN git config --global http.postBuffer 20k
RUN git config --global url."https://github.com/".insteadOf git://github.com/

CMD "/bin/bash"

#EOF
