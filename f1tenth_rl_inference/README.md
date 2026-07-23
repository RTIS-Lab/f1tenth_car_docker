# f1tenth_rl_inference (CUDA / GPU container)

Runs CUDA-enabled ROS 2 nodes on the Jetson's GPU, on a Focal base
(`dustynv/ros:humble-pytorch-l4t-*`) so it can use the host CUDA that the nvidia
container runtime bind-mounts. Everything else stays on the Jammy `f1tenth-base`
image and talks to this container over DDS via the shared FastDDS discovery
server.

## How it fits together

- It mounts the **same** source tree as `drive` (`./f1tenth_drive`) but builds
  into `build.cuda/` + `install.cuda/`, so the Focal build never clobbers the
  Jammy `drive` container's `build/` + `install/` in the same folder.
- `colcon build --packages-up-to $RL_PACKAGES` builds only the listed
  package(s) plus their in-workspace dependencies. nav2/grid_map/rviz are never
  built here, which is what keeps this image cheap.
- Missing leaf deps that can't be apt-installed on Focal (e.g. `ackermann_msgs`)
  are built from source into `/opt/ros_deps` at image-build time.

## Growing this container

To move a node onto the GPU / into this container:

1. Add it (space-separated) to `RL_PACKAGES` in `docker-compose.yml`.
2. If it needs a ROS package not in dusty's `ros_base` and not apt-installable
   on Focal, add that package to the source overlay in the `Dockerfile`.

Because it's the same workspace, once several packages are built here they live
in one `install.cuda/` and can be launched together under `ros_preempt`'s
executor in a single process.

## REQUIRED: select the CUDA device in rtis_f110_rl

`src/rtis_f110_rl/src/rl_driver.cpp` currently hardcodes the device:

```cpp
#define IS_IN_SIM 1          // -> torch::kCPU
// #define IS_IN_SIM 0       // -> torch::kCUDA
```

Set `IS_IN_SIM 0` (rebuild) to actually run on the GPU here. Better long-term:
make it a compile option or a ROS parameter/env var so the same source runs CPU
in sim and CUDA on the car without editing. (Happy to do that refactor.)

## Build & run

```sh
# One-time: build the base images if you haven't
sudo docker compose --profile setup build base

sudo docker compose build rl_inference
sudo docker compose up discovery rl_inference
```

Note: this needs a ~6 GB base image pull and an on-device colcon build; neither
has been run/verified yet in this repo.
