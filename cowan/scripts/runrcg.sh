#!/bin/sh

# Script that runs the ttrcg program from the TTMult suite.

# Enable debug output
set -x

echo "Starting runrcg.sh"
echo "TTMULT is set to: $TTMULT"
echo "Current directory: $(pwd)"

# Determine the platform (darwin or linux)
PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')
echo "Platform detected as: $PLATFORM"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "Script directory: $SCRIPT_DIR"

# First check if $TTMULT is set and the ttrcg executable exists there
if [ -x "$TTMULT/ttrcg" ]; then
    echo "Found ttrcg at $TTMULT/ttrcg"
    TTRCG_EXEC="$TTMULT/ttrcg"
    CFP_DIR="$TTMULT"
# Then check if ttrcg exists in the platform-specific directory
elif [ -x "$TTMULT/$PLATFORM/ttrcg" ]; then
    echo "Found ttrcg at $TTMULT/$PLATFORM/ttrcg"
    TTRCG_EXEC="$TTMULT/$PLATFORM/ttrcg"
    CFP_DIR="$TTMULT/$PLATFORM"
# Then check if the script is in the cowan/scripts directory and try to find the binary relative to that
elif [ -x "$SCRIPT_DIR/../bin/$PLATFORM/ttrcg" ]; then
    echo "Found ttrcg at $SCRIPT_DIR/../bin/$PLATFORM/ttrcg"
    TTRCG_EXEC="$SCRIPT_DIR/../bin/$PLATFORM/ttrcg"
    CFP_DIR="$SCRIPT_DIR/../bin/$PLATFORM"
# Check if we need to add execute permission
elif [ -f "$TTMULT/ttrcg" ]; then
    echo "Found ttrcg at $TTMULT/ttrcg but it's not executable, trying to fix permissions"
    chmod +x "$TTMULT/ttrcg"
    TTRCG_EXEC="$TTMULT/ttrcg"
    CFP_DIR="$TTMULT"
elif [ -f "$TTMULT/$PLATFORM/ttrcg" ]; then
    echo "Found ttrcg at $TTMULT/$PLATFORM/ttrcg but it's not executable, trying to fix permissions"
    chmod +x "$TTMULT/$PLATFORM/ttrcg"
    TTRCG_EXEC="$TTMULT/$PLATFORM/ttrcg"
    CFP_DIR="$TTMULT/$PLATFORM"
elif [ -f "$SCRIPT_DIR/../bin/$PLATFORM/ttrcg" ]; then
    echo "Found ttrcg at $SCRIPT_DIR/../bin/$PLATFORM/ttrcg but it's not executable, trying to fix permissions"
    chmod +x "$SCRIPT_DIR/../bin/$PLATFORM/ttrcg"
    TTRCG_EXEC="$SCRIPT_DIR/../bin/$PLATFORM/ttrcg"
    CFP_DIR="$SCRIPT_DIR/../bin/$PLATFORM"
else
    echo "ttrcg command was not found. Please make sure that TTMULT is set correctly."
    echo "Searched in:"
    echo "- $TTMULT/ttrcg"
    echo "- $TTMULT/$PLATFORM/ttrcg"
    echo "- $SCRIPT_DIR/../bin/$PLATFORM/ttrcg"
    
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

echo "Working with input file: $NAME.rcg"

# The input file $NAME.rcg has to be created using
# $NAME.rcg.orig file as a starting point.
# See this page for more details: http://www.anorg.chem.uu.nl/CTM4XAS/tutorial_rcg.html.
if [ -f "$NAME.rcg" ]; then
    echo "Input file found, proceeding with calculation"
    
    # Check if CFP files exist
    if [ ! -f "$CFP_DIR/rcg_cfp72" ] || [ ! -f "$CFP_DIR/rcg_cfp73" ] || [ ! -f "$CFP_DIR/rcg_cfp74" ]; then
        echo "Required CFP files not found in $CFP_DIR"
        ls -la "$CFP_DIR"
        exit 1
    fi
    
    echo "Copying CFP files from $CFP_DIR"
    cp "$CFP_DIR/rcg_cfp72" fort.72
    cp "$CFP_DIR/rcg_cfp73" fort.73
    cp "$CFP_DIR/rcg_cfp74" fort.74
    ln -sf "$NAME.rcg" fort.10
    
    # Create a temporary file for capturing output
    OUTPUT_FILE=$(mktemp)
    
    # Run the ttrcg executable and capture output
    echo "Running $TTRCG_EXEC (capturing output to $OUTPUT_FILE)"
    $TTRCG_EXEC > "$OUTPUT_FILE" 2>&1
    TTRCG_RESULT=$?
    
    # Check if the execution was successful
    if [ $TTRCG_RESULT -ne 0 ]; then
        echo "ttrcg calculation has failed with exit code $TTRCG_RESULT."
        echo "Output from ttrcg:"
        cat "$OUTPUT_FILE"
        rm "$OUTPUT_FILE"
        rm fort.10 fort.72 fort.73 fort.74
        if [ -f "FTN02" ]; then
            rm FTN02
        fi
        exit 1
    fi
    
    # Check if the output file was created
    if [ ! -f "fort.9" ]; then
        echo "ttrcg calculation did not produce expected output file (fort.9)."
        echo "Output from ttrcg:"
        cat "$OUTPUT_FILE"
        rm "$OUTPUT_FILE"
        rm fort.10 fort.72 fort.73 fort.74
        if [ -f "FTN02" ]; then
            rm FTN02
        fi
        exit 1
    fi
    
    echo "Output from ttrcg:"
    cat "$OUTPUT_FILE"
    rm "$OUTPUT_FILE"
    
    mv fort.9 $NAME.rcg_out
    # mv fort.14 $NAME.rcg_rme
    rm fort.10 fort.72 fort.73 fort.74
    if [ -f "FTN02" ]; then
        rm FTN02
    fi
    
    echo "ttrcg calculation has finished successfully."
else
    echo "Could not find $NAME.rcg in the current folder."
    echo "Contents of current directory:"
    ls -la .
    exit 1
fi

exit 0
