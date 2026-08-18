#!/bin/bash
# Copyright 1999-2018 Alibaba Group Holding Ltd.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
set -x

# ========== 关键修复: BASE_DIR 必须是纯路径 ==========
# 官方 Dockerfile 错误地设为 file://...，这里确保它是实际目录
BASE_DIR="${NACOS_HOME:-/home/nacos}"
export BASE_DIR

export CUSTOM_SEARCH_NAMES="application"
export CUSTOM_SEARCH_LOCATIONS=file:${BASE_DIR}/conf/
export MEMBER_LIST=""

# ========== 集群节点解析: 统一处理空格/逗号/换行 ==========
parse_servers() {
    local raw="${1}"
    # 逗号、换行、回车 → 空格，然后压缩多余空格
    echo "${raw}" | tr '\n\r,' '   ' | tr -s ' ' | sed 's/^ //;s/ $//'
}

function print_servers() {
    local servers
    servers=$(parse_servers "${NACOS_SERVERS}")
    echo "[集群] NACOS_SERVERS 原始值: [${NACOS_SERVERS}]"
    echo "[集群] 处理后节点列表: [${servers}]"

    local conf="${BASE_DIR}/conf/cluster.conf"
    mkdir -p "$(dirname "${conf}")"
    echo "" > "${conf}"
    for server in ${servers}; do
        echo "[集群] 写入节点: ${server}"
        echo "${server}" >> "${conf}"
    done
    echo "[集群] ===== cluster.conf 内容 ====="
    cat "${conf}"
    echo "[集群] =============================="
}

#===========================================================================================
# JVM Configuration
#===========================================================================================
if [[ "${MODE}" == "standalone" ]]; then

  JAVA_OPT="${JAVA_OPT} -Xms${JVM_XMS:-512m} -Xmx${JVM_XMX:-512m} -Xmn${JVM_XMN:-256m}"
  JAVA_OPT="${JAVA_OPT} -Dnacos.standalone=true"
else
  if [[ "${EMBEDDED_STORAGE}" == "embedded" ]]; then
    JAVA_OPT="${JAVA_OPT} -DembeddedStorage=true"
  fi
  JAVA_OPT="${JAVA_OPT} -server -Xms${JVM_XMS:-2g} -Xmx${JVM_XMX:-2g} -Xmn${JVM_XMN:-512m} -XX:MetaspaceSize=${JVM_MS:-128m} -XX:MaxMetaspaceSize=${JVM_MMS:-256m}"
  if [[ "${NACOS_DEBUG}" == "y" ]]; then
    JAVA_OPT="${JAVA_OPT} -Xdebug -Xrunjdwp:transport=dt_socket,address=9555,server=y,suspend=n"
  fi
  JAVA_OPT="${JAVA_OPT} -XX:-OmitStackTraceInFastThrow -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=${BASE_DIR}/logs/java_heapdump.hprof"
  JAVA_OPT="${JAVA_OPT} -XX:-UseLargePages"
  print_servers
fi

#===========================================================================================
# Setting system properties
#===========================================================================================
# set  mode that Nacos Server function of split
if [[ "${FUNCTION_MODE}" == "config" ]]; then
  JAVA_OPT="${JAVA_OPT} -Dnacos.functionMode=config"
elif [[ "${FUNCTION_MODE}" == "naming" ]]; then
  JAVA_OPT="${JAVA_OPT} -Dnacos.functionMode=naming"
fi
# set nacos server ip
if [[ ! -z "${NACOS_SERVER_IP}" ]]; then
  JAVA_OPT="${JAVA_OPT} -Dnacos.server.ip=${NACOS_SERVER_IP}"
fi

if [[ ! -z "${USE_ONLY_SITE_INTERFACES}" ]]; then
  JAVA_OPT="${JAVA_OPT} -Dnacos.inetutils.use-only-site-local-interfaces=${USE_ONLY_SITE_INTERFACES}"
fi

if [[ ! -z "${PREFERRED_NETWORKS}" ]]; then
  JAVA_OPT="${JAVA_OPT} -Dnacos.inetutils.preferred-networks=${PREFERRED_NETWORKS}"
fi

