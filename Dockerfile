FROM ghcr.io/gliwka/centos7-toolchain:main

# LLVM 22.1.8 needs Python >= 3.8 (CentOS 7 has 3.6)
RUN mkdir /python3 && cd /python3 && \
    curl -O https://www.python.org/ftp/python/3.9.21/Python-3.9.21.tar.xz && \
    tar -xvf Python-3.9.21.tar.xz && \
    cd Python-3.9.21 && \
    ./configure --enable-optimizations && \
    make -j $(nproc) && make install && \
    rm -rf /python3

# Stage 2: Clang 22.1.8 + lld compiled with the existing Stage 1 Clang 17
ENV CC=/usr/local/bin/clang
ENV CXX=/usr/local/bin/clang++
RUN mkdir /clang22 && \
    cd /clang22 && \
    curl -O -L https://github.com/llvm/llvm-project/releases/download/llvmorg-22.1.8/llvm-project-22.1.8.src.tar.xz && \
    tar -xvf llvm-project-22.1.8.src.tar.xz && \
    cd llvm-project-22.1.8.src && \
    mkdir build && \
    cd build && \
    cmake -DLLVM_ENABLE_PROJECTS="clang;lld" \
          -DCMAKE_BUILD_TYPE=Release \
          -G "Unix Makefiles" ../llvm && \
    make -j $(nproc) && \
    make install && \
    rm -rf /clang22
ENV CC=
ENV CXX=
ENTRYPOINT ["/bin/bash", "-l", "-c"]
