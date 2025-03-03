#!/bin/sh

# Script that runs the rcn2 program from the TTMult suite.

# Enable debug output
set -x

echo "Starting runrcn2.sh"
echo "TTMULT is set to: $TTMULT"
echo "Current directory: $(pwd)"

# Determine the platform (darwin or linux)
PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')
echo "Platform detected as: $PLATFORM"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "Script directory: $SCRIPT_DIR"

# First check if $TTMULT is set and the rcn2 executable exists there
if [ -x "$TTMULT/rcn2" ]; then
    echo "Found rcn2 at $TTMULT/rcn2"
    RCN2_EXEC="$TTMULT/rcn2"
# Then check if rcn2 exists in the platform-specific directory
elif [ -x "$TTMULT/$PLATFORM/rcn2" ]; then
    echo "Found rcn2 at $TTMULT/$PLATFORM/rcn2"
    RCN2_EXEC="$TTMULT/$PLATFORM/rcn2"
# Then check if the script is in the cowan/scripts directory and try to find the binary relative to that
elif [ -x "$SCRIPT_DIR/../bin/$PLATFORM/rcn2" ]; then
    echo "Found rcn2 at $SCRIPT_DIR/../bin/$PLATFORM/rcn2"
    RCN2_EXEC="$SCRIPT_DIR/../bin/$PLATFORM/rcn2"
# Check if we need to add execute permission
elif [ -f "$TTMULT/rcn2" ]; then
    echo "Found rcn2 at $TTMULT/rcn2 but it's not executable, trying to fix permissions"
    chmod +x "$TTMULT/rcn2"
    RCN2_EXEC="$TTMULT/rcn2"
elif [ -f "$TTMULT/$PLATFORM/rcn2" ]; then
    echo "Found rcn2 at $TTMULT/$PLATFORM/rcn2 but it's not executable, trying to fix permissions"
    chmod +x "$TTMULT/$PLATFORM/rcn2"
    RCN2_EXEC="$TTMULT/$PLATFORM/rcn2"
elif [ -f "$SCRIPT_DIR/../bin/$PLATFORM/rcn2" ]; then
    echo "Found rcn2 at $SCRIPT_DIR/../bin/$PLATFORM/rcn2 but it's not executable, trying to fix permissions"
    chmod +x "$SCRIPT_DIR/../bin/$PLATFORM/rcn2"
    RCN2_EXEC="$SCRIPT_DIR/../bin/$PLATFORM/rcn2"
else
    echo "rcn2 command was not found. Please make sure that TTMULT is set correctly."
    echo "Searched in:"
    echo "- $TTMULT/rcn2"
    echo "- $TTMULT/$PLATFORM/rcn2"
    echo "- $SCRIPT_DIR/../bin/$PLATFORM/rcn2"
    
    echo "Contents of TTMULT directory (if accessible):"
    ls -la "$TTMULT" 2>/dev/null || echo "TTMULT directory not found or not accessible"
    
    echo "Contents of platform-specific directory (if accessible):"
    ls -la "$TTMULT/$PLATFORM" 2>/dev/null || echo "Platform directory not found or not accessible"
    
    echo "Contents of script-relative bin directory (if accessible):"
    ls -la "$SCRIPT_DIR/../bin" 2>/dev/null || echo "Script relative bin directory not found"
    ls -la "$SCRIPT_DIR/../bin/$PLATFORM" 2>/dev/null || echo "Script relative platform bin directory not found"
    
    exit 1
fi

if [ "$#" -eq 0 ]; then
    NAME='input'
else
    NAME="$1"
fi

echo "Working with input file: $NAME.rcn2"

# The input file for rcn2 must be added in the current folder.
if [ -f "$NAME.rcn2" ]; then
    echo "Input file found, proceeding with calculation"
    ln -sf "$NAME.rcn2" fort.10
    
    # Create a temporary file for capturing output
    OUTPUT_FILE=$(mktemp)
    
    # Run the rcn2 executable and capture output
    echo "Running $RCN2_EXEC (capturing output to $OUTPUT_FILE)"
    $RCN2_EXEC > "$OUTPUT_FILE" 2>&1
    RCN2_RESULT=$?
    
    # Check if the execution was successful
    if [ $RCN2_RESULT -ne 0 ]; then
        echo "rcn2 calculation has failed with exit code $RCN2_RESULT."
        echo "Output from rcn2:"
        cat "$OUTPUT_FILE"
        rm "$OUTPUT_FILE"
        exit 1
    fi
    
    # Check if the output files were created
    if [ ! -f "fort.9" ] || [ ! -f "fort.11" ]; then
        echo "rcn2 calculation did not produce expected output files (fort.9 and/or fort.11)."
        echo "Output from rcn2:"
        cat "$OUTPUT_FILE"
        rm "$OUTPUT_FILE"
        exit 1
    fi
    
    echo "Output from rcn2:"
    cat "$OUTPUT_FILE"
    rm "$OUTPUT_FILE"
    
    mv fort.9 $NAME.rcn2_out
    mv fort.11 $NAME.rcg
    rm fort.10
    
    echo "rcn2 calculation has finished successfully."
else
    echo "Could not find $NAME.rcn2 in the current folder."
    echo "Contents of current directory:"
    ls -la .
    exit 1
fi

exit 0
