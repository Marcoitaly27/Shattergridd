# Character rules and day/night — v0.10

This implements the user's requested roster revision and the three timing/range
clarifications confirmed in chat. The Master Game Vision still guides art and
architecture. These are experimental gameplay rules, not claims of final balance.

## Current roster and exact rules

All base moves are exactly one tile. Player 1 (Ash) forward is decreasing row;
Player 2 (Slate) forward is increasing row. Left/right are the lateral board axis.
Movement/capture cannot land on friendly statues. Normal capture occupies the
victim's tile only when it is genuinely destroyed.

| Character | Category | Base movement | Ability |
| --- | --- | --- | --- |
| Core | Core | All eight directions (unchanged) | Destruction wins the match; no checkmate rule |
| Warden | Guard | Forward, backward, left, right | Shield of Stone: each Warden survives its first attempted capture |
| Hunter | Hunter (`hunt` internally) | Forward, backward | Last Arrow: one bow shot per individual Hunter per match |
| Werewolf | Power | Human: forward/backward; night beast: all eight | Blood Step earned by a successful night capture |
| Dragon | Power | All eight | Terror Flight earned by a successful capture |
| Witch | Special | Forward, left, right | Last Mercy: optional one-use rescue while alive |
| Elf | Random (working family name) | Forward, left, right | Veil Exchange: one-use positional swap |

**Warden:** the first attempted capture drops/rotates/hides the existing shield
and rib. Both statues keep their cells, the attacker spends its turn, no kill
bonus or Core victory occurs. Picking is rebuilt without the shield. A later
capture can destroy Warden normally. Shield protection is resolved before any
Witch offer; it does not consume her charge. Each reflected Warden owns its life.

**Hunter:** select, BOW SHOT (or A), then a marked enemy. Exactly two tiles forward,
forward-left diagonal, forward-right diagonal, left or right. The intervening tile
must be empty, regardless of army. There are no backward arrows, empty-square
shots, area hits or multiple victims. Hunter stays on its original tile throughout
the capture; only the target's occupancy is removed. Shooting spends the turn and
the individual Hunter's once-per-match use even when a shield or rescue blocks it.
A bow can destroy Core and contributes to the Core-threat warning. Existing
capture/audio/destruction/camera hooks are retained, with a small prototype arrow.

**Cycle:** start DAY. After both players have completed five turns, NIGHT begins.
After both reach ten, DAY returns; repeat in five-round blocks. The label shows
remaining full rounds. Shield-blocked attacks, rescues, shots and swaps consume
normal turns. A Dragon-imposed skipped turn also counts as a completed owner turn,
including status expiry and the shared day/night clock. Timing has no dependency
on seconds, frame rate, camera or lighting interpolation.

**Werewolf:** the night boundary changes both the actual prototype scene and the
movement/capture behavior, while preserving definition, owner, coordinate and
individual statuses. A successful night capture grants additional destinations
exactly two tiles along any of the eight directions during its owner's NEXT turn.
Intervening tiles must be clear; destination may be empty or enemy, never friendly.
The bonus is not an extra action. It expires at that turn's end even when another
ally acts. A new successful night capture refreshes the next-turn bonus rather
than stacking. A daytime capture grants nothing. A bonus already earned just
before dawn survives for its promised next owner turn, even in human form.

**Dragon:** the former Terror debuff is replaced for this character. After capture,
flight is pending until the owner's next turn. Choose TERROR FLIGHT (or A) to see
all empty board tiles. It ignores intermediate pieces and distance, never captures,
and consumes the turn. ONLY using flight imposes the cost: the army automatically
skips its next turn after the opponent acts. The opponent consequently gets two
consecutive actions across that skipped turn. The cost remains if Dragon dies.
Choosing a normal action instead expires flight without imposing a penalty. Each
Dragon has its own pending flight; the skipped-turn cost belongs to its army.

**Witch:** when a shield does not already block a capture, a living unused allied
Witch offers SAVE STATUE / ALLOW CAPTURE to the defending player. She may save
herself, another ally or Core anywhere on the board. Saving spends her charge;
both statues stay in place and the attacker spends the turn. Declining preserves
her charge and continues the original capture once. The dialog locks normal input;
restart/return to loadout still work. A destroyed Witch cannot rescue anyone.

**Elf — invented ability: Veil Exchange.** Once per match, swap with an adjacent
friendly statue in any of the eight neighboring cells, except Core. No empty-tile
swap, enemy swap or capture. Both logical coordinates update atomically, both
visuals move, and the turn ends. It rewards formations and rescue positioning
without a permanent power increase. This ability and the Elf's title are provisional.

## Deployment and visuals

Eight statues per army are preserved. Guard, Hunter and Power remain reflected
pairs around Core. Power chooses Werewolf OR Dragon. The existing single slot
accepts Special OR Random: Witch OR Elf. Categories remain distinct; there is no
additional Random square or change of board size. Both armies choose independently.

