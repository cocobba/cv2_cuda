#!/bin/bash
set -e

install_opencv () {
  # Check if the file /proc/device-tree/model exists
  if [ -e "/proc/device-tree/model" ]; then
      # Read the model information from /proc/device-tree/model and remove null bytes
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
          # Use "-j 4" only if swap space is larger than 5.5GB
          FREE_MEM="$(free -m | awk '/^Swap/ {print $2}')"
          if [[ "$FREE_MEM" -gt "5500" ]]; then
            NO_JOB=4
          else
            echo "Due to limited swap, make will only use 1 core"
            NO_JOB=1
          fi
      else
          echo "Unable to determine the Jetson Nano model."
          exit 1
      fi
      echo ""
  else
      echo "Error: /proc/device-tree/model not found. Are you sure this is a Jetson Nano?"
      exit 1
  fi
  
  echo "Installing OpenCV 4.10.0 on your Nano"
  echo "It will take approximately 3.5 hours!"
  
  # Reveal the CUDA location
  cd ~
  sudo sh -c "echo '/usr/local/cuda/lib64' >> /etc/ld.so.conf.d/nvidia-tegra.conf"
  sudo ldconfig
  
  # Install dependencies
  sudo apt-get update
  sudo apt-get install -y build-essential git unzip pkg-config zlib1g-dev
  sudo apt-get install -y python3-dev python3-numpy
  sudo apt-get install -y python-dev python-numpy
  sudo apt-get install -y cmake
  sudo apt-get install -y libjpeg-dev libjpeg8-dev libjpeg-turbo8-dev
  sudo apt-get install -y libpng-dev libtiff-dev libglew-dev
  sudo apt-get install -y libavcodec-dev libavformat-dev libswscale-dev
  sudo apt-get install -y libgtk2.0-dev libgtk-3-dev libcanberra-gtk*
  sudo apt-get install -y python3-pip
  sudo apt-get install -y libxvidcore-dev libx264-dev
  sudo apt-get install -y libtbb-dev libxine2-dev
  sudo apt-get install -y libv4l-dev v4l-utils qv4l2 v4l2ucp
  sudo apt-get install -y libtesseract-dev libpostproc-dev
  sudo apt-get install -y libvorbis-dev
  sudo apt-get install -y libfaac-dev libmp3lame-dev libtheora-dev
  sudo apt-get install -y libopencore-amrnb-dev libopencore-amrwb-dev
  sudo apt-get install -y libopenblas-dev libatlas-base-dev libblas-dev
  sudo apt-get install -y liblapack-dev liblapacke-dev libeigen3-dev gfortran
  sudo apt-get install -y libhdf5-dev libprotobuf-dev protobuf-compiler
  sudo apt-get install -y libgoogle-glog-dev libgflags-dev
  sudo apt-get install -y gstreamer1.0-tools libgstreamer-plugins-base1.0-dev
  sudo apt-get install -y libgstreamer-plugins-good1.0-dev
  sudo apt-get install -y libtbb2
  
  # OS-specific dependencies
  if [ -f /etc/os-release ]; then
      . /etc/os-release
      VERSION_MAJOR=$(echo "$VERSION_ID" | cut -d'.' -f1)
      if [ "$VERSION_MAJOR" = "22" ]; then
          sudo apt-get install -y libswresample-dev libdc1394-dev
      else
          sudo apt-get install -y libavresample-dev libdc1394-22-dev
      fi
  else
      sudo apt-get install -y libavresample-dev
