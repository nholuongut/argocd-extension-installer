FROM alpine:3.19.1
LABEL maintainer="Nho Luong <luongutnho@hotmail.com>"
ARG USER=ext-installer
ENV HOME /home/$USER

RUN apk update && apk add file curl jq

RUN adduser -D $USER
USER $USER
WORKDIR $HOME

ADD install.sh .

ENTRYPOINT ["./install.sh"]
