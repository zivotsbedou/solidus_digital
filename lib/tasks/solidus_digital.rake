# frozen_string_literal: true

namespace :solidus_digital do
  desc "Attach files stored by the Paperclip versions (private/digitals/:id/:filename) to Active Storage"
  task migrate_paperclip_files: :environment do
    Spree::Digital.where.missing(:attachment_attachment).find_each do |digital|
      path = Rails.root.join("private/digitals", digital.id.to_s, digital.attachment_file_name.to_s)
      next warn("Missing file for digital #{digital.id}: #{path}") unless digital.attachment_file_name? && path.file?

      digital.attachment.attach(io: path.open, filename: digital.attachment_file_name, content_type: digital.attachment_content_type)
      warn("Could not attach digital #{digital.id}: #{digital.errors.full_messages.to_sentence}") if digital.errors.any?
    end
  end
end
