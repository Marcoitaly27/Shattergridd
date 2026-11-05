# SHATTERGRID — MASTER GAME VISION

Read this document carefully before making future design or architectural decisions in this repository.

This is the high-level vision for SHATTERGRID.

It is NOT a request to immediately implement every feature described below.

Some systems already exist, some are prototypes, some are planned, and some ideas may change during development.

When working on future tasks:

1. Inspect the actual repository first.
2. Preserve working systems.
3. Treat this document as the intended long-term direction.
4. Do not implement future features unless specifically requested.
5. Do not assume every concept described here already exists.
6. Prefer architectures that allow this vision to grow without unnecessary rewrites.

---

# 1. WHAT IS SHATTERGRID?

SHATTERGRID is a 3D turn-based tactical board game.

Its inspiration comes partly from the clarity, positioning and readability of chess, but SHATTERGRID is NOT intended to be a chess clone.

It has:

- original characters;
- original movement rules;
- character abilities;
- status effects;
- army building;
- unlockable characters;
- cinematic captures;
- a dark medieval mythological world;
- long-term strategic roster customization.

The battlefield is relatively static.

The excitement comes from:

DECISIONS
POSITIONING
CHARACTER SYNERGY
THREAT
CAPTURES
CINEMATIC PAYOFF
ARMY CONSTRUCTION

rather than real-time action.

---

# 2. THE BATTLEFIELD

The current battlefield uses an 8x8 grid.

This may be rebalanced in the future, so avoid unnecessary assumptions that make 8x8 impossible to change.

The board is an ancient ceremonial stone pavement grounded in the courtyard of a ruined medieval cathedral. It is physically supported by continuous earth and masonry, not suspended above a void.

It should feel like part of:

a forgotten cathedral,
fortress,
monastery,
ritual site,
or ancient sacred structure.

It is NOT supposed to look like a normal chessboard floating in space.

The grid itself is built into ancient architecture.

Around it exists a continuous ruined world partially hidden by fog. Cathedral foundations, courtyard paving and earth must meet believably.

---

# 3. WORLD AND ATMOSPHERE

SHATTERGRID exists in an ORIGINAL fictional world inspired heavily by medieval Europe.

It is NOT historical medieval Europe.

The world combines believable medieval elements with frightening mythology and supernatural events.

Important themes include:

- medieval warfare;
- knights;
- armor;
- feudalism;
- plague;
- abandoned settlements;
- ruined churches;
- gothic architecture;
- religious fanaticism;
- witch hunts;
- executions;
- superstition;
- ancient cults;
- forbidden magic;
- dragons;
- mythological creatures;
- disease;
- death;
- forgotten religions;
- decaying monuments.

The supernatural exists, but it should usually feel:

RARE
ANCIENT
DANGEROUS
UNEXPLAINED

rather than normal everyday fantasy.

---

# 4. VISUAL DIRECTION

The target is:

REALISTIC DARK MEDIEVAL FANTASY.

Avoid:

- cartoon visuals;
- cute fantasy;
- mobile-game aesthetics;
- excessive saturation;
- generic high fantasy;
- excessive glowing magic;
- clean fantasy kingdoms;
- low-poly final art;
- arcade presentation.

The visual palette should emphasize:

weathered stone;
cold gray;
mud;
aged wood;
dirty greens;
moss;
rusted metal;
fog;
desaturated earth tones.

Warm light should mainly come from:

fire;
torches;
braziers;
candles.

Supernatural color should be used sparingly so it remains meaningful.

---

# 5. THE PLAYABLE CHARACTERS

The characters are one of the MOST IMPORTANT elements of SHATTERGRID.

They must never be treated as generic board pieces.

Every important character should eventually have:

- a unique name;
- title;
- recognizable silhouette;
- lore;
- personality;
- movement pattern;
- tactical role;
- ability;
- weakness;
- statue design;
- weapon/equipment;
- animation language;
- capture/execution identity;
- sound identity;
- visual effects where appropriate.

A player should eventually recognize a character from its SILHOUETTE alone.

If all characters were rendered completely black, their silhouettes should still be distinguishable.

---

# 6. THE STATUES

Playable characters appear on the battlefield as REALISTIC STONE STATUES.

They are not ordinary living humans running around on the board.

Their stone nature is fundamental to the game's identity.

Possible details include:

- cracked stone;
- chipped surfaces;
- erosion;
- moss;
- broken armor;
- carved cloth;
- chains;
- damaged weapons;
- vandalized religious symbols;
- missing fragments;
- old repairs;
- weathering.

Different statues should have different histories visible through their condition.

