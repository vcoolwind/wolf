# agent是单独部署的应用
FROM openresty/openresty:alpine
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories && \
    apk --no-cache  add --update sed bash &&\
    rm -rf /var/cache/apk/*
COPY ./ /opt/wolf/agent
WORKDIR /opt/wolf/agent
EXPOSE 10082
ENTRYPOINT ["bash", "./entrypoint.sh"]