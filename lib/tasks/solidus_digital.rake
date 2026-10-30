# frozen_string_literal: true

namespace :solidus_digital do
  desc "Attach files stored by the Paperclip versions (private/digitals/:id/:filename) to Active Storage"
  task migrate_paperclip_files: :environment do
    root = Pathname.new(ENV.fetch("PAPERCLIP_FILES_ROOT", Rails.root.join("private/digitals").to_s))
    missing = []
    Spree::Digital.where.missing(:attachment_attachment).find_each do |digital|
      path = root.join(digital.id.to_s, digital.attachment_file_name.to_s)
      unless digital.attachment_file_name? && path.file?
        missing << digital.id
        warn("Missing file for digital #{digital.id}: #{path}")
        next
      end

      path.open { |io| digital.attachment.attach(io:, filename: digital.attachment_file_name, content_type: digital.attachment_content_type) }
      warn("Could not attach digital #{digital.id}: #{digital.errors.full_messages.to_sentence}") if digital.errors.any?
    end
    abort "Missing files for digitals: #{missing.join(", ")}. Stage Paperclip files under PAPERCLIP_FILES_ROOT/:id/:filename and retry." if missing.any?
  end
end
