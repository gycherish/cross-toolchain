BuildType=cross
if [ "$1" = "cross-native" ]; then
    BuildType=cross-native
fi

xmake f --Libc=musl --Arch=i686 --BuildType=$BuildType
xmake -yvD
if [ $? -ne 0 ]; then
    exit $?
fi

xmake f --Libc=musl --Arch=x86_64 --BuildType=$BuildType
xmake -yvD
if [ $? -ne 0 ]; then
    exit $?
fi

xmake f --Libc=musl --Arch=aarch64 --BuildType=$BuildType
xmake -yvD
if [ $? -ne 0 ]; then
    exit $?
fi

xmake f --Libc=musl --Arch=loongarch64 --BuildType=$BuildType
xmake -yvD
if [ $? -ne 0 ]; then
    exit $?
fi

xmake f --Libc=glibc --Arch=i686 --BuildType=$BuildType
xmake -yvD
if [ $? -ne 0 ]; then
    exit $?
fi

xmake f --Libc=glibc --Arch=x86_64 --BuildType=$BuildType
xmake -yvD
if [ $? -ne 0 ]; then
    exit $?
fi

xmake f --Libc=glibc --Arch=aarch64 --BuildType=$BuildType
xmake -yvD
if [ $? -ne 0 ]; then
    exit $?
fi

xmake f --Libc=glibc --Arch=loongarch64 --BuildType=$BuildType
xmake -yvD
if [ $? -ne 0 ]; then
    exit $?
fi

echo "build all toolchain successfully!"
