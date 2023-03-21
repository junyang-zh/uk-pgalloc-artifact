make HOSTCC=clang \
    HOSTCPP=clang++ \
    HOSTCXX=clang++ \
    CONFIG_COMPILER=clang \
    LDFLAGS=-lm \
    CFLAGS='-fprofile-instr-generate' \
    CXXFLAGS='-fprofile-instr-generate' \
    -j32