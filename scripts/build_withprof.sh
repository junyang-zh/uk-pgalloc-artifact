export APP_PREFIX=/home/jyzhang/workspace/apps/app-redis
export IN_PERFRAW=$APP_PREFIX/fs0/redis.perfraw
export OUT_PERFDATA=$APP_PREFIX/redis.profdata
#llvm-profdata merge -o $OUT_PERFDATA $IN_PERFRAW
printf "${OUT_PERFDATA} created, making...\n"
HTTP_PROXY=localhost:20171 make HOSTCC=clang \
    HOSTCPP=clang++ \
    HOSTCXX=clang++ \
    CONFIG_COMPILER=clang \
    CFLAGS="-fprofile-use=${OUT_PERFDATA}" \
    CXXFLAGS="-fprofile-use=${OUT_PERFDATA}" \
    LDFLAGS=-lm \
    -j32