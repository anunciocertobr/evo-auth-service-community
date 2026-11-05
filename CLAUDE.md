# Fork — evo-auth-service-community

Este repositório é um **fork** de
[`evolution-foundation/evo-auth-service-community`](https://github.com/evolution-foundation/evo-auth-service-community)
(projeto open-source "Evolution", não nosso). Criado em 05/11/2026
especificamente pra poder customizar o serviço de login — até então rodava a
imagem pronta `evoapicloud/evo-auth-service-community:latest` direto do
Docker Hub, sem nenhum código nosso.

Deploy, checkout na VPS e histórico completo dessa migração: ver a seção
**"Auth service (`evo-auth-service-community`) — fork, deploy manual"** em
`~/CLAUDE.md` (não duplicado aqui pra não desincronizar).

## Nossa customização: sessão simultânea PC + celular

`app/controllers/api/v1/auth_controller.rb` (`render_successful_login`) e
`app/controllers/concerns/auth_helper.rb` (`create_user`, e os helpers novos
`classify_device_type` / `invalidate_same_device_tokens`) foram alterados
pra que um login bem-sucedido só revogue os tokens ativos do usuário que
sejam do **mesmo tipo de dispositivo** (classificado pelo User-Agent:
`mobile` ou `desktop`), em vez de revogar **todos** os tokens do usuário
como o upstream faz (`invalidate_user_tokens`, ainda usado no `logout` —
isso continua certo, "sair" deve mesmo encerrar tudo).

Bug real que isso corrige: sem essa mudança, logar no celular sempre
derrubava a sessão do PC (e vice-versa) — usuário não conseguia ficar
logado nos dois ao mesmo tempo. Com a mudança: até 1 sessão desktop + 1
sessão mobile simultâneas; um **segundo** login no mesmo tipo de aparelho
ainda derruba o primeiro daquele tipo (não é "sessões ilimitadas").

Migração nova: `db/migrate/20261105211300_add_device_type_to_oauth_access_tokens.rb`
— adiciona a coluna `device_type` em `oauth_access_tokens`, preenchida na
criação do token (`create_oauth_token`, em `auth_helper.rb`).

## Ao atualizar a partir do upstream (`git fetch` + merge de
`evolution-foundation/evo-auth-service-community`)

Esses três arquivos são os únicos tocados pela nossa customização:
- `app/controllers/api/v1/auth_controller.rb`
- `app/controllers/concerns/auth_helper.rb`
- `db/migrate/20261105211300_add_device_type_to_oauth_access_tokens.rb`

Se o upstream mexer em `render_successful_login`, `create_user`, ou em
`invalidate_user_tokens`/`create_oauth_token` (os pontos onde nossa mudança
se encaixa), resolver o conflito preservando a chamada a
`invalidate_same_device_tokens`/`classify_device_type` em vez de voltar pra
`invalidate_user_tokens` nos fluxos de LOGIN — `logout` continua usando
`invalidate_user_tokens` normalmente, isso não muda.

Não há remote configurado pro upstream ainda (só `origin`, apontando pro
nosso fork). Se precisar buscar mudanças de lá:
```bash
git remote add upstream https://github.com/evolution-foundation/evo-auth-service-community.git
git fetch upstream
git merge upstream/main   # ou main, verificar o nome do branch padrão deles
```
