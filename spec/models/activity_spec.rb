require 'spec_helper'

describe Activity do
  it "should use the correct field types on the model" do
    Activity.safely.create!(
      :public_id => 42,
      :correlation_id => 24,
      :name => "Some Activity"
    )
    activity = Activity.first
    activity.public_id.should == 42
    activity.correlation_id.should == 24
    activity.name.should == "Some Activity"
  end

  describe "validations" do
    before :each do
      @activity = FactoryGirl.build(:activity)
    end

    it "should have a database level uniqueness constraint on public_id" do
      FactoryGirl.create(:activity, :public_id => 42)
      @activity.public_id = 42
      lambda do
        @activity.safely.save
      end.should raise_error(Mongo::OperationFailure)
    end

    it "should have a database level uniqueness constraint on correlation_id" do
      FactoryGirl.create(:activity, :correlation_id => 42)
      @activity.correlation_id = 42
      lambda do
        @activity.safely.save
      end.should raise_error(Mongo::OperationFailure)
    end

    it "should require a name" do
      @activity.name = ''
      @activity.should_not be_valid
    end
  end

  describe "associations" do
    it "has many sectors" do
      s1 = FactoryGirl.create(:sector)
      s2 = FactoryGirl.create(:sector)

      a = FactoryGirl.build(:activity)
      a.sectors << s1
      a.sectors << s2
      a.save!

      a.reload
      a.sectors.should == [s1, s2]
    end
  end

  describe "retreival" do
    describe "find_by_public_id" do
      before :each do
        @activity = FactoryGirl.create(:activity)
      end

      it "should be able to retrieve by public_id" do
        found_activity = Activity.find_by_public_id(@activity.public_id)
        found_activity.should == @activity
      end

      it "should fail to retrieve a non-existent public_id" do
        found_activity = Activity.find_by_public_id(@activity.public_id + 1)
        found_activity.should == nil
      end
    end

    describe "find_by_public_ids" do
      before :each do
        @a1 = FactoryGirl.create(:activity, public_id: 10)
        @a2 = FactoryGirl.create(:activity, public_id: 11)
        @a3 = FactoryGirl.create(:activity, public_id: 12)
      end

      it "should return the activities for the given id's" do
        found_activities = Activity.find_by_public_ids([10, 11])
        found_activities.to_a.should =~ [@a1, @a2]
      end

      it "should skip any non-existent activities" do
        found_activities = Activity.find_by_public_ids([10, 12, 13])
        found_activities.to_a.should =~ [@a1, @a3]
      end
    end

    describe "find_by_correlation_id" do
      before :each do
        @activity = FactoryGirl.create(:activity)
      end

      it "should be able to retrieve by correlation_id" do
        found_activity = Activity.find_by_correlation_id(@activity.correlation_id)
        found_activity.should == @activity
      end

      it "should fail to retrieve a non-existent correlation_id" do
        found_activity = Activity.find_by_correlation_id(@activity.correlation_id + 1)
        found_activity.should == nil
      end
    end

    describe "find_by_sectors" do
      before :each do
        @s1 = FactoryGirl.create(:sector, :name => "Fooey Sector")
        @s2 = FactoryGirl.create(:sector, :name => "Kablooey Sector")
        @s3 = FactoryGirl.create(:sector, :name => "Gooey Sector")

        @a1 = FactoryGirl.create(:activity, :name => "Fooey Activity", :sectors => [@s1])
        @a2 = FactoryGirl.create(:activity, :name => "Kablooey Activity", :sectors => [@s2])
        @a3 = FactoryGirl.create(:activity, :name => "Gooey Activity", :sectors => [@s3])
        @a4 = FactoryGirl.create(:activity, :name => "Kabloom", :sectors => [@s1, @s2])
        @a5 = FactoryGirl.create(:activity, :name => "Transmogrifying", :sectors => [@s1, @s3])
      end

      it "should return activities relating to the given sectors" do
        Activity.find_by_sectors([@s2, @s3]).to_a.should =~ [@a2, @a3, @a4, @a5]
      end

      it "should only return each activity once" do
        Activity.find_by_sectors([@s1, @s3]).to_a.should =~ [@a1, @a3, @a4, @a5]
      end

      it "returns activities in a way that's chainable with other scopes" do
        Activity.find_by_sectors([@s2, @s3]).ascending(:name).should == [@a3, @a2, @a4, @a5]
      end
    end
  end

  specify "to_s returns the name" do
    a = FactoryGirl.build(:activity, :name => "Foo Activity")
    a.to_s.should == "Foo Activity"
  end

  describe "auto incrementing public_id" do
    it "should set the public_id to the next free public_id on save" do
      activity = FactoryGirl.build(:activity)
      activity.public_id.should == nil
      activity.save!
      activity.public_id.should == 1

      activity = FactoryGirl.build(:activity)
      activity.public_id.should == nil
      activity.save!
      activity.public_id.should == 2
    end

    it "should use a separate sequence for each model" do
      activity = FactoryGirl.create(:activity)
      activity.public_id.should == 1
      FactoryGirl.create(:licence)
      activity = FactoryGirl.create(:activity)
      activity.public_id.should == 2
    end
  end
end
