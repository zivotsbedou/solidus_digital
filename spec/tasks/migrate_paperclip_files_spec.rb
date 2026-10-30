# frozen_string_literal: true

require "spec_helper"
require "rake"

RSpec.describe "solidus_digital:migrate_paperclip_files" do
  let(:task) { Rake::Task["solidus_digital:migrate_paperclip_files"] }
  let!(:digital) { create(:digital) }

  before do
    load File.expand_path("../../lib/tasks/solidus_digital.rake", __dir__) unless Rake::Task.task_defined?("solidus_digital:migrate_paperclip_files")
    Rake::Task.define_task(:environment)
    task.reenable
    digital.attachment.purge
    digital.update_columns(attachment_file_name: "book.epub", attachment_content_type: "application/epub+zip")
  end

  it "attaches a staged remote file and skips it on reruns" do
    Dir.mktmpdir do |dir|
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("PAPERCLIP_FILES_ROOT", anything).and_return(dir)
      path = Pathname.new(dir).join(digital.id.to_s, "book.epub")
      path.dirname.mkpath
      path.write("original remote content")
      task.invoke
      expect(digital.reload.attachment.download).to eq("original remote content")
      path.delete
      task.reenable
      expect { task.invoke }.not_to raise_error
    end
  end

  it "fails visibly when a source file was not staged" do
    Dir.mktmpdir do |dir|
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("PAPERCLIP_FILES_ROOT", anything).and_return(dir)
      expect { task.invoke }.to raise_error(SystemExit)
      expect(digital.reload.attachment).not_to be_attached
    end
  end
end
