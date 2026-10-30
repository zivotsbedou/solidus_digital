# frozen_string_literal: true

# Files move to Active Storage; run `bin/rails solidus_digital:migrate_paperclip_files`
# to attach existing Paperclip files. A later release drops the Paperclip columns.
class PrepareDigitalsForActiveStorage < ActiveRecord::Migration[7.2]
  def change
    drop_table :spree_drm_records do |t|
      t.integer :digital_id, index: true
      t.integer :line_item_id, index: true
      t.string :attachment_file_name
      t.string :attachment_content_type
      t.integer :attachment_file_size
      t.timestamps
    end
    remove_index :spree_digital_links, :secret
    add_index :spree_digital_links, :secret, unique: true
  end
end
