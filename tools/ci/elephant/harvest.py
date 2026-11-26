#!/usr/bin/env python3
"""Operation Elephant: count why CI fails.

Pulls every failed "Run Tests" job from CI Suite runs (every attempt),
reads its log, and groups the failures by cause. Prints a ranked table.

Needs the gh CLI, signed in. Logs are cached in .elephant_cache so a
second run only fetches new jobs.

Usage:
    python3 tools/ci/elephant/harvest.py [--repo OWNER/NAME] [--runs N]
        [--branch BRANCH] [--json OUT.json] [--markdown OUT.md]
"""

import argparse
import collections
import json
import os
import re
import subprocess
import sys

CACHE = ".elephant_cache"

TIMESTAMP = re.compile(r"^\d{4}-\d\d-\d\dT[\d:.]+Z ?")
GROUP = re.compile(r"^##\[group\](?P<group>.+)")
FAILURE = re.compile(r"^\t?FAILURE #\d+: (?P<headline>.+)")
RUNTIME = re.compile(r"Runtime in (?P<where>[^:]+?,\d+): (?P<message>.+)")
HARDDEL = re.compile(r"(?:hard delete|hard deleted|failed to (?:qdel|gc)).*?(?P<type>/[a-z_/0-9]+)", re.I)
TOTAL_RUNTIMES = re.compile(r"^Total runtimes: (?P<count>\d+)")
PROBE = re.compile(r"ELEPHANT (?P<probe>\w+) (?P<type>\S+) at [^:]*: (?P<stack>.*)")


def gh(*args, raw=False):
    result = subprocess.run(["gh", "api", *args], capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip())
    return result.stdout if raw else json.loads(result.stdout)


def normalize(text):
    """Strip the parts of a message that change from run to run."""
    text = re.sub(r"\[0x[0-9a-f]+\]", "[ref]", text)
    text = re.sub(r"\(\d+,\s*\d+,\s*\d+\)", "(x,y,z)", text)
    text = re.sub(r"\b\d+(\.\d+)?\b", "N", text)
    text = re.sub(r"\s+", " ", text)
    return text.strip()[:200]


def parse_log(log):
    """Return a list of (kind, test, signature, sample) for one job log."""
    found = []
    group = "root"
    pending = None
    lines = [TIMESTAMP.sub("", line) for line in log.splitlines()]

    for index, line in enumerate(lines):
        group_match = GROUP.match(line)
        if group_match:
            group = group_match["group"].strip().replace("/datum/unit_test/", "")
            continue

        probe_match = PROBE.search(line)
        if probe_match:
            first_frame = probe_match["stack"].split(" <- ")[0]
            first_frame = re.sub(r" src=\S+", "", first_frame)
            signature = f"{probe_match['type']} from {first_frame}"
            found.append(("probe:" + probe_match["probe"], group, signature, probe_match["stack"][:400]))
            continue

        failure_match = FAILURE.match(line)
        if failure_match:
            headline = failure_match["headline"]
            kind = "harddel" if HARDDEL.search(headline) else "failure"
            found.append((kind, group, normalize(headline), headline))
            continue

        runtime_match = RUNTIME.search(line)
        if runtime_match:
            where = runtime_match["where"].strip()
            message = runtime_match["message"].strip()
            # The proc name is two lines down in the runtime block.
            proc = ""
            for follow in lines[index + 1:index + 3]:
                if "proc name:" in follow:
                    proc = follow.split("proc name:", 1)[1].strip()
                    break
            signature = f"{where}: {normalize(message)}"
            sample = f"{where}: {message} ({proc})" if proc else f"{where}: {message}"
            found.append(("runtime", group, signature, sample))

    if not found and any("Test run failed!" in line for line in lines):
        found.append(("unknown", "root", "Test run failed with no FAILURE or runtime line", ""))
    if not found and any("exit code 139" in line or "Segmentation fault" in line for line in lines):
        found.append(("crash", "root", "DreamDaemon segfault (exit 139)", ""))
    return found


def job_log(repo, job_id):
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, f"{job_id}.log")
    if os.path.exists(path):
        with open(path, encoding="utf-8", errors="replace") as handle:
            return handle.read()
    try:
        log = gh(f"repos/{repo}/actions/jobs/{job_id}/logs", raw=True)
    except RuntimeError:
        log = ""
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(log)
    return log


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", default="NanoCats/MaverickStation")
    parser.add_argument("--runs", type=int, default=100)
    parser.add_argument("--branch", default=None)
    parser.add_argument("--json", default=None)
    parser.add_argument("--markdown", default=None)
    options = parser.parse_args()

    query = f"repos/{options.repo}/actions/runs?per_page={min(options.runs, 100)}"
    if options.branch:
        query += f"&branch={options.branch}"
    runs = [run for run in gh(query)["workflow_runs"] if run["name"] == "CI Suite"][:options.runs]

    jobs_total = 0
    jobs_failed = 0
    per_map = collections.Counter()
    per_map_total = collections.Counter()
    causes = {}

    for run in runs:
        for attempt in range(1, run["run_attempt"] + 1):
            jobs = gh(f"repos/{options.repo}/actions/runs/{run['id']}/attempts/{attempt}/jobs?per_page=100")["jobs"]
            for job in jobs:
                if "Run Tests" not in job["name"] or job["conclusion"] not in ("success", "failure"):
                    continue
                map_name = re.search(r"Run Tests \((?P<map>[^;)]+)", job["name"])
                map_name = map_name["map"] if map_name else job["name"]
                jobs_total += 1
                per_map_total[map_name] += 1
                if job["conclusion"] != "failure":
                    continue
                jobs_failed += 1
                per_map[map_name] += 1
                seen = set()
                for kind, test, signature, sample in parse_log(job_log(options.repo, job["id"])):
                    key = (kind, test, signature)
                    if key in seen:
                        continue
                    seen.add(key)
                    entry = causes.setdefault(key, {"jobs": 0, "maps": collections.Counter(), "sample": sample, "example": job["html_url"]})
                    entry["jobs"] += 1
                    entry["maps"][map_name] += 1

    ranked = sorted(causes.items(), key=lambda item: -item[1]["jobs"])

    out = [f"Runs: {len(runs)}  Test jobs: {jobs_total}  Failed jobs: {jobs_failed}", ""]
    out.append("| Jobs | Kind | Test | Cause | Maps |")
    out.append("|---:|---|---|---|---|")
    for (kind, test, signature), entry in ranked:
        maps = ", ".join(f"{name} {count}" for name, count in entry["maps"].most_common(4))
        cause = signature.replace("|", "/")
        out.append(f"| {entry['jobs']} | {kind} | {test} | {cause} | {maps} |")
    out.append("")
    out.append("| Map | Failed | Total |")
    out.append("|---|---:|---:|")
    for map_name, total in per_map_total.most_common():
        out.append(f"| {map_name} | {per_map[map_name]} | {total} |")
    report = "\n".join(out)
    print(report)

    if options.markdown:
        with open(options.markdown, "w", encoding="utf-8") as handle:
            handle.write(report + "\n")
    if options.json:
        with open(options.json, "w", encoding="utf-8") as handle:
            json.dump([
                {"kind": kind, "test": test, "cause": signature, "jobs": entry["jobs"],
                 "maps": dict(entry["maps"]), "sample": entry["sample"], "example": entry["example"]}
                for (kind, test, signature), entry in ranked
            ], handle, indent=2)
    return 0


if __name__ == "__main__":
    sys.exit(main())
