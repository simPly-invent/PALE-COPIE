# PÂLE COPIE

RPG 2D façon Undertale, développé avec Godot 4.7 en GDScript. Fan-game privé.

Le jeu repose sur une idée : chaque salle visitée est une *copie* de la
précédente, un peu plus dégradée. Une fidélité (F) décroît à mesure que l'on
s'enfonce, et des mutations déterministes (couleurs, portes décalées,
boucles, sons) s'accumulent de copie en copie. Seule l'ancre de chaque
salle reste intacte. Les Souvenirs retrouvés en chemin redonnent de la
fidélité.

Cahier des charges complet : `docs/cahier_des_charges.pdf`.

## Lancer le jeu

- Ouvrir `project.godot` dans Godot 4.7 et appuyer sur F5.
- En ligne de commande, avec `GODOT` pointant vers l'exécutable :

```sh
$GODOT                                    # jeu complet
$GODOT -- --room=z1_arrival --skip-intro  # salle directe (dev)
$GODOT -- --battle=neon_flicker           # un combat
$GODOT -- --tape=t01                      # une cassette VHS
```

Les builds Windows, macOS et Linux sont publiés dans les releases GitHub.

## Vérifier

```sh
tools/check_scripts.sh      # parsing de tous les scripts (ne doit rien afficher)
tools/run_tests.sh          # tests de cohérence, doit finir sur ALL TESTS PASSED
$GODOT --headless res://tests/play_test.tscn   # partie jouée au clavier
```

Les tests couvrent les règles de dégradation (20 copies, 4 graines), toutes
les salles, l'accessibilité de la fin, les Souvenirs et l'aller-retour de
sauvegarde.

## Structure

```
.
├── autoload/      GameState, DegradationManager, AudioManager, FxManager,
│                  DialogueManager, BattleManager, SaveManager, World
├── core/          utilitaires (Assets, JsonUtil, TextFx, UI, TileGrid, ...)
├── rooms/         salles sources en JSON, une zone par dossier (z1 à z7)
├── mutations/     une mutation = un script + une ressource .tres
├── scenes/        overworld, battle, ui, tools
├── shaders/       post-traitement (VHS, palette, dither, glitch) et teinte
├── data/          zones, dialogues, ennemis, objets, énigmes, cassettes, fins
├── assets/        sprites, tuiles, portraits, VHS, UI, sons
│   └── source/    planches d'origine, non importées (.gdignore)
├── tests/         tests de cohérence et test joué
├── tools/         découpe des planches, captures, scripts de build
└── docs/          cahier des charges
```

Tout le contenu narratif est en données (JSON), jamais en dur dans le code.
Les mutations n'agissent que sur les nœuds fixes d'une salle (`Tiles`,
`Props`, `Doors`, `NPCs`, `Spawns`), jamais sur l'ancre.

## Rendu

640 x 480, mise à l'échelle `viewport`, filtre nearest, sans anti-aliasing.
Une case fait 40 px. Les calques vont du monde (0) aux dialogues (60) et au
fondu (90) ; l'ancre est rendue au-dessus du post-traitement pour ne jamais
changer de couleur.

## Builds

Le workflow `.github/workflows/release.yml` vérifie les scripts, lance les
tests, exporte les trois plateformes, vérifie que le build Linux démarre et
publie une release :

```sh
git tag v0.9.1
git push origin v0.9.1
```

Il peut aussi être lancé à la main depuis l'onglet Actions ; les builds sont
alors téléchargeables en artefacts. L'application macOS doit ensuite être
re-signée sur un Mac (`tools/build_macos.sh`).

## Notes de développement

`data/asset_manifest.json` liste les assets
encore à dessiner.
