#!/bin/bash
set -e

install_opencv() {
    if [ ! -e "/proc/device-tree/model" ]; then
        echo "Error: /proc/device-tree/model not found. Are you sure this is a Jetson Nano?"
        exit 1
    fi

    model=$(tr -d '\0' < /proc/device-tree/model)
    echo ""

    if [[ $model == *"Orin"* ]]; then
        echo "Detecting a Jetson Nano Orin."
        NO_JOB=4
        ARCH=8.7
        PTX="sm_87"
    elif [[ $model == *"Jetson Nano"* ]]; then
        echo "Detecting a regular Jetson Nano."
        ARCH=5.3
        PTX="sm_53"
        FREE_MEM=$(free -m | awk '/^Swap/ {print $2}')
        NO_JOB=$(( FREE_MEM > 5500 ? 4 : 1 ))
        [[ NO_JOB -eq 1 ]] && echo "Due to limited swap, using only 1 core."
    else
        echo "Unable to determine the Jetson Nano model."
        exit 1
    fi

    echo ""
    echo "Installing OpenCV 4.10.0 on your Nano. It will take approximately 3.5 hours!"

    sudo sh -c "echo '/usr/local/cuda/lib64' >> /etc/ld.so.conf.d/nvidia-tegra.conf"
    sudo ldconfig

    sudo apt-get update
    sudo apt-get install -y build-essential git unzip pkg-config zlib1g-dev \
        python3-dev python3-numpy python-dev python-numpy gstreamer1.0-tools \
        libgstreamer-plugins-base1.0-dev libgstreamer-plugins-good1.0-dev \
        libtbb2 libgtk-3-dev v4l2ucp libxine2-dev cmake libjpeg-dev \
        libjpeg8-dev libjpeg-turbo8-dev libpng-dev libtiff-dev libglew-dev \
        libavcodec-dev libavformat-dev libswscale-dev libgtk2.0-dev \
        libgtk-3-dev libcanberra-gtk* python3-pip libxvidcore-dev \
        libx264-dev libtbb-dev libxine2-dev libv4l-dev v4l-utils qv4l2 \
        libtesseract-dev libpostproc-dev libvorbis-dev libfaac-dev \
        libmp3lame-dev libtheora-dev libopencore-amrnb-dev \
        libopencore-amrwb-dev libopenblas-dev libatlas-base-dev libblas-dev \
        liblapack-dev liblapacke-dev libeigen3-dev gfortran \
        libhdf5-dev libprotobuf-dev protobuf-compiler \
        libgoogle-glog-dev libgflags-dev

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$VERSION_ID" == "22" ]; then
            sudo apt-get install -y libswresample-dev libdc1394-dev
        else
            sudo apt-get install -y libavresample-dev libdc1394-22-dev
        fi
    else
        sudo apt-get install -y libavresample-dev libdc1394-22-dev
    fi

    cd ~
    sudo rm -rf opencv*
    git clone --branch 4.9.0 --depth=1 https://github.com/opencv/opencv.git
    git clone --branch 4.9.0 --depth=1 https://github.com/opencv/opencv_contrib.git

    cd ~/opencv
    mkdir build
    cd build

    cmake -D CMAKE_BUILD_TYPE=RELEASE \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D OPENCV_EXTRA_MODULES_PATH=~/opencv_contrib/modules \
        -D EIGEN_INCLUDE_PATH=/usr/include/eigen3 \
        -D WITH_OPENCL=OFF \
        -D CUDA_ARCH_BIN=${ARCH} \
        -D CUDA_ARCH_PTX=${PTX} \
        -D WITH_CUDA=ON \
        -D WITH_CUDNN=ON \
        -D WITH_CUBLAS=ON \
        -D ENABLE_FAST_MATH=ON \
        -D CUDA_FAST_MATH=ON \
        -D OPENCV_DNN_CUDA=ON \
        -D ENABLE_NEON=ON \
        -D WITH_QT=OFF \
        -D WITH_OPENMP=ON \
        -D BUILD_TIFF=ON \
        -D WITH_FFMPEG=ON \
        -D WITH_GSTREAMER=ON \
        -D WITH_TBB=ON \
        -D BUILD_TBB=ON \
        -D BUILD_TESTS=OFF \
        -D WITH_EIGEN=ON \
        -D WITH_V4L=ON \
        -D WITH_LIBV4L=ON \
        -D WITH_PROTOBUF=ON \
        -D OPENCV_ENABLE_NONFREE=ON \
        -D INSTALL_C_EXAMPLES=OFF \
        -D INSTALL_PYTHON_EXAMPLES=OFF \
        -D PYTHON3_PACKAGES_PATH=/usr/lib/python3/dist-packages \
        -D OPENCV_GENERATE_PKGCONFIG=ON \
        -D BUILD_EXAMPLES=OFF \
        -D CMAKE_CXX_FLAGS="-march=native -mtune=native" \
        -D CMAKE_C_FLAGS="-march=native -mtune=native" ..

    make -j ${NO_JOB}
   
    directory="/usr/include/opencv4/opencv2"
    [ -d "$directory" ] && sudo rm -rf "$directory"
   
    sudo make install
    sudo ldconfig
    make clean

    echo "Congratulations!"
    echo "You've successfully installed OpenCV 4.9.0 on your Nano"
}

cd ~

if [ -d ~/opencv/build ]; then
    echo ""
    echo "You have a directory ~/opencv/build on your disk."
    echo "Continuing the installation will replace this folder."
    echo ""
    read -p "Do you wish to continue (Y/n)? " answer
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        echo "Leaving without installing OpenCV."
        exit 0
    fi
fi

install_opencv
