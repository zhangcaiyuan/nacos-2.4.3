/*
 * Copyright 1999-2018 Alibaba Group Holding Ltd.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.alibaba.nacos.plugin.datasource.enums.gaussdb;

import com.alibaba.nacos.common.utils.StringUtils;
import com.alibaba.nacos.plugin.datasource.constants.DataSourceConstant;

/**
 * GaussDB compatible mode utility.
 *
 * <p>Supports three modes: pg (default), ora, mysql.
 *
 * <p>Configuration via:
 *
 * <p>1. JVM system property: -Dspring.datasource.gaussdb.compatible.mode=ora
 *
 * <p>2. application.properties: spring.datasource.gaussdb.compatible.mode=mysql
 *
 * @author nacos
 */
public final class GaussdbCompatibleModeUtil {

    private static volatile String cachedMode;

    private GaussdbCompatibleModeUtil() {
    }

    public static String getCurrentMode() {
        if (cachedMode != null) {
            return cachedMode;
        }
        synchronized (GaussdbCompatibleModeUtil.class) {
            if (cachedMode == null) {
                String mode = System.getProperty(DataSourceConstant.GAUSSDB_COMPATIBLE_MODE_PROPERTY);
                if (StringUtils.isBlank(mode)) {
                    mode = System.getenv("SPRING_DATASOURCE_GAUSSDB_COMPATIBLE_MODE");
                }
                if (StringUtils.isBlank(mode)) {
                    mode = DataSourceConstant.GAUSSDB_COMPATIBLE_MODE_PG;
                }
                mode = mode.trim().toLowerCase();
                switch (mode) {
                    case DataSourceConstant.GAUSSDB_COMPATIBLE_MODE_ORA:
                    case DataSourceConstant.GAUSSDB_COMPATIBLE_MODE_MYSQL:
                    case DataSourceConstant.GAUSSDB_COMPATIBLE_MODE_PG:
                        cachedMode = mode;
                        break;
                    default:
                        cachedMode = DataSourceConstant.GAUSSDB_COMPATIBLE_MODE_PG;
                }
            }
        }
        return cachedMode;
    }

    public static boolean isPgMode() {
        return DataSourceConstant.GAUSSDB_COMPATIBLE_MODE_PG.equals(getCurrentMode());
    }

    public static boolean isOraMode() {
        return DataSourceConstant.GAUSSDB_COMPATIBLE_MODE_ORA.equals(getCurrentMode());
    }

    public static boolean isMysqlMode() {
        return DataSourceConstant.GAUSSDB_COMPATIBLE_MODE_MYSQL.equals(getCurrentMode());
    }

    public static void resetCache() {
        cachedMode = null;
    }
}
