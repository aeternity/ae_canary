CREATE ROLE ae_canary WITH LOGIN PASSWORD 'canary_pass';
ALTER ROLE ae_canary CREATEDB;
