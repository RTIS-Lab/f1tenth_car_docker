#!/bin/bash
set -e

# Source ROS 2. dusty's Focal image installs a from-source workspace under
# /opt/ros/humble/install; the stock Jammy image uses /opt/ros/humble. Handle
# both so this entrypoint is portable.
for f in /opt/ros/humble/install/setup.bash /opt/ros/humble/setup.bash; do
  if [ -f "$f" ]; then source "$f"; break; fi
done

# Source the pre-built dependency overlay (ackermann_msgs, ...).
if [ -f /opt/ros_deps/install/setup.bash ]; then
  source /opt/ros_deps/install/setup.bash
fi

# Build only the CUDA node(s) from the shared, volume-mounted workspace
# (./f1tenth_drive). We build into a SEPARATE base (build.cuda/install.cuda) so
# these Focal artifacts never clobber the Jammy `drive` container's build/ and
# install/ in the very same directory.
#
# `--packages-up-to` builds only the requested packages plus their in-workspace
# dependencies, so nav2/grid_map/etc. are never touched. To migrate more nodes
# into this container, add them to RL_PACKAGES (space-separated) in compose.
cd /ros_ws
PKGS="${RL_PACKAGES:-rtis_f110_rl}"
echo "--- Building (CUDA) packages up to: ${PKGS} ---"
# NOTE: --log-base is a top-level colcon arg (before the verb); --build-base and
# --install-base are `build` verb args (after it).
colcon --log-base log.cuda build \
  --packages-up-to ${PKGS} \
  --build-base build.cuda \
  --install-base install.cuda \
  --symlink-install

if [ -f /ros_ws/install.cuda/setup.bash ]; then
  echo "--- Sourcing CUDA workspace (install.cuda) ---"
  source /ros_ws/install.cuda/setup.bash
fi

exec "$@"
