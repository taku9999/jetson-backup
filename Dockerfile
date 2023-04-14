FROM nvcr.io/nvidia/l4t-ml:r32.5.0-py3
SHELL ["/bin/bash", "-c"]
RUN apt update && apt upgrade -y
RUN apt install -y iputils-ping net-tools
RUN apt install -y nano
RUN apt install -y python-pip python3-pip
RUN pip install --upgrade pip && pip3 install --upgrade pip

# ROS-Livox環境構築
RUN apt install -y lsb-release
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list' 
RUN apt install -y curl
RUN apt install -y gnupg
RUN curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -
RUN apt update
RUN apt install -y ros-melodic-desktop-full
RUN echo "source /opt/ros/melodic/setup.bash" >> ~/.bashrc
RUN source ~/.bashrc
RUN apt install -y python-rosdep python-rosinstall python-rosinstall-generator python-wstool build-essential
RUN rosdep init
RUN rosdep update
RUN mkdir workspace
WORKDIR /workspace
RUN apt install -y cmake
RUN git clone https://github.com/Livox-SDK/Livox-SDK.git
WORKDIR /workspace/Livox-SDK/build
RUN cmake ..
RUN make
RUN make install
WORKDIR /workspace
RUN git clone https://github.com/Livox-SDK/livox_ros_driver.git ws_livox/src
WORKDIR /workspace/ws_livox
RUN source /opt/ros/melodic/setup.sh; catkin_make
RUN echo "source /workspace/ws_livox/devel/setup.sh" >> ~/.bashrc
RUN source ~/.bashrc

# GitHubバージョンアップデート
WORKDIR /
RUN git clone git://git.kernel.org/pub/scm/git/git.git
WORKDIR /git
RUN git pull
RUN make all && sudo make prefix=/usr/local install

# === 機能拡張に必要な処理 =======================================
WORKDIR /workspace
RUN apt install -y ros-melodic-ros-numpy
RUN pip3 install rospkg
RUN pip3 install open3d
RUN pip3 install pcl
# =============================================================

# Git連携設定
WORKDIR /workspace
RUN rm -rf /workspace/ws_livox/src/.git
RUN rm -rf /workspace/ws_livox/src/.gitignore
RUN rm -rf /workspace/Livox-SDK/.git
RUN rm -rf /workspace/Livox-SDK/.gitignore
RUN git config --global user.name taku9999
RUN git config --global user.email 102945088+taku9999@users.noreply.github.com
RUN git config --global init.defaultBranch main

# LiDAR本体設定ファイル変更（livox_lidar_config.json）
WORKDIR /workspace/ws_livox/src/livox_ros_driver/config
RUN sed -i '3,11d' livox_lidar_config.json
RUN sed -i '4s/"broadcast_code": "0TFDG3U99101431"/"broadcast_code": "3JEDJCP00136071"/' livox_lidar_config.json
RUN sed -i '5s/"enable_connect": false/"enable_connect": true/' livox_lidar_config.json
RUN sed -i '8s/"imu_rate": 0/"imu_rate": 1/' livox_lidar_config.json

# launchファイル変更（livox_lidar.launch）
WORKDIR /workspace/ws_livox/src/livox_ros_driver/launch
RUN sed -i '5s/"xfer_format" default="0"/"xfer_format" default="2"/' livox_lidar.launch
RUN sed -i '8s/"publish_freq" default="10.0"/"publish_freq" default="1"/' livox_lidar.launch
RUN sed -i '32s/$/\n\n/' livox_lidar.launch
RUN sed -i '33s/$/\t<node pkg="livox_ros_driver" type="point_sub.py" name="point_sub" output="screen"\/>/' livox_lidar.launch

# GitHubからコードを引っ張ってくる
ADD "https://www.random.org/cgi-bin/randbyte?nbytes=10&format=h" /dev/null
WORKDIR /workspace/ws_livox/src/livox_ros_driver/
RUN git clone https://github.com/taku9999/scripts.git
WORKDIR /workspace/ws_livox/src/livox_ros_driver/scripts
RUN chmod +x point_sub.py
