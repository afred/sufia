require 'spec_helper'

describe IngestLocalFileJob do
  let(:user) { FactoryGirl.find_or_create(:jill) }

  let (:generic_file) do
    GenericFile.new.tap { |f| f.apply_depositor_metadata(user); f.save }
  end

  subject(:job) { IngestLocalFileJob.new(generic_file.id, @mock_upload_directory, "world.png", user.user_key) }

  before do
    @mock_upload_directory = 'spec/mock_upload_directory'
    Dir.mkdir @mock_upload_directory unless File.exists? @mock_upload_directory
    FileUtils.copy(File.expand_path('../../fixtures/world.png', __FILE__), @mock_upload_directory)
  end

  after do
    generic_file.destroy
  end

  it "should have attached a file" do
    job.run
    generic_file.reload.content.size.should == 4218
  end

  describe "virus checking" do
    it "should run virus check" do
      expect(Sufia::GenericFile::Actions).to receive(:virus_check).twice.and_return(0)
      job.run
    end
    it "should abort if virus check fails" do
      Sufia::GenericFile::Actions.stub(:virus_check).and_raise(Sufia::VirusFoundError.new('A virus was found'))
      job.run
      expect(user.mailbox.inbox.first.subject).to eq("Local file ingest error")
    end
  end
end
