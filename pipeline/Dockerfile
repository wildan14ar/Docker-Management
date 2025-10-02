# Dockerfile untuk Apache Airflow dengan custom requirements
FROM apache/airflow:3.0.6

# Copy requirements.txt ke dalam container
COPY ./dags/requirements.txt /requirements.txt

# Switch ke root user untuk install packages
USER root

# Install system dependencies termasuk Java untuk Spark Submit
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        openjdk-11-jre-headless \
        procps \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME environment variable
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Switch kembali ke airflow user
USER airflow

# Install Python packages dari requirements.txt
RUN pip install --no-cache-dir -r /requirements.txt

# Set working directory
WORKDIR /opt/airflow