FROM ghcr.io/gliwka/centos7-toolchain:main@sha256:e6cf17223408bb4d1314be547d74b23d04bcf6480d2fe23822fb672a52775f76

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
