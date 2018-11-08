FROM debian:stretch as build

ENV TARGET_ARCH=arm64
ENV TARGET_TRIPLET=aarch64-linux-gnu

RUN export DEBIAN_FRONTEND=noninteractive \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      gnupg2 \
      wget \
 && wget -O - https://packages.icinga.com/icinga.key | apt-key add - \
 && dpkg --add-architecture ${TARGET_ARCH} \
 && sed 's/^deb /deb-src /' /etc/apt/sources.list > /etc/apt/sources.list.d/debsrc.list \
 && echo "deb     http://packages.icinga.com/debian icinga-stretch main"  > /etc/apt/sources.list.d/icinga.list \
 && echo "deb-src http://packages.icinga.com/debian icinga-stretch main" >> /etc/apt/sources.list.d/icinga.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      dpkg-dev \
      qemu-system-arm \
# Link static, because on the local machine it's called /usr/bin/qemu-arm-static
 && ln -sT /usr/bin/qemu-system-arm /usr/bin/qemu-arm-static \
 && true

RUN export DEBIAN_FRONTEND=noninteractive \
 && apt-get install -y --no-install-recommends \
      default-libmysqlclient-dev:${TARGET_ARCH} \
      libboost-dev:${TARGET_ARCH} \
      libboost-program-options-dev:${TARGET_ARCH} \
      libboost-regex1.62-dev:${TARGET_ARCH} \
      libboost-regex-dev:${TARGET_ARCH} \
      libboost-system-dev:${TARGET_ARCH} \
      libboost-test-dev:${TARGET_ARCH} \
      libboost-thread-dev:${TARGET_ARCH} \
      libedit-dev:${TARGET_ARCH} \
      libicu-dev:${TARGET_ARCH} \
      libmariadbclient-dev:${TARGET_ARCH} \
      libmariadbclient-dev-compat:${TARGET_ARCH} \
      libpq-dev:${TARGET_ARCH} \
      libssl-dev:${TARGET_ARCH} \
      libsystemd-dev:${TARGET_ARCH} \
      libyajl-dev:${TARGET_ARCH} \
 && apt-get install -y --no-install-recommends \
      bash-completion \
      bison \
      build-essential \
      cmake \
      crossbuild-essential-${TARGET_ARCH} \
      debhelper \
      dh-systemd \
      flex \
      po-debconf \
 && true

ENV ICINGA_VERSION=2.10.1
ENV BASEDIR=/icinga2-${ICINGA_VERSION}
RUN true \
 && apt-get source icinga2 \
 && ln -sT ${BASEDIR}/obj-${TARGET_TRIPLET}/Bin/None/mkclass        /usr/bin/mkclass \
 && ln -sT ${BASEDIR}/obj-${TARGET_TRIPLET}/Bin/None/mkunity        /usr/bin/mkunity \
 && ln -sT ${BASEDIR}/obj-${TARGET_TRIPLET}/Bin/None/mkembedconfig  /usr/bin/mkembedconfig \
 && sed -i '/g++ (>= 1.96)/d;/make (>= 3.81)/d' ${BASEDIR}/debian/control

WORKDIR "${BASEDIR}"

RUN export DEB_BUILD_OPTIONS=nocheck \
 && dpkg-buildpackage -us -F -a "${TARGET_ARCH}" --target-arch "${TARGET_ARCH}"

# Use a small image, which only holds a sh and the deb packages
# We need the sh to successfully copy the files out, when the files aren't used in docker context
FROM alpine as transfer
COPY --from=build /*.deb /pkgs/

COPY entrypoint.sh /entrypoint

ENTRYPOINT /entrypoint
