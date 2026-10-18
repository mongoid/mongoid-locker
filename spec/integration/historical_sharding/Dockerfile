FROM --platform=linux/amd64 ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential ca-certificates curl libyaml-dev zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://cache.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p247.tar.gz \
    | tar -xz -C /tmp \
    && cd /tmp/ruby-2.0.0-p247 \
    && ./configure --disable-install-doc --without-openssl --without-readline \
    && make -j4 && make install

RUN curl -fsSL https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-2.4.6.tgz \
    | tar -xz --strip-components=2 -C /usr/local/bin mongodb-linux-x86_64-2.4.6/bin

RUN curl -fsSL https://github.com/openssl/openssl/archive/refs/tags/OpenSSL_1_0_1e.tar.gz \
    | tar -xz -C /tmp \
    && cd /tmp/openssl-OpenSSL_1_0_1e \
    && ./config --prefix=/opt/openssl shared && make && make install_sw

ENV LD_LIBRARY_PATH=/opt/openssl/lib

RUN cd /tmp/ruby-2.0.0-p247/ext/openssl \
    && (ruby extconf.rb --with-openssl-include=/opt/openssl/include --with-openssl-lib=/opt/openssl/lib || { cat mkmf.log; exit 1; }) \
    && make -j4 && make install

# Fetch with the modern TLS client, then install offline with period dependencies.
COPY gems.sha256 /gems/gems.sha256
RUN cd /gems \
    && for gem in mongoid-locker-0.2.1 mongoid-3.1.0 moped-1.4.5 origin-1.1.0 \
      activemodel-3.2.13 activesupport-3.2.13 builder-3.0.4 i18n-0.6.1 \
      multi_json-1.7.2 tzinfo-0.3.37; do \
      curl -fsSLO "https://rubygems.org/downloads/$gem.gem" || exit 1; \
    done \
    && sha256sum --check gems.sha256 \
    && gem install --local --no-document ./*.gem

COPY start.sh reproduce.rb /reproduction/
CMD ["bash", "/reproduction/start.sh"]
