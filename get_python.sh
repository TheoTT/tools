# ensure local python is preferred over distribution python
export PATH=/usr/local/bin:$PATH

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
export LANG=C.UTF-8

# runtime dependencies
apt-get update && apt-get install -y --no-install-recommends \
                ca-certificates \
                netbase \
        && rm -rf /var/lib/apt/lists/*

export GPG_KEY=0D96DF4D4110E5C43FBFB17F2D347EA6AA65421D
export PYTHON_VERSION=3.7.1

set -ex \
        \
        && savedAptMark="$(apt-mark showmanual)" \
        && apt-get update && apt-get install -y --no-install-recommends \
                dpkg-dev \
                gcc \
                libbz2-dev \
                libc6-dev \
                libexpat1-dev \
                libffi-dev \
                libgdbm-dev \
                liblzma-dev \
                libncursesw5-dev \
                libreadline-dev \
                libsqlite3-dev \
                libssl-dev \
                make \
                tk-dev \
                wget \
                xz-utils \
                zlib1g-dev \
# as of Stretch, "gpg" is no longer included by default
                $(command -v gpg > /dev/null || echo 'gnupg dirmngr') \
        \
        && wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" \
        && wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc" \
        && export GNUPGHOME="$(mktemp -d)" \
        && gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY" \
        && gpg --batch --verify python.tar.xz.asc python.tar.xz \
        && { command -v gpgconf > /dev/null && gpgconf --kill all || :; } \
        && rm -rf "$GNUPGHOME" python.tar.xz.asc \
        && mkdir -p /usr/src/python \
        && tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
        && rm python.tar.xz \
        \
        && cd /usr/src/python \
        && gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
        && ./configure \
                --build="$gnuArch" \
                --enable-loadable-sqlite-extensions \
                --enable-shared \
                --with-system-expat \
                --with-system-ffi \
                --without-ensurepip \
        && make -j "$(nproc)" \
        && make install \
        && ldconfig \
        \
        && apt-mark auto '.*' > /dev/null \
        && apt-mark manual $savedAptMark \
        && find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec ldd '{}' ';' \
                | awk '/=>/ { print $(NF-1) }' \
                | sort -u \
                | xargs -r dpkg-query --search \
                | cut -d: -f1 \
                | sort -u \
                | xargs -r apt-mark manual \
        && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
        && rm -rf /var/lib/apt/lists/* \
        \
        && find /usr/local -depth \
                \( \
                        \( -type d -a \( -name test -o -name tests \) \) \
                        -o \
                        \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
                \) -exec rm -rf '{}' + \
        && rm -rf /usr/src/python \
        \
        && python3 --version

# make some useful symlinks that are expected to exist
cd /usr/local/bin \
        && ln -s idle3 idle \
        && ln -s pydoc3 pydoc \
        && ln -s python3 python \
        && ln -s python3-config python-config

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
export PYTHON_PIP_VERSION=19.2.3
# https://github.com/pypa/get-pip
export PYTHON_GET_PIP_URL=https://github.com/pypa/get-pip/raw/309a56c5fd94bd1134053a541cb4657a4e47e09d/get-pip.py
export PYTHON_GET_PIP_SHA256=57e3643ff19f018f8a00dfaa6b7e4620e3c1a7a2171fd218425366ec006b3bfe

set -ex; \
        \
        savedAptMark="$(apt-mark showmanual)"; \
        apt-get update; \
        apt-get install -y --no-install-recommends wget; \
        \
        wget -O get-pip.py "$PYTHON_GET_PIP_URL"; \
        echo "$PYTHON_GET_PIP_SHA256 *get-pip.py" | sha256sum --check --strict -; \
        \
        apt-mark auto '.*' > /dev/null; \
        [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
        apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
        rm -rf /var/lib/apt/lists/*; \
        \
        python get-pip.py \
                --disable-pip-version-check \
                --no-cache-dir \
                "pip==$PYTHON_PIP_VERSION" \
        ; \
        pip --version; \
        \
        find /usr/local -depth \
                \( \
                        \( -type d -a \( -name test -o -name tests \) \) \
                        -o \
                        \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
                \) -exec rm -rf '{}' +; \
        rm -f get-pip.py