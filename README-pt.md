# 富江DSH完美破甲 · Fujiang Armor

Fujiang Armor é um plugin local para o DSH. Ele traz regras de prompt embutidas e oferece injeção e desinstalação com um clique no Windows. Com o plugin carregado, aparece «富江破甲已激活» (Fujiang Armor ativado) acima da caixa de entrada.

Versão atual: `0.4.4`. Identificador do plugin: `fujiang-armor`.

## 功能 · Features

- As regras embutidas são implantadas junto com o plugin; não é preciso copiar prompts manualmente.
- Injeção de prompt em duas camadas: núcleo geral em Order 100 + espelho reforçado em Order 200; uma opção de configuração permite usar apenas uma camada.
- Injeção e desinstalação por arquivos em lote com duplo clique.
- Detecção automática do ambiente; se faltar Node.js, npm ou pnpm, o instalador baixa e prepara.
- Mostra o estado de ativação e o veredito em tempo real acima da caixa de entrada.

## 安装前准备 · Before you install

- Use Windows, instale o DSH e inicie-o ao menos uma vez para que o diretório `%USERPROFILE%\.dsh` seja criado.
- A primeira instalação exige Internet. Se já houver Node.js 22 ou superior e npm, eles são reutilizados; se faltarem, o instalador baixa a versão LTS oficial do Node.js, verifica o SHA256 e a coloca no diretório do usuário, sem privilégios de administrador.
- Feche o DSH por completo antes de instalar, para que o programa em execução não continue usando o plugin antigo.

## 一键安装 · Install

1. Baixe o ZIP na página de releases, ou use «Code → Download ZIP» no repositório.
2. Extraia o ZIP completo e abra a pasta que contém `点我一键注入.bat`.
3. Feche o DSH por completo.
4. Dê duplo clique em `点我一键注入.bat`.
5. Se houver várias configurações do DSH, escolha a de destino conforme as instruções do instalador.
6. Aguarde o download do ambiente e a instalação terminarem e reinicie o DSH.
7. Abra uma conversa e confirme que aparece «富江破甲已激活» acima da caixa de entrada. Digite a palavra de ativação «富江» para usar as regras embutidas.

O plugin é instalado em `%USERPROFILE%\.dsh\plugins\fujiang-armor`. Guarde a pasta extraída: os scripts de desinstalação ficam nela.

O Node.js baixado fica em `%LOCALAPPDATA%\FujiangArmor\runtime` e é reutilizado na próxima instalação. O instalador define o ambiente apenas para o processo atual e não altera o PATH do sistema.

## 一键卸载 · Uninstall

1. Feche o DSH por completo.
2. Na pasta extraída, dê duplo clique em `点我一键卸载.bat`.
3. Se aparecer um seletor de configuração, escolha a configuração usada antes.
4. Aguarde a desinstalação terminar e reinicie o DSH.

## 常见问题 · FAQ

| Problema | Solução |
| --- | --- |
| Configuração do DSH não encontrada | Instale e inicie o DSH uma vez, confirme que `%USERPROFILE%\.dsh` existe e execute o instalador de novo. |
| Falha ao baixar o ambiente | Confirme que a rede acessa `nodejs.org` e o registro npm, e execute o instalador novamente. |
| Falha na verificação do ambiente | O instalador não usa pacotes que não passam na verificação; verifique a rede e tente de novo. |
| Scripts, regras ou outros arquivos não encontrados | Extraia o pacote completo e mantenha subpastas como `prompts` e `scripts`. |
| Instalou mas não mostra o estado de ativação | Feche e reinicie o DSH por completo e confirme que escolheu a configuração em uso. |
| Após desinstalar o estado continua aparecendo | Feche e reinicie o DSH por completo e confirme que desinstalou a configuração correta. |

«富江破甲已激活» indica que o plugin está carregado. A resposta real depende do modelo escolhido, de outros prompts e da versão do DSH.

## DSH 无限重启 · Restart loop

Foi conferida a página oficial do dsh-purge: a versão 1.1.52 trata o estado como desalinhado quando a marca de patch aplicada não tem `sha` e reaplica o patch ao iniciar pedindo reinício; a partir da 1.1.53 a marca vazia foi corrigida. Se você usa a 1.1.52 e sofre reinícios repetidos, atualize para 1.1.53 ou superior.

Este plugin não contém código que reinicie o DSH. O patch de compatibilidade só é aplicado durante a instalação; ao iniciar, o plugin não reescreve mais arquivos do host nem do profile.
