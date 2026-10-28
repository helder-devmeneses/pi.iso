# PI.ISO — continuidade do projeto

Atualizado em 22/09/2026.

## O que está funcionando

- tela de boas-vindas com Entrar e Criar conta (como no protótipo);
- cadastro inicial: nome, e-mail e senha gravados no aparelho;
- validação do login e acesso à tela inicial (senha do cadastro
  passa a ser exigida); e-mail lembrado automaticamente;
- sessão salva: fechar e abrir o app não pede login de novo
  (o botão Sair encerra a sessão);
- entrar com digital (`local_auth`): na abertura com sessão ativa
  e no botão "Entrar com digital" do login;
- botões Google/Apple no login (visuais; ativação futura);
- cadastro de receitas e despesas;
- escolha de categoria e data;
- atualização automática do saldo, das receitas e das despesas;
- exibição das últimas transações;
- extrato completo com busca por descrição e filtros de tipo, categoria e período;
- edição e exclusão de lançamentos, com confirmação;
- metas financeiras: cadastro, edição, exclusão e depósito;
- relatórios: maior despesa, despesas por categoria com barra de
  porcentagem e totais de receitas e despesas por mês;
- geladeira: registra o desejo de compra com período de espera;
  ao liberar, comprar (vira despesa no extrato) ou desistir;
  cartão azul com o total economizado e o total em espera;
- deslizar entre as cinco telas (PageView na casca `PisoShell`),
  com o menu inferior fixo;
- perfil: editar nome e e-mail, definir senha (validada no login),
  preferências de notificação, ajuda e sair;
- armazenamento em banco local SQLite (`sqflite`), com migração automática
  dos dados antigos que ficaram no `shared_preferences`.

## Como abrir no Android Studio

1. No Android Studio, escolha **Open**.
2. Selecione a pasta `pi_iso_atual`.
3. Execute `flutter pub get` quando solicitado.
4. Escolha Chrome ou o celular e clique em **Run**.

Na versão web, use sempre a mesma porta, senão o banco local muda de origem
e os dados cadastrados não aparecem:

    flutter run -d chrome --web-port=8080

No Android Studio isso fica em **Editar configurações** →
**Argumentos adicionais de execução** → `--web-port=8080`.

## Arquivos principais

- `lib/main.dart`: inicia o aplicativo e define o tema.
- `lib/data/banco_dados.dart`: acesso ao SQLite. Transações, metas,
  migração e consultas de relatório.
- `lib/screens/boas_vindas_screen.dart`: primeira tela, Entrar/Criar conta.
- `lib/screens/cadastro_screen.dart`: cadastro inicial do usuário.
- `lib/screens/login_screen.dart`: valida o acesso.
- `lib/screens/home_screen.dart`: resumo financeiro e menu inferior.
- `lib/screens/nova_transacao_screen.dart`: cadastro e edição de lançamento.
- `lib/screens/transacoes_screen.dart`: extrato, busca e filtros.
- `lib/screens/metas_screen.dart`: lista de metas com depósito, edição e exclusão.
- `lib/screens/nova_meta_screen.dart`: cadastro e edição de meta.
- `lib/screens/relatorios_screen.dart`: maior despesa, categorias e meses.
- `lib/screens/geladeira_screen.dart`: desejos de compra em espera e
  formulário de novo desejo.
- `lib/screens/piso_shell.dart`: casca com o menu inferior e o
  PageView que permite deslizar entre as telas.
- `lib/screens/perfil_screen.dart`: perfil, segurança, notificações,
  ajuda e sair.
- `lib/data/perfil.dart`: nome, e-mail, senha e preferências no
  `shared_preferences`.

## Etapas concluídas

| # | Etapa | Data |
|---|---|---|
| 1 | Estrutura inicial (`main.dart`, tema) | anterior |
| 2 | Login | anterior |
| 3 | Tela inicial e resumo | anterior |
| 4 | Cadastro de transações | anterior |
| 5 | Extrato, filtros, edição e exclusão de transações | anterior |
| 6 | Ligar o botão Nova Meta | 22/09/2026 |
| 7 | Metas: editar, excluir e depositar | 22/09/2026 |
| 8.1 | Consultas de relatório no banco (`GROUP BY`) | 22/09/2026 |
| 8.2 | Tela de Relatórios (`relatorios_screen.dart`) | 22/09/2026 |
| 8.3 | Botão Relatórios ligado no menu inferior | 22/09/2026 |
| 9 | Geladeira (banco versão 3 + tela + botão no menu) | 22/09/2026 |
| 10 | Perfil (editar, segurança, notificações, ajuda, sair) | 22/09/2026 |
| 10.1 | Deslizar entre telas (`PisoShell` com PageView) | 22/09/2026 |
| 10.2 | Cartão azul da Geladeira (design da equipe) | 22/09/2026 |
| 10.3 | Dashboard no Início (degradê, olhinho, ações rápidas, rosca) | 22/09/2026 |
| 10.4 | Gráfico de rosca e barras coloridas nos Relatórios | 22/09/2026 |
| 11 | Limpeza: `lib/utils/formatos.dart` unifica moeda/data/leitura | 22/09/2026 |
| 12 (início) | Testes automatizados: `test/formatos_test.dart` | 22/09/2026 |
| 10.5 | Boas-vindas + Criar conta (cadastro inicial) | 22/09/2026 |
| extra | Logo da balança como ícone do app; nome "PI.ISO" | 22/09/2026 |
| 10.6 | Sessão salva + entrar com digital + botões sociais | 22/09/2026 |

## Próximo passo exato

**Completar os testes (etapa 12)** — testar o BancoDados — e
entregas finais (13). Um APK de teste já foi gerado em
`build\app\outputs\flutter-apk\app-release.apk`; o APK final será
gerado quando tudo estiver pronto, com o mesmo comando
`flutter build apk --release`.

## Referências da equipe

- Figma (telas): https://www.figma.com/design/gTeOwtADXuPdim4BRUTN1e/
- Figma (ideação): https://www.figma.com/board/NRanQpKu3ilKOCOlOUgKYD/
- Repositório: https://github.com/tamiresdcosta-dot/PI.ISO.git

## Etapas seguintes previstas

9. Geladeira: registrar o desejo de compra, definir prazo de espera,
   acompanhar o valor e decidir entre comprar ou desistir.
10. Perfil, cadastro de usuário e segurança dos dados.
11. Limpeza: unificar em um só lugar as funções repetidas de formatação
    de moeda, de data e de leitura de valor digitado.
12. Testes automatizados.
13. Entregas finais: APK instalável, caderno de estudo por etapa em Word,
    roteiro de apresentação para o SAGA SENAI e dados fictícios para a demonstração.

## Backups por etapa

Mantidos em `Downloads` e no Google Drive:

- `PIISO_Etapa_Transacoes_Concluida.zip`
- `PIISO_Etapa_Excluir_Transacao_Concluida.zip`
- `PIISO_Etapa_Metas_Concluida.zip` (a criar)
