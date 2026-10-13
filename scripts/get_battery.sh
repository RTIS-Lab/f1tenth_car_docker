#!/bin/sh
docker compose exec system bash -c "source install/setup.bash; ros2 topic echo /sensors/core --once --field state.voltage_input"
