FROM nvidia/cuda:12.8.0-cudnn-devel-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=America/Los_Angeles

RUN apt-get update && apt-get install -y \
    git \
    make build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev git git-lfs  \
    ffmpeg libsm6 libxext6 cmake libglx-mesa0 \
    && rm -rf /var/lib/apt/lists/* \
    && git lfs install

WORKDIR /code

COPY ./requirements.txt /code/requirements.txt

# User
RUN useradd -m -u 1042 user
USER user
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH

# Pyenv
RUN curl https://pyenv.run | bash
ENV PATH=$HOME/.pyenv/shims:$HOME/.pyenv/bin:$PATH

ARG PYTHON_VERSION=3.10.12
# Python
RUN pyenv install $PYTHON_VERSION && \
    pyenv global $PYTHON_VERSION && \
    pyenv rehash && \
    pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir \
    datasets \
    huggingface-hub "protobuf<4" "click<8.1"

RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt

WORKDIR $HOME/app

# Copy the current directory contents into the container at $HOME/app setting the owner to the user
RUN git clone https://github.com/comfyanonymous/ComfyUI . && \
    pip install xformers!=0.0.18 --no-cache-dir -r requirements.txt --extra-index-url https://download.pytorch.org/whl/cu121

# ComfyUI Manager
RUN cd custom_nodes && git clone https://github.com/ltdrdata/ComfyUI-Manager.git

# Fix n-suit installation.
RUN python -m pip install llama-cpp-python

RUN echo "Done"

CMD ["python", "main.py", "--listen", "0.0.0.0", "--port", "7860"]
