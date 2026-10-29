# Screenshots checklist

Save these PNGs in this folder (names are suggestions):

| File | What to capture |
|---|---|
| `01_docker_build.png` | Terminal after `docker build -t bd-a1:1.0 .` finishes successfully |
| `02_docker_images.png` | `docker images` showing `bd-a1:1.0` and `<dockerhub-username>/bd-a1` |
| `03_docker_ps.png` | `docker ps` showing `bd-a1-container` running with `0.0.0.0:8888->8888/tcp` |
| `04_docker_ps_a.png` | `docker ps -a` after `docker stop` (status *Exited*) |
| `05_docker_logs.png` | `docker logs bd-a1-container` with the Jupyter URL |
| `06_docker_inspect.png` | `docker inspect` showing the `Mounts` section (bind mount to `output/`) |
| `07_jupyter_notebook.png` | JupyterLab in the browser with `analysis.ipynb` executed (first cell shows `Running inside Docker container: True`) |
| `08_output_on_host.png` | Host file explorer showing `output/` files **after** `docker rm` |
| `09_docker_push.png` | `docker push` to Docker Hub completing |
| `10_docker_pull_teammate.png` | Teammate's machine: `docker pull` + running container |
