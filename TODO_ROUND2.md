# Round 2 Cleanup TODO

## Context

Pure mod-driven core has been switched on:

- Core gameplay content now lives in `mods-unpacked/planewar-core_mod`.
- Upgrade apply path is unified through `ModExtensionBridge`.
- Transition adapter services were removed.

This round focuses on structural cleanup and finalization.

## Tasks

### 1) Merge upgrade flow shells

- Evaluate and simplify responsibilities between:
  - `scripts/systems/upgrade_catalog.gd`
  - `scripts/systems/upgrade_manager.gd`
- Goal: reduce unnecessary shell layers while keeping behavior unchanged.

Acceptance:

- No duplicate routing logic between catalog/manager.
- Upgrade apply call chain is clear and minimal.

---

### 2) Bridge API surface cleanup

- Review `scripts/systems/mod_extension_bridge.gd` public API.
- Keep core APIs, mark or remove redundant transitional APIs.
- Ensure registry/event/upgrade apply APIs stay consistent.

Acceptance:

- API set is coherent and documented.
- No dead/duplicate interfaces left.

---

### 3) Docs synchronization

- Update and align:
  - `docs/gdd/sections/12_technical_notes.md`
  - `docs/MOD_RUNTIME_OVERVIEW.md`
  - `docs/MOD_API_QUICK_REFERENCE.md`
- Remove historical transition wording where no longer needed.
- Add final architecture notes if needed.

Acceptance:

- Docs match current runtime behavior and API names.
- New contributor can follow docs without ambiguity.

---

### 4) Regression pass

Run and verify at least:

- Builtin core mod only
- Builtin core mod + external demo mod
- Conflict case (duplicate IDs) with expected warnings

Acceptance:

- No startup/runtime errors.
- Conflict behavior is deterministic and logged.

## Handoff Notes

- Follow project rule: if gameplay/content contract changes, update GDD first.
- Keep commits scoped and readable.
- If committing implementation changes, use project git convention and push after commit.
