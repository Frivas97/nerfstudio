FROM nvidia/cuda:11.3.0-devel
SHELL [ "/bin/bash", "--login", "-c" ]

# set timezone
ENV TZ=Europe/Lisbon
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Prevent stop building ubuntu at time zone selection.  
#ENV DEBIAN_FRONTEND=noninteractive

RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/3bf863cc.pub

RUN apt -y update &&\
    apt install -y net-tools &&\
    apt -y install git wget &&\
    apt -y update &&\ 
    apt clean &&\
    apt autoremove 

# Prepare and empty machine for building
RUN apt-get update && apt-get install -y \
    git \
    cmake \
    build-essential \
    libboost-program-options-dev \
    libboost-filesystem-dev \
    libboost-graph-dev \
    libboost-system-dev \
    libboost-test-dev \
    libeigen3-dev \
    libsuitesparse-dev \
    libfreeimage-dev \
    libmetis-dev \
    libgoogle-glog-dev \
    libgflags-dev \
    libglew-dev \
    qtbase5-dev \
    libqt5opengl5-dev \
    libcgal-dev \
    wget \
    libopenexr-dev \
    bzip2 \
    zlib1g-dev \
    libxmu-dev \
    libxi-dev \
    libxxf86vm-dev \
    libfontconfig1 \
    libxrender1 \
    libgl1-mesa-glx \
    xz-utils \
    python3-pip

RUN apt remove -y cmake
RUN pip install cmake --upgrade \
    numpy

# Build and install ceres solver
RUN apt-get -y install \
    libatlas-base-dev \
    libsuitesparse-dev \
    libsqlite3-dev

ARG CERES_SOLVER_VERSION=2.1.0

RUN git clone https://github.com/ceres-solver/ceres-solver.git --tag ${CERES_SOLVER_VERSION}
#SHELL [ "/bin/bash", "--login", "-c" ]
RUN cd ${CERES_SOLVER_VERSION} &&\
    mkdir build &&\
    cd build &&\
    cmake .. -DBUILD_TESTING=OFF -DBUILD_EXAMPLES=OFF &&\
    make -j4 &&\
    make install

#Colmap
ENV COMMIT=3.8
RUN git clone https://github.com/lz4/lz4.git && \
    cd lz4 && \
    make && \
    make install

RUN git clone https://github.com/flann-lib/flann.git && \
    cd flann && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make install

RUN apt-get update && apt-get install -y\
    git \
    cmake \
    ninja-build \
    build-essential \
    libboost-program-options-dev \
    libboost-filesystem-dev \
    libboost-graph-dev \
    libboost-system-dev \
    libboost-test-dev \
    libeigen3-dev \
    libflann-dev \
    libfreeimage-dev \
    libmetis-dev \
    libgoogle-glog-dev \
    libgflags-dev \
    libsqlite3-dev \
    libglew-dev \
    qtbase5-dev \
    libqt5opengl5-dev \
    libcgal-dev \
    libceres-dev

RUN git clone https://github.com/colmap/colmap.git 

RUN cd colmap && \
    git checkout $COMMIT && \
    mkdir build && \
    cd build && \
    cmake -D CMAKE_CUDA_ARCHITECTURES=80 .. && \
    make -j4 && \
    make install


# Pick up some TF dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        ffmpeg \
        pkg-config \
        python \
        rsync \
        software-properties-common \
        unzip \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV TCNN_CUDA_ARCHITECTURES=86
RUN pip install torch==1.12.1+cu113 torchvision==0.13.1+cu113 -f https://download.pytorch.org/whl/torch_stable.html && \
    pip install git+https://github.com/NVlabs/tiny-cuda-nn/#subdirectory=bindings/torch

RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python3 get-pip.py

COPY . ./nerfstudio
RUN pip3 install functorch==0.2.1 && \
    pip3 install -e ./nerfstudio