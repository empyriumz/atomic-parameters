# Atomic Parameters Docker Image

This Docker image provides everything needed to run the atomic parameters calculation codes originally developed by R.D. Cowan.

## Building the Docker Image

To build the Docker image, navigate to the repository root and run:

```bash
docker build -t atomic-parameters .
```

## Running the Docker Container

### Basic Usage

To run the container with default settings:

```bash
docker run -it atomic-parameters
```

### Calculating Atomic Parameters

To calculate parameters for specific elements and configurations:

```bash
docker run -it atomic-parameters python /home/atomic/atomic-parameters/parameters.py --element "Fe" --configuration "1s1,3d5"
```

### Running an Interactive Shell

To get an interactive shell where you can run multiple commands:

```bash
docker run -it atomic-parameters bash
```

Then within the container, you can run:

```bash
python parameters.py --element "Fe" --configuration "1s1,3d5"
```

### Mounting a Volume for Saving Results

To save the output to your local machine, mount a volume:

```bash
docker run -it -v $(pwd)/results:/home/atomic/results atomic-parameters bash
```

Then within the container:

```bash
python parameters.py --element "Fe" --configuration "1s1,3d5" > /home/atomic/results/fe_params.txt
```

## Troubleshooting

If you encounter any issues:

1. Make sure the executables have the correct permissions
2. Check that the Fortran libraries are correctly installed
3. Enable debug output using the `--loglevel debug` flag

## Notes

- This image includes the required Fortran runtime libraries (`libgfortran5`, `libquadmath0`)
- The `TTMULT` environment variable is pre-configured to point to the correct binaries
- Both Linux and macOS binaries are included, but only Linux binaries will be used when running in the container

## References

- Original software: Cowan's Codes for atomic structure calculations
- Repository: [atomic-parameters](https://github.com/mretegan/atomic-parameters) 