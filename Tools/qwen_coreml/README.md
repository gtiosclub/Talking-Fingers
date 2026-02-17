# Qwen Core ML Conversion Tooling

This folder contains scripts and dependencies to convert the Hugging Face model
`Qwen/Qwen2.5-0.5B-Instruct` into a Core ML `.mlpackage` artifact for iOS use.

Prerequisites:
* Python 3.11

## Initial Environment Setup
Ensure that you have Python 3.11 set up.
```bash
python3.11 --version
```

From repository root:
```bash
cd Tools/qwen_coreml
python3.11 -m venv .venv
source .venv/bin/activate
```
At this point, you should see a `(.venv)` in the current shell prompt. This will also create a .venv/ folder at Tools/qwen_coreml. .venv/ is included in the .gitignore -- it should NOT be committed as to not unnecessarily bloat the codebase.

Next, install the dependencies listed in `requirements.txt`.

```
python -m pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
```

## Workflow after Initial Setup
From repository root:

```bash
cd Tools/qwen_coreml
source .venv/bin/activate
```

When done:
```bash
deactivate
```

## Generate Core ML Artifact

From repository root:
```bash
cd Tools/qwen_coreml
source .venv/bin/activate
python covert.py
```

This will create/update files in Tools/qwen_coreml/output/.

Expected outputs (check with `ls -la`):
* output/QwenSentenceGen.mlpackage/
* output/tokenizer.json
* output/tokenizer_config.json
* output/chat_template.jinja (optional but useful)
