# frozen_string_literal: true

# Suporte a login simultâneo em até 2 dispositivos de tipos diferentes
# (um PC + um celular) sem um derrubar o outro: até aqui, todo login bem
# sucedido revogava TODOS os tokens ativos do usuário (ver
# AuthHelper#invalidate_user_tokens), então logar no celular sempre
# derrubava a sessão do PC e vice-versa. A correção escopa a revogação
# por tipo de dispositivo — precisa saber qual era o tipo de cada token
# pra só revogar os do mesmo tipo do login atual.
class AddDeviceTypeToOauthAccessTokens < ActiveRecord::Migration[7.1]
  def change
    add_column :oauth_access_tokens, :device_type, :string, if_not_exists: true
    add_index :oauth_access_tokens, [:resource_owner_id, :device_type, :revoked_at],
              name: 'index_oauth_tokens_on_owner_device_revoked', if_not_exists: true
  end
end
