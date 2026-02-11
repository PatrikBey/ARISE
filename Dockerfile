# ============================================================
# ARISE - Automated Region of Interest Streamline Extraction
# Multi-stage Dockerfile
# ============================================================
#
# Stage 1: Compile MRtrix3 from source (no GUI)
# Stage 2: Final runtime image with MRtrix3 + FSL + Python
#
# Build:
#   docker build -f DOCKERFILE -t arise:0.2 .
#
# Run (disconnectome):
#   docker run -v /path/to/study:/data \
#       -e Seed="lesion_mask.nii.gz" \
#       -e Atlas="AAL3v1" \
#       arise:0.2
#
# Run (ROI-to-ROI):
#   docker run -v /path/to/study:/data \
#       -e Seed="SeedROIs" \
#       -e Target="TargetROIs" \
#       arise:0.2
#
# ============================================================


# ============================================================
# Stage 1: Build MRtrix3 from source
# ============================================================
FROM ubuntu:22.04 AS mrtrix-builder

ARG DEBIAN_FRONTEND=noninteractive

# Install only the build-time dependencies needed for MRtrix3
RUN apt-get update && apt-get install -yq --no-install-recommends \
    ca-certificates \
    g++ \
    git \
    libeigen3-dev \
    libfftw3-dev \
    libpng-dev \
    libtiff-dev \
    python3 \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Clone MRtrix3 stable branch and build without GUI
RUN git clone -b master --depth 1 https://github.com/MRtrix3/mrtrix3.git /opt/mrtrix3

WORKDIR /opt/mrtrix3
RUN python3 ./configure -nogui && \
    NUMBER_OF_PROCESSORS=$(nproc) python3 ./build -persistent -nopaginate && \
    rm -rf tmp/ core/ src/ testing/ docs/ .git


# ============================================================
# Stage 2: Final runtime image
# ============================================================
FROM ubuntu:22.04

# ---- Metadata ---- #
LABEL name="ARISE"
LABEL maintainer="Patrik Bey <patrik.bey@ucl.ac.uk>"
LABEL version="0.3"
LABEL description="Automated Region of Interest Streamline Extraction (ARISE)"
LABEL url="https://github.com/PatrikBey/ARISE"

ARG DEBIAN_FRONTEND=noninteractive

ENV LANG="C.UTF-8" \
    LC_ALL="C.UTF-8"

# ---- Install runtime OS packages ---- #
# Includes:
#   - MRtrix3 shared library dependencies (libgomp1, zlib1g, libfftw3, libtiff5, libpng16-16)
#   - Python 3 with pip (for numpy, nibabel, pandas, lolcat)
#   - python-is-python3 (symlinks 'python' -> 'python3', needed by pipeline scripts)
#   - figlet (decorative banner output)
#   - bc, file, ca-certificates, curl, wget (general utilities)
RUN apt-get update && apt-get install -yq --no-install-recommends \
    bc \
    ca-certificates \
    curl \
    figlet \
    file \
    libfftw3-double3 \
    libfftw3-single3 \
    libgomp1 \
    libpng16-16 \
    libquadmath0 \
    libtiff5 \
    python-is-python3 \
    python3 \
    python3-pip \
    wget \
    zlib1g \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ---- Install Python packages via pip ---- #
# numpy:   used for connectome matrix annotation (genfromtxt, savetxt, concatenate, vstack)
# nibabel: neuroimaging file I/O (kept for future use)
# pandas:  data manipulation (kept for future use)
# lolcat:  colorized terminal output for logging
RUN pip3 install --no-cache-dir \
    numpy \
    nibabel \
    pandas \
    lolcat

# ---- Copy MRtrix3 binaries from builder stage ---- #
# Pipeline uses: tck2connectome, connectome2tck, tckedit
COPY --from=mrtrix-builder /opt/mrtrix3 /opt/mrtrix3
ENV MRTRIXDIR=/opt/mrtrix3
ENV PATH="/opt/mrtrix3/bin:${PATH}"

# ---- Install Miniforge + FSL tools ---- #
# Using Miniforge (conda-forge based) to avoid Anaconda TOS issues.
# Only installing the specific FSL packages needed by the pipeline:
#   fsl-avwutils: provides fslmaths, fslval
#   fsl-flirt:    provides flirt (image registration/resampling)
RUN wget -q https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh && \
    bash Miniforge3-Linux-x86_64.sh -b -p /opt/miniforge && \
    rm Miniforge3-Linux-x86_64.sh

ENV PATH="/opt/miniforge/bin:${PATH}"

RUN mamba install -y -n base \
    -c https://fsl.fmrib.ox.ac.uk/fsldownloads/fslconda/public/ \
    -c conda-forge \
    fsl-avwutils fsl-flirt \
    && mamba clean -afy

# FSL environment configuration
# FSLDIR points to the Miniforge base env where FSL packages are installed.
# Pipeline accesses flirt as ${FSLDIR}/bin/flirt (functions.sh:80).
ENV FSLDIR=/opt/miniforge
ENV FSLOUTPUTTYPE=NIFTI_GZ
ENV PATH="${FSLDIR}/bin:${PATH}"

# ---- Copy templates and source code ---- #
ENV TEMPLATEDIR="/templates"
COPY Templates /templates

RUN mkdir /src
COPY Code /src
ENV SRCDIR="/src"
WORKDIR /src

# ---- Entry point ---- #
CMD ["bash", "/src/run.sh"]
