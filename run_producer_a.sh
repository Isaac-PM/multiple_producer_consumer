#!/bin/bash
clear
source config.env
echo "Running producer 'a'..."
python3 producer_consumer.py a $element_count $runs_to_execute $seconds_to_sleep