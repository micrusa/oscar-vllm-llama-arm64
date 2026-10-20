# syntax=docker/dockerfile:1
# Upstream crate's vLLM version; this index contains linux/amd64 and linux/arm64.
FROM vllm/vllm-openai:v0.12.0@sha256:6766ce0c459e24b76f3e9ba14ffc0442131ef4248c904efdcbf0d89e38be01fe

# huggingface_hub is already a vLLM dependency. Use its Python API rather than
# installing a newer CLI that could change the base image's dependencies.
RUN python3 - <<'PY'
from huggingface_hub import snapshot_download
snapshot_download(
    repo_id="unsloth/Llama-3.2-1B-Instruct",
    revision="5a8abab4a5d6f164389b1079fb721cfab8d7126c",
)
PY

ENV HF_HUB_OFFLINE=1

# Check that this exact snapshot can be resolved without network access.
RUN python3 - <<'PY'
from pathlib import Path
from huggingface_hub import snapshot_download
snapshot = Path(snapshot_download(
    repo_id="unsloth/Llama-3.2-1B-Instruct",
    revision="5a8abab4a5d6f164389b1079fb721cfab8d7126c",
    local_files_only=True,
))
assert (snapshot / "config.json").is_file()
assert (snapshot / "model.safetensors").is_file()
assert (snapshot / "tokenizer.json").is_file()
PY

# Inherit vLLM's `vllm serve` entrypoint. OSCAR supplies script.sh separately.
CMD ["unsloth/Llama-3.2-1B-Instruct", "--revision", "5a8abab4a5d6f164389b1079fb721cfab8d7126c"]
