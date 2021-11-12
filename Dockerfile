## Stage 1
FROM python:3.10-slim-bullseye as create_venv

# Install build dependencies
RUN apt-get update && apt-get install --no-install-recommends --yes \
    build-essential \
    libopenblas-dev \
    liblapack-dev \
    cmake

# Create venv and activate it
ENV VENV=/opt/venv
RUN python -m venv ${VENV}
ENV PATH="${VENV}/bin:$PATH"

# Download DFX SDK wheel
ADD https://s3.us-east-2.amazonaws.com/nuralogix-assets/dfx-sdk/python/libdfx-4.9.3.0-py3-none-linux_x86_64.whl /wheel/

# Copy project files
WORKDIR /app
COPY *.py ./
COPY dfxdemo/*.py dfxdemo/
COPY dfxutils/*.py dfxutils/

# Switch to headless OpenCV
RUN sed -i "s/opencv-python/opencv-python-headless/" setup.py

# Install everything into the venv
RUN pip install wheel --no-cache-dir --disable-pip-version-check && \
    pip install . --disable-pip-version-check --no-cache-dir --use-feature=in-tree-build --find-links /wheel

## Stage 2
FROM python:3.10-slim-bullseye

# Install run dependencies
RUN apt-get update && apt-get install --no-install-recommends --yes \
    libopenblas0 \
    liblapack3 \
    libatomic1

# Copy venv from previous stage and activate it
ENV VENV=/opt/venv
COPY --from=create_venv ${VENV} ${VENV}
ENV PATH="${VENV}/bin:$PATH"

WORKDIR /app
ENTRYPOINT [ "dfxdemo" ]