#!/bin/bash

cd $WORKSPACE

export PYTHONUNBUFFERED=1

echo "============= SAVANNA ============="
./ttx.sh -N savanna juno

echo "========= SAVANNA CLIENT =========="
./ttx.sh -N python-savannaclient 0.7.x
