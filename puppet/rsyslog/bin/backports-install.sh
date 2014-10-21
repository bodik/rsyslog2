dpkg --purge libjson0:i386 libpulse0:i386 ia32-libs-i386 libsdl1.2debian:i386 ia32-libs
find /tmp/build-area/ -name "*deb" ! -name "*-dev*" ! -name "*-doc*" -exec dpkg -i {} \;
