#FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04
FROM nvcr.io/nvidia/rapidsai/rapidsai:23.06-cuda11.8-runtime-ubuntu22.04-py3.10
#FROM nvcr.io/nvidia/pytorch:23.07-py3
# metainformation
LABEL org.opencontainers.image.version = "2.3.1"
LABEL org.opencontainers.image.authors = "Matthias Fey"
LABEL org.opencontainers.image.source = "https://github.com/pyg-team/pytorch_geometric"
LABEL org.opencontainers.image.licenses = "MIT"
LABEL org.opencontainers.image.base.name="docker.io/library/ubuntu:22.04"

RUN apt-get update && apt-get install -y apt-transport-https ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends apt-utils gnupg2 curl && \
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/7fa2af80.pub | apt-key add - && \
    echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64 /" > /etc/apt/sources.list.d/cuda.list && \
    echo "deb https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu2004/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list &&\
    apt-get purge --autoremove -y curl && \
rm -rf /var/lib/apt/lists/*

ENV CUDA_VERSION 11.8.0
ENV NCCL_VERSION 2.18.3
ENV CUDA_PKG_VERSION 11-8=$CUDA_VERSION-1
ENV CUDNN_VERSION 8.9.3

ENV LIBRARY_PATH /usr/local/cuda/lib64/stubs

# NVIDIA docker 1.0.
LABEL com.nvidia.volumes.needed="nvidia_driver"
LABEL com.nvidia.cuda.version="${CUDA_VERSION}"

RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64

# NVIDIA container runtime.
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV NVIDIA_REQUIRE_CUDA "cuda>=10.0 brand=tesla,driver>=384,driver<385 brand=tesla,driver>=410,driver<411"

# PyTorch (Geometric) installation
RUN rm /etc/apt/sources.list.d/cuda.list && \
    rm /etc/apt/sources.list.d/nvidia-ml.list

RUN apt-get update &&  apt-get install -y \
    curl \
    ca-certificates \
    vim \
    sudo \
    git \
    bzip2 \
    libx11-6 \
    h5utils \
    wget \
 && rm -rf /var/lib/apt/lists/*

# Create a working directory.
#RUN mkdir /workspace
WORKDIR /workspace

# Create a non-root user and switch to it.
RUN adduser --disabled-password --gecos '' --shell /bin/bash user \
 && chown -R user:user /workspace
RUN echo "user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-user
USER user

# All users can use /home/user as their home directory.
ENV HOME=/home/user
RUN chmod 777 /home/user

# Install Miniconda.
#RUN curl -so ~/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
# && chmod +x ~/miniconda.sh \
# && ~/miniconda.sh -b -p ~/miniconda \
# && rm ~/miniconda.sh
#ENV PATH=/home/user/miniconda/bin:$PATH
#ENV CONDA_AUTO_UPDATE_CONDA=false

# Create a Python 3.8 environment.
#RUN /home/user/miniconda/bin/conda install conda-build \
# && /home/user/miniconda/bin/conda create -y --name py38 python=3.8.10 \
# && /home/user/miniconda/bin/conda clean -ya
#ENV CONDA_DEFAULT_ENV=py38
#ENV CONDA_PREFIX=/home/user/miniconda/envs/$CONDA_DEFAULT_ENV
#ENV PATH=$CONDA_PREFIX/bin:$PATH

# update python pip
RUN python -m pip install --upgrade pip
RUN python --version
RUN python -m pip --version

# CUDA 11.8-specific steps.
#RUN conda install -y -c pytorch -c nvidia \
#    pytorch=2.1.0 \ 
#    torchvision \
#    pytorch-cuda=11.8 \
#    #cudatoolkit=11.8 \
#    #"pytorch=2.1.0=py3.8_cuda11.8.0_cudnn8.9.0.131_0" \
#    #torchvision=0.15.2=py38_cu118 \
# && conda clean -ya

RUN pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118

# Install HDF5 Python bindings.
RUN pip install h5py==3.10.0 
RUN pip install h5py-cache

# Install Requests, a Python library for making HTTP requests.
RUN conda install -y requests=2.31.0 \
 && conda clean -ya

# Install Graphviz.
#RUN conda install -y graphviz=2.50.0 python-graphviz=0.8.4 \
# && conda clean -ya

# Install OpenCV3 Python bindings.
#RUN sudo apt-get update && sudo apt-get install -y --no-install-recommends \
#    libgtk2.0-0 \
#    libcanberra-gtk-module \
# && sudo rm -rf /var/lib/apt/lists/*
#RUN conda install -y -c menpo opencv3=3.2.0 \
# && conda clean -ya

# Install PyG.
RUN CPATH=/usr/local/cuda/include:$CPATH \
 && LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH \
 && DYLD_LIBRARY_PATH=/usr/local/cuda/lib:$DYLD_LIBRARY_PATH

RUN pip install scipy

RUN pip install --no-index torch_scatter -f https://data.pyg.org/whl/torch-2.1.0+cu118.html \
 && pip install --no-index torch_sparse -f https://data.pyg.org/whl/torch-2.1.0+cu118.html \
 && pip install --no-index torch_cluster -f https://data.pyg.org/whl/torch-2.1.0+cu118.html \
 && pip install --no-index torch_spline_conv -f https://data.pyg.org/whl/torch-2.1.0+cu118.html \
 && pip install torch-geometric

# copy and install package
COPY . .
RUN python -m pip install -e .
