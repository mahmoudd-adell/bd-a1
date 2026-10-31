# bd-a1 — Dockerized SMS Spam Analysis (CSCI461 Assignment 1)

Data cleaning, sampling, text analysis, TF‑IDF spam classification and K‑Means clustering on the **SMS Spam Collection** dataset, running entirely inside a custom Docker image built on `quay.io/jupyter/scipy-notebook:latest`.

```
Dockerfile → custom image → container → JupyterLab → cleaning → sampling → text analysis
→ TF-IDF → classification + K-Means → persistent outputs (bind mount) → Docker Hub
```

## Results at a glance

| Item | Result |
|---|---|
| Rows | 5,574 raw → **5,171** after removing 403 exact duplicates (12.6 % spam) |
| Best classifier | Tuned Logistic Regression (TF‑IDF): **accuracy 98.65 %, spam precision 0.961, recall 0.931, F1 0.946** |
| Other classifiers | Multinomial NB (F1 0.919), balanced Logistic Regression (F1 0.939) |
| K‑Means | **k = 2**: a promotional cluster (621 msgs, 93.9 % spam) and a conversational cluster (4,550 msgs, 1.5 % spam); ARI 0.88, silhouette 0.027 |

---

## 1. Project structure

```
bd-a1/
├── Dockerfile              # builds the custom image
├── requirements.txt        # extra pip packages (wordcloud, tabulate)
├── README.md
├── .dockerignore
├── data/
│   ├── dataset.csv                     # SMS Spam Collection as CSV (label, message)
│   └── SMSSpamCollection_readme.txt    # original dataset readme / licence
├── notebook/
│   └── analysis.ipynb      # full analysis (sections 4, 5, 6)
├── output/                 # written by the notebook, bind-mounted to the host
│   ├── cleaned_data.csv
│   ├── model_metrics.txt
│   ├── cluster_summary.txt
│   └── figures/            # 9-10 PNG figures
└── screenshots/            # evidence for the Docker steps (see screenshots/README.md)
```

## 2. Dataset

