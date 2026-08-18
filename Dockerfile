# ==================== Nacos Docker 镜像 ====================
# 支持单机模式 (standalone) 和集群模式 (cluster)
# 
# 使用方法:
#   # 构建镜像
#   docker build -t nacos:2.4.3 .
#
#   # 单机模式
#   docker run -d -p 8848:8848 -p 9848:9848 -p 9849:9849 nacos:2.4.3
#
#   # 集群模式 (3节点示例)
#   # 节点1
#   docker run -d --name nacos1 -p 8848:8848 -p 9848:9848 -p 9849:9849 \
#     -e MODE=cluster -e SERVER_ADDR=10.0.0.1:9848,10.0.0.2:9848,10.0.0.3:9848 \
#     nacos:2.4.3
#   # 节点2
#   docker run -d --name nacos2 -p 8858:8848 -p 9948:9848 -p 9949:9849 \
#     -e MODE=cluster -e SERVER_ADDR=10.0.0.1:9848,10.0.0.2:9848,10.0.0.3:9848 \
#     nacos:2.4.3
#   # 节点3
#   docker run -d --name nacos3 -p 8868:8848 -p 9958:9848 -p 9959:9849 \
#     -e MODE=cluster -e SERVER_ADDR=10.0.0.1:9848,10.0.0.2:9848,10.0.0.3:9848 \
#     nacos:2.4.3

# ========== 修改这里为你的私有镜像 ==========
ARG BASE_IMAGE=openjdk:8-jdk-alpine
# =============================================

FROM ${BASE_IMAGE}

LABEL maintainer="nacos"
LABEL version="2.4.3"
LABEL description="Nacos 2.4.3 with PostgreSQL/GaussDB support (Cluster Ready)"

# ==================== 默认环境变量 ====================
ENV NACOS_HOME=/home/nacos
ENV NACOS_VERSION=2.4.3
# MODE: standalone (单机) | cluster (集群)
ENV MODE=standalone
ENV PREFER_HOST_MODE=hostname
# 集群节点地址列表，格式: ip1:port1 ip2:port2 ip3:port3
# 端口为各节点的 8848 端口，脚本会自动转成 gRPC 9848 进行通信
ENV NACOS_SERVERS=""
# 当前节点 IP（集群模式下可选指定）
ENV NODE_IP=""
# Jasypt 密钥（生产环境通过 docker run -e 传入）
ENV JASYPT_ENCRYPTOR_PASSWORD=""

# 创建工作目录
WORKDIR ${NACOS_HOME}

# 复制编译产物
COPY console/target/nacos-server.jar ${NACOS_HOME}/target/

# 创建必要目录
RUN mkdir -p ${NACOS_HOME}/data \
    && mkdir -p ${NACOS_HOME}/logs \
    && mkdir -p ${NACOS_HOME}/conf \
    && mkdir -p ${NACOS_HOME}/lib \
    && mkdir -p ${NACOS_HOME}/plugins

# 暴露端口
# 8848: Nacos HTTP 端口
# 9848: Nacos gRPC 端口 (2.0+，集群通信)
# 9849: Nacos 主从同步端口
EXPOSE 8848 9848 9849

# 数据卷
VOLUME ["${NACOS_HOME}/data", "${NACOS_HOME}/logs"]

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=5 \
    CMD curl -f http://localhost:8848/nacos/v1/cs/configs?search=accurate&dataId=&group=&tenant=&pageNo=1&pageSize=1 || exit 1

# ==================== 启动脚本 ====================
COPY docker-startup.sh /home/nacos/docker-startup.sh
RUN chmod +x /home/nacos/docker-startup.sh

ENTRYPOINT ["/home/nacos/docker-startup.sh"]
