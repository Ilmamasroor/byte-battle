# Visualization platform (`frontend/lib/features/learning/viz3d/`)

One platform powers "See it happen" for every concept.

| Layer | Where | Role |
|---|---|---|
| Contract | `contract/viz_contract.dart` | `VizLesson` (id, version, concept/topic, category, variants, inputs, prediction, fallback), `VizTimeline` (`length`, `frameAt(p)`, outcome, markers), `ReducerTimeline<S,E>` (typed domain state + pure reducer) |
| State engine | `engine/` | `VizPlaybackController` (the only playback state), `VizSession` (lesson/variant/input/selection/3D choice) |
| Renderer | `render/` | `SceneSpec` (plain data), `ScenePainter` (pure-Dart software 3D: perspective, depth sort, lighting, glow), `OrbitCamera`, `SceneTween`, `VizViewport`. Knows nothing about any topic |
| Topic modules | `modules/` | Turn domain state into a `SceneSpec`: thread chamber, binary search, insertion sort, Round Robin, and `scene_doc/` (all 58 authored scenes) |
| Explanation / UI | `ui/` | `VizShell`, `VizControls`, `ExplanationPanel`, inspector, outcome card, fallbacks |
| Registry | `registry/` | `VizRegistry` maps a concept to lessons; `curriculum_catalog.dart` lists the shipped concepts |

Rendering is pure Dart on `Canvas`, so it runs on every platform the app targets with no plugin or asset. AI never produces state: every position comes from a deterministic reducer.

## Add a lesson
1. Model the domain state `S` and events `E`; write `reduce`, `explain` and `scene` in a `ReducerTimeline`.
2. Wrap it in a `VizLesson` (variants, `VizParam`s, `declared outcome`).
3. Register it: `VizRegistry.instance.register('my-topic', (source) => source.conceptId == id ? [myLesson()] : const []);` (or add it to `VizRegistry.standard()`).
4. Add tests: initial state, final state vs expectation, seeking, `scene.validate()` on every frame.
Concepts with no adapter fall back to an explicit "no 3D yet" message; a thrown error in a lesson degrades to the flat view.

## Known limits
Software renderer: tens of solids, not detailed meshes. Bit's voice narrates in the thread simulator and the 3D lab, but the lab has no per-step voice-paced autoplay like the original 2D walkthrough (which is kept).

## Thread lessons: events, honesty and audio
- **Events.** The simulator (`ai-service/.../simulator.py`) returns READ, COMPUTE, WRITE, LOCK, UNLOCK steps with `before`, `stale` (a write built on an out-of-date read) and `synthetic` (lines the synchronized fix adds). Schedules: `RACE` (both read, both calculate, A writes, B overwrites; the default), `RACE_ALT`, `SYNC` (same threads under one lock; B is blocked), `SAFE`, `DEADLOCK`.
- **Provenance.** Every response carries `provenance: teaching-simulation` and a `support` verdict (`supported` / `partial` / `unsupported`). A calculation the extractor cannot evaluate makes the program `unsupported`: nothing is drawn rather than guessed. The offline example in `builtin_lost_update.dart` is labelled "Authored example" and is tested against a real simulator trace (`test/fixtures/lost_update_trace.json`).
- **One selected event.** `VizPlaybackController.position` drives the lanes (`thread_lanes.dart`), timeline strip, inspector, source highlight, values and captions. 3D is optional.
- **Audio.** `NarrationController` speaks the selected event only while playing (see its class comment for the full seek/pause/speed policy); an epoch counter discards stale completions. Auto-advance waits for narration via `VizPlaybackController.advanceGate`. Captions always show the same text. Preferences (narration, volume, sound cues) live in `BitVoice`'s existing `shared_preferences` keys. Sound cues use the system click/alert only on Android, iOS and macOS; richer cues would need an audio package (not added).

## Speech ownership (`core/voice/bit_voice.dart`)
`BitVoice` is the only component that talks to the speech engine. Every sentence is an utterance with an id, an optional owner and an event tag; at most one is active; a new one supersedes the old one only after the engine confirms the stop (browsers drop a `speak` made right after `cancel`). Engine events are applied only to the utterance they belong to, and a completion that arrives before the sentence started is ignored as stale. `stop(owner: x)` only cancels x's own speech. Waits (no start, no completion, no stop confirmation) are bounded, logged and never advance playback on their own. Speed is Slower 0.85, Normal 1.0 or Faster 1.2, mapped per platform by `platformSpeechRate` (web uses the value as is; Android and iOS use half of it). The voice sheet has a temporary "Speech log" (ids, timings, settings; no spoken text) with a Copy button.
