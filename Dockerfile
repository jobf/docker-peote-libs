#
# origin: https://github.com/HaxeFoundation/docker-library-haxe/blob/master/4.2/bullseye/Dockerfile
# with some alterations and additions at the end
#

FROM buildpack-deps:bullseye-scm

# ensure local haxe is preferred over distribution haxe
ENV PATH /usr/local/bin:$PATH

# runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
		libgc1 \
		zlib1g \
		libpcre3 \
		libmariadb3 \
		libsqlite3-0 \
		libmbedcrypto3 \
		libmbedtls12 \
		libmbedx509-0 \
	&& rm -rf /var/lib/apt/lists/*

# install neko, which is a dependency of haxelib
ENV NEKO_VERSION 2.3.0
RUN set -ex \
	&& buildDeps=' \
		gcc \
		make \
		cmake \
		libgc-dev \
		libssl-dev \
		libpcre3-dev \
		zlib1g-dev \
		apache2-dev \
		libmariadb-client-lgpl-dev-compat \
		libsqlite3-dev \
		libmbedtls-dev \
		libgtk2.0-dev \
	' \
	&& apt-get update && apt-get install -y $buildDeps --no-install-recommends && rm -rf /var/lib/apt/lists/* \
	\
	&& wget -O neko.tar.gz "https://github.com/HaxeFoundation/neko/archive/v2-3-0/neko-2.3.0.tar.gz" \
	&& echo "850e7e317bdaf24ed652efeff89c1cb21380ca19f20e68a296c84f6bad4ee995 *neko.tar.gz" | sha256sum -c - \
	&& mkdir -p /usr/src/neko \
	&& tar -xC /usr/src/neko --strip-components=1 -f neko.tar.gz \
	&& rm neko.tar.gz \
	&& cd /usr/src/neko \
	&& cmake -DRELOCATABLE=OFF . \
	&& make \
	&& make install \
	\
	&& apt-get purge -y --auto-remove $buildDeps \
	&& rm -rf /usr/src/neko ~/.cache

# install haxe
ENV HAXE_VERSION 4.2.5
ENV HAXE_STD_PATH /usr/local/share/haxe/std
RUN set -ex \
	&& buildDeps=' \
		make \
		ocaml-nox \
		ocaml-native-compilers \
		camlp4 \
		ocaml-findlib \
		zlib1g-dev \
		libpcre3-dev \
		libmbedtls-dev \
		libxml-light-ocaml-dev \
		\
		opam \
		mccs \
		m4 \
		unzip \
		pkg-config \
		libstring-shellquote-perl \
		libipc-system-simple-perl \
		\
	' \
	&& git clone --recursive --depth 1 --branch 4.2.5 "https://github.com/HaxeFoundation/haxe.git" /usr/src/haxe \
	&& cd /usr/src/haxe \
	&& mkdir -p $HAXE_STD_PATH \
	&& cp -r std/* $HAXE_STD_PATH \
	&& apt-get update && apt-get install -y $buildDeps --no-install-recommends \
	\
	\
	&& opam init --disable-sandboxing \
	&& eval `opam env` \
	\
	&& ( [ -f /usr/src/haxe/opam ] && opam install /usr/src/haxe --deps-only --yes || make opam_install ) \
	\
	&& make all tools \
	&& mkdir -p /usr/local/bin \
	&& cp haxe haxelib /usr/local/bin \
	&& mkdir -p /haxelib \
	&& cd / && haxelib setup /haxelib \
	\
	\
	&& eval `opam env --revert` \
	&& rm -rf ~/.opam \
	\
	&& rm -rf /var/lib/apt/lists/* \
	&& apt-get purge -y --auto-remove $buildDeps \
	&& rm -rf /usr/src/haxe ~/.cache

# install lime
RUN haxelib install lime \
	&& cp "/haxelib/lime/8,0,1/templates/bin/lime.sh" /usr/local/bin/lime \
	&& chmod 755 /usr/local/bin/lime



# install haxelib peote-view dependencies
RUN haxelib install jasper \
	&& haxelib install json2object

# install peote libs from git
RUN git clone https://github.com/maitag/peote-view.git \
	&& haxelib dev peote-view peote-view \
	&& git clone https://github.com/maitag/peote-layout.git \
	&& haxelib dev peote-layout peote-layout \
	&& git clone https://github.com/maitag/peote-text.git \
	&& haxelib dev peote-text peote-text \
	&& git clone https://github.com/maitag/peote-ui.git \
	&& haxelib dev peote-ui peote-ui \
	&& git clone https://github.com/maitag/peote-net.git \
	&& haxelib dev peote-net peote-net \
	&& git clone https://github.com/maitag/peote-socket \
	&& haxelib dev peote-socket peote-socket \ 
	&& git clone https://github.com/maitag/input2action.git \
	&& haxelib dev input2action input2action

# install libs for samples
RUN haxelib install openfl \
	&& haxelib install hxmath \
	&& haxelib install echo \
	&& haxelib install safety \
	&& haxelib install bits \
	&& git clone https://github.com/Aidan63/ecs.git \
	&& haxelib dev ecs ecs \
	&& git clone https://github.com/nanjizal/justPath.git \
	&& haxelib dev justPath justPath