-- =====================================================================
-- Nacos 2.4.3 GaussDB Schema - Multi Compatible Mode
-- =====================================================================
-- This schema file provides THREE compatible modes for GaussDB:
--   1. PG mode     (default) - PostgreSQL compatible (BIGSERIAL, TIMESTAMP, LIMIT/OFFSET)
--   2. ORA mode    - Oracle compatible     (NUMBER, DATE, ROWNUM, SYSDATE)
--   3. MySQL mode  - MySQL compatible      (BIGINT, DATETIME, LIMIT m,n)
--
-- Configuration (choose ONE mode):
--   application.properties:
--     spring.sql.init.platform=gaussdb
--     spring.datasource.gaussdb.compatible.mode=pg      # or: ora / mysql
--
--   JVM parameter:
--     -Dspring.datasource.gaussdb.compatible.mode=ora
--
--   Environment variable:
--     SPRING_DATASOURCE_GAUSSDB_COMPATIBLE_MODE=mysql
--
-- Choose the section below that matches your configured mode.
-- =====================================================================


-- =====================================================================
--  MODE 1: PG (PostgreSQL compatible) - DEFAULT MODE
--  Use this if: spring.datasource.gaussdb.compatible.mode=pg  (or not set)
-- =====================================================================

-- Uncomment the following block for PG mode:
/*
CREATE TABLE config_info (
  id BIGSERIAL PRIMARY KEY,
  data_id VARCHAR(255) NOT NULL,
  group_id VARCHAR(128) DEFAULT NULL,
  content TEXT NOT NULL,
  md5 VARCHAR(32) DEFAULT NULL,
  gmt_create TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  gmt_modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  src_user TEXT,
  src_ip VARCHAR(50) DEFAULT NULL,
  app_name VARCHAR(128) DEFAULT NULL,
  tenant_id VARCHAR(128) DEFAULT '',
  c_desc VARCHAR(256) DEFAULT NULL,
  c_use VARCHAR(64) DEFAULT NULL,
  effect VARCHAR(64) DEFAULT NULL,
  type VARCHAR(64) DEFAULT NULL,
  c_schema TEXT,
  encrypted_data_key VARCHAR(1024) NOT NULL DEFAULT '',
  CONSTRAINT uk_configinfo_datagrouptenant UNIQUE (data_id, group_id, tenant_id)
);

CREATE TABLE config_info_aggr (
  id BIGSERIAL PRIMARY KEY,
  data_id VARCHAR(255) NOT NULL,
  group_id VARCHAR(128) NOT NULL,
  datum_id VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  gmt_modified TIMESTAMP NOT NULL,
  app_name VARCHAR(128) DEFAULT NULL,
  tenant_id VARCHAR(128) DEFAULT '',
  CONSTRAINT uk_configinfoaggr_datagrouptenantdatum UNIQUE (data_id, group_id, tenant_id, datum_id)
);

CREATE TABLE config_info_beta (
  id BIGSERIAL PRIMARY KEY,
  data_id VARCHAR(255) NOT NULL,
  group_id VARCHAR(128) NOT NULL,
  app_name VARCHAR(128) DEFAULT NULL,
  content TEXT NOT NULL,
  beta_ips VARCHAR(1024) DEFAULT NULL,
  md5 VARCHAR(32) DEFAULT NULL,
  gmt_create TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  gmt_modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  src_user TEXT,
  src_ip VARCHAR(50) DEFAULT NULL,
  tenant_id VARCHAR(128) DEFAULT '',
  encrypted_data_key VARCHAR(1024) NOT NULL DEFAULT '',
  CONSTRAINT uk_configinfobeta_datagrouptenant UNIQUE (data_id, group_id, tenant_id)
);

CREATE TABLE config_info_tag (
  id BIGSERIAL PRIMARY KEY,
  data_id VARCHAR(255) NOT NULL,
  group_id VARCHAR(128) NOT NULL,
  tenant_id VARCHAR(128) DEFAULT '',
  tag_id VARCHAR(128) NOT NULL,
  app_name VARCHAR(128) DEFAULT NULL,
  content TEXT NOT NULL,
  md5 VARCHAR(32) DEFAULT NULL,
  gmt_create TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  gmt_modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  src_user TEXT,
  src_ip VARCHAR(50) DEFAULT NULL,
  CONSTRAINT uk_configinfotag_datagrouptenanttag UNIQUE (data_id, group_id, tenant_id, tag_id)
);

CREATE TABLE config_tags_relation (
  id BIGINT NOT NULL,
  tag_name VARCHAR(128) NOT NULL,
  tag_type VARCHAR(64) DEFAULT NULL,
  data_id VARCHAR(255) NOT NULL,
  group_id VARCHAR(128) NOT NULL,
  tenant_id VARCHAR(128) DEFAULT '',
  nid BIGSERIAL PRIMARY KEY,
  CONSTRAINT uk_configtagrelation_configidtag UNIQUE (id, tag_name, tag_type)
);
CREATE INDEX idx_tenant_id ON config_tags_relation (tenant_id);

CREATE TABLE group_capacity (
  id BIGSERIAL PRIMARY KEY,
  group_id VARCHAR(128) NOT NULL DEFAULT '',
  quota INTEGER NOT NULL DEFAULT 0,
  usage INTEGER NOT NULL DEFAULT 0,
  max_size INTEGER NOT NULL DEFAULT 0,
  max_aggr_count INTEGER NOT NULL DEFAULT 0,
  max_aggr_size INTEGER NOT NULL DEFAULT 0,
  max_history_count INTEGER NOT NULL DEFAULT 0,
  gmt_create TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  gmt_modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uk_group_id UNIQUE (group_id)
);

CREATE TABLE his_config_info (
  id BIGINT NOT NULL,
  nid BIGSERIAL PRIMARY KEY,
  data_id VARCHAR(255) NOT NULL,
  group_id VARCHAR(128) NOT NULL,
  app_name VARCHAR(128) DEFAULT NULL,
  content TEXT NOT NULL,
  md5 VARCHAR(32) DEFAULT NULL,
  gmt_create TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  gmt_modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  src_user TEXT,
  src_ip VARCHAR(50) DEFAULT NULL,
  op_type CHAR(10) DEFAULT NULL,
  tenant_id VARCHAR(128) DEFAULT '',
  encrypted_data_key VARCHAR(1024) NOT NULL DEFAULT ''
);
CREATE INDEX idx_gmt_create ON his_config_info (gmt_create);
CREATE INDEX idx_gmt_modified ON his_config_info (gmt_modified);
CREATE INDEX idx_did ON his_config_info (data_id);

CREATE TABLE tenant_capacity (
  id BIGSERIAL PRIMARY KEY,
  tenant_id VARCHAR(128) NOT NULL DEFAULT '',
  quota INTEGER NOT NULL DEFAULT 0,
  usage INTEGER NOT NULL DEFAULT 0,
  max_size INTEGER NOT NULL DEFAULT 0,
  max_aggr_count INTEGER NOT NULL DEFAULT 0,
  max_aggr_size INTEGER NOT NULL DEFAULT 0,
  max_history_count INTEGER NOT NULL DEFAULT 0,
  gmt_create TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  gmt_modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uk_tenant_id UNIQUE (tenant_id)
);

CREATE TABLE tenant_info (
  id BIGSERIAL PRIMARY KEY,
  kp VARCHAR(128) NOT NULL,
  tenant_id VARCHAR(128) DEFAULT '',
  tenant_name VARCHAR(128) DEFAULT '',
  tenant_desc VARCHAR(256) DEFAULT NULL,
  create_source VARCHAR(32) DEFAULT NULL,
  gmt_create BIGINT NOT NULL,
  gmt_modified BIGINT NOT NULL,
  CONSTRAINT uk_tenant_info_kptenantid UNIQUE (kp, tenant_id)
);
CREATE INDEX idx_tenant_info_id ON tenant_info (tenant_id);

CREATE TABLE users (
  username VARCHAR(50) PRIMARY KEY,
  password VARCHAR(500) NOT NULL,
  enabled BOOLEAN NOT NULL
);

CREATE TABLE roles (
  username VARCHAR(50) NOT NULL,
  role VARCHAR(50) NOT NULL,
  CONSTRAINT idx_user_role UNIQUE (username, role)
);

CREATE TABLE permissions (
  role VARCHAR(50) NOT NULL,
  resource VARCHAR(128) NOT NULL,
  action VARCHAR(8) NOT NULL,
  CONSTRAINT uk_role_permission UNIQUE (role, resource, action)
);

INSERT INTO users (username, password, enabled) VALUES ('nacos', '$2a$10$EuWPZHzz32dJN7jexM34MOeYirDdFAZm2kuWj7VEOJhhZkDrxfvUu', true) ON CONFLICT (username) DO NOTHING;
INSERT INTO roles (username, role) VALUES ('nacos', 'ROLE_ADMIN') ON CONFLICT (username, role) DO NOTHING;
*/


