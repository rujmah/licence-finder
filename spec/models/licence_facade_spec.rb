require 'spec_helper'

describe LicenceFacade do

  describe "create_for_licences" do
    before :each do
      GdsApi::Publisher.any_instance.stubs(:licences_for_ids).returns([])
      @l1 = FactoryGirl.create(:licence)
      @l2 = FactoryGirl.create(:licence)
    end

    it "should query publisher for licence details" do
      GdsApi::Publisher.any_instance.expects(:licences_for_ids).with([@l1.correlation_id, @l2.correlation_id]).returns([])
      LicenceFacade.create_for_licences([@l1, @l2])
    end

    it "should skip querying publisher if not given any licences" do
      GdsApi::Publisher.any_instance.unstub(:licences_for_ids) # clear the stub above, otherwise the next line won't work
      GdsApi::Publisher.any_instance.expects(:licences_for_ids).never()
      LicenceFacade.create_for_licences([])
    end

    it "should construct Facades for each licence maintaining order" do
      result = LicenceFacade.create_for_licences([@l1, @l2])
      result.map(&:licence).should == [@l1, @l2]
    end

    it "should add the publisher details to each Facade where details exist" do
      pub_data2 = OpenStruct.new(:licence_identifier => @l2.correlation_id.to_s)
      GdsApi::Publisher.any_instance.stubs(:licences_for_ids).returns([pub_data2])

      result = LicenceFacade.create_for_licences([@l1, @l2])
      result[0].licence.should == @l1
      result[0].publisher_data.should == nil
      result[1].licence.should == @l2
      result[1].publisher_data.should == pub_data2
    end

    context "when publisher api returns nil" do
      before :each do
        GdsApi::Publisher.any_instance.stubs(:licences_for_ids).returns(nil)
      end

      it "should continue with no publisher data" do
        result = LicenceFacade.create_for_licences([@l1, @l2])
        result[0].licence.should == @l1
        result[0].publisher_data.should == nil
        result[1].licence.should == @l2
        result[1].publisher_data.should == nil
      end

      it "should log the error" do
        Rails.logger.expects(:warn).with("Error fetching licence details from publisher")
        LicenceFacade.create_for_licences([@l1, @l2])
      end
    end

    context "when publisher times out" do
      before :each do
        GdsApi::Publisher.any_instance.stubs(:licences_for_ids).raises(GdsApi::TimedOutException)
      end

      it "should continue with no publisher data" do
        result = LicenceFacade.create_for_licences([@l1, @l2])
        result[0].licence.should == @l1
        result[0].publisher_data.should == nil
        result[1].licence.should == @l2
        result[1].publisher_data.should == nil
      end

      it "should log the error" do
        Rails.logger.expects(:warn).with("Timeout fetching licence details from publisher")
        LicenceFacade.create_for_licences([@l1, @l2])
      end
    end
  end

  describe "attribute accessors" do
    before :each do
      @licence = FactoryGirl.create(:licence)
    end

    context "with publisher data" do
      before :each do
        @pub_data = OpenStruct.new(:licence_identifier => @licence.correlation_id.to_s,
                                   :title => "Publisher title",
                                   :slug => "licence-slug",
                                   :licence_short_description => "Short description of licence")
        @lf = LicenceFacade.new(@licence, @pub_data)
      end

      it "should be published" do
        @lf.published?.should == true
      end

      it "should return the publisher title" do
        @lf.title.should == @pub_data.title
      end

      it "should return the frontend url" do
        @lf.url.should == "/#{@pub_data.slug}"
      end

      it "should return the publisher short description" do
        @lf.short_description.should == @pub_data.licence_short_description
      end
    end

    context "without publisher data" do
      before :each do
        @lf = LicenceFacade.new(@licence, nil)
      end

      it "should not be published?" do
        @lf.published?.should == false
      end

      it "should return the licence name" do
        @lf.title.should == @licence.name
      end

      it "should return nil for the url" do
        @lf.url.should == nil
      end

      it "should return nil for the short_description" do
        @lf.short_description.should == nil
      end
    end
  end
end
