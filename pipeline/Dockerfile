# Base image
FROM apache/airflow:3.0.6

# Copy requirements.txt
COPY ./dags/requirements.txt /requirements.txt

USER root

# Install system dependencies + Java + wget for Spark client
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        openjdk-17-jdk \
        wget \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="$JAVA_HOME/bin:$PATH"

# Optional: Install Spark client (hanya spark-submit) versi 3.4.0
RUN wget https://downloads.apache.org/spark/spark-3.5.6/spark-3.5.6-bin-hadoop3.tgz \
    && tar -xzf spark-3.5.6-bin-hadoop3.tgz -C /opt/ \
    && rm spark-3.5.6-bin-hadoop3.tgz \
    && export SPARK_HOME=/opt/spark-3.4.0-bin-hadoop3 \
    && export PATH=$SPARK_HOME/bin:$PATH

# Switch back to airflow user
USER airflow

# Install Python packages
RUN pip install --no-cache-dir -r /requirements.txt

WORKDIR /opt/airflow