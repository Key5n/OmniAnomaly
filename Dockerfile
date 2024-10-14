FROM nvcr.io/nvidia/cuda:9.0-cudnn7.2-devel-ubuntu16.04

ENV DEBIAN_FRONTEND noninteractive

RUN set -eux; \
	apt-get update; \
	apt-get upgrade -y --no-install-recommends \
	git \
	zlib1g-dev \
	libexpat1-dev

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
	ca-certificates \
	curl \
	netbase \
	wget \
	; \
	rm -rf /var/lib/apt/lists/*

RUN set -ex; \
	if ! command -v gpg > /dev/null; then \
	apt-get update; \
	apt-get install -y --no-install-recommends \
	gnupg \
	dirmngr \
	; \
	rm -rf /var/lib/apt/lists/*; \
	fi
# procps is very common in build systems, and is a reasonably small package
RUN apt-get update && apt-get install -y --no-install-recommends \
	git \
	mercurial \
	openssh-client \
	subversion \
	\
	procps \
	&& rm -rf /var/lib/apt/lists/*

RUN set -ex; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
	autoconf \
	automake \
	bzip2 \
	dpkg-dev \
	file \
	g++ \
	gcc \
	imagemagick \
	libbz2-dev \
	libc6-dev \
	libcurl4-openssl-dev \
	libdb-dev \
	libevent-dev \
	libffi-dev \
	libgdbm-dev \
	libglib2.0-dev \
	libgmp-dev \
	libjpeg-dev \
	libkrb5-dev \
	liblzma-dev \
	libmagickcore-dev \
	libmagickwand-dev \
	libmaxminddb-dev \
	libncurses5-dev \
	libncursesw5-dev \
	libpng-dev \
	libpq-dev \
	libreadline-dev \
	libsqlite3-dev \
	libssl-dev \
	libtool \
	libwebp-dev \
	libxml2-dev \
	libxslt-dev \
	libyaml-dev \
	make \
	patch \
	unzip \
	xz-utils \
	zlib1g-dev \
	\
	# https://lists.debian.org/debian-devel-announce/2016/09/msg00000.html
	$( \
	# if we use just "apt-cache show" here, it returns zero because "Can't select versions from package 'libmysqlclient-dev' as it is purely virtual", hence the pipe to grep
	if apt-cache show 'default-libmysqlclient-dev' 2>/dev/null | grep -q '^Version:'; then \
	echo 'default-libmysqlclient-dev'; \
	else \
	echo 'libmysqlclient-dev'; \
	fi \
	) \
	; \
	rm -rf /var/lib/apt/lists/*

ENV PYTHON_VERSION 3.6.15

RUN set -eux \
	&& wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" \
	&& mkdir -p /usr/src/python \
	&& tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
	&& rm python.tar.xz \
	&& cd /usr/src/python \
	&& ./configure \
	--enable-loadable-sqlite-extensions \
	--enable-optimizations \
	--enable-option-checking=fatal \
	--enable-shared \
	--with-system-expat \
	--with-system-ffi \
	--without-ensurepip \
	&& make -j "$(nproc)" \
	&& make install \
	&& rm -rf /usr/src/python \
	&& ldconfig

# make some useful symlinks that are expected to exist
RUN cd /usr/local/bin \
	&& ln -s idle3 idle \
	&& ln -s pydoc3 pydoc \
	&& ln -s python3 python \
	&& ln -s python3-config python-config

# ensure local python is preferred over distribution python
ENV PATH /usr/local/bin:$PATH

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 21.2.4
# https://github.com/docker-library/python/issues/365
ENV PYTHON_SETUPTOOLS_VERSION 57.5.0
# https://github.com/pypa/get-pip
ENV PYTHON_GET_PIP_URL https://github.com/pypa/get-pip/raw/3cb8888cc2869620f57d5d2da64da38f516078c7/public/get-pip.py

RUN set -ex; \
	wget -O get-pip.py "$PYTHON_GET_PIP_URL"; \
	python get-pip.py \
	--disable-pip-version-check \
	--no-cache-dir \
	"pip==$PYTHON_PIP_VERSION" \
	"setuptools==$PYTHON_SETUPTOOLS_VERSION" \
	; \
	pip --version; \
	find /usr/local -depth \
	\( \
	\( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \
	-o \
	\( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
	\) -exec rm -rf '{}' +; \
	rm -f get-pip.py

CMD ["bash"]
