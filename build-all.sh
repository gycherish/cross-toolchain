xmake f --Libc=musl --Arch=i686
xmake -yvD
if [ $? -ne 0 ]; then
    exit $?
fi

xmake f --Libc=musl --Arch=x86_64
xmake -yvD
if [ $? -ne 0 ]; then
    exit $?
fi

xmake f --Libc=musl --Arch=aarch64
xmake -yvD
if [ $? -ne 0 ]; then
    exit $?
fi

xmake f --Libc=musl --Arch=loongarch64
xmake -yvD
if [ $? -ne 0 ]; then
    exit $?
fi

xmake f --Libc=glibc --Arch=i686
xmake -yvD
if [ $? -ne 0 ]; then
    exit $?
fi

xmake f --Libc=glibc --Arch=x86_64
xmake -yvD
if [ $? -ne 0 ]; then
    exit $?
fi

xmake f --Libc=glibc --Arch=aarch64
xmake -yvD
if [ $? -ne 0 ]; then
    exit $?
fi

xmake f --Libc=glibc --Arch=loongarch64
xmake -yvD
if [ $? -ne 0 ]; then
    exit $?
fi

echo "build all cross toolchain successfully!"
