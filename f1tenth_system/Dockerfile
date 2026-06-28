ARG BASE_IMAGE_TAG=latest
FROM f1tenth-base:${BASE_IMAGE_TAG}

WORKDIR /ros_ws

# SSH server setup
RUN mkdir -p /var/run/sshd && \
    echo 'root:password' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd

# Copy package.xml files for dependency caching
COPY src/f1tenth_system/vesc/vesc_driver/package.xml src/f1tenth_system/vesc/vesc_driver/package.xml
COPY src/f1tenth_system/vesc/vesc_msgs/package.xml src/f1tenth_system/vesc/vesc_msgs/package.xml
COPY src/f1tenth_system/vesc/vesc_ackermann/package.xml src/f1tenth_system/vesc/vesc_ackermann/package.xml
COPY src/f1tenth_system/vesc/vesc/package.xml src/f1tenth_system/vesc/vesc/package.xml
COPY src/f1tenth_system/f1tenth_stack/package.xml src/f1tenth_system/f1tenth_stack/package.xml

# Install ROS dependencies for this specific service
RUN --mount=target=/var/lib/apt/lists,type=cache,sharing=private \
    --mount=target=/var/cache/apt,type=cache,sharing=private \
    apt-get update && \
    source /opt/ros/humble/setup.bash && \
    rosdep install -i --from-path src --rosdistro humble -y

# Copy application code
COPY . .

# Install Python dependencies for this service using uv
RUN --mount=type=cache,target=/root/.cache uv pip install gym numpy scipy numba pyglet pyopengl

# The entrypoint script will build, source, and then execute the CMD
ENTRYPOINT ["/ros_ws/entrypoint.sh"]
CMD ["ros2", "launch", "f1tenth_stack", "bringup_launch.py"]
