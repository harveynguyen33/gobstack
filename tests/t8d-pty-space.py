# T8d: the space key on the emit (sync) checkboxes screen — the tty_key SPACE case.
# pty.fork (the T8 probe approach), a 4-anchor fake HOME so exactly four platforms
# pre-tick, then: SPACE, SPACE, arrows, SPACE — assert the pointed row's mark flips
# ☑→☐→☑ and that Enter commits. Run by hand (not in run-tests.sh): the suite has no
# pty guarantee; T8's script(1) path already pins the tty frame shapes.
import json, os, pty, sys, time, select, shutil, tempfile, subprocess

SRC = "/tmp/wizv2"
fail = 0
def check(name, ok):
    global fail
    print(("ok   " if ok else "FAIL ") + name)
    if not ok: fail = 1

work = tempfile.mkdtemp(prefix="t8d.")
home = os.path.join(work, "home")
repo = os.path.join(work, "repo")
os.makedirs(os.path.join(home, ".hermes"))
os.makedirs(os.path.join(home, ".claude"))
os.makedirs(os.path.join(home, ".cursor"))
os.makedirs(os.path.join(home, ".codex"))
os.makedirs(os.path.join(repo, "tests"))
subprocess.run(["git", "init", "-q", "-b", "main"], cwd=repo, check=True)
subprocess.run(["git", "config", "user.name", "t"], cwd=repo, check=True)
subprocess.run(["git", "config", "user.email", "t@t.co"], cwd=repo, check=True)
with open(os.path.join(repo, "README.md"), "w") as f: f.write("# probe\n")
with open(os.path.join(repo, "tests", "run-tests.sh"), "w") as f:
    f.write("#!/usr/bin/env bash\nexit 0\n")
os.chmod(os.path.join(repo, "tests", "run-tests.sh"), 0o755)
subprocess.run(["git", "add", "-A"], cwd=repo, check=True)
subprocess.run(["git", "commit", "-q", "-m", "seed"], cwd=repo, check=True)

env = {
    "HOME": home,
    "GOBLIN_MODELS": os.path.join(work, "models.yaml"),
    "GOBLIN_PRACTICE": os.path.join(work, "standard.md"),
    "PATH": "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
    "TERM": "xterm",
}
with open(env["GOBLIN_MODELS"], "w") as f:
    f.write("profiles:\n  coder:\n    model: m\n    provider: p\n    effort: low\n")
with open(env["GOBLIN_PRACTICE"], "w") as f:
    f.write("the referenced standard\n")

cmd = "bash %s/bin/goblin-init --target %s" % (SRC, repo)
pid, fd = pty.fork()
if pid == 0:
    os.environ.update(env)
    os.environ["NO_COLOR"] = "1"
    os.execvp("bash", ["bash", "-c", cmd])

out = b""
start = time.time()
UP, DOWN, SPACE, ENTER = b"\033[A", b"\033[B", b" ", b"\r"
# screen order on a tty: welcome+health draw, then class radio (ENTER), identity
# branch (ENTER), email (ENTER), gate (ENTER), ci radio (ENTER), emit checkboxes.
keys = [
    (1.0, ENTER),   # class: accept the pointed default
    (0.5, ENTER),   # branch
    (0.5, ENTER),   # email
    (0.5, ENTER),   # gate
    (0.5, ENTER),   # ci
    (1.0, SPACE),   # emit: toggle the pointed (first) row off  ☑ -> ☐
    (0.5, SPACE),   # ... and back on                          ☐ -> ☑
    (0.5, DOWN),
    (0.4, SPACE),   # toggle the second row off
    (0.5, ENTER),   # commit -> plan -> [run] prompt
    (0.8, ENTER),   # confirm the plan
]
ki = iter(keys)
nk = next(ki, None)
exited = False
while True:
    if time.time() - start > 90:
        os.write(fd, b"\003"); time.sleep(0.3); break
    r, _, _ = select.select([fd], [], [], 0.2)
    if r:
        try: data = os.read(fd, 65536)
        except OSError: break
        if not data: break
        out += data
    if nk is not None and time.time() - start >= nk[0]:
        os.write(fd, nk[1]); nk = next(ki, None)
    try:
        wpid, status = os.waitpid(pid, os.WNOHANG)
        if wpid == pid: exited = True
    except ChildProcessError: exited = True
    if exited:
        while True:
            r, _, _ = select.select([fd], [], [], 0.3)
            if not r: break
            try: data = os.read(fd, 65536)
            except OSError: break
            if not data: break
            out += data
        break
try: os.waitpid(pid, 0)
except ChildProcessError: pass

txt = out.decode("utf-8", "replace")
with open("/tmp/wizv2/tests/t8d-transcript.txt", "w") as f: f.write(txt)
print("__RC__ see transcript tail below")

# The emit screen renders rows as:  ▸ ☑ <platform>   (NO_COLOR keeps the C_ vars empty
# but the frame shapes stay). Anchor on the checkbox glyph with the platform names.
def rows_on_screen():
    # take the LAST occurrence of the emit prompt and read the frame after it
    i = txt.rfind("sync them into")
    return txt[i:] if i >= 0 else ""

tail = rows_on_screen()
# The pointed row flips first: after two spaces it must show ☑ again; after the
# down+space the second row shows ☐ while the first still shows ☑. Because the redraw
# overwrites in place, assert on the frame history: find each glyph-pair near a name.
first_on  = txt.count("☑ claude") + txt.count("☑ hermes")
first_off = txt.count("☐ claude") + txt.count("☐ hermes")
check("the transcript shows a ticked platform row at all (screen reached)", first_on > 0)
check("space toggled the pointed row OFF (an unticked ☐ row appeared)", first_off > 0)
# the pointed row is ☐ then ☑ again later in the transcript history (two spaces)
check("the toggle returned (the row is ☑ again after the second space)",
      txt.rfind("☐ claude") < txt.rfind("☑ claude", txt.rfind("☐ claude") + 1))
check("the arrow moved the pointer and the second row toggles too (☐ hermes seen)",
      "☐ hermes" in txt)
check("the committed plan drops the unticked platform (claude cursor codex)",
      "(claude cursor codex)" in txt)
check("the wizard finished (the sync/next-steps epilogue printed)", "not synced here" in txt or "gob sync" in txt)
rcf = os.path.join(repo, ".goblin", "goblin.yaml")
check("the install wrote the record", os.path.exists(rcf))
shutil.rmtree(work, ignore_errors=True)
sys.exit(1 if fail else 0)
