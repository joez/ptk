FROM perl:5.24

MAINTAINER Joe Zheng

COPY . /var/ptk
RUN echo 'source /var/ptk/envsetup' >> ~/.bashrc && exec bash --login

VOLUME ["/work"]
WORKDIR /work

CMD ["bash"]
