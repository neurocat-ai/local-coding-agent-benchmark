#!/usr/bin/env python3
import json
import os
import sys
import urllib.request

if len(sys.argv) != 2:
    raise SystemExit("Usage: warm-model.py MODEL")
port = os.environ.get("OLLAMA_PORT", "11434")
url = f"http://127.0.0.1:{port}/api/generate"
req = urllib.request.Request(
    url,
    data=json.dumps({"model": sys.argv[1], "prompt": "Reply READY", "stream": False}).encode(),
    headers={"Content-Type": "application/json"},
)
with urllib.request.urlopen(req, timeout=900) as response:
    payload = json.load(response)
if "response" not in payload:
    raise SystemExit(f"Warm-up failed: {payload}")