if [[ ! -z "${IGNORED_INTERFACES}" ]]; then
  JAVA_OPT="${JAVA_OPT} -Dnacos.inetutils.ignored-interfaces=${IGNORED_INTERFACES}"
fi

### If turn on auth system:
# 默认开启鉴权，与 Nacos 2.x 默认行为一致
AUTH_ENABLED="${NACOS_AUTH_ENABLE:-true}"
JAVA_OPT="${JAVA_OPT} -Dnacos.core.auth.enabled=${AUTH_ENABLED}"

if [[ "${AUTH_ENABLED}" == "true" ]]; then
  # 鉴权开启时以下3项必须有值，否则登录接口异常
  AUTH_TOKEN="${NACOS_AUTH_TOKEN:-VGhpc0lzTXlDdXN0b21TZWNyZXRLZXkwMTIzNDU2Nzg5MDEyMzQ1Njc4OTA=}"
  AUTH_IDENTITY_KEY="${NACOS_AUTH_IDENTITY_KEY:-nacos-server-identity}"
  AUTH_IDENTITY_VALUE="${NACOS_AUTH_IDENTITY_VALUE:-nacos-server-identity-value-2026}"
  JAVA_OPT="${JAVA_OPT} -Dnacos.core.auth.plugin.nacos.token.secret.key=${AUTH_TOKEN}"
  JAVA_OPT="${JAVA_OPT} -Dnacos.core.auth.server.identity.key=${AUTH_IDENTITY_KEY}"
  JAVA_OPT="${JAVA_OPT} -Dnacos.core.auth.server.identity.value=${AUTH_IDENTITY_VALUE}"
  echo "[鉴权] 已开启"
else
  echo "[鉴权] 已关闭"
fi

if [[ "${PREFER_HOST_MODE}" == "hostname" ]]; then
  JAVA_OPT="${JAVA_OPT} -Dnacos.inetutils.prefer-hostname-over-ip=true"
fi
JAVA_OPT="${JAVA_OPT} -Dnacos.member.list=${MEMBER_LIST}"

JAVA_MAJOR_VERSION=$($JAVA -version 2>&1 | sed -E -n 's/.* version "([0-9]*).*$/\1/p')
if [[ "$JAVA_MAJOR_VERSION" -ge "9" ]]; then
  JAVA_OPT="${JAVA_OPT} -cp .:${BASE_DIR}/plugins/cmdb/*.jar:${BASE_DIR}/plugins/mysql/*.jar"
  JAVA_OPT="${JAVA_OPT} -Xlog:gc*:file=${BASE_DIR}/logs/nacos_gc.log:time,tags:filecount=10,filesize=102400"
else
  JAVA_OPT="${JAVA_OPT} -Djava.ext.dirs=${JAVA_HOME:-/usr/lib/jvm/java-8-openjdk-amd64}/jre/lib/ext:${JAVA_HOME:-/usr/lib/jvm/java-8-openjdk-amd64}/lib/ext:${BASE_DIR}/plugins/health:${BASE_DIR}/plugins/cmdb:${BASE_DIR}/plugins/mysql"
  JAVA_OPT="${JAVA_OPT} -Xloggc:${BASE_DIR}/logs/nacos_gc.log -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintGCTimeStamps -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=10 -XX:GCLogFileSize=100M"
fi

JAVA_OPT="${JAVA_OPT} -Dloader.path=${BASE_DIR}/plugins"
JAVA_OPT="${JAVA_OPT} -Dnacos.home=${BASE_DIR}"
JAVA_OPT="${JAVA_OPT} -jar ${BASE_DIR}/target/nacos-server.jar"
JAVA_OPT="${JAVA_OPT} ${JAVA_OPT_EXT}"
JAVA_OPT="${JAVA_OPT} --spring.config.additional-location=${CUSTOM_SEARCH_LOCATIONS}"
JAVA_OPT="${JAVA_OPT} --spring.config.name=${CUSTOM_SEARCH_NAMES}"
JAVA_OPT="${JAVA_OPT} --logging.config=${BASE_DIR}/conf/nacos-logback.xml"
JAVA_OPT="${JAVA_OPT} --server.max-http-header-size=524288"

echo "Nacos is starting, you can docker logs your container"
echo "[启动命令] java ${JAVA_OPT}"
exec $JAVA ${JAVA_OPT}
