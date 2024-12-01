#!/usr/bin/env bash

id=$(xinput | grep stylus | awk -F= '{print $2}' | cut -f1)
display=$(xrandr | grep primary | cut -d' ' -f1)

xinput | grep stylus
xrandr | grep primary
echo "Id: $id, Display: $display"
xinput map-to-output $id $display
