# Curriculum content pipeline

Every concept in the curriculum ships with three kinds of learning content. All of it is checked by machines
before it reaches a learner.

| What | Where | How it is checked |
|---|---|---|
| Battles, coding challenges, debugging exercises | `content/<conceptId>.json` -> `verified/` -> `src/main/resources/db/migration/V31__seed_curriculum_content.sql` | `verify_content.py` runs every program on the local Judge0: PREDICT_OUTPUT answers must equal real output, expected outputs of coding/debug tests come from the reference solutions, every starter/buggy version must fail at least one test |
| "See it happen" scenes (animations) | `frontend/assets/scenes/<conceptId>.json` | `validate_scene.py` (structure) and `frontend/test/scenes_render_test.dart` (every scene plays end to end at phone width with no overflow) |

Schemas and rules: `CONTENT_SCHEMA.md`, `SCENE_SCHEMA.md`. Reference examples: `content/...1001.json`, `examples/`.

## Regenerate the migration
```
python3 content-authoring/verify_content.py content-authoring/content/<conceptId>.json   # needs Judge0 running
python3 content-authoring/build_migration.py src/main/resources/db/migration/V31__seed_curriculum_content.sql
```
`build_migration.py` caps each test input at 30 KB (keeps the database small and submissions quick).
A migration that has already been applied must not be edited: put changes in a new `V32__...` file instead.
