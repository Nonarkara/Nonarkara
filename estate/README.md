<!-- SPDX-License-Identifier: MIT -->
# Estate inventory (importable)

Portable GitHub health + repo metadata for **Nonarkara**.

| File | What |
|---|---|
| [`public-inventory.v1.json`](./public-inventory.v1.json) | Public repos only — safe to fetch and import |
| [`SCHEMA.md`](./SCHEMA.md) | Field dictionary + import examples |
| [`refresh.sh`](./refresh.sh) | Regenerate the JSON (`gh` as Nonarkara) |

```bash
curl -fsSL https://raw.githubusercontent.com/Nonarkara/Nonarkara/main/estate/public-inventory.v1.json | jq '.counts'
```

Full owner inventory (includes private) is **not** published here — run `./refresh.sh --full` on a trusted machine.
