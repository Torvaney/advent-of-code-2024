#!/bin/zsh

# Get the highest existing day number
highest_day=$(ls src/day*.gleam 2>/dev/null | sed -E 's/.*day([0-9]+)\.gleam/\1/' | sort -n | tail -1)
next_day=$((highest_day + 1))

# Create variables for the next day's paths
next_day_src="src/day${next_day}.gleam"
next_day_input_dir="inputs/day${next_day}"
template_path="templates/day{n}.gleam"

# Check if template exists
if [[ ! -f "$template_path" ]]; then
  echo "Template $template_path not found!"
  exit 1
fi

# Create the source file for the next day from the template
sed "s/{n}/${next_day}/g" "$template_path" > "$next_day_src"
echo "Created $next_day_src from template."

# Create the input directory and placeholder files
mkdir -p "$next_day_input_dir"
touch "$next_day_input_dir/example.txt"
touch "$next_day_input_dir/puzzle.txt"
echo "Created directory $next_day_input_dir with example.txt and puzzle.txt."

echo "Setup for Day $next_day is complete!"
