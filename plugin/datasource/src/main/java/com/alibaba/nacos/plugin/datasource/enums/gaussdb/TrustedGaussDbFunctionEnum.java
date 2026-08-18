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

import java.util.HashMap;
import java.util.Map;

/**
 * The TrustedGaussDbFunctionEnum enum class is used to enumerate and manage a list of trusted built-in SQL functions.
 *
 * <p>Supports three compatible modes: pg (default), ora, mysql.
 *
 * <p>Function mapping per mode:
 *
 * <p>PG mode:    NOW() -> now()
 *
 * <p>ORA mode:   NOW() -> SYSDATE
 *
 * <p>MySQL mode: NOW() -> NOW(3)
 *
 * @author blake.qiu
 */
public enum TrustedGaussDbFunctionEnum {

    NOW("NOW()");

    private static final Map<String, TrustedGaussDbFunctionEnum> LOOKUP_MAP = new HashMap<>();

    static {
        for (TrustedGaussDbFunctionEnum entry : TrustedGaussDbFunctionEnum.values()) {
            LOOKUP_MAP.put(entry.functionName, entry);
        }
    }

    private final String functionName;

    TrustedGaussDbFunctionEnum(String functionName) {
        this.functionName = functionName;
    }

    public static String getFunctionByName(String functionName) {
        TrustedGaussDbFunctionEnum entry = LOOKUP_MAP.get(functionName);
        if (entry != null) {
            return entry.resolveFunction();
        }
        throw new IllegalArgumentException(String.format("Invalid function name: %s", functionName));
    }

    private String resolveFunction() {
        if (GaussdbCompatibleModeUtil.isOraMode()) {
            return resolveOraFunction();
        } else if (GaussdbCompatibleModeUtil.isMysqlMode()) {
            return resolveMysqlFunction();
        }
        return resolvePgFunction();
    }

    private String resolvePgFunction() {
        switch (this) {
            case NOW:
                return "now()";
            default:
                return this.functionName;
        }
    }

    private String resolveOraFunction() {
        switch (this) {
            case NOW:
                return "SYSDATE";
            default:
                return this.functionName;
        }
    }

    private String resolveMysqlFunction() {
        switch (this) {
            case NOW:
                return "NOW(3)";
            default:
                return this.functionName;
        }
    }
}
