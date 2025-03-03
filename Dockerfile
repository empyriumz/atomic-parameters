FROM ubuntu:22.04

LABEL maintainer="Your Name <your.email@example.com>"
LABEL description="Docker image for atomic-parameters using Cowan's codes"

# Set environment variables to avoid interactive installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    wget \
    git \
    libgfortran5 \
    libquadmath0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -ms /bin/bash atomic

# Install Miniforge3 (includes conda and mamba with conda-forge configured)
WORKDIR /tmp
RUN wget "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh" -O miniforge.sh \
    && chmod +x miniforge.sh \
    && ./miniforge.sh -b -p /opt/conda \
    && rm miniforge.sh

# Make conda accessible to atomic user
RUN chown -R atomic:atomic /opt/conda

# Set up conda for the atomic user
USER atomic
ENV PATH=/opt/conda/bin:$PATH
RUN conda init bash \
    && mamba create -y -n atomic-env python=3.10 \
    && mamba install -y -n atomic-env -c conda-forge xraydb \
    && echo "conda activate atomic-env" >> ~/.bashrc

# Set the working directory to the user's home
WORKDIR /home/atomic

# Copy the repository to the container
COPY --chown=atomic:atomic . /home/atomic/atomic-parameters

# Set TTMULT environment variable to the repository's cowan/bin/ directory
ENV TTMULT=/home/atomic/atomic-parameters/cowan/bin

# Make sure executable permissions are correct on binaries
RUN chmod +x /home/atomic/atomic-parameters/cowan/bin/linux/* \
    && chmod +x /home/atomic/atomic-parameters/cowan/bin/darwin/* \
    && chmod +x /home/atomic/atomic-parameters/cowan/scripts/*.sh

# Set up shell entrypoint that activates the conda environment
SHELL ["/bin/bash", "-c"]
ENTRYPOINT ["/bin/bash", "-c", "source /opt/conda/etc/profile.d/conda.sh && conda activate atomic-env && exec \"$@\"", "-s"]

# Default command
CMD ["python /home/atomic/atomic-parameters/parameters.py --help"] 