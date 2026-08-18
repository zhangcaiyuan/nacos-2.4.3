#!/bin/bash
# ==================== Nacos 启动入口脚本 ====================
# 适配 K8s StatefulSet 部署，支持多种环境变量命名方式

set -e

echo "============================================"
echo " Nacos ${NACOS_VERSION:-2.4.3} 启动脚本"
echo "============================================"

# ==================== 通用参数 ====================
NACOS_HOME="${NACOS_HOME:-/home/nacos}"

# 设置时区
if [ -n "${TZ}" ]; then
    export TZ
    echo "[时区] ${TZ}"
fi

# ==================== JVM 参数 ====================
JVM_OPTS="${JVM_OPTS:--server -Xms2g -Xmx2g -Xmn512m}"
JVM_OPTS="$JVM_OPTS -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=256m"
JVM_OPTS="$JVM_OPTS -XX:+UseG1GC -XX:MaxGCPauseMillis=100"
JVM_OPTS="$JVM_OPTS -XX:ParallelGCThreads=4 -XX:ConcGCThreads=2"
JVM_OPTS="$JVM_OPTS -XX:+DisableExplicitGC"
JVM_OPTS="$JVM_OPTS -XX:+AlwaysPreTouch"
JVM_OPTS="$JVM_OPTS -XX:+PerfDisableSharedMem"
JVM_OPTS="$JVM_OPTS -XX:+HeapDumpOnOutOfMemoryError"
JVM_OPTS="$JVM_OPTS -XX:HeapDumpPath=${NACOS_HOME}/logs/java_heapdump.hprof"

# ==================== 鉴权配置 ====================
AUTH_ENABLED="${NACOS_AUTH_ENABLE:-true}"
AUTH_OPTS="--server.port=${NACOS_SERVER_PORT:-8848}"
AUTH_OPTS="$AUTH_OPTS --nacos.core.auth.enabled=${AUTH_ENABLED}"

if [ "${AUTH_ENABLED}" = "true" ]; then
    echo "[鉴权] 已开启"
    AUTH_TOKEN="${NACOS_AUTH_TOKEN:-VGhpc0lzTXlDdXN0b21TZWNyZXRLZXkwMTIzNDU2Nzg5MDEyMzQ1Njc4OTA=}"
    AUTH_IDENTITY_KEY="${NACOS_AUTH_IDENTITY_KEY:-nacos-server-identity}"
    AUTH_IDENTITY_VALUE="${NACOS_AUTH_IDENTITY_VALUE:-nacos-server-identity-value-2026}"
    AUTH_OPTS="$AUTH_OPTS --nacos.core.auth.plugin.nacos.token.secret.key=${AUTH_TOKEN}"
    AUTH_OPTS="$AUTH_OPTS --nacos.core.auth.server.identity.key=${AUTH_IDENTITY_KEY}"
    AUTH_OPTS="$AUTH_OPTS --nacos.core.auth.server.identity.value=${AUTH_IDENTITY_VALUE}"
else
    echo "[鉴权] 已关闭"
fi

# ==================== 数据库配置 ====================
DB_OPTS=""
DB_CONFIGURED=false

DB_PLATFORM="${SPRING_DATASOURCE_PLATFORM:-mysql}"
DB_DRIVER=$(printenv 'db.pool.config.driverClassName' 2>/dev/null || echo "")

if [ -n "${DB_URL}" ]; then
    FINAL_DB_URL="${DB_URL}"
