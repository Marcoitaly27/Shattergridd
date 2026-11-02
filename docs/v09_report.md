# SHATTERGRID v0.9 — rapporto finale

1. **Audit.** Base `dcfcc82`, v0.8 funzionante: scacchiera, schieramenti, sei personaggi prototipo, catture, distruzione, camera e audio predisposto. Nessun modello importato, rig o texture PBR reali. [Audit completo](asset_pipeline.md#audit-of-the-actual-repository).
2. **File creati.**
   - `scripts/visuals/animation_config.gd`
   - `scripts/visuals/asset_validation.gd`
   - `scripts/visuals/asset_wrapper.gd`
   - `scripts/visuals/environment_asset.gd`
   - `scripts/visuals/geometry_helpers.gd`
   - `scripts/visuals/pick_proxy.gd`
   - `scripts/visuals/stone_surface.gd`
   - `scripts/visuals/visual_animation.gd`
   - `scripts/capture/authored_capture.gd`, `resources/visuals/authored_capture.tres`.
   - `resources/visuals/MAT_StoneSurface_Template.tres`.
   - `scenes/assets/CHR_VisualWrapper_Template.tscn`, `scenes/assets/ENV_VisualWrapper_Template.tscn`.
   - `tests/asset_smoke.gd`; UID associati ai nuovi script.
   - `docs/asset_pipeline.md`, `docs/ASSET_SOURCES.md`, questo rapporto.
3. **File modificati.** `README.md`, `project.godot`; `scripts/pieces/character_definition.gd`, `piece.gd`, `placeholder_visual.gd`; `scripts/capture/capture_context.gd`; `scripts/debug/debug_overlay.gd`; le sei scene in `scenes/pieces/characters/` (soltanto metadato di prototipo).
4. **Architettura visuale.** `Piece/Visuals/Model` separa identità, coordinate e regole da modello e correzioni. La sostituzione aggiorna il picking ed è bloccata durante un’azione. Variante riflessa opzionale senza scala negativa.
5. **GLB/importazione.** Modello importato come figlio esterno di un wrapper nativo. Scala, orientamento, proxy e riferimenti restano nel wrapper/CharacterDefinition; non si modificano i contenuti generati dell’importazione.
6. **Animazioni.** AnimationPlayer/AnimationTree opzionali e mappa degli stati. Per le catture, il segnale `impact` della traccia metodi attiva i meccanismi esistenti; clip assenti o non sicure mantengono le catture procedurali. Nessuna animazione finale creata.
7. **PBR.** Configurazione StandardMaterial3D per albedo, normal, roughness, metallic, AO/ORM, detail, altezza ed emissione opzionali. Materiali per istanza e superfici nominate preservano metallo/tessuto e risorse condivise. Nessuna texture nuova.
8. **Ambiente.** Wrapper indipendenti per strutture, sfondo, oggetti, vegetazione, VFX e luci; correzione, distanza visibile e ombre configurabili, senza dipendenze dalla scacchiera.
9. **Collisioni.** Picking semplice con proxy espliciti o bounding box. Collisioni importate disattivate e corpi congelati. Gli sfondi decorativi non richiedono collisione.
10. **Prestazioni/LOD.** La guida specifica budget indicativi di geometria/texture, LOD di importazione, distanze, ombre e memoria. Nessun gestore LOD complesso. La verifica OpenGL software non misura le prestazioni della tua GPU.
11. **Licenze.** [Registro fonti](ASSET_SOURCES.md): autore, fonte, licenza/URL, modifiche, uso commerciale, attribuzione e prove da conservare. Nessuna provenienza inventata.
12. **Prove eseguite.** Risorse native esistenti e fixture solo in memoria: Executioner con visuale Witch conserva mosse, occupazione, cattura e Blood Step; Core con visuale Wyrm conserva la vittoria; sostituzione di un modulo ambientale conserva i turni. Provati materiali indipendenti, proxy, schieramento riflesso, marker d’impatto a due tempi diversi, fallback, audio e riavvio durante una clip. **3.702 controlli headless + 2.240 OpenGL, zero fallimenti**, editor importato e 316 riferimenti risolti. Nessun vero GLB/rig/PBR è stato collaudato.
13. **Sostituire un personaggio reale.** Segui i dieci passaggi esatti della [procedura GLB](asset_pipeline.md#preferred-glb-workflow--replace-one-placeholder): conserva fonte/licenza, importa, duplica il template, aggiungi il GLB, correggi trasformazioni e appoggio, prepara proxy/materiali/animazioni opzionali, collega `model_scene` e verifica entrambi gli eserciti. La guida indica campi e unità.
14. **Prove manuali.** Con Godot chiuso fai Pull origin; riapri, F5, conferma gli eserciti e START MATCH. Prova mosse/catture per entrambi, Blood Step/Terror, vittoria Core e riavvio. Seleziona un pezzo e premi F7 per ispezionare l’asset; F3 nasconde il pannello. F6 apre il laboratorio catture. Con un asset reale verifica appoggio, orientamento, click, materiali, impatto, camera, reimportazione e prestazioni: [checklist completa](asset_pipeline.md#exact-manual-review).
15. **Limiti precedenti.** Nessun guasto di base emerso. Hex non presente; audio senza registrazioni; distruzione ancora provvisoria; modelli ancora prototipi. Importazione/reimportazione reale, skinning, qualità delle texture e Windows/Godot 4.7 restano da provare con asset autentici. Versione 0.10 non iniziata.
