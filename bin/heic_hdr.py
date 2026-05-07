import os
import sys
import subprocess
import time
from concurrent.futures import ThreadPoolExecutor

# Record the start time
start_time = time.time()

# Get the directory path
if len(sys.argv) < 2:
    print("Usage: python run.py <directory> <options>")
    sys.exit(1)

dir_path = os.path.expanduser(sys.argv[1])
extra_options = sys.argv[2:]

# Check if the directory exists
if not os.path.isdir(dir_path):
    print(f"Error: Directory {dir_path} does not exist.")
    sys.exit(1)

# Define the file extensions for conversion
input_extension = ".tif"
output_extension = ".heic"

# Get all .tif files in the directory
tif_files = sorted(
    [f for f in os.listdir(dir_path) if f.endswith(input_extension)]
)

if not tif_files:
    print(f"No {input_extension} files found in the directory {dir_path}.")
    sys.exit(1)

current_directory = os.getcwd()
exc_path = os.path.join(current_directory, "toGainMapHDR")

# Define the conversion function
def convert_to_heic(tif_file):
    input_file_path = os.path.join(dir_path, tif_file)
    output_file_path = dir_path
    
    # Build the command with optional arguments
    # You may need to edit exc_path before running!
    # Sample: command = [‘/home/user/toGainMapHDR’, input_file_path, output_file_path] + extra_options
    command = [exc_path, input_file_path, output_file_path] + extra_options

    # Call the external program toGainMapHDR
    try:
        result = subprocess.run(command, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

        # If there is stdout output, display it
        if result.stdout.strip():
            print(f"[STDOUT] {tif_file} {result.stdout.strip()}")
        # If there is warning/stderr output, display it
        elif result.stderr.strip():
            print(f"[WARNING] {tif_file} {result.stderr.strip()}")
        # Otherwise display OK
        else:
            print(f"[OK] {tif_file}")

    except subprocess.CalledProcessError as e:
        print(f"\n[ERROR] File: {tif_file}")
        if e.stderr:
            print(e.stderr.strip())
        print("-" * 60)

# Set the maximum number of threads to 8
max_threads = 8

# Use ThreadPoolExecutor to batch process the files
with ThreadPoolExecutor(max_workers=max_threads) as executor:
    executor.map(convert_to_heic, tif_files)

# Record the end time
end_time = time.time()

# Calculate the total runtime
elapsed_time = end_time - start_time

print(f"All files have been processed in {elapsed_time:.2f} seconds")

