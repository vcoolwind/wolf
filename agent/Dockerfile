FROM openresty/openresty:alpine
RUN apk add --update \
    sed bash \
    && rm -rf /var/cache/apk/*
COPY ./ /opt/wolf/agent
WORKDIR /opt/wolf/agent
EXPOSE 10082
ENTRYPOINT ["bash", "./entrypoint_multi.sh"]