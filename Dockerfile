FROM perl:5.24

#  docker run -it -v $(pwd):/work -e USER_ID=$(id -u) -e GROUP_ID=$(id -g) ptk
LABEL author=joez

# deploy gosu
RUN set -eux; \
    arch=$(dpkg --print-architecture | awk -F- '{ print $NF }'); \
    base="https://github.com/tianon/gosu/releases/download"; \
    version=1.12; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
    wget -O /usr/local/bin/gosu "${base}/${version}/gosu-${arch}"; \
    wget -O /usr/local/bin/gosu.asc "${base}/${version}/gosu-${arch}.asc"; \
    gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	chmod +x /usr/local/bin/gosu; \
	gosu --version; \
	gosu nobody true

# deploy ptk
COPY . /opt/ptk
RUN ["/bin/bash", "-c", "source /opt/ptk/envsetup"]

# add user, its uid/gid will be modified by docker-entry later
RUN groupadd -g 1000 -r joe \
    && useradd -u 1000 -l -m -r -g joe -s /bin/bash -d /home/joe joe
RUN echo 'source /opt/ptk/envsetup' >> /home/joe/.bashrc

# here is the workspace
RUN mkdir -p /work && chown joe:joe /work
VOLUME ["/work"]
WORKDIR /work

ENTRYPOINT ["/opt/ptk/docker-entry"]
CMD ["bash"]