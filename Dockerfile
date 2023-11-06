# base image
#FROM pytorch/pytorch:2.1.0-cuda11.8-cudnn8-runtime
#FROM nvcr.io/nvidia/rapidsai/notebook:23.10-cuda11.8-py3.10
#FROM nvcr.io/nvidia/rapidsai/base:23.10-cuda11.8-py3.10
FROM nvcr.io/nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04 
#FROM nvcr.io/nvidia/pytorch:23.07-py3

# local and envs
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV PIP_ROOT_USER_ACTION=ignore
ARG DEBIAN_FRONTEND=noninteractive

#USER rapids

# add some packages
RUN apt-get update
RUN apt-get install -y git h5utils wget vim \
   python3.10 \
   python3-pip \
   && \
   apt-get clean && \
   rm -rf /var/lib/apt/lists/*

# update python pip
RUN python3 -m pip install --upgrade pip 
#python3 for nvidia and python for pytorch 
RUN python3 --version
RUN python3 -m pip --version

RUN pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118
RUN pip install onnx onnxscript

# Install PyG.
RUN CPATH=/usr/local/cuda/include:$CPATH \
 && LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH \
 && DYLD_LIBRARY_PATH=/usr/local/cuda/lib:$DYLD_LIBRARY_PATH

RUN pip install scipy

RUN pip install pyg_lib -f https://data.pyg.org/whl/torch-2.1.0+cu118.html \
 && pip install --no-index torch_scatter -f https://data.pyg.org/whl/torch-2.1.0+cu118.html \
 && pip install --no-index torch_sparse -f https://data.pyg.org/whl/torch-2.1.0+cu118.html \
 && pip install --no-index torch_cluster -f https://data.pyg.org/whl/torch-2.1.0+cu118.html \
 && pip install --no-index torch_spline_conv -f https://data.pyg.org/whl/torch-2.1.0+cu118.html \
 && pip install torch-geometric

# copy and install package
COPY . .
RUN pip install prefix_sum-0.0.0-cp310-cp310-linux_x86_64.whl
RUN pip install frnn-0.0.0-cp310-cp310-linux_x86_64.whl
RUN pip install -e .