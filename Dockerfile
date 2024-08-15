# syntax=docker/dockerfile:1
# lightweight, cross-platform, cpu-only dockerfile for demoing MWA software stack on desktops
# amd64, arm32v7, arm64v8
# ref: https://docs.docker.com/build/building/multi-platform/
ARG BASE_IMG="ubuntu:20.04"

FROM ${BASE_IMG} as base

ENV DEBIAN_FRONTEND="noninteractive"
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    casacore-data \
    casacore-dev \
    clang \
    cmake \
    curl \
    cython3 \
    fontconfig \
    g++ \
    git \
    ipython3 \
    jq \
    lcov \
    libatlas3-base \
    libblas-dev \
    libboost-date-time-dev \
    libboost-filesystem-dev \
    libboost-program-options-dev \
    libboost-system-dev \
    libboost-test-dev \
    libcfitsio-dev \
    liberfa-dev \
    libexpat1-dev \
    libfftw3-dev \
    libfontconfig-dev \
    libfreetype-dev \
    libgsl-dev \
    libgtkmm-3.0-dev \
    libhdf5-dev \
    liblapack-dev \
    liblua5.3-dev \
    libopenmpi-dev \
    libpng-dev \
    libpython3-dev \
    libssl-dev \
    libxml2-dev \
    pkg-config \
    procps \
    python3 \
    python3-dev \
    python3-pip \
    tzdata \
    unzip \
    wget \
    zip \
    && \
    apt-get clean all && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    apt-get -y autoremove

# use python3 as the default python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

# install python prerequisites
RUN python -m pip install --upgrade pip && \
    python -m pip install \
    kneed \
    matplotlib \
    maturin[patchelf] \
    numpy>=1.21.0 \
    pandas \
    pip \
    pyuvdata \
    pyvo \
    tabulate \
    seaborn \
    ;

# install ssins
ARG SSINS_BRANCH=master
RUN git clone --depth 1 --branch=${SSINS_BRANCH} https://github.com/mwilensky768/SSINS.git /ssins && \
    python -m pip install /ssins && \
    rm -rf /ssins

# install mwa_qa
ARG MWAQA_BRANCH=dev
RUN git clone --depth 1 --branch=${MWAQA_BRANCH} https://github.com/d3v-null/mwa_qa.git /mwa_qa && \
    python -m pip install /mwa_qa && \
    rm -rf /mwa_qa

# Get Rust
ARG RUST_VERSION=1.75
ENV RUSTUP_HOME=/opt/rust CARGO_HOME=/opt/cargo PATH=/opt/cargo/bin:$PATH
RUN mkdir -m755 $RUSTUP_HOME $CARGO_HOME && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    --profile=minimal \
    --default-toolchain=${RUST_VERSION}-$(uname -m)-unknown-linux-gnu

ARG MWALIB_BRANCH=v1.4.0
RUN git clone --depth 1 --branch=${MWALIB_BRANCH} https://github.com/MWATelescope/mwalib.git /mwalib && \
    cd /mwalib && \
    maturin build --release --features=python && \
    python -m pip install $(ls -1 target/wheels/*.whl | tail -n 1) && \
    cd / && \
    rm -rf /mwalib ${CARGO_HOME}/registry

ARG EVERYBEAM_BRANCH=v0.5.2
RUN git clone --depth 1 --branch=${EVERYBEAM_BRANCH} --recurse-submodules https://git.astron.nl/RD/EveryBeam.git /EveryBeam && \
    cd /EveryBeam && \
    git submodule update --init --recursive && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make install -j`nproc` && \
    cd / && \
    rm -rf /EveryBeam

ARG IDG_BRANCH=1.2.0
RUN git clone --depth 1 --branch=${IDG_BRANCH} https://git.astron.nl/RD/idg.git /idg && \
    cd /idg && \
    git submodule update --init --recursive && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make install -j`nproc` && \
    cd / && \
    rm -rf /idg

ARG WSCLEAN_BRANCH=v3.4
RUN git clone --depth 1 --branch=${WSCLEAN_BRANCH} https://gitlab.com/aroffringa/wsclean.git /wsclean && \
    cd /wsclean && \
    git submodule update --init --recursive && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make install -j`nproc` && \
    cd / && \
    rm -rf /wsclean

ARG GIANTSQUID_BRANCH=v1.0.3
RUN git clone --depth 1 --branch=${GIANTSQUID_BRANCH} https://github.com/MWATelescope/giant-squid.git /giant-squid && \
    cd /giant-squid && \
    cargo install --path . --locked && \
    cd / && \
    rm -rf /giant-squid ${CARGO_HOME}/registry

# download latest Leap_Second.dat file
RUN python -c "from astropy.time import Time; print(Time.now().gps)"

ARG AOFLAGGER_BRANCH=v3.4.0
RUN git clone --depth 1 --branch=${AOFLAGGER_BRANCH} --recurse-submodules https://gitlab.com/aroffringa/aoflagger.git /aoflagger && \
    cd /aoflagger && \
    mkdir build && \
    cd build && \
    cmake \
    -DENABLE_GUI=OFF \
    -DPORTABLE=ON \
    .. && \
    make install -j1 && \
    ldconfig && \
    cd / && \
    rm -rf /aoflagger

ARG BIRLI_BRANCH=main
RUN git clone --depth 1 --branch=${BIRLI_BRANCH} https://github.com/MWATelescope/Birli.git /Birli && \
    cd /Birli && \
    cargo install --path . --locked && \
    cd / && \
    rm -rf /Birli ${CARGO_HOME}/registry

ARG HYPERDRIVE_BRANCH=marlu0.13
RUN git clone --depth 1 --branch=${HYPERDRIVE_BRANCH} https://github.com/MWATelescope/mwa_hyperdrive.git /hyperdrive && \
    cd /hyperdrive && \
    cargo install --path . --locked && \
    cd / && \
    rm -rf /hyperdrive ${CARGO_HOME}/registry
