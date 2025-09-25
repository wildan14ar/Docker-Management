# Dockerfile untuk Apache Airflow dengan custom requirements
FROM apache/airflow:3.0.6

# Copy requirements.txt ke dalam container
COPY ./dags/requirements.txt /requirements.txt

# Switch ke root user untuk install packages
USER root

# Install system dependencies jika diperlukan
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Switch kembali ke airflow user
USER airflow

# Install Python packages dari requirements.txt
RUN pip install --no-cache-dir -r /requirements.txt

# Set working directory
WORKDIR /opt/airflow