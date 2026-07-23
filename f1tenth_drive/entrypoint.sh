#!/bin/bash
set -e

# Source ROS 2
source /opt/ros/humble/setup.bash

# Start SSH server in the background
echo "--- Starting SSH Server ---"
/usr/sbin/sshd -p 2222

# Build the workspace.
# rtis_f110_rl is the GPU/libtorch node -- it is built and run in the
# rl_inference (CUDA) container, not here. This image has no libtorch, so skip
# it (nothing else in the workspace depends on it). Override with
# SKIP_PACKAGES="" to build everything, or add more space-separated names.
echo "--- Building workspace at /ros_ws ---"
cd /ros_ws
SKIP_PACKAGES="${SKIP_PACKAGES-rtis_f110_rl}"
if [ -n "${SKIP_PACKAGES}" ]; then
  colcon build --packages-skip ${SKIP_PACKAGES}
else
  colcon build
fi

# Source the local workspace if it exists
if [ -f /ros_ws/install/setup.bash ]; then
  echo "--- Sourcing local workspace ---"
  source /ros_ws/install/setup.bash
fi

# Execute the command passed to the script
exec "$@"
