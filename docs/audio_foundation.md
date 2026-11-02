# SHATTERGRID 0.8 — audio foundation and real-asset manifest

## Audit and present limitations

Starting revision: `ec3096c` (0.7). The seven existing Godot suites completed
**3,393 checks with zero failures** before changes. Actions, 8×8 board, six
characters, reflected army setup, movement, turns, statuses, captures, camera,
Core victory, rematch and return-to-setup were working. The world already had
two animated braziers, native height/distance fog, and bounded capture dust and
stone fragments. UI/F3 diagnostics were working.

There were **no real audio assets, AudioStreamPlayer nodes, sound manager or
custom bus layout**. Only Godot's default Master bus existed. The capture
timeline already exposed useful events; no temporary sound code needed removal.
Hex remains absent; Witch's Wither is capture presentation. No audio dependency
required changing rules, characters, lore, loadouts, balance or environment art.

**This checkout is intentionally silent.** All 57 optional cue entries have
empty `variations` arrays. No sound was downloaded, synthesized into an asset,
encoded or represented by a fake WAV/OGG/MP3. No empty media directories or
pretend file paths were added. The entries are routing/timing/configuration data,
not audio files. Listening, mix judgment and device behavior need real recordings.

## Buses and settings

`default_bus_layout.tres` is the native project bus layout:

```text
Master
  Music
  Ambience
  SFX
    Cinematic
    UI
```

Default bus gains: Master 0 dB, Music −8, Ambience −4, SFX −2, Cinematic 0 and
UI −6. Cinematic alone has a restrained native Reverb: wet 0.06, dry 1, 65 ms
predelay, damped long outdoor-stone tail. Wind, fire and UI do not inherit it.
This is a prototype effect to evaluate with real recordings, not a final mix.

The SoundManager autoload owns linear volume settings and explicit mute flags:

```gdscript
SoundManager.set_volume(&"Master", 0.8)   # linear 0..1, not decibels
SoundManager.set_volume(&"Music", 0.35)
SoundManager.set_volume(&"SFX", 0.7)      # includes Cinematic and UI child buses
SoundManager.set_volume(&"Ambience", 0.5)
SoundManager.set_muted(&"Music", true)
```

All six buses are individually supported. Unknown names/non-finite values are
rejected; finite values clamp to 0..1. Conversion uses `linear_to_db`; zero mutes
cleanly without negative infinity. Settings survive scene changes, not app exit.
There is no new settings menu or save system.

## Playback, profiles and scene ownership

`AudioCue` describes real stream variations, bus, positional/looping flags,
gain/pitch range, cooldown, per-cue voice cap, priority, deadline and attenuation.
Null/empty references are skipped without errors or player allocation. Variation
selection excludes the immediately previous stream when there is a choice;
duplicate/null references are filtered. Audio RNGs are separate from gameplay.

`resources/audio/library.tres` contains the shared named cue entries. Use
`SoundManager.play_ui(id)`, `play_id(id, position, scope, channel)` or
`play_profile(profile, event, position, scope, channel)`. Callers do not create
players. Eight non-positional one-shot slots, ten positional slots, six loop slots
and two music channels are the hard limits; pools allocate lazily. Cooldowns,
per-cue limits and lower-priority replacement contain rapid UI/impact requests.
Idle players retain no stream. Natural completion or a bounded deadline releases
one-shots, including an accidentally looping imported source.

World movement, real chunk contacts, distant events and fire use 3D players.
Essential cinematic layers and UI use non-positional players even if an entry
was mistakenly marked positional: the close camera cannot make an impact vanish.
The current Camera3D remains the normal 3D listener; no camera behavior changed.
Movement uses 12-unit attenuation / 90-unit maximum distance. Fire uses 4 / 18,
so it is quiet at altitude and perceptible when a cinematic comes near it.

Each main scene has a MatchAudio bridge and an instance-ID scope. It owns wind,
world, at most two grouped fire sources, rare-event scheduling and cinematic mix
ownership. SetupAudio owns the army-setup music context. Leaving a scope stops
its voices/loops, disconnects emitter ownership, cancels ducking and releases its
music request. Late requests from a departed scope are ignored. Explicit loop
keys are idempotent; emitter destruction stops its loop. UI one-shots use the
global scope and remain short/bounded across a transition.

