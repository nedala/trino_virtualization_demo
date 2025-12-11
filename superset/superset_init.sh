#!/bin/bash
set -e
echo "SQLALCHEMY_DATABASE_URI = \"${SQLALCHEMY_DATABASE_URI}\"" >> /app/superset/superset_config.py
echo "SUPERSET_LOAD_EXAMPLES = False" >> /app/superset/superset_config.py
echo "SUPERSET_SECRET_KEY = \"${SUPERSET_SECRET_KEY}\"" >> /app/superset/superset_config.py
export PYTHONPATH=/app/superset:$PYTHONPATH
superset db upgrade
superset fab create-admin \
              --username admin \
              --firstname Superset \
              --lastname Admin \
              --email admin@superset.com \
              --password admin
superset init
superset run --port=8088 --host=0.0.0.0