#
#  convert.py
#  Talking Fingers
#
#  Created by Jagat Sachdeva on 2/11/26.
#

from pathlib import Path

import torch
from transformers import AutoTokenizer, AutoModelForCausalLM

import coremltools as ct
import numpy as np

import transformers.masking_utils as masking_utils

def _no_packed_sequence_indices(position_ids):
    return None

masking_utils.find_packed_sequence_indices = _no_packed_sequence_indices

# --- coremltools workarounds: replace unsupported ops used by HF masking utils ---
def _diff_compat(x: torch.Tensor, n: int = 1, dim: int = -1, prepend=None, append=None) -> torch.Tensor:
    if prepend is not None:
        if not torch.is_tensor(prepend):
            prepend = torch.tensor(prepend, dtype=x.dtype, device=x.device)
        prepend = prepend.to(dtype=x.dtype, device=x.device)
        while prepend.dim() < x.dim():
            prepend = prepend.unsqueeze(0)
        x = torch.cat([prepend, x], dim=dim)

    if append is not None:
        if not torch.is_tensor(append):
            append = torch.tensor(append, dtype=x.dtype, device=x.device)
        append = append.to(dtype=x.dtype, device=x.device)
        while append.dim() < x.dim():
            append = append.unsqueeze(0)
        x = torch.cat([x, append], dim=dim)

    for _ in range(n):
        if x.size(dim) < 2:
            shape = list(x.shape)
            shape[dim] = 0
            return x.new_empty(shape)
        a = x.narrow(dim, 1, x.size(dim) - 1)
        b = x.narrow(dim, 0, x.size(dim) - 1)
        x = a - b
    return x

torch.diff = _diff_compat  # type: ignore[attr-defined]

# 2) Replace Tensor.new_ones(...) with full_like, avoiding aten::new_ones and shape-tensor issues
def _new_ones_compat(self: torch.Tensor, size, dtype=None, device=None, **kwargs):
    if torch.is_tensor(size):
        size = tuple(size.tolist())
    elif isinstance(size, (list, tuple)):
        size = tuple(size)

    if dtype is None:
        dtype = self.dtype
    if device is None:
        device = self.device

    tmp = torch.empty(size, dtype=dtype, device=device)
    return torch.full_like(tmp, 1)


torch.Tensor.new_ones = _new_ones_compat  # type: ignore[assignment]

MODEL_ID = "Qwen/Qwen2.5-0.5B-Instruct"
CONTEXT_LEN = 128  # fixed context length
OUTPUT_DIR = Path(__file__).parent / "output"
MLPACKAGE_NAME = "QwenSentenceGen.mlpackage"


def main():
    # =========================
    # Stage 0: Setup output dir
    # =========================
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # =========================
    # Stage 1: Load tokenizer + model (HF)
    # =========================
    print(f"Loading tokenizer: {MODEL_ID}")
    tokenizer = AutoTokenizer.from_pretrained(MODEL_ID, use_fast=True)

    print(f"Loading model: {MODEL_ID}")
    model = AutoModelForCausalLM.from_pretrained(
        MODEL_ID,
        torch_dtype=torch.float32,
        device_map=None,
    )
    model.eval()  # inference-only mode

    # =========================
    # Stage 2: Wrap model for export (logits-only)
    # =========================
    class Wrapper(torch.nn.Module):
        def __init__(self, m):
            super().__init__()
            self.m = m

        def forward(self, input_ids, position_ids):
            out = self.m(
                input_ids=input_ids,
                attention_mask=None,
                position_ids=position_ids,
                use_cache=False,
                return_dict=False,
            )
            return out[0]

    wrapped = Wrapper(model).eval()

    # Example inputs for tracing: fixed (1, CONTEXT_LEN)
    example_input_ids = torch.zeros((1, CONTEXT_LEN), dtype=torch.int64)
    example_position_ids = torch.arange(CONTEXT_LEN, dtype=torch.int64).unsqueeze(0)

    # =========================
    # Stage 3: Trace PyTorch graph
    # =========================
    print("Tracing PyTorch graph (torch.jit.trace)...")
    with torch.no_grad():
        print(example_input_ids.shape, example_position_ids.shape)
        traced = torch.jit.trace(
            wrapped,
            (example_input_ids, example_position_ids),
            strict=False,
        )


    # =========================
    # Stage 4: Convert to Core ML (ML Program)
    # =========================
    print("Converting to Core ML (ML Program)...")
    mlmodel = ct.convert(
        traced,
        convert_to="mlprogram",
        inputs=[
            ct.TensorType(
                name="input_ids",
                shape=example_input_ids.shape,
                dtype=np.int32,
            ),
            ct.TensorType(
                name="position_ids",
                shape=example_position_ids.shape,
                dtype=np.int32,
            ),
        ],
        # Helps reduce model size / improve perf on Apple hardware
        compute_precision=ct.precision.FLOAT16,
        compute_units=ct.ComputeUnit.ALL,
    )

    # =========================
    # Stage 5: Save artifacts (.mlpackage + tokenizer files)
    # =========================
    out_path = OUTPUT_DIR / MLPACKAGE_NAME
    print(f"Saving Core ML package -> {out_path}")
    mlmodel.save(str(out_path))

    print(f"Saving tokenizer files -> {OUTPUT_DIR}")
    # Writes tokenizer.json and related configs if available
    tokenizer.save_pretrained(str(OUTPUT_DIR))

    # =========================
    # Stage 6: Sanity checks
    # =========================
    expected_tokenizer = OUTPUT_DIR / "tokenizer.json"
    print("\n=== DONE CHECK ===")
    print(f"MLPackage exists: {out_path.exists()} ({out_path})")
    print(f"tokenizer.json exists: {expected_tokenizer.exists()} ({expected_tokenizer})")

    if not out_path.exists():
        raise RuntimeError("Core ML package was not created.")
    if not expected_tokenizer.exists():
        print("⚠️ tokenizer.json not found. (Some tokenizers may not emit tokenizer.json.)")
        print("   Check output/ for tokenizer_config.json / vocab files and share listing if needed.")


if __name__ == "__main__":
    main()

