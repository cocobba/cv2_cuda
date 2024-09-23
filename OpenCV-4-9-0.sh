#!/bin/bash
set -e

install_opencv () {
  # /proc/device-tree/model 파일이 존재하는지 확인
  if [ -e "/proc/device-tree/model" ]; then
      # 모델 정보를 읽고 null 바이트 제거
      model=$(tr -d '\0' < /proc/device-tree/model)
      echo ""
      if [[ $model == *"Orin"* ]]; then
          echo "Detecting a Jetson Nano Orin."
          # Orin에 필요한 의존성 설치
          sudo apt-get update
          sudo apt-get install -y build-essential git unzip pkg-config zlib1g-dev
          sudo apt-get install -y python3-dev python3-numpy
          sudo apt-get install -y python-dev python-numpy
          sudo apt-get install -y gstreamer1.0-tools libgstreamer-plugins-base1.0-dev
          sudo apt-get install -y libgstreamer-plugins-good1.0-dev
          sudo apt-get install -y libtbb2 libgtk-3-dev v4l2ucp libxine2-dev
          NO_JOB=4
          ARCH=8.7
          PTX="sm_87"
      else
          echo "Unable to determine the Jetson Nano Orin model."
          exit 1
      fi
      echo ""
  else
      echo "Error: /proc/device-tree/model not found. Are you sure this is a Jetson Nano Orin?"
      exit 1
  fi
  
  echo "Installing OpenCV 4.9.0 on your Nano Orin"
  echo "It will take several hours!"
  
  # CUDA 경로 설정
  cd ~
  sudo sh -c "echo '/usr/local/cuda/lib64' >> /etc/ld.so.conf.d/nvidia-tegra.conf"
  sudo ldconfig
  
  # OS 릴리스 파일 확인 및 의존성 설치
  if [ -f /etc/os-release ]; then
      # /etc/os-release 파일 소싱
      . /etc/os-release
      # VERSION_ID에서 주요 버전 추출
      VERSION_MAJOR=$(echo "$VERSION_ID" | cut -d'.' -f1)
      # 주요 버전이 22 이하인지 확인
      if [ "$VERSION_MAJOR" = "22" ]; then
          sudo apt-get install -y libswresample-dev libdc1394-dev
      else
          sudo apt-get install -y libavresample-dev libdc1394-22-dev
      fi
  else
      sudo apt-get install -y libavresample-dev libdc1394-22-dev
  fi

  # 공통 의존성 설치
  sudo apt-get install -y cmake
  sudo apt-get install -y libjpeg-dev libjpeg8-dev libjpeg-turbo8-dev
  sudo apt-get install -y libpng-dev libtiff-dev libglew-dev
  sudo apt-get install -y libavcodec-dev libavformat-dev libswscale-dev
  sudo apt-get install -y libgtk2.0-dev libgtk-3-dev libcanberra-gtk*
  sudo apt-get install -y python3-pip
  sudo apt-get install -y libxvidcore-dev libx264-dev
  sudo apt-get install -y libtbb-dev libxine2-dev
  sudo apt-get install -y libv4l-dev v4l-utils qv4l2
  sudo apt-get install -y libtesseract-dev libpostproc-dev
  sudo apt-get install -y libvorbis-dev
  sudo apt-get install -y libfaac-dev libmp3lame-dev libtheora-dev
  sudo apt-get install -y libopencore-amrnb-dev libopencore-amrwb-dev
  sudo apt-get install -y libopenblas-dev libatlas-base-dev libblas-dev
  sudo apt-get install -y liblapack-dev liblapacke-dev libeigen3-dev gfortran
  sudo apt-get install -y libhdf5-dev libprotobuf-dev protobuf-compiler
  sudo apt-get install -y libgoogle-glog-dev libgflags-dev
 
  # 이전 버전 또는 빌드 파일 삭제
  cd ~ 
  sudo rm -rf opencv*
  sudo rm -rf opencv_contrib*
  
  # OpenCV 4.9.0 다운로드
  git clone --branch 4.9.0 --depth=1 https://github.com/opencv/opencv.git
  git clone --branch 4.9.0 --depth=1 https://github.com/opencv/opencv_contrib.git
  
  # 설치 디렉토리 설정
  cd ~/opencv
  mkdir build
  cd build
  
  # CMake 실행
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
  
  # 컴파일
  make -j ${NO_JOB} 
  
  # 기존 OpenCV 헤더 파일 삭제
  directory="/usr/include/opencv4/opencv2"
  if [ -d "$directory" ]; then
    sudo rm -rf "$directory"
  fi
  
  # 설치 및 링크 설정
  sudo make install
  sudo ldconfig
  
  # 정리 (320 MB 절약)
  make clean
  sudo apt-get update
  
  echo "Congratulations!"
  echo "You've successfully installed OpenCV 4.9.0 on your Nano Orin"
}

cd ~

if [ -d ~/opencv/build ]; then
  echo " "
  echo "You have a directory ~/opencv/build on your disk."
  echo "Continuing the installation will replace this folder."
  echo " "
  
  printf "Do you wish to continue (Y/n)? "
  read answer

  if [[ "$answer" =~ ^[Nn]$ ]]; then 
      echo "Leaving without installing OpenCV"
  else
      install_opencv
  fi
else
    install_opencv
fi
