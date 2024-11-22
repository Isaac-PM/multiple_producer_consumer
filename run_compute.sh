#!/bin/bash
clear
source config.env
source clean.sh
nvcc -o compute compute.cu
echo "Running compute..."
./compute $element_count $runs_to_execute $seconds_to_sleep