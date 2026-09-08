#!/usr/bin/env bash
# Regenerate Nonarkara GitHub estate inventories (importable JSON).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
FULL=0
[[ "${1:-}" == "--full" ]] && FULL=1

python3 - "$ROOT" "$FULL" <<'PY'
import json, subprocess, sys
from datetime import datetime, timezone
from pathlib import Path

root = Path(sys.argv[1])
want_full = sys.argv[2] == "1"

def gh_json(args):
    return json.loads(subprocess.check_output(["gh", *args], text=True))

repos = []
page = 1
while True:
    batch = gh_json([
        "api",
        f"user/repos?per_page=100&page={page}&affiliation=owner&sort=full_name",
    ])
    if not batch:
        break
    repos.extend(batch)
    if len(batch) < 100:
        break
    page += 1

def row(r):
    lic = (r.get("license") or {}).get("spdx_id")
    return {
        "full_name": r["full_name"],
        "name": r["name"],
        "private": r["private"],
        "archived": r["archived"],
        "fork": r["fork"],
        "description": r.get("description") or "",
        "homepage": r.get("homepage") or "",
        "html_url": r["html_url"],
        "clone_url": r["clone_url"],
        "default_branch": r.get("default_branch") or "main",
        "language": r.get("language"),
        "topics": r.get("topics") or [],
        "license_spdx": lic,
        "has_issues": r.get("has_issues"),
        "has_wiki": r.get("has_wiki"),
        "has_pages": r.get("has_pages"),
        "size_kb": r.get("size"),
        "stargazers": r.get("stargazers_count"),
        "open_issues": r.get("open_issues_count"),
        "pushed_at": r.get("pushed_at"),
        "created_at": r.get("created_at"),
        "updated_at": r.get("updated_at"),
        "visibility": r.get("visibility"),
    }

rows = [row(r) for r in repos]
public = [r for r in rows if not r["private"] and not r["archived"]]
missing_lic = [
    r["full_name"]
    for r in public
    if not r["license_spdx"] or r["license_spdx"] in ("NOASSERTION", "NONE")
]

serving_public = [
    "nonarkara.org",
    "globalmonitor",
    "SLIC-Index",
    "BKKx",
    "bkk-3d-atlas",
    "FloodDash-Blueprint",
    "dr-non-vibecoding-skills",
    "dr-non-luggage-tag-aesthetic",
    "Nonarkara",
    "city-hub",
    "globalmonitor-v3",
]
ci = {}
for name in serving_public:
    full = f"Nonarkara/{name}"
    try:
        runs = gh_json(["api", f"repos/{full}/actions/runs?per_page=1&branch=main"])
        items = runs.get("workflow_runs") or []
        if not items:
            runs = gh_json(["api", f"repos/{full}/actions/runs?per_page=1"])
            items = runs.get("workflow_runs") or []
        if items:
            w = items[0]
            ci[full] = {
                "conclusion": w.get("conclusion"),
                "status": w.get("status"),
                "name": w.get("name"),
                "html_url": w.get("html_url"),
                "updated_at": w.get("updated_at"),
                "head_branch": w.get("head_branch"),
            }
        else:
            ci[full] = {"conclusion": None, "status": "no_runs"}
    except Exception as e:
        ci[full] = {"error": str(e)[:160]}

now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
pub = {
    "schema": "nonarkara.github.estate.public.v1",
    "generated_at": now,
    "owner": "Nonarkara",
    "import": {
        "how": "Fetch this JSON; each repos[] row is one public GitHub repository. Prefer full_name as stable id. Use clone_url or html_url to import.",
        "fields": [
            "full_name",
            "name",
            "description",
            "homepage",
            "html_url",
            "clone_url",
            "default_branch",
            "language",
            "topics",
            "license_spdx",
            "pushed_at",
            "stargazers",
        ],
    },
    "counts": {
        "public_active": len(public),
        "public_missing_or_unknown_license": len(missing_lic),
    },
    "health_summary": {
        "public_missing_or_unknown_license": missing_lic,
        "serving_ci": ci,
    },
    "repos": [
        {
            "full_name": r["full_name"],
            "name": r["name"],
            "description": r["description"],
            "homepage": r["homepage"],
            "html_url": r["html_url"],
            "clone_url": r["clone_url"],
            "default_branch": r["default_branch"],
            "language": r["language"],
            "topics": r["topics"],
            "license_spdx": r["license_spdx"],
            "stargazers": r["stargazers"],
            "open_issues": r["open_issues"],
            "pushed_at": r["pushed_at"],
            "created_at": r["created_at"],
            "has_pages": r["has_pages"],
        }
        for r in sorted(public, key=lambda x: x["full_name"].lower())
    ],
}
(root / "public-inventory.v1.json").write_text(
    json.dumps(pub, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
)
print(f"wrote {root / 'public-inventory.v1.json'} ({len(public)} public repos)")

if want_full:
    private = [r for r in rows if r["private"] and not r["archived"]]
    archived = [r for r in rows if r["archived"]]
    full = {
        "schema": "nonarkara.github.estate.v1",
        "generated_at": now,
        "owner": "Nonarkara",
        "counts": {
            "total": len(rows),
            "public_active": len(public),
            "private_active": len(private),
            "archived": len(archived),
            "public_missing_or_unknown_license": len(missing_lic),
        },
        "health_summary": pub["health_summary"],
        "repos": sorted(rows, key=lambda x: x["full_name"].lower()),
    }
    (root / "estate-inventory.v1.json").write_text(
        json.dumps(full, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print(f"wrote {root / 'estate-inventory.v1.json'} (FULL — keep private)")
PY
