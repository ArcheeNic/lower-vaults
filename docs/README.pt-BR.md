# As abóbadas inferiores

[English](../README.md) · [简体中文](README.zh-CN.md) · [Русский](README.ru.md) · [Español](README.es.md) · **Português (Brasil)** · [Deutsch](README.de.md) · [日本語](README.ja.md) · [Français](README.fr.md) · [Polski](README.pl.md) · [한국어](README.ko.md)

Uma caminhada em primeira pessoa por uma torre sem fim. O percurso começa no Arquivo de pesos e medidas, em uma ponte de madeira entre fileiras de gavetas. As escadas levam à cisterna das marés, ao observatório e à floresta de diapasões. Cada habitante tem um som próprio que você pode reconhecer antes de vê-lo.

![Uma passarela de madeira com corrimãos de latão passa entre as gavetas do arquivo.](screenshots/archive.jpg)

*Arquivo de pesos e medidas*

## Como jogar

Extraia todo o arquivo x86-64 da sua plataforma. Mantenha as bibliotecas do EOS ao lado do executável. Ao começar uma partida, a versão configurada abre uma sala e mostra no canto superior direito um código de seis caracteres, por exemplo `K7Q-2MX`. Seus amigos digitam o código na tela inicial e escolhem **Entrar com código** para percorrer a mesma expedição.

- **Windows** — clique duas vezes em `LowerVaults.exe`.
- **Linux** — execute estes comandos na pasta extraída.

```sh
chmod +x LowerVaults.x86_64
./LowerVaults.x86_64
```

### Se o Windows bloquear o jogo

A versão para Windows ainda não tem assinatura, por isso o Windows pode impedir que ela abra.

- O **Microsoft Defender SmartScreen** mostra “O Windows protegeu o computador”. Clique em **Mais informações** e depois em **Executar assim mesmo**.
- O **Controle Inteligente de Aplicativos** (Smart App Control) bloqueia programas sem assinatura e não oferece como abri-los. Você pode desativá-lo em **Segurança do Windows → Controle de aplicativos e do navegador → Configurações do Controle Inteligente de Aplicativos**. Em algumas versões do Windows 11, ele só pode ser reativado reinstalando o Windows. A versão para Linux não tem essa restrição.

Pedimos à SignPath Foundation um certificado gratuito de assinatura de código. A fundação certifica apenas projetos que já são conhecidos, então por enquanto o pedido foi recusado. Vamos pedir de novo quando o jogo for mais conhecido.

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

## Registro de alterações

As mudanças de cada versão estão no [registro de alterações](CHANGELOG.pt-BR.md).

## Licença

O código e os recursos do jogo são distribuídos sob a [Apache License 2.0](../LICENSE). A fonte reserva para chinês, japonês e coreano usa a [SIL Open Font License](../i18n/fonts/OFL.txt). Os arquivos de cada versão também incluem o SDK do Epic Online Services, que a Epic distribui sob os próprios termos.

## Privacidade

Quando um passeio começa, o jogo se conecta ao Epic Online Services para encontrar companheiros pelo código da sala. O login é anônimo, por um identificador do dispositivo, e só sua posição e direção são compartilhadas com os jogadores da mesma sala. O jogo não envia nenhum outro dado. A Epic trata a conexão conforme sua [política de privacidade](https://www.epicgames.com/site/privacypolicy).

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
python3 tools/install_eos.py
godot --headless --import
godot --headless --export-release "Linux"
godot --headless --export-release "Windows"
```

Os caminhos de saída estão em [export_presets.cfg](../export_presets.cfg). Os textos originais estão em russo e as outras nove traduções ficam em [i18n](../i18n/). O jogo inclui uma fonte alternativa para chinês, japonês e coreano. [Licença da fonte](../i18n/fonts/OFL.txt).