elif [ -n "${MYSQL_SERVICE_HOST}" ]; then
    DB_NAME="${MYSQL_SERVICE_DB_NAME:-nacos}"
    DB_HOST="${MYSQL_SERVICE_HOST}"
    DB_PORT="${MYSQL_SERVICE_PORT:-3306}"

    if [ "${DB_PLATFORM}" = "gaussdb" ]; then
        FINAL_DB_URL="jdbc:gaussdb://${DB_HOST}:${DB_PORT}/${DB_NAME}?characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true&useSSL=false"
        if [ -z "${DB_DRIVER}" ]; then
            DB_DRIVER="com.huawei.gaussdb.jdbc.Driver"
        fi
    elif [ "${DB_PLATFORM}" = "postgresql" ]; then
        FINAL_DB_URL="jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}?characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true&useSSL=false"
        if [ -z "${DB_DRIVER}" ]; then
            DB_DRIVER="org.postgresql.Driver"
        fi
    else
        FINAL_DB_URL="jdbc:mysql://${DB_HOST}:${DB_PORT}/${DB_NAME}?characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true&useUnicode=true&useSSL=false&serverTimezone=Asia/Shanghai"
        if [ -z "${DB_DRIVER}" ]; then
            DB_DRIVER="com.mysql.cj.jdbc.Driver"
        fi
    fi
else
    if [ -n "${DB_URL_0}" ]; then
        FINAL_DB_URL="${DB_URL_0}"
    fi
fi

if [ -n "${DB_USER}" ]; then
    FINAL_DB_USER="${DB_USER}"
elif [ -n "${DB_USER_0}" ]; then
    FINAL_DB_USER="${DB_USER_0}"
elif [ -n "${MYSQL_SERVICE_USER}" ]; then
    FINAL_DB_USER="${MYSQL_SERVICE_USER}"
fi

if [ -n "${DB_PASSWORD}" ]; then
    FINAL_DB_PASSWORD="${DB_PASSWORD}"
elif [ -n "${DB_PASSWORD_0}" ]; then
    FINAL_DB_PASSWORD="${DB_PASSWORD_0}"
elif [ -n "${MYSQL_SERVICE_PASSWORD}" ]; then
    FINAL_DB_PASSWORD="${MYSQL_SERVICE_PASSWORD}"
fi

if [ -n "${FINAL_DB_URL}" ]; then
    DB_OPTS="--spring.sql.init.platform=${DB_PLATFORM}"
    DB_OPTS="$DB_OPTS --db.num=1"
    DB_OPTS="$DB_OPTS --db.url.0=${FINAL_DB_URL}"
    if [ -n "${FINAL_DB_USER}" ]; then
        DB_OPTS="$DB_OPTS --db.user.0=${FINAL_DB_USER}"
    fi
    if [ -n "${FINAL_DB_PASSWORD}" ]; then
        DB_OPTS="$DB_OPTS --db.password.0=${FINAL_DB_PASSWORD}"
    fi
    if [ -n "${DB_DRIVER}" ]; then
        DB_OPTS="$DB_OPTS --db.pool.config.driverClassName=${DB_DRIVER}"
    fi
    DB_CONFIGURED=true
fi

# ========== Jasypt 配置 ==========
JASYPT_PASSWORD=$(printenv 'jasypt.encryptor.password' 2>/dev/null || echo "${JASYPT_ENCRYPTOR_PASSWORD:-}")
JASYPT_ALGORITHM=$(printenv 'jasypt.encryptor.algorithm' 2>/dev/null || echo "PBEWithMD5AndDES")
JASYPT_IV_CLASS=$(printenv 'jasypt.encryptor.iv-generator-classname' 2>/dev/null || echo "org.jasypt.iv.NoIvGenerator")

if [ -n "${JASYPT_PASSWORD}" ]; then
    DB_OPTS="$DB_OPTS --jasypt.encryptor.password=${JASYPT_PASSWORD}"
    DB_OPTS="$DB_OPTS --jasypt.encryptor.algorithm=${JASYPT_ALGORITHM}"
    DB_OPTS="$DB_OPTS --jasypt.encryptor.iv-generator-classname=${JASYPT_IV_CLASS}"
fi

if [ "${DB_CONFIGURED}" = "true" ]; then
    echo "[数据库] 已配置外部数据库 [${DB_PLATFORM}]"
    echo "[数据库] URL: ${FINAL_DB_URL}"
    echo "[数据库] User: ${FINAL_DB_USER:-nacos}"
else
    echo "[数据库] 未配置外部数据库，使用内嵌存储模式"
