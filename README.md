# vLLM Llama for AMD64 and ARM64

Multi-platform rebuild of [GRyCAP's vllm-llama crate](https://github.com/grycap/oscar-hub/tree/main/crates/vllm-llama), using the same vLLM **0.12.0** and **unsloth/Llama-3.2-1B-Instruct** model at revision `5a8abab4a5d6f164389b1079fb721cfab8d7126c`.

The model is downloaded during the build and `HF_HUB_OFFLINE=1` is set at runtime. The official vLLM base index is pinned by digest and includes both `linux/amd64` and `linux/arm64`. These are CUDA GPU images: ARM64 support requires a compatible NVIDIA GPU, driver, and container runtime (for example, a supported Grace Hopper system). This does not add CPU or Apple Metal support.

## Publish with GitHub Actions

Once this repository is hosted on GitHub, pushes to `main`, `v*` tags, and manual workflow runs build on native AMD64 and ARM64 runners. The workflow pushes both images by digest and combines them into one multi-platform image at `ghcr.io/<owner>/<repository>` (lowercase). It uses the built-in `GITHUB_TOKEN` with `packages: write`; no registry password secret is needed. Enable Actions and package publishing in the repository/organization settings if restricted.

- Default branch builds publish `latest` and `sha-<short-commit>`.
- Version tags publish the exact tag (e.g. `v1.0.0`) and a commit tag.
- Pull requests build both architectures without logging in or publishing.
- Manual runs publish a commit tag, plus `latest` when run on the default branch.

Native ARM runners must be available for the repository's GitHub plan. CUDA base images and the bundled model are large; the workflow frees unused preinstalled SDKs before building. GHCR packages may initially be private: make the package public, or configure registry credentials in your cluster.

## Deploy to OSCAR

`script.sh` is copied unchanged from upstream. `fdl.yaml` is upstream's `fdl.yml`, renamed and updated to use `ghcr.io/micrusa/oscar-vllm-llama-arm64:latest`. If hosted under another owner/repository, update its `image` field. Set the `oscar-cluster` alias and replace the example `API_KEY: "secretkey"` before deployment.

```bash
oscar-cli apply fdl.yaml
```

The image tag automatically selects the node's architecture. The FDL retains upstream's GPU requirement, resource settings, API path, and health endpoint.

## Build or run locally

Build for the current host architecture:

```bash
docker build -t vllm-llama:local .
```

For a multi-platform build, configure a Buildx builder with native nodes or QEMU, then use a registry you can push to:

```bash
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ghcr.io/<owner>/<repository>:test --push .
```

Run on an NVIDIA GPU host (the default command selects the bundled model):

```bash
docker run --rm --gpus all --ipc=host -p 8000:8000 \
  ghcr.io/micrusa/oscar-vllm-llama-arm64:latest
```

OSCAR uses the separately provided script. For direct Docker usage, arguments after the image replace the defaults passed to the inherited `vllm serve` entrypoint; include the model name and revision when overriding them.

## Provenance

Upstream files were retrieved from GRyCAP/oscar-hub commit [`4f55aaadd73a766553e1f77a5275e6af190147bb`](https://github.com/grycap/oscar-hub/tree/4f55aaadd73a766553e1f77a5275e6af190147bb/crates/vllm-llama). The Dockerfile follows that crate's image setup, using the already-installed Hugging Face Python API to download the same snapshot instead of installing a separate CLI. Model files retain their upstream licensing terms; see the [model repository](https://huggingface.co/unsloth/Llama-3.2-1B-Instruct).
