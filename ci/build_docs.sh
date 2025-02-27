#!/bin/bash
# Copyright (c) 2023, NVIDIA CORPORATION.

set -euo pipefail

rapids-logger "Create test conda environment"
. /opt/conda/etc/profile.d/conda.sh

rapids-dependency-file-generator \
  --output conda \
  --file_key docs \
  --matrix "cuda=${RAPIDS_CUDA_VERSION%.*};arch=$(arch);py=${RAPIDS_PY_VERSION}" | tee env.yaml

rapids-mamba-retry env create --force -f env.yaml -n docs
conda activate docs

rapids-print-env

rapids-logger "Downloading artifacts from previous jobs"
CPP_CHANNEL=$(rapids-download-conda-from-s3 cpp)
PYTHON_CHANNEL=$(rapids-download-conda-from-s3 python)

rapids-mamba-retry install \
  --channel "${CPP_CHANNEL}" \
  --channel "${PYTHON_CHANNEL}" \
  libcudf cudf dask-cudf

export RAPIDS_VERSION_NUMBER="23.10"
export RAPIDS_DOCS_DIR="$(mktemp -d)"

rapids-logger "Build CPP docs"
pushd cpp/doxygen
aws s3 cp s3://rapidsai-docs/librmm/${RAPIDS_VERSION_NUMBER}/html/rmm.tag . || echo "Failed to download rmm Doxygen tag"
doxygen Doxyfile
mkdir -p "${RAPIDS_DOCS_DIR}/libcudf/html"
mv html/* "${RAPIDS_DOCS_DIR}/libcudf/html"
popd

rapids-logger "Build Python docs"
pushd docs/cudf
sphinx-build -b dirhtml source _html
sphinx-build -b text source _text
mkdir -p "${RAPIDS_DOCS_DIR}/cudf/"{html,txt}
mv _html/* "${RAPIDS_DOCS_DIR}/cudf/html"
mv _text/* "${RAPIDS_DOCS_DIR}/cudf/txt"
popd

rapids-logger "Build dask-cuDF Sphinx docs"
pushd docs/dask_cudf
sphinx-build -b dirhtml source _html
sphinx-build -b text source _text
mkdir -p "${RAPIDS_DOCS_DIR}/dask-cudf/"{html,txt}
mv _html/* "${RAPIDS_DOCS_DIR}/dask-cudf/html"
mv _text/* "${RAPIDS_DOCS_DIR}/dask-cudf/txt"
popd

rapids-upload-docs
