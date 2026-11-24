# As abóbadas inferiores

[English](../README.md) · [简体中文](README.zh-CN.md) · [Русский](README.ru.md) · [Español](README.es.md) · **Português (Brasil)** · [Deutsch](README.de.md) · [日本語](README.ja.md) · [Français](README.fr.md) · [Polski](README.pl.md) · [한국어](README.ko.md)

Uma caminhada em primeira pessoa por uma torre sem fim. O percurso começa no Arquivo de pesos e medidas, em uma ponte de madeira entre fileiras de gavetas. As escadas levam à cisterna das marés, ao observatório e à floresta de diapasões. Cada habitante tem um som próprio que você pode reconhecer antes de vê-lo.

![Uma passarela de madeira com corrimãos de latão passa entre as gavetas do arquivo.](screenshots/archive.jpg)

*Arquivo de pesos e medidas*

## Como jogar

As versões para Linux e Windows incluem todos os recursos do jogo em um único executável x86-64. O jogo usa o renderizador Forward+ da Godot.

- **Windows** — clique duas vezes em `build/LowerVaults.exe`.
- **Linux** — execute estes comandos na pasta do projeto.

```sh
chmod +x "build/Нижние своды.x86_64"
"./build/Нижние своды.x86_64"
```

## Controles

| Ação | Controle |
| --- | --- |
| Entrar na torre | Enter, barra de espaço ou o botão **Entrar** |
| Andar | WASD ou setas |
| Olhar ao redor | Mouse |
| Correr | Segure Shift enquanto anda |
| Pausar ou continuar | Esc |
| Sair | Esc → **Sair do jogo** |

O menu de pausa permite ajustar a sensibilidade do mouse, o volume geral e o volume dos seus passos.

## Idioma

O seletor de idioma fica no canto superior direito da tela inicial e do menu de pausa. Os menus, as dicas e os nomes dos lugares mudam na hora. Na primeira vez, o jogo usa o idioma do sistema se houver tradução, ou inglês caso contrário. Sua escolha fica salva para a próxima partida. Os dez idiomas estão no topo desta página.

## Capturas de tela

![Um caminho de pedra passa sob arcos ogivais e leva a uma rosácea.](screenshots/cathedral.jpg)

*Catedral sobre o abismo*

![O crânio e as costelas de um leviatã pairam sobre pontes estreitas.](screenshots/leviathan.jpg)

*Restos do leviatã*

## Consumo de tokens da versão 0.1.0

| Ferramenta | Sessões | Tokens |
|---|---|---:|
| Codex | 4 principais e 6 de subagentes | 75.875.836 |
| Claude Code | 1 de preparação do lançamento | 1.645.162 |
| **Total** | **11** | **77.520.998** |

Segundo os registros locais de desenvolvimento e preparação do lançamento de 24 e 25 de novembro de 2026, 98,45% dos tokens vieram de leituras do cache. Dos 1.199.332 restantes, os modelos geraram 364.313.

## Compilar a partir do código-fonte

Use a **Godot 4.7.1 stable** e os modelos de exportação da mesma versão. Instale os modelos pelo menu **Editor → Manage Export Templates**. Para jogar no editor, abra `project.godot` e pressione F5.

Para gerar as duas versões, execute os comandos abaixo na raiz do projeto. O comando `godot` deve apontar para o executável do editor.

```sh
godot --headless --import
godot --headless --export-release "Linux"
godot --headless --export-release "Windows"
```

Os caminhos de saída estão em [export_presets.cfg](../export_presets.cfg). Os textos originais estão em russo e as outras nove traduções ficam em [i18n](../i18n/). O jogo inclui uma fonte alternativa para chinês, japonês e coreano. [Licença da fonte](../i18n/fonts/OFL.txt).
