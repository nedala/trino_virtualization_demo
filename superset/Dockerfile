FROM apache/superset:master-py39
# Switching to root to install the required packages
USER root
RUN apt-get update && \
DEBIAN_FRONTEND=noninteractive apt-get -qq install wget curl ca-certificates
RUN update-ca-certificates

RUN pip install mysqlclient psycopg2-binary pyhive trino sqlalchemy-trino

WORKDIR /superset
COPY superset_init.sh /superset/
RUN chmod a+x /superset/superset_init.sh

# Switching back to using the `superset` user
USER superset
CMD ["/superset/superset_init.sh"]