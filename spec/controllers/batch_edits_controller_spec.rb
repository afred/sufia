require 'spec_helper'

describe BatchEditsController do
  before do
    controller.stub(:has_access?).and_return(true)
    @user = FactoryGirl.find_or_create(:user)
    sign_in @user
    User.any_instance.stub(:groups).and_return([])
    controller.stub(:clear_session_user) ## Don't clear out the authenticated session
    request.env["HTTP_REFERER"] = 'test.host/original_page'
  end

  routes { Internal::Application.routes }

  describe "edit" do
    before do
      @one = GenericFile.new(:creator=>"Fred", :language=>'en', :resource_type=>'foo')
      @one.apply_depositor_metadata('mjg36')
      @two = GenericFile.new(:creator=>"Wilma", :publisher=>'Rand McNally', :language=>'en', :resource_type=>'bar')
      @two.apply_depositor_metadata('mjg36')
      @one.save!
      @two.save!
      controller.batch = [@one.pid, @two.pid]
      controller.should_receive(:can?).with(:edit, @one.pid).and_return(true)
      controller.should_receive(:can?).with(:edit, @two.pid).and_return(true)
    end
    it "should be successful" do
      get :edit
      response.should be_successful
      assigns[:terms].should == [:creator, :contributor, :description, :tag, :rights, :publisher, 
                        :date_created, :subject, :language, :identifier, :based_near, :related_url]
      assigns[:show_file].creator.should == ["Fred", "Wilma"]
      assigns[:show_file].publisher.should == ["Rand McNally"]
      assigns[:show_file].language.should == ["en"]
    end
  end
  
  describe "update" do
    before do
      @one = GenericFile.new(:creator=>"Fred", :language=>'en')
      @one.apply_depositor_metadata('mjg36')
      @two = GenericFile.new(:creator=>"Wilma", :publisher=>'Rand McNally', :language=>'en')
      @two.apply_depositor_metadata('mjg36')
      @one.save!
      @two.save!
      controller.batch = [@one.pid, @two.pid]
      controller.should_receive(:can?).with(:edit, @one.pid).and_return(true)
      controller.should_receive(:can?).with(:edit, @two.pid).and_return(true)
    end
    it "should be successful" do
      put :update , update_type:"delete_all"
      response.should be_redirect
      expect {GenericFile.find(@one.id)}.to raise_error(ActiveFedora::ObjectNotFoundError)
      expect {GenericFile.find(@two.id)}.to raise_error(ActiveFedora::ObjectNotFoundError)
    end
    it "should update the records" do
      put :update , update_type:"update", "generic_file"=>{"subject"=>["zzz"]}
      response.should be_redirect
      GenericFile.find(@one.id).subject.should == ["zzz"]
      GenericFile.find(@two.id).subject.should == ["zzz"]
    end
  end

end
