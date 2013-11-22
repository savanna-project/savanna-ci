#!/bin/bash

cd $WORKSPACE

export PYTHONUNBUFFERED=1

echo "============= SAVANNA ============="
./ttx.sh -N savanna icehouse

echo "========= SAVANNA CLIENT =========="
./ttx.sh -N python-savannaclient 0.4.x
