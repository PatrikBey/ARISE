FROM ubuntu:22.04
# ---- set metadata ---- #
LABEL name="ARISE"
LABEL maintainer="Patrik Bey <patrik.bey@ucl.ac.uk>"
LABEL version="0.1"
LABEL description="Automated Region of Interest Streamline Extraction (ARISE)"
LABEL url="https://github.com/PatrikBey/ARISE"


ARG DEBIAN_FRONTEND=noninteractive

ENV LANG="C.UTF-8" \
    LC_ALL="C.UTF-8" \
    OS=Linux

# ---- Install OS packages using apt-get ---- #
RUN apt-get -qq update && \
apt-get install -yq --no-install-recommends \
bc \
bzip2 \
ca-certificates \
curl \
libgomp1 \
perl-modules \
tar \
tcsh \
wget \
libxmu6 \
git \
libeigen3-dev \
libfftw3-dev \
libgl1-mesa-dev \
libpng-dev \
libtiff5-dev \
zlib1g-dev \
libxext6 \
libxpm-dev \
libxt6 \
libfreetype6 \
libglib2.0 \
gcc \
g++ \
libglu1 \
file \
dc \
mesa-utils \
pulseaudio \
libquadmath0 \
libgtk2.0-0 \
firefox \
figlet \
unzip && \
apt-get clean && \
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


RUN wget -q https://repo.continuum.io/miniconda/Miniconda2-4.7.12.1-Linux-x86_64.sh && \
    bash Miniconda2-4.7.12.1-Linux-x86_64.sh -b -p /usr/local/miniconda && \
    rm Miniconda2-4.7.12.1-Linux-x86_64.sh

ENV PATH="/usr/local/miniconda/bin:$PATH"

RUN conda config --add channels conda-forge && \
    conda install -y mkl=2019.3 mkl-service=2.0.2 numpy=1.16.4 nibabel=2.4.1 pandas=0.24.2 && sync && \
    conda clean -tipsy && sync 

# ---- install mrtrix3 for tractography ---- #

RUN git clone -b "master" --depth 1 https://github.com/MRtrix3/mrtrix3.git /opt/mrtrix3
RUN cd /opt/mrtrix3/ && \
    ./configure -nogui && \
    ./build -persistent -nopaginate

ENV MRTRIXDIR=/opt/mrtrix3

ENV PATH="/opt/mrtrix3/bin:$PATH"

# ---- install FSL for processing ---- #

RUN wget https://fsl.fmrib.ox.ac.uk/fsldownloads/fslconda/releases/fslinstaller.py && \
    python2 ./fslinstaller.py -d /usr/local/fsl/

ENV FSLDIR=/usr/local/fsl
ENV PATH="${FSLDIR}/bin:${PATH}"
ENV FSLOUTPUTTYPE=NIFTI_GZ

# ---- install figlet and lolcat for colourful output ---- #
RUN pip install lolcat

# ---- copy templates and source code ---- #
ENV TEMPLATEDIR="/templates"
COPY Templates "/templates"

RUN mkdir "/src"
COPY Code "/src"
ENV SRCDIR="/src"
WORKDIR "/src"

# ---- call run script ---- #
CMD ["bash", "/src/run.sh"]