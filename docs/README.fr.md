# Les voûtes inférieures

[English](../README.md) · [简体中文](README.zh-CN.md) · [Русский](README.ru.md) · [Español](README.es.md) · [Português (Brasil)](README.pt-BR.md) · [Deutsch](README.de.md) · [日本語](README.ja.md) · **Français** · [Polski](README.pl.md) · [한국어](README.ko.md)

Une promenade à la première personne dans une tour sans fin. Le parcours commence aux Archives des poids et mesures, sur une passerelle en bois entre des rangées de tiroirs. Les escaliers mènent à la citerne des marées, à l’observatoire et à la forêt des diapasons. Chaque habitant émet un son qui permet de le reconnaître avant de le voir.

![Une passerelle en bois bordée de garde-corps en laiton longe les tiroirs des archives.](screenshots/archive.jpg)

*Archives des poids et mesures*

## Lancer le jeu

Décompressez toute l’archive x86-64 pour votre plateforme. Gardez les bibliothèques EOS à côté de l’exécutable. Au début d’une partie, la version configurée ouvre un salon et affiche en haut à droite son code de six caractères, par exemple `K7Q-2MX`. Vos compagnons le saisissent sur l’écran titre et choisissent **Rejoindre avec un code** pour parcourir la même expédition.

- **Windows** — double-cliquez sur `LowerVaults.exe`.
- **Linux** — lancez ces commandes dans le dossier extrait.

```sh
chmod +x LowerVaults.x86_64
./LowerVaults.x86_64
```

### Si Windows bloque le jeu

La version Windows n’est pas encore signée, Windows peut donc l’empêcher de démarrer.

- **Microsoft Defender SmartScreen** affiche « Windows a protégé votre ordinateur ». Choisissez **Informations complémentaires**, puis **Exécuter quand même**.
- Le **Contrôle intelligent des applications** (Smart App Control) bloque les programmes non signés sans permettre de les lancer. Vous pouvez le désactiver dans **Sécurité Windows → Contrôle des applications et du navigateur → Paramètres du contrôle intelligent des applications**. Sur certaines versions de Windows 11, il ne peut être réactivé qu’en réinstallant Windows. La version Linux n’a pas cette restriction.

Nous avons demandé un certificat de signature de code gratuit à la SignPath Foundation. La fondation ne certifie que des projets déjà connus : la demande a donc été refusée pour l’instant. Nous la renouvellerons quand le jeu sera plus connu.

## Commandes

| Action | Commande |
| --- | --- |
| Entrer dans la tour | Entrée, Espace ou le bouton **Entrer** |
| Marcher | Flèches, WASD sur clavier QWERTY ou ZQSD sur clavier AZERTY |
| Regarder autour de soi | Souris |
| Courir | Maintenir Maj en se déplaçant |
| Mettre en pause ou reprendre | Échap |
| Quitter | Échap → **Quitter le jeu** |

Le menu de pause permet de régler la sensibilité de la souris, le volume général et le volume de vos propres pas.

## Langue

Le sélecteur de langue se trouve en haut à droite de l’écran d’accueil et du menu de pause. Les menus, les indications et les noms de lieux changent immédiatement. Au premier lancement, le jeu utilise la langue du système si elle est disponible, et l’anglais dans les autres cas. Votre choix est conservé pour la prochaine partie. Les dix langues sont accessibles en haut de cette page.

## Captures d’écran

![Une passerelle en pierre passe sous des arcs brisés et mène à une rosace.](screenshots/cathedral.jpg)

*Cathédrale au-dessus du gouffre*

![Le crâne et la cage thoracique d’un léviathan surplombent des passerelles étroites.](screenshots/leviathan.jpg)

*Dépouille du léviathan*

## Journal des modifications

Les changements de chaque version sont décrits dans le [journal des modifications](CHANGELOG.fr.md).

## Licence

Le code et les ressources du jeu sont publiés sous [Apache License 2.0](../LICENSE). La police de secours pour le chinois, le japonais et le coréen relève de la [SIL Open Font License](../i18n/fonts/OFL.txt). Les archives des versions incluent aussi le SDK Epic Online Services, distribué par Epic selon ses propres conditions.

## Confidentialité

Au début d’une promenade, le jeu se connecte à Epic Online Services pour retrouver des compagnons grâce au code du salon. La connexion est anonyme, via un identifiant d’appareil, et seuls votre position et votre orientation sont partagées avec les joueurs du même salon. Le jeu n’envoie aucune autre donnée. Epic traite la connexion selon sa [politique de confidentialité](https://www.epicgames.com/site/privacypolicy).

## Consommation de tokens pour la version 0.1.0

| Outil | Sessions | Tokens |
|---|---|---:|
| Codex | 4 sessions principales et 6 de sous-agents | 75 875 836 |
| Claude Code | 1 session de préparation de la publication | 1 645 162 |
| **Total** | **11** | **77 520 998** |

Les journaux locaux couvrent le développement et la préparation de la publication les 24 et 25 novembre 2026. Les lectures en cache représentent 98,45 % des tokens. Sur les 1 199 332 tokens restants, les modèles en ont généré 364 313.

## Compiler à partir des sources

Utilisez **Godot 4.7.1 stable** et les modèles d’exportation de la même version. Installez-les depuis **Editor → Manage Export Templates**. Pour jouer dans l’éditeur, ouvrez `project.godot` et appuyez sur F5.

Pour produire les deux exécutables, lancez les commandes suivantes à la racine du projet. La commande `godot` doit correspondre à l’exécutable de l’éditeur.

```sh
python3 tools/install_eos.py
godot --headless --import
godot --headless --export-release "Linux"
godot --headless --export-release "Windows"
```

Les chemins de sortie sont définis dans [export_presets.cfg](../export_presets.cfg). Les textes d’origine sont en russe et les neuf traductions se trouvent dans [i18n](../i18n/). Une police de secours est fournie pour le chinois, le japonais et le coréen. [Licence de la police](../i18n/fonts/OFL.txt).
