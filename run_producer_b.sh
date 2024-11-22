#!/bin/bash
clear
source config.env
echo "Running producer 'b'..."
python3 producer_consumer.py b $element_count $runs_to_execute $seconds_to_sleep