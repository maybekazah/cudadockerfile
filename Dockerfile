FROM tuttelikz/opencv-cuda:4.10.0-cuda11.8.0-arch8.6-ubuntu22.04

ENV TZ=Europe/Moscow
RUN ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
    
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONOPTIMIZE=1 \
    PYTHONHASHSEED=0 

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --upgrade pip && \
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 
RUN --mount=type=cache,target=/root/.cache/pip \ 
    pip install redis==5.2.1 \
    requests==2.32.3 \
    pytest==8.3.4 \
    rich==13.9.4\
    shapely==2.0.7\
    kornia==0.8.0\
    cupy-cuda12x==13.4.1\
    celery==5.4.0\
    meson==1.4.0 \
    ninja==1.11.1 \
    numba==0.61.2
    
    
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential pkg-config git ffmpeg unzip cmake \
        flex bison python3-setuptools python3-wheel \
        libnvidia-encode-525 \
    && rm -rf /var/lib/apt/lists/*
    

RUN ln -sf /usr/bin/python3 /usr/bin/python

COPY ./video_codec_sdk/Video_Codec_SDK_11.1.5.zip /tmp/
RUN cd /tmp && unzip Video_Codec_SDK_11.1.5.zip && \
    cp Video_Codec_SDK_11.1.5/Interface/* /usr/local/cuda/include/ && \
    cp Video_Codec_SDK_11.1.5/Lib/linux/stubs/x86_64/* /usr/local/cuda/lib64/stubs/ && \
    rm -rf Video_Codec_SDK_11.1.5*
    

COPY ./nv-codec-headers /tmp/nv-codec-headers
WORKDIR /tmp/nv-codec-headers
RUN make PREFIX=/usr install && ldconfig
    

RUN ln -sf /usr/local/cuda/lib64/stubs/libnvcuvid.so       /usr/lib/x86_64-linux-gnu/libnvcuvid.so && \
    ln -sf /usr/local/cuda/lib64/stubs/libnvidia-encode.so /usr/lib/x86_64-linux-gnu/libnvidia-encode.so && \
    ln -sf /usr/local/cuda/lib64/stubs/libcuda.so          /usr/lib/x86_64-linux-gnu/libcuda.so && \
    ln -sf /usr/local/cuda/lib64/stubs/libcuda.so          /usr/lib/x86_64-linux-gnu/libcuda.so.1
    
ENV CFLAGS="-I/usr/include"
ENV LDFLAGS="-L/usr/local/cuda/lib64/stubs"
    

WORKDIR /tmp
RUN git clone --depth 1 -b 4.10.0 https://github.com/opencv/opencv.git && \
    git clone --depth 1 -b 4.10.0 https://github.com/opencv/opencv_contrib.git && \
    cd opencv && mkdir build && cd build && \
    cmake -D CMAKE_BUILD_TYPE=Release \
          -D CMAKE_INSTALL_PREFIX=/usr/local \
          -D OPENCV_EXTRA_MODULES_PATH=/tmp/opencv_contrib/modules \
          -D WITH_CUDA=ON -D WITH_CUDNN=ON -D OPENCV_DNN_CUDA=ON \
          -D WITH_GSTREAMER=ON -D WITH_NVCUVID=ON -D WITH_CUDACODEC=ON \
          -D BUILD_opencv_cudacodec=ON -D CUDA_ARCH_BIN=6.1,7.5,8.0,8.6 \
          .. && \
    make -j"$(nproc)" && make install && ldconfig && \
    rm -rf /tmp/opencv /tmp/opencv_contrib
 

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install av==14.3.0   

    
RUN --mount=type=cache,target=/root/.cache/pip \
pip install httpx==0.28.1

WORKDIR /app
COPY . .

CMD ["python3", "main.py"]

