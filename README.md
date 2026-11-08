# PÂLE COPIE

RPG 2D façon Undertale, Godot 4.7. Fan-game privé.

- Lancer : ouvrir `project.godot` dans Godot puis F5, ou `~/Godot.app/Contents/MacOS/Godot` dans ce dossier.
- Cahier des charges : `docs/cahier_des_charges.pdf`.
- Notes techniques et outils : `CLAUDE.md`.
- Assets à dessiner : `data/asset_manifest.json`. Planches d'origine : `assets/source/`.

## Builds (Windows, macOS, Linux)

Les builds sont faits par GitHub Actions (`.github/workflows/release.yml`) :

```sh
git tag v0.9.1
git push origin v0.9.1
```

Le workflow vérifie les scripts, lance les tests, exporte les trois plateformes, vérifie que le build Linux
démarre, puis publie une release avec `PaleCopie-<version>-windows.zip`, `-macos.zip` et `-linux.zip`.
On peut aussi le lancer à la main depuis l'onglet Actions (les builds sont alors téléchargeables en artefacts).