Werewolf replaces Executioner in the active catalog/default loadout. Dragon replaces
Wyrm and moves to Power. Elf is added to the catalog as Random. Original Executioner
and Wyrm resource/scene/cue filenames are retained as reusable presentation families
and historical fixtures; they are no longer selectable characters. No unlock
progression, XP, AI, multiplayer, balance stat system or new production asset is added.

Human/beast and Elf silhouettes are intentionally simple native prototypes. Day/night
uses restrained changes to existing lights. Warden shield loss and Dragon flight
have short procedural animations. Final character modeling, rigging, transformation
animations and real sounds still require production assets. Sound hooks remain
available; no real recordings were supplied.

## Architecture and changed files

- `CharacterDefinition`: declarative active/passive ability keys, explanation and
  optional night model/movement/capture references.
- `directional_movement.gd` and three movement Resources: army-relative offsets.
- `character_actions.gd`: pure bow/exchange/flight target generation and path checks.
- `Piece`: individual shield/use/form state, shield-loss and flight presentation.
- `GameManager`: explicit rescue/defense states, ranged occupancy resolution,
  ability targeting, turn-based cycle and army skip cost. Cinematics do not own
  these gameplay rules. Earned bonuses use the existing status architecture.
- `BoardState`: safe target removal and atomic allied swap.
- `CaptureDirector/Context`: optional ranged presentation; arrow and cancellation
  cleanup; existing close-capture paths and event-driven adapters preserved.
- Existing UI/input/builder: ability controls, rescue choice, cycle indicator,
  correct selectable categories. F6 capture lab now previews seven identities.
- Visual helpers: hidden shield/weapon parts do not contribute picking or bounds;
  hidden parts still receive the correct instance/team materials.
- New Resources: Werewolf/Dragon/Elf, form scenes, movement/status/effect Resources,
  ranged capture behavior; imported script UIDs generated by Godot.

The old camera/input/audio/material regression suites use an explicitly named
`tests/legacy_fixture.gd` to retain their original controlled movement/capture
setups. Those fixtures are never loaded by gameplay. `tests/roster_smoke.gd` tests
the actual new roster and protections separately, including both armies, Core,
clock boundaries, earned-bonus expiry, skipped turns and restart cleanup.

## Manual checks in Godot

1. Close Godot, Pull origin in GitHub Desktop, reopen and F5. In the builder check
   Werewolf/Dragon in Power and Witch/Elf in Special/Wildcard. Confirm both armies;
   check reflected pair deployment and START MATCH.
2. Click each character and inspect movement highlights and the ability explanation.
   Forward must reverse for the other army. Try invalid diagonals and friendly tiles.
3. Attack each Warden: first hit drops its shield, nobody changes cells, turn ends.
   A second hit destroys it unless its Witch explicitly saves it.
4. Select Hunter; BOW SHOT or A previews only valid exact-range targets. Put a statue
   between Hunter and target to test blocking. Check Hunter stays put, one use per
   Hunter, shield/rescue interactions and a ranged Core victory.
5. Attack a Witch or another of her allies. As defender, test both dialog choices,
   then a self-save and a Core save. A spent/dead Witch must not offer another save.
6. Play five turns each: NIGHT, lighting and both Werewolf forms change. Play another
   five each: DAY restores humans. Night Blood Step offers exact two-tile destinations,
   respects blockers, and expires after the next owner turn even if another ally moves.
7. Capture with Dragon, move the opponent, select Dragon and TERROR FLIGHT/A. Fly to
   a distant empty tile. After the opponent's action your next turn is skipped once.
   Repeat a capture but choose a normal move instead: no skip penalty.
8. Choose Elf; VEIL EXCHANGE/A marks adjacent allied non-Core statues with a bonus
   mark, not a capture X. Swap once; verify both cells, turn and spent-use explanation.
9. Test R and ARMY LOADOUT during shield loss, the rescue dialog, arrow capture and
   flight. New matches reset form, shields, charges, bonuses, cycle and penalties;
   selected loadouts survive rematch. Recheck Core victory and normal captures.
10. F6 capture lab supports 1–7, Enter replay, C Core target and Space fast-forward.
    It intentionally bypasses move eligibility to preview each capture presentation.

## Verification results

Godot 4.6.3: all ten headless suites passed **3,873 checks**; seven OpenGL
Compatibility suites passed **1,995 checks**. The new actual-roster suite executes
**168 checks** in each mode. No failed checks, GDScript errors or resource-path
failures were reported. Editor import completed and all **411** local resource
references resolved. `git diff --check` passed.

Graphical review at 960×666 checked the builder, bow target control, rescue dialog,
Warden information and transformed Werewolf/night lighting. OpenGL used software
Mesa and Dummy audio; this is not a GPU benchmark or proof of final asset quality.
Windows/Godot 4.7 and final assets remain manual checks.

The board size remains 8×8 and roster balance is unproven. No AI, progression,
permanent upgrades or final art/audio were introduced. Current movement can create
blocked armies; automatic stalemate/draw/pass rules remain undefined. This change
only automatically skips turns imposed by Dragon flight.