-- =====================================================================
--  MODE 2: ORA (Oracle compatible)
--  Use this if: spring.datasource.gaussdb.compatible.mode=ora
-- =====================================================================

-- Uncomment the following block for ORA mode:
/*
CREATE TABLE config_info (
  id NUMBER(20) NOT NULL,
  data_id VARCHAR2(255) NOT NULL,
  group_id VARCHAR2(128) DEFAULT NULL,
  content CLOB NOT NULL,
  md5 VARCHAR2(32) DEFAULT NULL,
  gmt_create DATE NOT NULL DEFAULT SYSDATE,
  gmt_modified DATE NOT NULL DEFAULT SYSDATE,
  src_user CLOB,
  src_ip VARCHAR2(50) DEFAULT NULL,
  app_name VARCHAR2(128) DEFAULT NULL,
  tenant_id VARCHAR2(128) DEFAULT '',
  c_desc VARCHAR2(256) DEFAULT NULL,
  c_use VARCHAR2(64) DEFAULT NULL,
  effect VARCHAR2(64) DEFAULT NULL,
  type VARCHAR2(64) DEFAULT NULL,
  c_schema CLOB,
  encrypted_data_key VARCHAR2(1024) NOT NULL DEFAULT '',
  CONSTRAINT uk_configinfo_datagrouptenant UNIQUE (data_id, group_id, tenant_id)
);
CREATE SEQUENCE seq_config_info_id START WITH 1 INCREMENT BY 1 NOMAXVALUE NOCYCLE CACHE 20;
CREATE OR REPLACE TRIGGER trg_config_info_id BEFORE INSERT ON config_info FOR EACH ROW
BEGIN IF :NEW.id IS NULL THEN SELECT seq_config_info_id.NEXTVAL INTO :NEW.id FROM DUAL; END IF; END;
/
ALTER TABLE config_info ADD CONSTRAINT pk_config_info PRIMARY KEY (id);

CREATE TABLE config_info_aggr (
  id NUMBER(20) NOT NULL,
  data_id VARCHAR2(255) NOT NULL,
  group_id VARCHAR2(128) NOT NULL,
  datum_id VARCHAR2(255) NOT NULL,
  content CLOB NOT NULL,
  gmt_modified DATE NOT NULL,
  app_name VARCHAR2(128) DEFAULT NULL,
  tenant_id VARCHAR2(128) DEFAULT '',
  CONSTRAINT uk_configinfoaggr_datagrouptenantdatum UNIQUE (data_id, group_id, tenant_id, datum_id)
);
CREATE SEQUENCE seq_config_info_aggr_id START WITH 1 INCREMENT BY 1 NOMAXVALUE NOCYCLE CACHE 20;
CREATE OR REPLACE TRIGGER trg_config_info_aggr_id BEFORE INSERT ON config_info_aggr FOR EACH ROW
BEGIN IF :NEW.id IS NULL THEN SELECT seq_config_info_aggr_id.NEXTVAL INTO :NEW.id FROM DUAL; END IF; END;
/
ALTER TABLE config_info_aggr ADD CONSTRAINT pk_config_info_aggr PRIMARY KEY (id);

CREATE TABLE config_info_beta (
  id NUMBER(20) NOT NULL,
  data_id VARCHAR2(255) NOT NULL,
  group_id VARCHAR2(128) NOT NULL,
  app_name VARCHAR2(128) DEFAULT NULL,
  content CLOB NOT NULL,
  beta_ips VARCHAR2(1024) DEFAULT NULL,
  md5 VARCHAR2(32) DEFAULT NULL,
  gmt_create DATE NOT NULL DEFAULT SYSDATE,
  gmt_modified DATE NOT NULL DEFAULT SYSDATE,
  src_user CLOB,
  src_ip VARCHAR2(50) DEFAULT NULL,
  tenant_id VARCHAR2(128) DEFAULT '',
  encrypted_data_key VARCHAR2(1024) NOT NULL DEFAULT '',
  CONSTRAINT uk_configinfobeta_datagrouptenant UNIQUE (data_id, group_id, tenant_id)
);
CREATE SEQUENCE seq_config_info_beta_id START WITH 1 INCREMENT BY 1 NOMAXVALUE NOCYCLE CACHE 20;
CREATE OR REPLACE TRIGGER trg_config_info_beta_id BEFORE INSERT ON config_info_beta FOR EACH ROW
BEGIN IF :NEW.id IS NULL THEN SELECT seq_config_info_beta_id.NEXTVAL INTO :NEW.id FROM DUAL; END IF; END;
/
ALTER TABLE config_info_beta ADD CONSTRAINT pk_config_info_beta PRIMARY KEY (id);

CREATE TABLE config_info_tag (
  id NUMBER(20) NOT NULL,
  data_id VARCHAR2(255) NOT NULL,
  group_id VARCHAR2(128) NOT NULL,
  tenant_id VARCHAR2(128) DEFAULT '',
  tag_id VARCHAR2(128) NOT NULL,
  app_name VARCHAR2(128) DEFAULT NULL,
  content CLOB NOT NULL,
  md5 VARCHAR2(32) DEFAULT NULL,
  gmt_create DATE NOT NULL DEFAULT SYSDATE,
  gmt_modified DATE NOT NULL DEFAULT SYSDATE,
  src_user CLOB,
  src_ip VARCHAR2(50) DEFAULT NULL,
  CONSTRAINT uk_configinfotag_datagrouptenanttag UNIQUE (data_id, group_id, tenant_id, tag_id)
);
CREATE SEQUENCE seq_config_info_tag_id START WITH 1 INCREMENT BY 1 NOMAXVALUE NOCYCLE CACHE 20;
CREATE OR REPLACE TRIGGER trg_config_info_tag_id BEFORE INSERT ON config_info_tag FOR EACH ROW
BEGIN IF :NEW.id IS NULL THEN SELECT seq_config_info_tag_id.NEXTVAL INTO :NEW.id FROM DUAL; END IF; END;
/
ALTER TABLE config_info_tag ADD CONSTRAINT pk_config_info_tag PRIMARY KEY (id);

CREATE TABLE config_tags_relation (
  id NUMBER(20) NOT NULL,
  tag_name VARCHAR2(128) NOT NULL,
  tag_type VARCHAR2(64) DEFAULT NULL,
  data_id VARCHAR2(255) NOT NULL,
  group_id VARCHAR2(128) NOT NULL,
  tenant_id VARCHAR2(128) DEFAULT '',
  nid NUMBER(20) NOT NULL,
  CONSTRAINT uk_configtagrelation_configidtag UNIQUE (id, tag_name, tag_type)
);
CREATE SEQUENCE seq_config_tags_relation_nid START WITH 1 INCREMENT BY 1 NOMAXVALUE NOCYCLE CACHE 20;
CREATE OR REPLACE TRIGGER trg_config_tags_relation_nid BEFORE INSERT ON config_tags_relation FOR EACH ROW
BEGIN IF :NEW.nid IS NULL THEN SELECT seq_config_tags_relation_nid.NEXTVAL INTO :NEW.nid FROM DUAL; END IF; END;
/
ALTER TABLE config_tags_relation ADD CONSTRAINT pk_config_tags_relation PRIMARY KEY (nid);
CREATE INDEX idx_tenant_id ON config_tags_relation (tenant_id);

CREATE TABLE group_capacity (
  id NUMBER(20) NOT NULL,
  group_id VARCHAR2(128) NOT NULL DEFAULT '',
  quota NUMBER(10) NOT NULL DEFAULT 0,
  usage NUMBER(10) NOT NULL DEFAULT 0,
  max_size NUMBER(10) NOT NULL DEFAULT 0,
  max_aggr_count NUMBER(10) NOT NULL DEFAULT 0,
  max_aggr_size NUMBER(10) NOT NULL DEFAULT 0,
  max_history_count NUMBER(10) NOT NULL DEFAULT 0,
  gmt_create DATE NOT NULL DEFAULT SYSDATE,
  gmt_modified DATE NOT NULL DEFAULT SYSDATE,
  CONSTRAINT uk_group_id UNIQUE (group_id)
);
CREATE SEQUENCE seq_group_capacity_id START WITH 1 INCREMENT BY 1 NOMAXVALUE NOCYCLE CACHE 20;
CREATE OR REPLACE TRIGGER trg_group_capacity_id BEFORE INSERT ON group_capacity FOR EACH ROW
BEGIN IF :NEW.id IS NULL THEN SELECT seq_group_capacity_id.NEXTVAL INTO :NEW.id FROM DUAL; END IF; END;
/
ALTER TABLE group_capacity ADD CONSTRAINT pk_group_capacity PRIMARY KEY (id);

CREATE TABLE his_config_info (
  id NUMBER(20) NOT NULL,
  nid NUMBER(20) NOT NULL,
  data_id VARCHAR2(255) NOT NULL,
  group_id VARCHAR2(128) NOT NULL,
  app_name VARCHAR2(128) DEFAULT NULL,
  content CLOB NOT NULL,
  md5 VARCHAR2(32) DEFAULT NULL,
  gmt_create DATE NOT NULL DEFAULT SYSDATE,
  gmt_modified DATE NOT NULL DEFAULT SYSDATE,
  src_user CLOB,
  src_ip VARCHAR2(50) DEFAULT NULL,
  op_type CHAR(10) DEFAULT NULL,
  tenant_id VARCHAR2(128) DEFAULT '',
  encrypted_data_key VARCHAR2(1024) NOT NULL DEFAULT ''
);
CREATE SEQUENCE seq_his_config_info_nid START WITH 1 INCREMENT BY 1 NOMAXVALUE NOCYCLE CACHE 20;
CREATE OR REPLACE TRIGGER trg_his_config_info_nid BEFORE INSERT ON his_config_info FOR EACH ROW
BEGIN IF :NEW.nid IS NULL THEN SELECT seq_his_config_info_nid.NEXTVAL INTO :NEW.nid FROM DUAL; END IF; END;
/
ALTER TABLE his_config_info ADD CONSTRAINT pk_his_config_info PRIMARY KEY (nid);
CREATE INDEX idx_gmt_create ON his_config_info (gmt_create);
CREATE INDEX idx_gmt_modified ON his_config_info (gmt_modified);
CREATE INDEX idx_did ON his_config_info (data_id);

CREATE TABLE tenant_capacity (
  id NUMBER(20) NOT NULL,
  tenant_id VARCHAR2(128) NOT NULL DEFAULT '',
  quota NUMBER(10) NOT NULL DEFAULT 0,
  usage NUMBER(10) NOT NULL DEFAULT 0,
  max_size NUMBER(10) NOT NULL DEFAULT 0,
  max_aggr_count NUMBER(10) NOT NULL DEFAULT 0,
  max_aggr_size NUMBER(10) NOT NULL DEFAULT 0,
  max_history_count NUMBER(10) NOT NULL DEFAULT 0,
  gmt_create DATE NOT NULL DEFAULT SYSDATE,
  gmt_modified DATE NOT NULL DEFAULT SYSDATE,
  CONSTRAINT uk_tenant_id UNIQUE (tenant_id)
);
CREATE SEQUENCE seq_tenant_capacity_id START WITH 1 INCREMENT BY 1 NOMAXVALUE NOCYCLE CACHE 20;
CREATE OR REPLACE TRIGGER trg_tenant_capacity_id BEFORE INSERT ON tenant_capacity FOR EACH ROW
BEGIN IF :NEW.id IS NULL THEN SELECT seq_tenant_capacity_id.NEXTVAL INTO :NEW.id FROM DUAL; END IF; END;
/
ALTER TABLE tenant_capacity ADD CONSTRAINT pk_tenant_capacity PRIMARY KEY (id);

CREATE TABLE tenant_info (
  id NUMBER(20) NOT NULL,
  kp VARCHAR2(128) NOT NULL,
  tenant_id VARCHAR2(128) DEFAULT '',
  tenant_name VARCHAR2(128) DEFAULT '',
  tenant_desc VARCHAR2(256) DEFAULT NULL,
  create_source VARCHAR2(32) DEFAULT NULL,
  gmt_create NUMBER(20) NOT NULL,
  gmt_modified NUMBER(20) NOT NULL,
  CONSTRAINT uk_tenant_info_kptenantid UNIQUE (kp, tenant_id)
);
CREATE SEQUENCE seq_tenant_info_id START WITH 1 INCREMENT BY 1 NOMAXVALUE NOCYCLE CACHE 20;
CREATE OR REPLACE TRIGGER trg_tenant_info_id BEFORE INSERT ON tenant_info FOR EACH ROW
BEGIN IF :NEW.id IS NULL THEN SELECT seq_tenant_info_id.NEXTVAL INTO :NEW.id FROM DUAL; END IF; END;
/
ALTER TABLE tenant_info ADD CONSTRAINT pk_tenant_info PRIMARY KEY (id);
CREATE INDEX idx_tenant_info_id ON tenant_info (tenant_id);

CREATE TABLE users (
  username VARCHAR2(50) NOT NULL,
  password VARCHAR2(500) NOT NULL,
  enabled NUMBER(1) NOT NULL,
  CONSTRAINT pk_users PRIMARY KEY (username)
);

CREATE TABLE roles (
  username VARCHAR2(50) NOT NULL,
  role VARCHAR2(50) NOT NULL,
  CONSTRAINT idx_user_role UNIQUE (username, role)
);

CREATE TABLE permissions (
  role VARCHAR2(50) NOT NULL,
  resource VARCHAR2(128) NOT NULL,
  action VARCHAR2(8) NOT NULL,
  CONSTRAINT uk_role_permission UNIQUE (role, resource, action)
);

INSERT INTO users (username, password, enabled)
SELECT 'nacos', '$2a$10$EuWPZHzz32dJN7jexM34MOeYirDdFAZm2kuWj7VEOJhhZkDrxfvUu', 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'nacos');

INSERT INTO roles (username, role)
SELECT 'nacos', 'ROLE_ADMIN'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM roles WHERE username = 'nacos' AND role = 'ROLE_ADMIN');
*/


