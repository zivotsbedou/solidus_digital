# frozen_string_literal: true

# Files now live in Active Storage. Paperclip files are not migrated: re-upload them.
class MoveDigitalsToActiveStorage < ActiveRecord::Migration[7.2]
  def change
    remove_column :spree_digitals, :attachment_file_name, :string
    remove_column :spree_digitals, :attachment_content_type, :string
    remove_column :spree_digitals, :attachment_file_size, :integer
    drop_table :spree_drm_records do |t|
      t.integer :digital_id, index: true
      t.integer :line_item_id, index: true
      t.string :attachment_file_name
      t.string :attachment_content_type
      t.integer :attachment_file_size
      t.timestamps
    end
  end
end