Do not make every statue equally damaged.

---

# 7. THE MYSTERY OF THE STATUES

Do NOT fully explain why the statues exist.

The world should contain conflicting theories.

Questions should remain:

Were these people once alive?

Do their souls exist inside the statues?

Are the statues copies?

Are they prisoners?

Were they created by the Grid?

Are they religious monuments?

Why do they fight?

Who created the Shattergrid?

Do not answer all of these questions through exposition.

Mystery is important.

---

# 8. THE CORE

Every army revolves around a CORE.

The Core is the most important piece.

Destroying the enemy Core wins the match.

There is NO chess-style checkmate requirement.

If the Core is captured/destroyed:

the match ends.

The Core should feel like:

STATUE
+
RELIQUARY
+
TOMB
+
SACRED MONUMENT
+
PRISON.

It should NOT simply look like a medieval king chess piece.

Multiple unlockable Core characters may eventually exist.

Different Cores may eventually influence army construction or provide passive strategic effects.

Do not implement those future effects unless specifically requested.

---

# 9. ARMY BUILDING

Players should NOT always use the exact same characters.

Over time, players unlock additional statues.

Before a match, the player builds an army.

The important principle is:

UNLOCKING CHARACTERS SHOULD INCREASE STRATEGIC OPTIONS MORE THAN RAW POWER.

Avoid designing progression where:

new character = old character with better numbers.

Characters should primarily be SIDEGRADES.

A starter character should remain strategically useful even after many characters have been unlocked.

---

# 10. THE LAW OF REFLECTION

Army construction follows a supernatural rule known as:

THE LAW OF REFLECTION.

Most deployment positions exist in mirrored pairs around the Core.

The player chooses one character for a paired slot and that character manifests in BOTH mirrored positions.

Conceptually:

A — B — C — CORE — C — B — A

The exact final formation may change during balancing.

Do not hard-code unrelated systems around one exact starting array.

The Law of Reflection is BOTH:

GAMEPLAY

and

LORE.

Working lore concept:

"The Grid does not summon armies. It reflects them."

Nobody fully understands why.

---

# 11. CHARACTER CATEGORIES

The current long-term army system uses several broad character categories.

These are deployment / strategic families.

They are NOT rigid RPG classes.

Current categories:

CORE

GUARD

HUNTER

POWER

SPECIAL

RANDOM

These categories may evolve during development.

Character architecture should remain data-driven enough to support changes.

---

# 12. GUARDS

GUARDS generally represent:

protection;
territorial control;
defense;
resilience;
formation.

Possible character fantasies include:

armored knights;
saints;
sentinels;
protectors;
cursed defenders;
ancient warriors.

A Guard does NOT necessarily need to be physically slow.

The category represents tactical purpose more than a strict movement template.

---

# 13. HUNTERS

HUNTERS generally represent:

pursuit;
precision;
mobility;
target selection;
pressure.

Possible fantasies include:

witch hunters;
monster hunters;
assassins;
trackers;
religious hunters;
rangers;
specialized killers.

They should often reward positioning and pursuit rather than brute force.

---

# 14. POWER

POWER characters generally represent:

high-impact threats;
aggression;
board pressure;
dangerous captures;
high-risk tactical power.

Possible fantasies include:

Executioner;
Inquisitor;
Fallen Prince;
Dragon Slayer;
massive warriors;
dangerous supernatural fighters.

Power characters should NOT automatically be the best characters.

Strong offensive capability should come with meaningful limitations.

---

# 15. SPECIAL

SPECIAL characters are characters whose mechanics are unusual enough that they do not fit comfortably into Guard, Hunter or Power.

Examples could include:

Witch;
Oracle;
Heretic Monk;
Plague-related characters;
ritual characters;
support characters;
strange supernatural entities.

Their mechanics may manipulate:

status;
position;
information;
abilities;
the board itself.

---

# 16. RANDOM — THE WILDCARD CATEGORY

RANDOM is an intentionally unusual category.

The name "Random" is currently a DEVELOPMENT / WORKING NAME and may later receive a lore-appropriate name.

Do NOT assume the final UI must literally call it "Random."

The purpose of this category is to give SHATTERGRID room for characters that deliberately break the normal thematic or mechanical expectations of the other families.

Random characters may include ideas such as:

ELF
MAGICIAN
STRANGE KNIGHT
ALCHEMIST
FOOL / JESTER
FOREIGN WARRIOR
CURSED CHILD
MONSTER
UNUSUAL MYTHOLOGICAL CREATURE
UNKNOWN WANDERER
NON-HUMAN CHARACTER

and other unusual concepts.

However:

RANDOM DOES NOT MEAN "ANYTHING GOES."

Every Random character must still feel like they belong inside SHATTERGRID.

---

# 17. RANDOM CHARACTER VISUAL RULE

For example:

BAD ELF:

clean handsome high-fantasy elf;
bright green clothing;
glowing bow;
perfect skin;
generic fantasy forest aesthetic.

GOOD SHATTERGRID ELF:

an unsettling ancient humanoid from a race medieval humans barely understand;
unnaturally thin proportions;
weathered stone statue;
strange old armor;
ambiguous religious symbols;
long damaged ears;
evidence that humans may once have feared or hunted its kind.

Likewise:

BAD MAGICIAN:

bright robe;
wizard hat;
colorful staff;
constant glowing spell effects.

GOOD SHATTERGRID MAGICIAN:

a forbidden medieval occult scholar;
ritual robes represented in stone;
astrological or alchemical instruments;
burned or vandalized symbols;
restrained supernatural effects;
perhaps someone executed for knowledge they should not have possessed.

Every fantasy concept must pass through the SHATTERGRID visual and narrative filter.

---

# 18. PURPOSE OF RANDOM CHARACTERS

Random characters should help create:

SURPRISE
EXPERIMENTATION
UNUSUAL STRATEGIES
WORLD-BUILDING
MYSTERY

They are where we can explore strange ideas without forcing every character into a rigid family.

They may have unusual:

movement geometry;
abilities;
deployment behavior;
capture behavior;
risk/reward mechanics.

However, they must still be understandable and balanceable.

"Random" does NOT mean their moves should literally be determined by random chance unless a specific character is deliberately designed around controlled randomness.

---

# 19. FUTURE CHARACTER COLLECTION

The game may eventually contain many unlockable characters.

Potential scale:

dozens rather than hundreds of shallow characters.

QUALITY > QUANTITY.

Every character should justify its existence.

Before adding a character, ask:

Does it create a new tactical decision?

Does it have a memorable silhouette?

Does it have a strong fantasy?

Does it fit the world?

Does it have a meaningful weakness?

Would a player remember it?

Would someone want a physical miniature/statue of it?

If not, reconsider the character.

---

# 20. CHARACTER UNLOCKS

Characters may eventually be unlocked through:

progression;
victories;
mastery;
challenges;
secret conditions;
narrative discoveries;
specific gameplay achievements.

Do NOT assume every character needs a visible XP requirement.

Some characters may remain completely hidden until discovered.

Avoid designing this as a loot-box system.

---

# 21. CINEMATIC CAPTURES

Captures are one of SHATTERGRID's signature features.

A capture should not simply be:

piece moves
→ enemy disappears.

Instead:

capture begins
→ gameplay locks
→ camera moves closer
→ attacker performs character-specific action
→ impact
→ enemy stone statue fractures/destroys
→ dust/debris
→ attacker finishes movement
→ camera returns
→ gameplay continues.

Normal capture cinematics should generally remain SHORT.

Approximately:

1.5–3 seconds.

They should remain satisfying after many repetitions.

---

# 22. CAPTURE PERSONALITY

The ATTACKER primarily determines capture identity.

Examples:

heavy defender:
crushing impact.

executioner:
large deliberate killing blow.

hunter:
fast precise strike followed by delayed fracture.

witch:
victim fractures unnaturally from within.

creature:
animalistic physical attack.

magician:
restrained supernatural destruction.

Do NOT create unique animations for every attacker-victim combination unless there is a compelling reason.

That would scale poorly.

---

# 23. STONE DESTRUCTION

Destroyed characters should feel like HEAVY STONE.

Good:

large chunks;
dust;
major fractures;
weight;
gravity;
pieces falling onto the stone battlefield and surrounding courtyard.

Bad:

confetti;
hundreds of tiny fragments;
weightless explosions;
excessive particle spam.

Destruction should reinforce physical mass.

---

# 24. SOUND

Sound is essential.

The world should use:

wind;
fire;
stone movement;
stone cracking;
debris;
metal resonance;
wood;
distant bells;
rare environmental sounds;
subtle supernatural audio.

Silence is valuable.

Do not fill every second with music or sound.

The player should feel the enormous empty space surrounding the battlefield.

---

# 25. MUSIC

Music should be restrained.

Normal tactical gameplay may rely heavily on ambience.

Music may become more prominent during:

menus;
army setup;
important moments;
victory;
future narrative sequences.

Avoid constant generic epic fantasy music.

---

# 26. ENVIRONMENT

The world surrounding the board should eventually contain realistic assets such as:

ruined medieval houses;
gothic churches;
broken towers;
mossy stone;
abandoned execution structures;
plague-related environmental storytelling;
cliffs;
fog;
dead vegetation;
ancient statues;
dragon-related remains or mythology.

The environment should frame the board rather than interfere with gameplay.

---

# 27. DRAGONS AND MYTHOLOGY

Dragons and mythological creatures exist within the world's mythology.

Do not immediately show enormous dragons flying everywhere.

Mystery is more powerful.

Their existence can initially be suggested through:

bones;
carvings;
statues;
damage;
legends;
characters;
distant silhouettes.

The world should feel larger than what the player directly sees.

---

# 28. REALISTIC ASSET PIPELINE

CODEX BUILDS SYSTEMS.

PRODUCTION ASSETS PROVIDE DETAIL.

Do NOT attempt to solve missing realistic art by constructing increasingly complicated humans or buildings from Godot primitives.

Final assets may come from:

Blender;
professional/free asset libraries;
AI-assisted 3D generation;
custom modeling;
PBR texture libraries.

Codex should integrate these assets cleanly into Godot.

Gameplay logic must remain independent from specific final meshes.

---

# 29. GAMEPLAY PHILOSOPHY

The game should be:

EASY TO UNDERSTAND
DIFFICULT TO MASTER.

A player should quickly understand:

whose turn it is;
which character is selected;
where it can move;
what it can capture;
what its ability does.

Strategic complexity should come from interactions between simple rules.

Avoid characters with paragraphs of exceptions unless their complexity genuinely produces interesting gameplay.

---

# 30. BALANCE PHILOSOPHY

Every character should have:

STRENGTH
WEAKNESS
COUNTERPLAY.

Avoid universally optimal characters.

Avoid progression power creep.

A newly unlocked character should ideally make the player think:

"I want to build a strategy around this."

not:

"I have to use this because its stats are higher."

---

# 31. STATIC GAMEPLAY, LIVING WORLD

The tactical game itself is intentionally relatively static.

The board does not need real-time action.

However, the WORLD should feel subtly alive through:

fog;
wind;
fire;
dust;
distant environmental movement;
audio;
occasional atmospheric events.

Keep motion restrained.

The statues and their capture cinematics should remain the focus.

---

# 32. LONG-TERM PRODUCT VISION

The initial goal is NOT to build an enormous game immediately.

The first excellent version should focus on:

ONE GREAT BOARD

A STRONG CHARACTER ROSTER

ARMY BUILDING

EXCELLENT TACTICAL GAMEPLAY

BEAUTIFUL REALISTIC PRESENTATION

SATISFYING CINEMATIC CAPTURES

AI OPPONENT

LOCAL / CORE MATCH EXPERIENCE

Only after this foundation is excellent should we seriously consider larger systems such as:

multiple boards;
campaign;
online PvP;
ranked modes;
large progression systems;
additional game modes.

Do not prematurely build those systems.

---

# 33. DEVELOPMENT PRIORITIES

When making tradeoffs, prioritize roughly:

1. GAME STABILITY
2. TACTICAL CLARITY
3. CHARACTER IDENTITY
4. GAMEPLAY DEPTH
5. CINEMATIC CAPTURE QUALITY
6. ATMOSPHERE
7. REALISTIC VISUAL QUALITY
8. EXPANDABILITY
9. QUANTITY OF CONTENT

Do not sacrifice the first five merely to add more content.

---

# 34. MOST IMPORTANT PRINCIPLE

SHATTERGRID should not ultimately be remembered as:

"dark fantasy chess."

It should be remembered as:

"that tactical game with the incredible stone characters, weird army combinations, dark medieval world and brutal cinematic captures."

Whenever implementing a future system, preserve that identity.

---

# INSTRUCTIONS FOR FUTURE CODEX TASKS

Treat this document as PRODUCT VISION, not as a backlog to implement automatically.

When receiving a future version prompt:

1. Inspect the actual repository.
2. Determine what already exists.
3. Implement ONLY the requested version/scope.
4. Use this document to resolve architectural/design ambiguity.
5. Do not silently add large future systems.
6. Do not invent final characters unless requested.
7. Do not remove flexibility needed for CORE / GUARD / HUNTER / POWER / SPECIAL / RANDOM character categories.
8. Keep character systems data-driven.
9. Keep visuals replaceable.
10. Keep gameplay independent from production art.
11. Preserve the Law of Reflection unless a future prompt explicitly changes it.
12. Report conflicts between the current repository and this vision instead of hiding them.

Do not implement new functionality merely because it appears in this document.

Use it as the guiding vision for SHATTERGRID.