-- =====================================================================
--  MODE 3: MySQL compatible
--  Use this if: spring.datasource.gaussdb.compatible.mode=mysql
-- =====================================================================

-- Uncomment the following block for MySQL mode:
/*
CREATE TABLE config_info (
  id BIGINT NOT NULL AUTO_INCREMENT,
  data_id VARCHAR(255) NOT NULL,
  group_id VARCHAR(128) DEFAULT NULL,
  content LONGTEXT NOT NULL,
  md5 VARCHAR(32) DEFAULT NULL,
  gmt_create DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  gmt_modified DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  src_user LONGTEXT,
  src_ip VARCHAR(50) DEFAULT NULL,
  app_name VARCHAR(128) DEFAULT NULL,
  tenant_id VARCHAR(128) DEFAULT '',
  c_desc VARCHAR(256) DEFAULT NULL,
  c_use VARCHAR(64) DEFAULT NULL,
  effect VARCHAR(64) DEFAULT NULL,
  type VARCHAR(64) DEFAULT NULL,
  c_schema LONGTEXT,
  encrypted_data_key VARCHAR(1024) NOT NULL DEFAULT '',
  PRIMARY KEY (id),
  CONSTRAINT uk_configinfo_datagrouptenant UNIQUE (data_id, group_id, tenant_id)
);

CREATE TABLE config_info_aggr (
  id BIGINT NOT NULL AUTO_INCREMENT,
  data_id VARCHAR(255) NOT NULL,
  group_id VARCHAR(128) NOT NULL,
  datum_id VARCHAR(255) NOT NULL,
  content LONGTEXT NOT NULL,
  gmt_modified DATETIME NOT NULL,
  app_name VARCHAR(128) DEFAULT NULL,
  tenant_id VARCHAR(128) DEFAULT '',
  PRIMARY KEY (id),
  CONSTRAINT uk_configinfoaggr_datagrouptenantdatum UNIQUE (data_id, group_id, tenant_id, datum_id)
);

CREATE TABLE config_info_beta (
  id BIGINT NOT NULL AUTO_INCREMENT,
  data_id VARCHAR(255) NOT NULL,
  group_id VARCHAR(128) NOT NULL,
  app_name VARCHAR(128) DEFAULT NULL,
  content LONGTEXT NOT NULL,
  beta_ips VARCHAR(1024) DEFAULT NULL,
  md5 VARCHAR(32) DEFAULT NULL,
  gmt_create DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  gmt_modified DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  src_user LONGTEXT,
  src_ip VARCHAR(50) DEFAULT NULL,
  tenant_id VARCHAR(128) DEFAULT '',
  encrypted_data_key VARCHAR(1024) NOT NULL DEFAULT '',
  PRIMARY KEY (id),
  CONSTRAINT uk_configinfobeta_datagrouptenant UNIQUE (data_id, group_id, tenant_id)
);

CREATE TABLE config_info_tag (
  id BIGINT NOT NULL AUTO_INCREMENT,
  data_id VARCHAR(255) NOT NULL,
  group_id VARCHAR(128) NOT NULL,
  tenant_id VARCHAR(128) DEFAULT '',
  tag_id VARCHAR(128) NOT NULL,
  app_name VARCHAR(128) DEFAULT NULL,
  content LONGTEXT NOT NULL,
  md5 VARCHAR(32) DEFAULT NULL,
  gmt_create DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  gmt_modified DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  src_user LONGTEXT,
  src_ip VARCHAR(50) DEFAULT NULL,
  PRIMARY KEY (id),
  CONSTRAINT uk_configinfotag_datagrouptenanttag UNIQUE (data_id, group_id, tenant_id, tag_id)
);

CREATE TABLE config_tags_relation (
  id BIGINT NOT NULL,
  tag_name VARCHAR(128) NOT NULL,
  tag_type VARCHAR(64) DEFAULT NULL,
  data_id VARCHAR(255) NOT NULL,
  group_id VARCHAR(128) NOT NULL,
  tenant_id VARCHAR(128) DEFAULT '',
  nid BIGINT NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (nid),
  CONSTRAINT uk_configtagrelation_configidtag UNIQUE (id, tag_name, tag_type)
);
CREATE INDEX idx_tenant_id ON config_tags_relation (tenant_id);

CREATE TABLE group_capacity (
  id BIGINT NOT NULL AUTO_INCREMENT,
  group_id VARCHAR(128) NOT NULL DEFAULT '',
  quota INT NOT NULL DEFAULT 0,
  usage INT NOT NULL DEFAULT 0,
  max_size INT NOT NULL DEFAULT 0,
  max_aggr_count INT NOT NULL DEFAULT 0,
  max_aggr_size INT NOT NULL DEFAULT 0,
  max_history_count INT NOT NULL DEFAULT 0,
  gmt_create DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  gmt_modified DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT uk_group_id UNIQUE (group_id)
);

CREATE TABLE his_config_info (
  id BIGINT NOT NULL,
  nid BIGINT NOT NULL AUTO_INCREMENT,
  data_id VARCHAR(255) NOT NULL,
  group_id VARCHAR(128) NOT NULL,
  app_name VARCHAR(128) DEFAULT NULL,
  content LONGTEXT NOT NULL,
  md5 VARCHAR(32) DEFAULT NULL,
  gmt_create DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  gmt_modified DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  src_user LONGTEXT,
  src_ip VARCHAR(50) DEFAULT NULL,
  op_type CHAR(10) DEFAULT NULL,
  tenant_id VARCHAR(128) DEFAULT '',
  encrypted_data_key VARCHAR(1024) NOT NULL DEFAULT '',
  PRIMARY KEY (nid)
);
CREATE INDEX idx_gmt_create ON his_config_info (gmt_create);
CREATE INDEX idx_gmt_modified ON his_config_info (gmt_modified);
CREATE INDEX idx_did ON his_config_info (data_id);

CREATE TABLE tenant_capacity (
  id BIGINT NOT NULL AUTO_INCREMENT,
  tenant_id VARCHAR(128) NOT NULL DEFAULT '',
  quota INT NOT NULL DEFAULT 0,
  usage INT NOT NULL DEFAULT 0,
  max_size INT NOT NULL DEFAULT 0,
  max_aggr_count INT NOT NULL DEFAULT 0,
  max_aggr_size INT NOT NULL DEFAULT 0,
  max_history_count INT NOT NULL DEFAULT 0,
  gmt_create DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  gmt_modified DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT uk_tenant_id UNIQUE (tenant_id)
);

CREATE TABLE tenant_info (
  id BIGINT NOT NULL AUTO_INCREMENT,
  kp VARCHAR(128) NOT NULL,
  tenant_id VARCHAR(128) DEFAULT '',
  tenant_name VARCHAR(128) DEFAULT '',
  tenant_desc VARCHAR(256) DEFAULT NULL,
  create_source VARCHAR(32) DEFAULT NULL,
  gmt_create BIGINT NOT NULL,
  gmt_modified BIGINT NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT uk_tenant_info_kptenantid UNIQUE (kp, tenant_id)
);
CREATE INDEX idx_tenant_info_id ON tenant_info (tenant_id);

CREATE TABLE users (
  username VARCHAR(50) NOT NULL,
  password VARCHAR(500) NOT NULL,
  enabled TINYINT(1) NOT NULL,
  PRIMARY KEY (username)
);

CREATE TABLE roles (
  username VARCHAR(50) NOT NULL,
  role VARCHAR(50) NOT NULL,
  CONSTRAINT idx_user_role UNIQUE (username, role)
);

CREATE TABLE permissions (
  role VARCHAR(50) NOT NULL,
  resource VARCHAR(128) NOT NULL,
  action VARCHAR(8) NOT NULL,
  CONSTRAINT uk_role_permission UNIQUE (role, resource, action)
);

INSERT INTO users (username, password, enabled) VALUES ('nacos', '$2a$10$EuWPZHzz32dJN7jexM34MOeYirDdFAZm2kuWj7VEOJhhZkDrxfvUu', 1);
INSERT INTO roles (username, role) VALUES ('nacos', 'ROLE_ADMIN');
*/
