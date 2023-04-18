FROM gcc:9
# this image ships with: GLIBC 2.28, GLIBCXX_3.4.28

ARG FAUST_VERSION="2.54.9"
ARG HISE_VERSION="3.0.3"
ARG IPP_VERSION="2021.7.0"

ARG HISE_REPOSITORY="https://github.com/christophhart/HISE"

LABEL com.github.spezifisch.hise-builder.version.faust=$FAUST_VERSION
LABEL com.github.spezifisch.hise-builder.version.hise=$HISE_VERSION
LABEL com.github.spezifisch.hise-builder.version.ipp=$IPP_VERSION

RUN if [ -z "$HISE_REPOSITORY" ]; then exit 1; fi

# intel IPP sources
# see: https://www.intel.com/content/www/us/en/docs/oneapi/installation-guide-linux/2023-0/apt.html
RUN wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | gpg --dearmor > /usr/share/keyrings/oneapi-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" > /etc/apt/sources.list.d/oneAPI.list

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get -y install \
# HISE deps
    build-essential \
    clang-11 \
    freeglut3-dev \
    libasound2-dev \
    libcurl4-gnutls-dev \
    libfftw3-dev \
    libfreetype6-dev \
    libgtk-3-dev \
    libjack-jackd2-dev \
    libwebkit2gtk-4.0 \
    libx11-dev \
    libxcomposite-dev \
    libxcursor-dev \
    libxinerama-dev \
    libxrandr-dev \
    llvm-11 \
    make \
    mesa-common-dev \
# IPP support for HISE
    intel-oneapi-ipp-devel-$IPP_VERSION \
# fake X server for HISE
    xvfb \
# faust deps
    cmake \
    && rm -rf /var/lib/apt/lists/*

# print lib versions
RUN echo "Libraries:" \
    && /lib/x86_64-linux-gnu/libc.so.6 --version | head -1 \
    && readelf -sV /usr/local/lib64/libstdc++.so.6 | sed -n 's/.*@@//p' | sort -u -V | tail -1

# this is needed so llvm-config can be found
ENV PATH="/usr/lib/llvm-11/bin:$PATH"

# build faust
# see: https://github.com/grame-cncm/faust/wiki/BuildingSimple
WORKDIR /root
RUN git clone https://github.com/grame-cncm/faust.git -b "$FAUST_VERSION" --depth 1
WORKDIR /root/faust
RUN make all install

# add ipp and faust libs (/usr/local/lib is already present) to library path
RUN echo /opt/intel/oneapi/ipp/latest/lib/intel64 > /etc/ld.so.conf.d/ipp.conf \
    && ldconfig

# put ipp where HISE hardcodedly expects it
RUN mkdir -p /opt/intel/ipp \
    && ln -s /opt/intel/oneapi/ipp/latest/include /opt/intel/ipp/include \
    && ln -s /opt/intel/oneapi/ipp/latest/lib/intel64 /opt/intel/ipp/lib \
    && ln -s . /opt/intel/ipp/lib/intel64

# build HISE
# see: https://github.com/christophhart/HISE#linux
WORKDIR /root
RUN git clone "$HISE_REPOSITORY" -b "$HISE_VERSION" --depth 1
RUN unzip HISE/tools/SDK/sdk.zip -d HISE/tools/SDK/

ARG juceproject="config/HISE Standalone.jucer"
COPY ${juceproject} /root/HISE/projects/standalone/
COPY config/AppConfig.h /root/HISE/projects/standalone/JuceLibraryCode/
RUN ./HISE/tools/projucer/Projucer --resave HISE/projects/standalone/HISE\ Standalone.jucer

WORKDIR /root/HISE/projects/standalone/Builds/LinuxMakefile
RUN make CONFIG=Release -j$(nproc)

# add "HISE Standalone" to path
ENV PATH="/root/HISE/projects/standalone/Builds/LinuxMakefile/build:$PATH"

WORKDIR /root

# ready to go. use this image as base image, add your own plugin code and run HISE to build it

