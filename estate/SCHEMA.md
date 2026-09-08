<!-- SPDX-License-Identifier: MIT -->
# Nonarkara GitHub estate — import schemas

Machine-readable inventory so agents and tools can **import** repo health and metadata without scraping HTML.

## Public schema: `nonarkara.github.estate.public.v1`

**File:** [`public-inventory.v1.json`](./public-inventory.v1.json)  
**Safe to publish.** Public, non-archived repositories only. No private names, tokens, or secrets.

### Top-level fields

| Field | Meaning |
|---|---|
| `schema` | Always `nonarkara.github.estate.public.v1` |
| `generated_at` | ISO-8601 UTC timestamp when this file was built |
| `owner` | GitHub login (`Nonarkara`) |
| `import.how` | One-line human instruction |
| `import.fields` | Canonical field list for importers |
| `counts` | Tallies (public_active, license gaps, …) |
| `health_summary` | License gaps + last known Actions status for serving/flagship public repos |
| `repos[]` | One object per public active repository |

### Repo row (stable id = `full_name`)

| Field | Use when importing |
|---|---|
| `full_name` | Primary key (`Nonarkara/FloodDash-Blueprint`) |
| `html_url` / `clone_url` | Open or `git clone` |
| `description` | Listing blurb |
| `homepage` | Live URL if set |
| `license_spdx` | SPDX id or null / unknown |
| `topics` | GitHub topics array |
| `language` | GitHub primary language |
| `default_branch` | Usually `main` |
| `pushed_at` / `created_at` | Freshness |
| `stargazers` / `open_issues` / `has_pages` | Lightweight signals |

### Import examples

```bash
curl -fsSL https://raw.githubusercontent.com/Nonarkara/Nonarkara/main/estate/public-inventory.v1.json \
  -o estate.json
jq -r '.repos[].clone_url' estate.json | head
jq '.health_summary' estate.json
```

```js
const inv = await fetch(
  'https://raw.githubusercontent.com/Nonarkara/Nonarkara/main/estate/public-inventory.v1.json'
).then((r) => r.json());
// inv.schema === 'nonarkara.github.estate.public.v1'
for (const repo of inv.repos) {
  // import repo.full_name, repo.description, repo.clone_url, …
}
```

## Full owner schema: `nonarkara.github.estate.v1`

Includes private repos and denser health. **Do not commit** that file to a public repository. Regenerate locally with `./refresh.sh --full` (writes next to the script, gitignored if you keep it private).

## Refresh

```bash
./refresh.sh          # public inventory only → public-inventory.v1.json
./refresh.sh --full   # also writes estate-inventory.v1.json (owner machine only)
```

Requires authenticated `gh` as `Nonarkara`.
