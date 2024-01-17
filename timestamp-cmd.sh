#!/bin/bash

# Check if a command is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <command>"
  exit 1
fi

# Record the start time
start_time=$(date +%s.%N)

# Run the specified command
"$@"

# Record the end time
end_time=$(date +%s.%N)

# Calculate the time taken
elapsed_time=$(echo "$end_time - $start_time" | bc)

# Display the result
echo "Time taken: $elapsed_time seconds"
