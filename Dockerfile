FROM ubuntu

ADD . /password-server/
WORKDIR /password-server/

run apt-get update && \
  apt-get install -y pwgen \
    openssl \
    wget \
    net-tools \
    nodejs && \
  sed -i "s/sudo //g" /password-server/confidentalInfo.sh && \
  /password-server/installGlobal.sh

ENTRYPOINT confidentalInfo.sh start-server && bash
