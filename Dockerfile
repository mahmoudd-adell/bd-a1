# ---------------------------------------------------------------
# CSCI461 Assignment 1 - Dockerized SMS Spam Analysis
# Base image required by the assignment (Python + JupyterLab +
# pandas, numpy, scikit-learn, matplotlib, seaborn already inside)
# ---------------------------------------------------------------
FROM quay.io/jupyter/scipy-notebook:latest

LABEL maintainer="CSCI461 Team" \
      description="SMS Spam Collection: data cleaning, text analysis, TF-IDF classification and K-Means"

# 1) Install the extra Python packages listed in requirements.txt.
#    Copying requirements.txt on its own first means this layer is
#    cached and only rebuilt when requirements.txt changes.
COPY --chown=${NB_UID}:${NB_GID} requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt && \
    rm /tmp/requirements.txt

# 2) Create the project folder inside the image (owned by the default
#    notebook user "jovyan" so Jupyter can write into it).
RUN mkdir -p /home/jovyan/bd-a1/data \
             /home/jovyan/bd-a1/notebook \
             /home/jovyan/bd-a1/output/figures

# 3) Make that folder the working directory. JupyterLab opens here.
WORKDIR /home/jovyan/bd-a1

# 4) Copy the dataset and the notebook into the image.
COPY --chown=${NB_UID}:${NB_GID} data/dataset.csv            data/dataset.csv
COPY --chown=${NB_UID}:${NB_GID} notebook/analysis.ipynb     notebook/analysis.ipynb

# JupyterLab listens on port 8888 inside the container.
EXPOSE 8888

# No CMD needed: the base image already starts JupyterLab
# (start-notebook.py) when the container runs.
