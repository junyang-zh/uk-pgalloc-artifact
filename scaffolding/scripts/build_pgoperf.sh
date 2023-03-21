export APP_PREFIX=`pwd`
export IN_PERFRAW=$APP_PREFIX/fs0/.perfraw
export OUT_PERFDATA=$APP_PREFIX/.profdata
llvm-profdata merge -o $OUT_PERFDATA $IN_PERFRAW
printf "${OUT_PERFDATA} created, making...\n"
make HOSTCC=clang \
    HOSTCPP=clang++ \
    HOSTCXX=clang++ \
    CONFIG_COMPILER=clang \
    CFLAGS="-fprofile-use=${OUT_PERFDATA}" \
    CXXFLAGS="-fprofile-use=${OUT_PERFDATA}" \
    LDFLAGS=-lm \
    -j32