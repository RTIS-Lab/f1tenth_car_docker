ARG BASE_IMAGE_TAG=slim
FROM f1tenth-base:${BASE_IMAGE_TAG}

# Extra dependencies for the teleop workspace.
ARG DEBIAN_FRONTEND=noninteractive
RUN --mount=target=/var/lib/apt/lists,type=cache,sharing=private \
    --mount=target=/var/cache/apt,type=cache,sharing=private \
    apt-get update --fix-missing && \
    apt-get install -y \
        clang-14 \
        clangd-14 \
        libomp-14-dev \
        ninja-build \
        ccache \
        ros-humble-cv-bridge \
    && apt-get -y dist-upgrade

# SSH server setup
RUN mkdir -p /var/run/sshd && \
    echo 'root:password' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd

# clang setup
RUN update-alternatives --install /usr/bin/clang clang /usr/bin/clang-14 14 && \
    update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-14 14

WORKDIR /ros_ws

# Copy the workspace. Only kw_f110_drive / kw_f110_msgs are present; the rest
# of the former drive stack (RL, safety, lidar odom, preemption experiments)
# is intentionally absent from this base setup.
COPY . .

# The entrypoint script will build, source, and then execute the CMD
ENTRYPOINT ["/ros_ws/entrypoint.sh"]
CMD ["ros2", "run", "kw_f110_drive", "teleop"]