fi

# ============ 集群节点配置 ============
parse_servers() {
    local raw="${1}"
    # 把逗号、换行、回车都换成空格，然后压缩多余空格
    echo "${raw}" | tr '\n\r,' '   ' | tr -s ' ' | sed 's/^ //;s/ $//'
}

CLUSTER_NODES=""
if [ -n "${NACOS_SERVERS}" ]; then
    CLUSTER_NODES=$(parse_servers "${NACOS_SERVERS}")
fi
if [ -z "${CLUSTER_NODES}" ] && [ -n "${SERVER_ADDR}" ]; then
    CLUSTER_NODES=$(parse_servers "${SERVER_ADDR}")
fi

COMMON_JAVA_OPTS="-Dnacos.home=${NACOS_HOME} -Dnacos.logging.default.config.enabled=false"

MODE="${MODE:-standalone}"

if [ "${MODE}" = "cluster" ]; then
    echo "[模式] 集群模式 [cluster]"

    CLUSTER_CONF="${NACOS_HOME}/conf/cluster.conf"
    mkdir -p "$(dirname "${CLUSTER_CONF}")"

    echo "[集群] NACOS_SERVERS 原始值: [${NACOS_SERVERS}]"
    echo "[集群] SERVER_ADDR 原始值: [${SERVER_ADDR}]"
    echo "[集群] 处理后节点列表: [${CLUSTER_NODES}]"

    if [ -n "${CLUSTER_NODES}" ]; then
        echo "" > "${CLUSTER_CONF}"
        node_count=0
        IFS=' ' read -ra NODE_ARRAY <<< "${CLUSTER_NODES}"
        for node in "${NODE_ARRAY[@]}"; do
            if [ -n "${node}" ]; then
                node_count=$((node_count + 1))
                echo "[集群] 写入节点 ${node_count}: ${node}"
                echo "${node}" >> "${CLUSTER_CONF}"
            fi
        done
        echo "[集群] ===== cluster.conf 内容 (${node_count} 个节点) ====="
        cat "${CLUSTER_CONF}"
        echo "[集群] ==================================="
    else
        echo "[警告] 未设置集群节点列表！"
        CONTAINER_IP=$(hostname -i 2>/dev/null || echo "127.0.0.1")
        echo "${CONTAINER_IP}:8848" > "${CLUSTER_CONF}"
    fi

    # 集群 IP 配置
    if [ "${PREFER_HOST_MODE}" = "hostname" ]; then
        CLUSTER_OPTS="--nacos.inetutils.prefer-hostname-over-ip=true"
        echo "[节点] 使用 hostname 模式"
    elif [ -n "${NODE_IP}" ]; then
        CLUSTER_OPTS="--nacos.inetutils.ip-address=${NODE_IP}"
    else
        CONTAINER_IP=$(hostname -i 2>/dev/null || echo "127.0.0.1")
        CLUSTER_OPTS="--nacos.inetutils.ip-address=${CONTAINER_IP}"
    fi

    CLUSTER_OPTS="$CLUSTER_OPTS --spring.profiles.active=cluster"
    CLUSTER_OPTS="$CLUSTER_OPTS --nacos.data.local.root=${NACOS_HOME}/data"

    echo "[启动] java ... -jar ${NACOS_HOME}/target/nacos-server.jar"
    exec java $JVM_OPTS $COMMON_JAVA_OPTS \
        -jar ${NACOS_HOME}/target/nacos-server.jar \
        $AUTH_OPTS $DB_OPTS $CLUSTER_OPTS

else
    echo "[模式] 单机模式 [standalone]"
    STANDALONE_OPTS="--spring.profiles.active=standalone"

    echo "[启动] java ... -jar ${NACOS_HOME}/target/nacos-server.jar"
    exec java $JVM_OPTS $COMMON_JAVA_OPTS \
        -jar ${NACOS_HOME}/target/nacos-server.jar \
        $AUTH_OPTS $DB_OPTS $STANDALONE_OPTS
fi
