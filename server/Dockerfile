# 先编译console，生成静态文件，为防止包太大，静态文件生成放入server包中
FROM node:12.10.0-alpine as builder

ARG env=prod
RUN set -ex && \
    sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories && \
    npm config set registry https://registry.npm.taobao.org && \
    apk --no-cache add postgresql-libs && \
    apk --no-cache add --virtual native-deps &&\
    apk --no-cache add g++ gcc libgcc libstdc++ linux-headers make python postgresql-dev  busybox-extras && \
    npm install --quiet node-gyp -g

WORKDIR /build/
COPY . /build/

RUN cd console/ && \
    npm install && \
    npm run build:${env}

# 打包server
FROM node:12.10.0-alpine
RUN set -ex && \
    sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories && \
    npm config set registry https://registry.npm.taobao.org && \
    apk --no-cache add postgresql-libs && \
    apk --no-cache add --virtual native-deps &&\
    apk --no-cache add g++ gcc libgcc libstdc++ linux-headers make python postgresql-dev  busybox-extras && \
    npm install --quiet node-gyp -g

WORKDIR /opt/wolf/server
# copy source to /opt/wolf/server
COPY . .
RUN rm -fr console && \
    rm -rf html/   && \
    npm install

COPY --from=builder /build/console/dist ./html

EXPOSE 10080
ENTRYPOINT ["sh", "./entrypoint.sh"]