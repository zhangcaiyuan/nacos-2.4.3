/*
 * Copyright 1999-2022 Alibaba Group Holding Ltd.
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

package com.alibaba.nacos.plugin.datasource.impl.gaussdb;

import com.alibaba.nacos.plugin.datasource.enums.gaussdb.GaussdbCompatibleModeUtil;
import com.alibaba.nacos.plugin.datasource.enums.gaussdb.TrustedGaussDbFunctionEnum;
import com.alibaba.nacos.plugin.datasource.mapper.AbstractMapper;

/**
 * The abstract gaussdb mapper contains CRUD methods.
 *
 * <p>Supports three compatible modes:
 *
 * <p>pg    : LIMIT n OFFSET m (default)
 *
 * <p>ora   : ROWNUM pagination
 *
 * <p>mysql : LIMIT m, n
 *
 * @author blake.qiu
 **/
public abstract class AbstractMapperByGaussDb extends AbstractMapper {

    @Override
    public String getFunction(String functionName) {
        return TrustedGaussDbFunctionEnum.getFunctionByName(functionName);
    }

    protected String buildPagination(int startRow, int pageSize) {
        if (GaussdbCompatibleModeUtil.isMysqlMode()) {
            return " LIMIT " + startRow + "," + pageSize;
        } else if (GaussdbCompatibleModeUtil.isOraMode()) {
            return buildOraPagination(startRow, pageSize);
        }
        return " LIMIT " + pageSize + " OFFSET " + startRow;
    }

    private String buildOraPagination(int startRow, int pageSize) {
        int endRow = startRow + pageSize;
        return " AND ROWNUM <= " + endRow + " AND RN > " + startRow;
    }

    protected String buildWrappedPagination(String innerSql, int startRow, int pageSize) {
        if (GaussdbCompatibleModeUtil.isMysqlMode()) {
            return innerSql + " LIMIT " + startRow + "," + pageSize;
        } else if (GaussdbCompatibleModeUtil.isOraMode()) {
            return buildWrappedOraPagination(innerSql, startRow, pageSize);
        }
        return innerSql + " LIMIT " + pageSize + " OFFSET " + startRow;
    }

    private String buildWrappedOraPagination(String innerSql, int startRow, int pageSize) {
        int endRow = startRow + pageSize;
        return "SELECT * FROM ( SELECT TMP.*, ROWNUM RN FROM ( "
                + innerSql
                + " ) TMP WHERE ROWNUM <= " + endRow + " ) WHERE RN > " + startRow;
    }

    protected String buildLimitOnly(int limitSize) {
        if (GaussdbCompatibleModeUtil.isMysqlMode()) {
            return " LIMIT " + limitSize;
        } else if (GaussdbCompatibleModeUtil.isOraMode()) {
            return " AND ROWNUM <= " + limitSize;
        }
        return " LIMIT " + limitSize;
    }

    protected String buildSubQueryLimitOnly(int limitSize) {
        return " LIMIT " + limitSize;
    }
}
