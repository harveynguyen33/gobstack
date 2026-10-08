#!/usr/bin/env python3
"""mcp-client.py — a tiny JSON-RPC client used by tests/t-mcp.sh.

Reads newline-delimited JSON-RPC requests from stdin, runs them against the server
command given as argv[1] (a shell string), and prints one response line per request
that carries an id. Notifications produce no answer, and the client waits for each
id before sending nothing further — a batch is sent whole, the answers are read in
order, matching the server's line-framed stdin/stdout.

Stdlib only (subprocess, json, sys) — the suite's dependency contract.
"""
import json
import subprocess
import sys


def main() -> int:
    if len(sys.argv) < 2:
        sys.stderr.write("usage: mcp-client.py <server-command>\n")
        return 2
    server_cmd = sys.argv[1]
    requests = []
    for raw in sys.stdin:
        raw = raw.strip()
        if raw:
            requests.append(raw)

    proc = subprocess.Popen(
        server_cmd,
        shell=True,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
    )
    assert proc.stdin is not None and proc.stdout is not None
    try:
        proc.stdin.write("\n".join(requests) + "\n")
        proc.stdin.flush()
    except BrokenPipeError:
        pass

    # Collect every id we owe an answer for; read until all are answered or the
    # server closes. A notification in the input is legal and draws no line.
    owed = set()
    for raw in requests:
        try:
            msg = json.loads(raw)
        except json.JSONDecodeError:
            continue
        if isinstance(msg, dict) and "id" in msg:
            owed.add(msg["id"])

    answered = 0
    total = len(owed)
    out_lines = []
    while owed and answered < total:
        line = proc.stdout.readline()
        if not line:
            break
        line = line.strip()
        if not line:
            continue
        print(line, flush=True)
        try:
            resp = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(resp, dict) and "id" in resp and resp["id"] in owed:
            owed.discard(resp["id"])
            answered += 1
    proc.stdin.close()
    try:
        proc.wait(timeout=10)
    except subprocess.TimeoutExpired:
        proc.kill()
    return 0


if __name__ == "__main__":
    sys.exit(main())