* **Source:** UCI Machine Learning Repository, [SMS Spam Collection (#228)](https://archive.ics.uci.edu/dataset/228/sms+spam+collection), by T. A. Almeida and J. M. Gómez Hidalgo. Free to use with citation (see `data/SMSSpamCollection_readme.txt`).
* **One row = one SMS message** with a label: `ham` (legitimate, 4,827) or `spam` (747).
* The original file is tab‑separated with no header. It was converted on the host to `data/dataset.csv` with:

```bash
python -c "import pandas as pd, csv; pd.read_csv('SMSSpamCollection', sep='\t', header=None, names=['label','message'], quoting=csv.QUOTE_NONE, encoding='utf-8').to_csv('data/dataset.csv', index=False)"
```

---

## 3. Docker concepts (for the discussion)

**Image vs container.** An **image** is a read‑only, layered template: the OS, Python, libraries, our notebook and dataset, built from the `Dockerfile`. Each `Dockerfile` instruction (`FROM`, `RUN`, `COPY`, …) adds a cached **layer**. A **container** is a running (or stopped) **instance** of an image with its own writable layer, processes and network. One image can start many containers; deleting a container does not delete the image.

**Port mapping `-p 8888:8888` = `HOST_PORT:CONTAINER_PORT`.** JupyterLab listens on port 8888 *inside* the container, which is isolated from the host network. `-p 8888:8888` forwards port 8888 on the host to port 8888 in the container, so `http://localhost:8888` on the laptop reaches Jupyter. If 8888 is busy on the host, use e.g. `-p 9999:8888` and open `localhost:9999`; the container side stays 8888.

**Bind mount vs volume.** A **bind mount** (`-v "$(pwd)/output:/home/jovyan/bd-a1/output"`) maps a specific host folder into the container. Files the notebook writes to `output/` appear immediately on the host and **remain after the container is removed**. A **named volume** (`-v bd-a1-data:/path`) is storage managed by Docker itself (`docker volume ls`); it also persists, but it is not a normal folder you browse on the host. We use a bind mount because the outputs must be submitted from the host.

**Registry / repository / tag.** **Docker Hub** is a *registry*. `<username>/bd-a1` is a *repository* inside it, and `1.0` / `latest` are *tags* (versions) of the image in that repository.

---

## 4. Build and run (reproduce from scratch)

> Commands are for **Linux/macOS (bash)**. Windows **PowerShell** equivalents are given where they differ (`${PWD}` instead of `$(pwd)`). Run everything from inside the `bd-a1/` folder.

### 4.1 Build the custom image
```bash
docker build -t bd-a1:1.0 .
docker images                      # bd-a1   1.0   ...
```

### 4.2 Run the container (JupyterLab + bind mount for outputs)
```bash
docker run -d --name bd-a1-container \
  -p 8888:8888 \
  -v "$(pwd)/output:/home/jovyan/bd-a1/output" \
  bd-a1:1.0
```
PowerShell:
```powershell
docker run -d --name bd-a1-container -p 8888:8888 -v "${PWD}/output:/home/jovyan/bd-a1/output" bd-a1:1.0
```

* `-d` runs in the background, `--name` gives the container a fixed name.
* *Optional:* also add `-v "$(pwd)/notebook:/home/jovyan/bd-a1/notebook"` if you want notebook edits saved back to the host.
* *Linux only:* if the notebook gets `Permission denied` writing to `output/`, run `chmod -R a+rwX output` once on the host (the container user `jovyan` has UID 1000).

### 4.3 Open JupyterLab and run the notebook
```bash
docker logs bd-a1-container        # copy the URL that contains ?token=...
```
1. Open `http://127.0.0.1:8888/lab?token=...` in the browser.
2. Open `notebook/analysis.ipynb`.
3. **Kernel → Restart Kernel and Run All Cells.** The first cell prints `Running inside Docker container: True`.
4. Check the host: `output/` now contains `cleaned_data.csv`, `model_metrics.txt`, `cluster_summary.txt` and `figures/*.png`.

### 4.4 Prove the outputs persist after the container is removed
```bash
docker stop bd-a1-container
docker rm bd-a1-container
ls output output/figures           # PowerShell: dir output, output\figures
```

---

## 5. Container lifecycle evidence

| Command | What it shows |
|---|---|
| `docker images` | the custom image `bd-a1:1.0` (and the Docker Hub tag) exists |
| `docker ps` | running containers only: `bd-a1-container`, port `0.0.0.0:8888->8888/tcp` |
| `docker ps -a` | all containers, including stopped ones (after `docker stop`) |
| `docker logs bd-a1-container` | Jupyter server log and the access token URL |
| `docker inspect bd-a1-container` | full JSON config: image, port bindings, **Mounts** (the bind mount), WorkingDir |

Useful filters:
```bash
docker inspect -f "{{ json .Mounts }}" bd-a1-container
docker inspect -f "{{ .Config.WorkingDir }}" bd-a1-container     # /home/jovyan/bd-a1
docker history bd-a1:1.0                                          # image layers
```

---

## 6. Docker Hub distribution

Replace `<dockerhub-username>` with the team's Docker Hub username.

```bash
docker login
docker tag bd-a1:1.0 <dockerhub-username>/bd-a1:1.0
docker tag bd-a1:1.0 <dockerhub-username>/bd-a1:latest
docker push <dockerhub-username>/bd-a1:1.0
docker push <dockerhub-username>/bd-a1:latest
```

**Published image:** repository `<dockerhub-username>/bd-a1`, tags `1.0` and `latest`
→ `https://hub.docker.com/r/<dockerhub-username>/bd-a1`

### Reproducibility check (done by another team member on a different machine)
```bash
docker pull <dockerhub-username>/bd-a1:1.0
mkdir -p output
docker run -d --name bd-a1-test -p 8888:8888 \
  -v "$(pwd)/output:/home/jovyan/bd-a1/output" \
  <dockerhub-username>/bd-a1:1.0
docker logs bd-a1-test             # open the token URL, Restart & Run All
```
The dataset and notebook are baked into the image, so no other files are needed.

---

## 7. What the notebook does

| Section | Content |
|---|---|
| **4.1** | head, shape, columns, dtypes, info, describe; meaning of a row; text / label / numerical columns |
| **4.2** | missing values (none), 403 exact duplicates removed (justified: over‑counting + train/test leakage), shape before/after |
| **4.3** | `loc` conditional selection (long spam containing "free"), `iloc` positional selection, `iloc` with `np.r_` |
| **4.4** | 5 transformations: type conversion, label encoding, feature creation (10 text features), binning by the 160‑char SMS limit, Min–Max normalisation |
| **4.5** | simple random, stratified and cluster sampling, plus 300 repetitions to compare their variability |
| **4.6** | correlation heatmap of 8 text features + label; interpretation; correlation ≠ causation |
| **5** | `cleaned_text` (HTML entities, placeholders, URLs/money/phone/numbers → tokens), tokenisation stats, top‑20 words before/after stop‑word removal, spam vs ham comparison, 6 written insights |
| **6.1** | stratified 80/20 split, TF‑IDF, Multinomial NB vs Logistic Regression, **bonus:** grid‑searched model; accuracy, precision, recall, F1, ROC‑AUC, confusion matrices, limitations |
| **6.2** | TF‑IDF → TruncatedSVD(100) → K‑Means, k = 2…10 experiment (silhouette, elbow, cluster composition), k = 2 chosen, cluster sizes, top terms, comparison with labels |

---

## 8. Bonus

* **GitHub (+0.5):** this repository, with one commit per assignment step.
* **Model extension (+0.5):** two supervised classifiers compared (Naive Bayes vs Logistic Regression) **and** a tuned model (grid search over n‑gram range, `min_df` and `C` with 5‑fold CV).

## 9. Team

| Member | ID |
|---|---|
| Mahmoud Adel Khalil | 231001114 |
| Ibrahim Abdellatif | 222000075 |
| Abdulsalam Emad | 222000008 |
