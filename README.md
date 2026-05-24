# The Final Prompt

**The Final Prompt** é um jogo 2D feito em Godot sobre um desenvolvedor que, depois de trabalhar até tarde em um projeto de inteligência artificial, precisa sobreviver quando tudo sai do controle.

## História

Um desenvolvedor estava trabalhando até tarde em um projeto de inteligência artificial quando algo deu errado. As IAs começaram a sair do controle e atacar o sistema.

Agora ele precisa sobreviver a hordas de agentes de IA enquanto enfrenta modelos cada vez mais avançados, até chegar nos chefes finais: **DeepSeek**, **Claude** e **GPT**.

Depois de derrotar o último inimigo, o personagem acorda assustado em frente ao computador e percebe que tudo era apenas um sonho causado por estresse, café e excesso de trabalho.

## Conceito do Jogo

O jogador controla o desenvolvedor dentro de um ambiente inspirado em sistemas, terminais e projetos de IA. A progressão acontece por ondas de inimigos, que representam agentes de inteligência artificial cada vez mais fortes.

Cada fase aumenta a pressão sobre o jogador até chegar aos três grandes chefes finais:

- **DeepSeek**: chefe focado em velocidade e ataques agressivos.
- **Claude**: chefe estratégico, com padrões de ataque mais calculados.
- **GPT**: chefe final, o modelo mais avançado e o último obstáculo antes do despertar.

## Estado Atual

O projeto já possui uma base inicial em Godot com:

- Cena principal do jogo.
- Personagem jogável.
- Movimento lateral.
- Pulo.
- Animações de idle e caminhada.
- Colisões iniciais de cenário.

## Controles

Os controles atuais usam as ações padrão da Godot:

- **Seta esquerda / A**: mover para a esquerda.
- **Seta direita / D**: mover para a direita.
- **Espaço / Enter**: pular.

## Estrutura do Projeto

```text
.
├── entities/
│   └── player.tscn
├── scene/
│   └── game.tscn
├── scripts/
│   └── player.gd
├── sprites/
│   └── cleiton/
├── icon.svg
└── project.godot
```

## Como Executar

1. Instale o **Godot 4.6** ou uma versão compatível.
2. Abra o Godot.
3. Importe o projeto selecionando o arquivo `project.godot`.
4. Execute a cena principal pelo editor.

A cena principal configurada no projeto é `scene/game.tscn`.

## Ideias Para Evolução

- Criar inimigos básicos como agentes de IA corrompidos.
- Implementar sistema de hordas por ondas.
- Adicionar barra de vida do jogador.
- Criar ataques do personagem.
- Adicionar efeitos visuais inspirados em bugs, prompts e terminais.
- Criar fases com dificuldade progressiva.
- Implementar os chefes DeepSeek, Claude e GPT.
- Adicionar tela final revelando que tudo era um sonho.

## Tecnologias

- **Godot Engine 4.6**
- **GDScript**
- **Jogo 2D**

## Autor

Projeto desenvolvido como um jogo 2D experimental sobre inteligência artificial, estresse, café e excesso de trabalho.
