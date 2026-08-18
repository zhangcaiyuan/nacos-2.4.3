-- Nacos 2.4.3 PostgreSQL Schema
-- 自动转换自 mysql-schema.sql

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

COMMENT ON TABLE config_info IS 'config_info';
COMMENT ON COLUMN config_info.id IS 'id';
COMMENT ON COLUMN config_info.data_id IS 'data_id';
COMMENT ON COLUMN config_info.group_id IS 'group_id';
COMMENT ON COLUMN config_info.content IS 'content';
COMMENT ON COLUMN config_info.md5 IS 'md5';
COMMENT ON COLUMN config_info.gmt_create IS 'create time';
COMMENT ON COLUMN config_info.gmt_modified IS 'modify time';
COMMENT ON COLUMN config_info.src_user IS 'source user';
COMMENT ON COLUMN config_info.src_ip IS 'source ip';
COMMENT ON COLUMN config_info.app_name IS 'app_name';
COMMENT ON COLUMN config_info.tenant_id IS 'tenant';
COMMENT ON COLUMN config_info.c_desc IS 'configuration description';
COMMENT ON COLUMN config_info.c_use IS 'configuration usage';
COMMENT ON COLUMN config_info.effect IS 'configuration effect';
COMMENT ON COLUMN config_info.type IS 'configuration type';
COMMENT ON COLUMN config_info.c_schema IS 'configuration schema';
COMMENT ON COLUMN config_info.encrypted_data_key IS 'encrypted data key';

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

COMMENT ON TABLE config_info_aggr IS 'config_info_aggr';

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

COMMENT ON TABLE config_info_beta IS 'config_info_beta';

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

COMMENT ON TABLE config_info_tag IS 'config_info_tag';

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

COMMENT ON TABLE config_tags_relation IS 'config_tag_relation';

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

COMMENT ON TABLE group_capacity IS 'group_capacity';

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

COMMENT ON TABLE his_config_info IS 'his_config_info';

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

COMMENT ON TABLE tenant_capacity IS 'tenant_capacity';

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

COMMENT ON TABLE tenant_info IS 'tenant_info';

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

-- Default admin user (BCrypt encoded password: nacos)
INSERT INTO users (username, password, enabled) VALUES ('nacos', '$2a$10$EuWPZHzz32dJN7jexM34MOeYirDdFAZm2kuWj7VEOJhhZkDrxfvUu', true) ON CONFLICT (username) DO NOTHING;
INSERT INTO roles (username, role) VALUES ('nacos', 'ROLE_ADMIN') ON CONFLICT (username, role) DO NOTHING;