Every existing CharacterDefinition now optionally references AudioProfile.
Profiles map event names to **arrays of cue IDs**, allowing restrained layering.
The movement fallback supplies `move_start` / `move_end`. Temporary mappings are:
Hunter light, Wyrm medium, Warden/Executioner heavy, Witch/Core supernatural.
Each of the six profiles has separate anticipation, motion and impact entries.
These are editable data choices, not future roster restrictions or hard-coded
archetype branches in the audio manager.

## Ambient layers and music

- Wind: non-positional, low-level loop. If assigned, gain varies only ±0.6 dB
  over 75 seconds, sampled every 1.5 seconds. No dramatic pumping/filter effect.
- Lower world: a quieter independent loop, leaving room for silence.
- Local fire: two owned 3D loops at the existing braziers, shared cue/config.
- Rare world events: weighted choices every 90–240 seconds, avoiding immediate
  repeat when alternatives exist. Bell is independent at **240–720 seconds**.
  Each entry can specify an origin. Categories can be disabled with
  `scheduler.set_category_enabled(category, false)`. Groups with no assigned
  streams allocate no timers and do not repeatedly request missing assets.

Music supports `menu`, `army_setup`, `match`, `victory` and intentional silence.
Two channels crossfade; repeated requests do not restart/stack a track. Rapid
changes retire the quieter old channel before reuse. Missing tracks fade out.
No music is required for normal tactics. Native imported loop flags should be
enabled for seamless music/wind/fire; restarting on `finished` is only a fallback.

During a capture, Ambience ducks 3 dB and Music 4 dB; Core release adds 2 / 1 dB.
These are mix offsets, separate from user settings. Attack fades take 0.18 s;
normal restoration takes 0.75 s. Changing/muting a bus while ducked is preserved.
Core mix ownership holds through the existing 0.30-second victory pause, then
restores. Restart/scene exit immediately removes departed mix ownership.
Audio zones/acoustic simulation were not useful for this fixed small arena and
were not added; rare-event origins provide the lightweight positional foundation.

## Exact capture/destruction hooks

All requests follow the existing procedural timeline, never guessed timers:

| Visual/game event | Audio request |
| --- | --- |
| Confirmed normal movement | Profile `move_start` at actual origin |
| Tween reaches destination | Profile `move_end` at actual destination |
| `capture_started` | Capture start and cinematic ducking |
| `anticipation` | Attacker's anticipation layer |
| `weapon_swing` / `wither` / `predatory_lunge` / `core_force` | Profile motion/signature |
| `impact` | Character-specific impact in that exact callback |
| `stone_impact` | Low stone layer |
| `stone_crack` | Initial fracture |
| `debris` | Major break + one debris cluster + optional grit |
| `core_destruction` | Victim Core profile: fracture/resonance/release and reduced world mix |
| `attacker_settled` | Quiet movement settle profile, using the cinematic channel |
| Director completion after camera return | Release cinematic voices; optional end cue capped at 0.75 s |
| Director cancellation | Stop cinematic voices and release ducking |

The Cinematic bus supplies the environmental tail instead of stacking another
large boom. Core destruction uses the **victim's** profile, so future Core choices
need no new manager switch. Audio observers cannot resolve an action or a turn.

Only two selected physics chunks monitor contacts. Each can report once, only
on an actual collision with the tile/slab layer; the shared contact cue also has
a cooldown and voice limit. There is no timer-generated landing sound and no
ground/catch floor beneath the void. Destruction still cleans up after 2.4 seconds.

## One real-asset manifest

Use your own recordings or assets you can legally use. Variations are alternatives,
not mandatory simultaneous layers. Reuse compatible recordings across cue IDs.
Prioritize wind/fire, quiet UI, stone start/settle and capture fracture/debris;
music and rare events can remain unassigned indefinitely.

