# CUDA / GPU inference container for the F1TENTH car.
#
# This runs the CUDA-enabled ROS 2 nodes (currently just `rtis_f110_rl`) on the
# Jetson's GPU. Everything else stays on the Jammy `f1tenth-base` image; this
# container joins the same FastDDS discovery server and talks over DDS.
#
# Base = dusty-nv's L4T PyTorch + ROS Humble image:
#   * Ubuntu 20.04 Focal (L4T r35 is Focal), so it can consume the host's CUDA
#     libraries that `runtime: nvidia` bind-mounts via /etc/.../l4t.csv.
#   * ROS Humble is built FROM SOURCE and lives under /opt/ros/humble/install
#     (NOT /opt/ros/humble), and there is no `ros-humble-*` apt repo for Focal.
#   * It is the `ros_base` variant + PyTorch: no rviz2/desktop, no nav2, no
#     ackermann_msgs. Anything missing must be built from source (see overlay
#     below).
#
# Pick the tag closest to your L4T release. r35.3.1 is the newest published
# `humble-pytorch` tag in the r35 line; it works on an r35.6.x host because CUDA
# 11.4 is constant across the whole r35 series and the CUDA runtime is
# bind-mounted from the host by the nvidia container runtime.
ARG L4T_TAG=r35.3.1
FROM dustynv/ros:humble-pytorch-l4t-${L4T_TAG}

SHELL ["/bin/bash", "-c"]
ARG DEBIAN_FRONTEND=noninteractive

# dusty's r35.3.1 image was built in 2023 and ships an EXPIRED ROS apt signing
# key, so `apt-get update` fails with:
#   EXPKEYSIG F42ED6FBAB17C654 ... 'http://packages.ros.org/ros2/ubuntu ...' is not signed
# Refresh it with the current key from rosdistro. The ROS repo is configured
# with `signed-by=/usr/share/keyrings/ros-archive-keyring.gpg`, so overwriting
# that file is all that's needed. (curl ships in the base image.)
RUN curl -fsSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
        -o /usr/share/keyrings/ros-archive-keyring.gpg

# Runtime/build deps not present in the ros_base image.
#   * Boost::iostreams is used by rtis_f110_rl's data_recorder (stream compression).
#   * git is needed to fetch the source-only ROS deps below.
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        libboost-all-dev \
    && rm -rf /var/lib/apt/lists/*

# --- Pre-built ROS dependency overlay --------------------------------------
# Leaf ROS packages that aren't in dusty's ros_base and can't be apt-installed
# on Focal get built from source into a *separate* overlay. Baking them here
# keeps them cached and out of your mounted workspace. As you migrate more nodes
# into this container, add their missing deps to this list.
ENV ROS_DEPS_WS=/opt/ros_deps
RUN mkdir -p ${ROS_DEPS_WS}/src && cd ${ROS_DEPS_WS}/src && \
    git clone --depth 1 -b ros2 https://github.com/ros-drivers/ackermann_msgs.git && \
    cd ${ROS_DEPS_WS} && \
    source /opt/ros/humble/install/setup.bash && \
    colcon build --merge-install && \
    rm -rf ${ROS_DEPS_WS}/build ${ROS_DEPS_WS}/log

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /ros_ws
ENTRYPOINT ["/entrypoint.sh"]
CMD ["ros2", "run", "rtis_f110_rl", "rl_driver", "--ros-args", "--params-file", "/ros_ws/src/rtis_f110_rl/config/vanilla_driver.yaml"]
