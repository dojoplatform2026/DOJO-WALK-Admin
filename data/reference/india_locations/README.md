# India Location Reference Data

This directory is reserved for **source provenance and reproducibility documentation**. It is separate from the generated Dart reference data under `lib/data/reference/india_locations/` and from live customer addresses or service Zones.

## Current state

- The current Dart files describe their origin as a user-supplied Local Government Directory (LGD) CSV.
- The raw CSV/source artifact is not currently tracked in this directory.
- The original source URL, retrieval date, publication/update date, licence/terms, checksum and exact generation command have not yet been independently recorded.
- Therefore, the dataset's provenance is **not yet verified**. Do not label it as independently verified official current data, and do not import it into production Firebase.

## Required layout when source artifacts are available

Keep the following concerns separate:

- `source/`: unmodified source files as received/downloaded, with permitted redistribution checked first.
- `staging/`: normalized intermediate files and reconciliation output.
- `audit/`: validation summaries, source-difference reports and checksums.
- `source_manifest.md`: source identity, official URL or supplied-artifact origin, retrieval/publication dates, licence/terms, checksum, transformation command/tool version and output counts.
- Generated Dart remains under `lib/data/reference/india_locations/`; do not copy generated files into this directory.

Create only the subfolders that contain actual tracked artifacts. Do not add placeholder datasets or invent missing provenance.

## Required validation before integration

1. Confirm the original source artifact and its permitted use.
2. Preserve official identifiers as strings where leading zeros or non-numeric values matter; document placeholder values without silently rewriting them.
3. Re-run deterministic generation from the recorded source and compare output.
4. Validate State/UT, district and sub-district unique IDs, parent-child relationships, record counts and source differences.
5. Run the reference-data integrity tests and full Admin validation.
6. Keep production Firebase import separate; require a reviewed schema and a successful import dry run before any production import.

## UI hierarchy note

The current Admin Create Zone form uses exactly four dependent selectors: **State/UT → District → City → Zone**. Reference data may contain other government geography levels, but those levels must not be added as extra Create Zone selectors. Only a verified Zone polygon can be considered for service activation under the approved workflow.