| Cue ID / category | Purpose / type | Loop? | Space | Variations | Notes |
| --- | --- | --- | --- | --- | --- |
| `ambience.wind` | High exposed cold wind, OGG | Loop | Non-positional | 1–2 | Soft continuous altitude; no musical drone or loud gust pumping |
| `ambience.world` | Far ruined-world texture, OGG | Loop | Non-positional | 1–2 | Extremely quiet wood/structure/air texture; room for silence |
| `environment.fire` | Brazier crackle, OGG | Loop | 3D | 2–3 | Mono recommended; two sources only, no large roaring wall of fire |
| `distant.bell` | Old lonely bell, WAV/OGG | One-shot | 3D, church origin | 2–3 | Long natural decay; 4–12 minute scheduling, not a minute timer |
| `distant.crow/chain/wood/thunder` | Rare distant environment events, WAV/OGG | One-shot | Optional 3D origin | 2–4 each | Low levels; no constant calls or aggressive thunder booms |
| `move.light.start/settle` | Light scrape / small stone rest, WAV | One-shot | 3D | 3–5 each | Short and much quieter than capture |
| `move.medium.start/settle` | Medium stone weight / rest, WAV | One-shot | 3D | 3–5 each | Temporary Wyrm mapping; no final identity restriction |
| `move.heavy.start/settle` | Heavy grind / weight settling, WAV | One-shot | 3D | 3–5 each | Warden/Executioner prototype; restrained low end |
| `move.supernatural.start/settle` | Minimal unnerving stone texture, WAV | One-shot | 3D | 2–4 each | Subtle; no bright fantasy magic |
| `capture.start/end` | Restrained transition/closure, WAV | One-shot | Non-positional | 1–3 | Optional; end is short, not a victory fanfare |
| `capture.<character>.anticipation/motion/impact` | Six replaceable prototype signatures, WAV | One-shot | Non-positional cinematic | 2–4 each | Shield/armor, sharp strike, axe weight, Wither texture, animal stone, deep Core resonance |
| `capture.stone_impact` | Low stone collision, WAV | One-shot | Non-positional cinematic | 3–6 | Weight rather than an explosion |
| `capture.fracture/break` | Initial crack and major stone failure, WAV | One-shot | Non-positional cinematic | 3–6 each | Separate timing/layers, not one huge generic crash |
| `capture.debris/dust` | Debris cluster / grit, WAV | One-shot | Non-positional cinematic | 3–5 each | One cluster, not one sound per fragment |
| `destruction.contact` | Limited heavy chunk contact, WAV | One-shot | 3D | 3–5 | Only actual platform collisions; no void landing |
| `core.fracture/resonance/release` | Dedicated ancient architectural failure, WAV | One-shot | Non-positional cinematic | 2–3 each | Deep stone and restrained uncanny release; no Hollywood explosion |
| `ui.hover/select/confirm/cancel/invalid/army_select/match_start/victory` | Quiet physical UI language, WAV | One-shot | Non-positional | 2–3 each | Stone/wood/metal, no beeps or reward jingles; hover/invalid very quiet |
| `music.menu/army_setup/match/victory` | Future sparse music, OGG | Loop | Non-positional | 0–1 each | Entirely optional. No music composed or downloaded |

## Assign real assets in Godot

1. Add actual recordings to sensible folders such as `audio/ambience/`,
   `audio/impacts/`, `audio/ui/` **when you have files**, then allow Godot to import.
2. Open `resources/audio/library.tres`. Expand `cues`; entries are named by cue ID.
   Expand the desired entry, increase `variations` and drag imported AudioStreams
   into it. Empty entries remain supported; do not insert dummy files.
3. Enable the real stream's native loop setting for wind/world/fire/music. Use
   mono sources for positional effects where possible. Check seams and gain.
4. Edit cue gain/attenuation or profile event mappings as needed. A character can
   reference another AudioProfile without editing the manager or game rules.
5. Restart F5 after assigning assets. The ambient scheduler only schedules groups
   with usable streams when started; it does not poll for editor changes.

## Debugging, files and runtime validation

F3 now includes active/pooled players, ambience loops, ready/missing references,
music/context state, cinematic offsets, user volumes, actual bus dB and the last
request outcome. **F4** requests `ui.confirm` in a debug build. With no stream it
reports `missing`, not an error. These controls are absent from production UI.
`SoundManager.metrics()` returns a read-only snapshot; the performance probe
includes it. The last-request trace is bounded to 64 entries.

Created: native `default_bus_layout.tres`; `scripts/audio/` (cue/library/profile,
manager, music, ambient event/group/scheduler and setup/match bridges);
`resources/audio/` (library, two rare-event categories and ten shared/character
profiles); `tests/audio_smoke.gd`; generated script UIDs; this single manifest.

