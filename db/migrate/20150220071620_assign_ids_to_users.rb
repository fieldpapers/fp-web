class AssignIdsToUsers < ActiveRecord::Migration[4.2]
  def up
    execute <<-EOQ
      CREATE TABLE new_users (
        id INT NOT NULL AUTO_INCREMENT,
        PRIMARY KEY(id),
        UNIQUE(username),
        UNIQUE(email),
        UNIQUE(reset_password_token),
        UNIQUE(confirmation_token)
      )
      SELECT
        id AS slug,
        CONVERT(CAST(CONVERT(username USING latin1) AS BINARY) USING utf8) username, -- fix encoding issues
        legacy_password,
        email,
        encrypted_password,
        reset_password_token,
        reset_password_sent_at,
        remember_created_at,
        confirmation_token,
        confirmed_at,
        confirmation_sent_at,
        unconfirmed_email,
        updated_at,
        created_at
      FROM users
    EOQ

    drop_table :users
    rename_table :new_users, :users
  end
end
