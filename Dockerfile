FROM docker.io/library/centos:7
ADD adoptium.repo /etc/yum.repos.d/
ADD adoptium.gpg /etc/pki/rpm-gpg/
RUN sed -i 's/^mirrorlist=/#mirrorlist=/g' /etc/yum.repos.d/*.repo && \
    sed -i 's|^#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/*.repo && \
    yum update -y && \
    yum install -y centos-release-scl git python3 openssl-devel patch temurin-21-jdk && \
    yum clean all && \
    rm -rf /var/cache/yum
RUN echo $'[centos-sclo-rh]\nname=CentOS-7 - SCLo rh\nbaseurl=http://vault.centos.org/centos/7/sclo/x86_64/rh/\ngpgcheck=1\nenabled=1\ngpgkey=http://vault.centos.org/centos/7/os/x86_64/RPM-GPG-KEY-CentOS-7\n' > /etc/yum.repos.d/centos-sclo-rh-vault.repo && \
    echo $'[centos-sclo-sclo]\nname=CentOS-7 - SCLo sclo\nbaseurl=http://vault.centos.org/centos/7/sclo/x86_64/sclo/\ngpgcheck=1\nenabled=1\ngpgkey=http://vault.centos.org/centos/7/os/x86_64/RPM-GPG-KEY-CentOS-7\n' > /etc/yum.repos.d/centos-sclo-sclo-vault.repo && \
    yum-config-manager --disable centos-sclo-rh centos-sclo-sclo 2>/dev/null || true && \
    yum install -y devtoolset-9 binutils-devel && \
    yum clean all && \
    rm -rf /var/cache/yum
COPY --chmod=0755 .bashrc /root
# Need this because GitHub Actions chooses to override $HOME
ENV BASH_ENV=/root/.bashrc
# Make sure devtoolset gets used during build
SHELL [ "/bin/bash", "-l", "-c" ]
RUN mkdir /maven && \
    cd /maven && \
    curl -O -L https://dlcdn.apache.org/maven/maven-3/3.9.5/binaries/apache-maven-3.9.5-bin.tar.gz && \
    echo "4810523ba025104106567d8a15a8aa19db35068c8c8be19e30b219a1d7e83bcab96124bf86dc424b1cd3c5edba25d69ec0b31751c136f88975d15406cab3842b  apache-maven-3.9.5-bin.tar.gz" | sha512sum -c && \
    tar -xvf apache-maven-3.9.5-bin.tar.gz && \
    mv apache-maven-3.9.5 /usr/local/src/apache-maven && \
    ln -s /usr/local/src/apache-maven/bin/mvn /usr/local/bin/mvn && \
    rm -rf /maven
RUN mkdir /cmake && \
    cd /cmake && \
    curl -O -L https://github.com/Kitware/CMake/releases/download/v3.27.8/cmake-3.27.8.tar.gz && \
    echo "ca7782caee11d487a21abcd1c00fce03f3172c718c70605568d277d5a8cad95a18f2bf32a52637935afb0db1102f0da92d5a412a7166e3f19be2767d6f316f3d  cmake-3.27.8.tar.gz" | sha512sum -c && \
    tar -xvf cmake-3.27.8.tar.gz && \
    cd cmake-3.27.8 && \
    ./bootstrap --parallel=$(nproc) && \
    make -j $(nproc) && \
    make install && \
    rm -rf /cmake
RUN mkdir /clang && \
    cd /clang && \
    curl -O -L https://github.com/llvm/llvm-project/releases/download/llvmorg-17.0.5/llvm-project-17.0.5.src.tar.xz && \
    echo "793b63aa875b6d02e3a2803815cc9361b76c9ab1506967e18630fc3d6811bf51c73f53c51d148a5fc72e87e35dc2b88cb18b48419939c436451fe65c5a326022  llvm-project-17.0.5.src.tar.xz" | sha512sum -c && \
    tar -xvf llvm-project-17.0.5.src.tar.xz && \
    cd llvm-project-17.0.5.src && \
    mkdir build && \
    cd build && \
    cmake -DLLVM_ENABLE_PROJECTS=clang -DCMAKE_BUILD_TYPE=Release -G "Unix Makefiles" ../llvm && \
    make -j $(nproc) && \
    make install && \
    rm -rf /clang
# Stage 2: Clang 22.1.8 + lld compiled with Stage 1 Clang 17
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
          -DLLVM_BINUTILS_INCDIR=/usr/include \
          -DCMAKE_BUILD_TYPE=Release \
          -G "Unix Makefiles" ../llvm && \
    make -j $(nproc) && \
    make install && \
    rm -rf /clang22
# Revert CC/CXX to default so Stage 1 Clang is not accidentally used
ENV CC=
ENV CXX=
ENTRYPOINT ["/bin/bash", "-l", "-c"]