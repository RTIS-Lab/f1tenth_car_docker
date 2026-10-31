# F1TENTH car — slim base setup

A trimmed-down Docker base for an F1TENTH car. It keeps the onboard driver
stack and joystick teleop, and drops the GPU/RL, safety, lidar-odometry and
real-time experiment code from the larger `f1tenth_car_docker` setup.

## Services

| Service     | Purpose                                                           |
| ----------- | ----------------------------------------------------------------- |
| `base`      | Shared ROS 2 Humble image (`f1tenth-base:slim`). Setup profile only. |
| `discovery` | Fast DDS discovery server used by all other containers.           |
| `drive`     | `kw_f110_drive` workspace. Default command: `teleop`.             |
| `system`    | VESC / sensor / joystick bringup (`f1tenth_stack`).               |

`drive` publishes joystick commands as `AckermannDriveStamped` on
`/teleop/drive`; `system` remaps `ackermann_cmd` to that topic for the VESC.

## First-time build

The `base` image is built once and reused by `drive` and `system`:

```sh
docker compose --profile setup build base
docker compose build drive system
```

### Image names

This setup uses the `:slim` tag so it cannot overwrite the images from the
full `f1tenth_car_docker` checkout:

- `f1tenth-base:slim`
- `f1tenth-drive:slim`
- `f1tenth-system:slim`

Override the tag for all three consistently by exporting `BASE_IMAGE_TAG`
before building/running, e.g. `BASE_IMAGE_TAG=test docker compose build`.

## Run

```sh
docker compose up discovery system drive
```

or in the background:

```sh
docker compose up -d discovery system drive
docker compose logs -f drive
```

The entrypoints build their workspaces (`colcon build`) on every container
start, then run the service command.

## Teleop

The `drive` container runs `ros2 run kw_f110_drive teleop`. It reads
`sensor_msgs/Joy` on `/joy` (published by the `system` container's `joy`
node) and publishes on `/teleop/drive`.

Current button/axis mapping in `teleop.cpp`:

- steering: axis `0`
- throttle: axis `5`
- reverse: axis `4`
- speed up: button `10`
- speed down: button `9`
- toggle autonomy (`cmd_vel` forwarding): button `0`

When autonomy is enabled, the node forwards `geometry_msgs/Twist` from
`cmd_vel` as Ackermann commands and stops the car if `cmd_vel` goes stale
(0.5 s by default). Parameters: `wheelbase`, `max_steering_angle`,
`twist_timeout`.

## Useful commands

```sh
# Battery voltage (run against the system container)
./scripts/get_battery.sh

# Shell in the drive container, with the workspace sourced by the entrypoint
docker compose exec drive bash

# Rebuild only the drive workspace after editing its source
docker compose restart drive
```

## What this base intentionally leaves out

Removed from the full setup:

- `f1tenth_rl_inference` (CUDA/L4T) and the `rl_inference` compose service
- `rtis_f110_rl`, `rtis_cuda`
- `rtis_safety`, `rtis_lidar_odom`, `ros_preempt`
- `ROS-Phys-MC-2`, `message_filters`, `range_libc`, `nlopt`
- the cpuset/real-time helper scripts and stale `build*/install*/log*` trees
- `f1tenth_system/src/Fast-DDS-spy` and the historical `f1tenth_system/old_maps`

`f1tenth_system` is otherwise kept as-is: VESC driver, sensors, joy bringup,
robot_localization/fusion and mapping launches are still present.

## Submodules

Only two submodules remain:

```sh
git submodule update --init --recursive
```

- `f1tenth_drive/src/kw_f110_drive` (contains `kw_f110_drive` + `kw_f110_msgs`)
- `f1tenth_system/src/f1tenth_system` (VESC + `f1tenth_stack`)
