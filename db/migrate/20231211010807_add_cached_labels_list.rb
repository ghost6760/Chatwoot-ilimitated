class AddCachedLabelsList < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :cached_label_list, :string

    reversible do |dir|
      dir.up do
        # Backfill usando SQL puro (no cargar modelos ni módulos)
        # Solo se ejecuta si las tablas que emplea acts-as-taggable-on existen.
        if table_exists?(:conversations) && table_exists?(:taggings) && table_exists?(:tags)
          execute <<~SQL
            UPDATE conversations
            SET cached_label_list = sub.tags
            FROM (
              SELECT taggings.taggable_id AS conversation_id,
                     string_agg(tags.name, ',') AS tags
              FROM taggings
              JOIN tags ON tags.id = taggings.tag_id
              WHERE taggings.taggable_type = 'Conversation'
              GROUP BY taggings.taggable_id
            ) AS sub
            WHERE conversations.id = sub.conversation_id;
          SQL
        end
      end
      # dir.down no es necesario porque al hacer rollback se quitará la columna automáticamente
    end
  end
end
