#!/bin/sh

# Script that runs the rcn program from the TTMult suite.
# Note that the input file $NAME.rcn has to be created.

# Enable debug output
set -x

echo "Starting runrcn.sh"
echo "TTMULT is set to: $TTMULT"
echo "Current directory: $(pwd)"

# Determine the platform (darwin or linux)
PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')
echo "Platform detected as: $PLATFORM"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "Script directory: $SCRIPT_DIR"

# Check if rcn31 is available (since rcn is usually a symlink to rcn31)
if [ -x "$TTMULT/rcn31" ]; then
    echo "Found rcn31 at $TTMULT/rcn31"
    RCN_EXEC="$TTMULT/rcn31"
elif [ -x "$TTMULT/$PLATFORM/rcn31" ]; then
    echo "Found rcn31 at $TTMULT/$PLATFORM/rcn31"
    RCN_EXEC="$TTMULT/$PLATFORM/rcn31"
elif [ -x "$SCRIPT_DIR/../bin/$PLATFORM/rcn31" ]; then
    echo "Found rcn31 at $SCRIPT_DIR/../bin/$PLATFORM/rcn31"
    RCN_EXEC="$SCRIPT_DIR/../bin/$PLATFORM/rcn31"
# First check if $TTMULT is set and the rcn executable exists there
elif [ -x "$TTMULT/rcn" ]; then
    echo "Found rcn at $TTMULT/rcn"
    RCN_EXEC="$TTMULT/rcn"
# Then check if rcn exists in the platform-specific directory
elif [ -x "$TTMULT/$PLATFORM/rcn" ]; then
    echo "Found rcn at $TTMULT/$PLATFORM/rcn"
    RCN_EXEC="$TTMULT/$PLATFORM/rcn"
# Then check if the script is in the cowan/scripts directory and try to find the binary relative to that
elif [ -x "$SCRIPT_DIR/../bin/$PLATFORM/rcn" ]; then
    echo "Found rcn at $SCRIPT_DIR/../bin/$PLATFORM/rcn"
    RCN_EXEC="$SCRIPT_DIR/../bin/$PLATFORM/rcn"
# Check if we need to add execute permission
elif [ -f "$TTMULT/rcn31" ]; then
    echo "Found rcn31 at $TTMULT/rcn31 but it's not executable, trying to fix permissions"
    chmod +x "$TTMULT/rcn31"
    RCN_EXEC="$TTMULT/rcn31"
elif [ -f "$TTMULT/$PLATFORM/rcn31" ]; then
    echo "Found rcn31 at $TTMULT/$PLATFORM/rcn31 but it's not executable, trying to fix permissions"
    chmod +x "$TTMULT/$PLATFORM/rcn31"
    RCN_EXEC="$TTMULT/$PLATFORM/rcn31"
elif [ -f "$SCRIPT_DIR/../bin/$PLATFORM/rcn31" ]; then
    echo "Found rcn31 at $SCRIPT_DIR/../bin/$PLATFORM/rcn31 but it's not executable, trying to fix permissions"
    chmod +x "$SCRIPT_DIR/../bin/$PLATFORM/rcn31"
    RCN_EXEC="$SCRIPT_DIR/../bin/$PLATFORM/rcn31"
elif [ -f "$TTMULT/rcn" ]; then
    echo "Found rcn at $TTMULT/rcn but it's not executable, trying to fix permissions"
    chmod +x "$TTMULT/rcn"
    RCN_EXEC="$TTMULT/rcn"
elif [ -f "$TTMULT/$PLATFORM/rcn" ]; then
    echo "Found rcn at $TTMULT/$PLATFORM/rcn but it's not executable, trying to fix permissions"
    chmod +x "$TTMULT/$PLATFORM/rcn"
    RCN_EXEC="$TTMULT/$PLATFORM/rcn"
elif [ -f "$SCRIPT_DIR/../bin/$PLATFORM/rcn" ]; then
    echo "Found rcn at $SCRIPT_DIR/../bin/$PLATFORM/rcn but it's not executable, trying to fix permissions"
    chmod +x "$SCRIPT_DIR/../bin/$PLATFORM/rcn"
    RCN_EXEC="$SCRIPT_DIR/../bin/$PLATFORM/rcn"
else
    echo "rcn command was not found. Please make sure that TTMULT is set correctly."
    echo "Searched in:"
    echo "- $TTMULT/rcn and $TTMULT/rcn31"
    echo "- $TTMULT/$PLATFORM/rcn and $TTMULT/$PLATFORM/rcn31"
    echo "- $SCRIPT_DIR/../bin/$PLATFORM/rcn and $SCRIPT_DIR/../bin/$PLATFORM/rcn31"
    
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

echo "Working with input file: $NAME.rcn"

if [ -f "$NAME.rcn" ]; then
    echo "Input file found, proceeding with calculation"
    ln -sf "$NAME.rcn" fort.10
    
    # Create a temporary file for capturing output
    OUTPUT_FILE=$(mktemp)
    
    # Run the rcn executable and capture output
    echo "Running $RCN_EXEC (capturing output to $OUTPUT_FILE)"
    $RCN_EXEC > "$OUTPUT_FILE" 2>&1
    RCN_RESULT=$?
    
    # Check if the execution was successful
    if [ $RCN_RESULT -ne 0 ]; then
        echo "rcn calculation has failed with exit code $RCN_RESULT."
        echo "Output from rcn:"
        cat "$OUTPUT_FILE"
        rm "$OUTPUT_FILE"
        exit 1
    fi
    
    # Check if the output file fort.9 was created
    if [ ! -f "fort.9" ]; then
        echo "rcn calculation did not produce expected output file (fort.9)."
        echo "Output from rcn:"
        cat "$OUTPUT_FILE"
        rm "$OUTPUT_FILE"
        exit 1
    fi
    
    echo "Output from rcn:"
    cat "$OUTPUT_FILE"
    rm "$OUTPUT_FILE"
    
    mv fort.9 $NAME.rcn_out
    rm fort.10
    
    echo "rcn calculation has finished successfully."
else
    echo "Could not find $NAME.rcn in the current folder."
    echo "Contents of current directory:"
    ls -la .
    exit 1
fi

exit 0