Modified: optional audio-profile field and six character Resource references;
main scene/autoload/version; movement/cancel signals; capture settle/cancel/effect
hooks; two-fragment contact reporting; brazier emitter group; setup UI hooks;
F3/F4 diagnostics, performance probe and README. No movement/ability/turn rules,
formation data, camera behavior, model geometry or environment art were changed.

The audio suite uses empty catalog copies and native AudioStreamGenerator objects
**only in test memory**, with no generated sample frames. No file is written or
production cue populated. These fixtures exercise playback lifecycle, finite
deadlines, priority limits, loop ownership, music fades and settings/mix restoration.
Native physics tests also compare real platform contacts against fragments in the
void. Every capture style verifies that the request occurs inside the impact
callback. Technical execution does not demonstrate an audible soundscape.

Executed with Godot **4.6.3**:

- Eight headless suites: battlefield 328, interaction 116, characters 1,302,
  captures 473, world 248, army 451, feel 487, audio 231:
  **3,636 checks, zero failures**.
- OpenGL Compatibility / Dummy audio: audio 231, captures 473, army 451,
  interaction 116, feel 487, world 416: **2,174 checks, zero failures**.
- No script/resource errors or ObjectDB leak warnings in final runs. Audio mix
  thread stop commands were allowed to drain before terminating RAM-fixture tests.
- Editor import passed. Static validation found 284 resource references, no
  missing files, and **zero encoded audio files**. Whitespace checks passed.
- The F3/F4 overlay was rendered/inspected with 0/57 ready and safe missing-cue
  feedback. Headless idle probe: zero active/pooled audio players, 57 missing
  references, 1,085 match descendants, two existing flame process scripts and one
  interaction physics script; no repeated idle rays or legal calculations.

Run the seven existing suites plus
`godot --headless --path . --script res://tests/audio_smoke.gd`. The optional
`scripts/debug/performance_probe.gd` reports audio allocation/state as well.
The cloud X11 software driver reports unsupported VSync. These are technical
runtime tests, not listening validation or a Windows/Godot 4.7 hardware claim.

## Exact manual checks

1. Pull main with Godot closed. Reopen and F5 → START MATCH. With this checkout
   expect silence and otherwise identical gameplay, without missing-file errors.
2. F3: expect assets **0/57 ready**, zero active/pooled audio players, context
   match/music match. F4 should report `ui.confirm · missing` safely.
3. Assign a real `ui.confirm` recording as above. F4 should play it quietly. Add
   select/cancel/invalid/army-select/start recordings; test mouse and keyboard,
   rapid hover and rejected moves for bounded, restrained feedback.
4. Assign real wind/world/fire loops. Start, R, rematch and return to setup several
   times. There should be one wind, one world and two fire layers in a match,
   no duplicate loops, and no match ambience in setup. Approach fire via captures
   and check attenuation. Removing its emitter should stop its owned loop.
5. Add stone start/settle and capture recordings. Ordinary moves should scrape at
   the origin and settle at the destination. In the F6 capture lab, 1–6 should
   synchronize anticipation, motion, impact, fracture, debris and settle with
   visuals. C tests the dedicated Core treatment and existing victory pause.
6. Watch F3 during captures: ambience/music recede slightly and restore. Use R or
   return-to-setup during early/late capture. No cinematic mix/voices may remain
   owned by the departed scene. Listen for bounded natural end/reverb tails.
7. Use the volume API above while ducked, including zero/explicit mute. The current
   user value/mute must survive restoration. Confirm SFX also controls UI/Cinematic.
8. Add music only if desired. Test setup → match → victory → rematch/return quickly:
   fades should converge to one desired track, with at most two transition voices.
9. Assign rare events, wait the configured minute-scale intervals and test category
   disabling. No immediate repeat when alternatives exist; no bell every minute.
10. Review seams, relative loudness, spatial placement, reverb tail and real output
    device behavior locally on Windows/Godot 4.7. Cloud Dummy-driver tests do not
    establish those audible qualities.

Known limits: no real recordings or listening validation; no final music/mix,
acoustic zones, volume menu/save or automatic editor hot reload. Existing Hex is
still absent. All player/roster/progression expansion remains postponed.
Version 0.9 was not started.
