FROM ghcr.io/gliwka/centos7-toolchain:main@sha256:e6cf17223408bb4d1314be547d74b23d04bcf6480d2fe23822fb672a52775f76

# Stage 2: Clang 22.1.8 + lld compiled with the existing Stage 1 Clang 17
ENV CC=/usr/local/bin/clang
ENV CXX=/usr/local/bin/clang++
RUN mkdir /clang22 && \
    cd /clang22 && \
    curl -O -L https://github.com/llvm/llvm-project/releases/download/llvmorg-22.1.8/llvm-project-22.1.8.src.tar.xz && \
    echo "2615b20ba08534f83ab8ecc7b5ba43b5f1dfcf9cdb2534a32fcdbf0ccdd9a008b46276e45ef26ed9377f65b5e4ae89ea798f3863fd034484b5715140f3a7b35c  llvm-project-22.1.8.src.tar.xz" | sha512sum -c && \
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
