#!/bin/bash
set -e
alias trino="java -jar ${JAR_HOME}/trino.jar --server http://trino:8080 --catalog minio --schema default"
if [[ -z "${MINIO_HOST}" ]]; then
  echo "Skipping Minio Server Configuration"
else
  # Use mc alias set (mc config host add is not supported); ensure URL scheme is present
  mc alias set minio http://${MINIO_HOST} ${MINIO_ACCESS_KEY} ${MINIO_SECRET_KEY} --api S3v4 && \
  mc mb -p minio/spark || true
fi
sleep 10
if [[ -z "${SQL_HOST}" ]]; then
  echo "Database for Metastore is skipped"
else
  schematool -dbType mssql -initSchema || true
  ${HIVE_HOME}/bin/start-metastore &
  ${SPARK_HOME}/sbin/start-thriftserver.sh --master=local[1] --driver-memory=1g \
    --hiveconf hive.server2.thrift.bind.host=0.0.0.0 \
    --hiveconf hive.server2.thrift.port=10000 \
    --hiveconf hive.server2.authentication=NOSASL \
    --conf "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension" \
    --conf "spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog"
fi

# Start JupyterLab ONLY IF JUPYTER_ENABLE_LAB is set to 1
if [[ "${JUPYTER_ENABLE_LAB}" == "1" ]]; then
  echo "Starting JupyterLab"
  cd /
  jupyter lab --port 8888 --no-browser --ip=* --NotebookApp.token='' --NotebookApp.password='' --allow-root &
fi
# Wait in background mode
tail -f /dev/null