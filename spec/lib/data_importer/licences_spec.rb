require 'spec_helper'
require 'data_importer'

describe DataImporter::Licences do
  before :each do
    @sector = FactoryGirl.create(:sector, public_id: 1)
    @activity = FactoryGirl.create(:activity, public_id: 1)
  end

  describe "clean import" do
    it "should import a single licence from a file handle" do
      source = StringIO.new(<<-END)
"SECTOR_OID","SECTOR","BUSINESSACT_ID","ACTIVITY_TITLE","LICENCE_OID","LICENCE","REGULATION_AREA","DA_ENGLAND","DA_SCOTLAND","DA_WALES","DA_NIRELAND","ALL_OF_UK"
"1","Motor vehicle fuel retail","1","Play background music in your premises","1","Licences to play music in a theatre (All UK)","Copyright","1","0","1","0","0"
      END

      importer = DataImporter::Licences.new(source)
      importer.run

      imported_licence = Licence.find_by_public_id(1)
      imported_licence.public_id.should == 1
      imported_licence.name.should == "Licences to play music in a theatre (All UK)"
      imported_licence.regulation_area.should == "Copyright"
      imported_licence.da_england == true
      imported_licence.da_wales == true
      imported_licence.da_scotland == false
      imported_licence.da_northern_ireland == false

      imported_licence_link = LicenceLink.first
      imported_licence_link.sector.should == @sector
      imported_licence_link.activity.should == @activity
      imported_licence_link.licence.should == imported_licence
      LicenceLink.all.length.should == 1
    end
    it "should update the licence if one with the same public_id already exists" do
      FactoryGirl.create(:licence, public_id: 1, name: "Test Name", da_england: false)

      source = StringIO.new(<<-END)
"SECTOR_OID","SECTOR","BUSINESSACT_ID","ACTIVITY_TITLE","LICENCE_OID","LICENCE","REGULATION_AREA","DA_ENGLAND","DA_SCOTLAND","DA_WALES","DA_NIRELAND","ALL_OF_UK"
"1","Motor vehicle fuel retail","1","Play background music in your premises","1","Licences to play music in a theatre (All UK)","Copyright","1","1","1","1","0"
      END

      importer = DataImporter::Licences.new(source)
      importer.run

      imported_licence = Licence.find_by_public_id(1)
      imported_licence.public_id.should == 1
      imported_licence.name.should == "Licences to play music in a theatre (All UK)"
      imported_licence.da_england.should be_true
    end
    it "should fail early if the sector does not exist" do
      source = StringIO.new(<<-END)
"SECTOR_OID","SECTOR","BUSINESSACT_ID","ACTIVITY_TITLE","LICENCE_OID","LICENCE","REGULATION_AREA","DA_ENGLAND","DA_SCOTLAND","DA_WALES","DA_NIRELAND","ALL_OF_UK"
"2","Motor vehicle fuel retail","1","Play background music in your premises","1","Licences to play music in a theatre (All UK)","Copyright","1","1","1","1","0"
      END

      importer = DataImporter::Licences.new(source)
      lambda do
        importer.run
      end.should raise_error
      imported_licence = Licence.find_by_public_id(1)
      imported_licence.should == nil
    end
    it "should fail early if the activity does not exist" do
      source = StringIO.new(<<-END)
"SECTOR_OID","SECTOR","BUSINESSACT_ID","ACTIVITY_TITLE","LICENCE_OID","LICENCE","REGULATION_AREA","DA_ENGLAND","DA_SCOTLAND","DA_WALES","DA_NIRELAND","ALL_OF_UK"
"1","Motor vehicle fuel retail","2","Play background music in your premises","1","Licences to play music in a theatre (All UK)","Copyright","0","0","0","0","1"
      END

      importer = DataImporter::Licences.new(source)
      lambda do
        importer.run
      end.should raise_error
      imported_licence = Licence.find_by_public_id(1)
      imported_licence.should == nil
    end
    it "should add links for all layer3 sectors if a layer2 sector id is provided" do
      sector1 = FactoryGirl.create(:sector, public_id: 2, layer2_id: 101)
      sector2 = FactoryGirl.create(:sector, public_id: 3, layer2_id: 101)
      sector3 = FactoryGirl.create(:sector, public_id: 4, layer2_id: 102)

      source = StringIO.new(<<-END)
"SECTOR_OID","SECTOR","BUSINESSACT_ID","ACTIVITY_TITLE","LICENCE_OID","LICENCE","REGULATION_AREA","DA_ENGLAND","DA_SCOTLAND","DA_WALES","DA_NIRELAND","ALL_OF_UK"
"101","Motor vehicle fuel retail","1","Play background music in your premises","1","Licences to play music in a theatre (All UK)","Copyright","1","0","1","0","0"
      END

      importer = DataImporter::Licences.new(source)
      importer.run

      imported_links = LicenceLink.all
      imported_links.length.should == 2
      sectors = imported_links.map(&:sector)
      sectors.should include(sector1)
      sectors.should include(sector2)
      sectors.should_not include(sector3)
    end
    it "should add links for all layer3 sectors if a layer1 sector id is provided" do
      sector1 = FactoryGirl.create(:sector, public_id: 2, layer1_id: 101)
      sector2 = FactoryGirl.create(:sector, public_id: 3, layer1_id: 101)
      sector3 = FactoryGirl.create(:sector, public_id: 4, layer1_id: 102)

      source = StringIO.new(<<-END)
"SECTOR_OID","SECTOR","BUSINESSACT_ID","ACTIVITY_TITLE","LICENCE_OID","LICENCE","REGULATION_AREA","DA_ENGLAND","DA_SCOTLAND","DA_WALES","DA_NIRELAND","ALL_OF_UK"
"101","Motor vehicle fuel retail","1","Play background music in your premises","1","Licences to play music in a theatre (All UK)","Copyright","1","0","1","0","0"
      END

      importer = DataImporter::Licences.new(source)
      importer.run

      imported_links = LicenceLink.all
      imported_links.length.should == 2
      sectors = imported_links.map(&:sector)
      sectors.should include(sector1)
      sectors.should include(sector2)
      sectors.should_not include(sector3)
    end
    it "should not create a new licence_link if it already exists" do
      require 'ruby-debug'
      @licence = FactoryGirl.create(:licence, public_id: 1, name: "Test Name", da_england: false)
      licence_link = FactoryGirl.create(:licence_link, sector: @sector, activity: @activity, licence: @licence)

      source = StringIO.new(<<-END)
"SECTOR_OID","SECTOR","BUSINESSACT_ID","ACTIVITY_TITLE","LICENCE_OID","LICENCE","REGULATION_AREA","DA_ENGLAND","DA_SCOTLAND","DA_WALES","DA_NIRELAND","ALL_OF_UK"
"1","Motor vehicle fuel retail","1","Play background music in your premises","1","Licences to play music in a theatre (All UK)","Copyright","1","1","1","1","0"
      END

      importer = DataImporter::Licences.new(source)
      importer.run

      LicenceLink.first.should == licence_link
    end
  end

  describe "devolved authorities" do
    it "should mark all devolved authority flags true if DA_ALL is set" do
      source = StringIO.new(<<-END)
"SECTOR_OID","SECTOR","BUSINESSACT_ID","ACTIVITY_TITLE","LICENCE_OID","LICENCE","REGULATION_AREA","DA_ENGLAND","DA_SCOTLAND","DA_WALES","DA_NIRELAND","ALL_OF_UK"
"1","Motor vehicle fuel retail","1","Play background music in your premises","1","Licences to play music in a theatre (All UK)","Copyright","0","0","0","0","1"
      END

      importer = DataImporter::Licences.new(source)
      importer.run

      imported_licence = Licence.find_by_public_id(1)
      imported_licence.da_england.should == true
      imported_licence.da_scotland.should == true
      imported_licence.da_wales.should == true
      imported_licence.da_northern_ireland.should == true
    end
  end

  describe "open_data_file" do
    it "should open the input data file" do
      tmpfile = Tempfile.new("licences.csv")
      DataImporter::Licences.expects(:data_file_path).with("licences.csv").returns(tmpfile.path)

      DataImporter::Licences.open_data_file
    end
    it "should fail if the input data file does not exist" do
      DataImporter::Licences.expects(:data_file_path).with("licences.csv").returns("/example/licences.csv")

      lambda do
        DataImporter::Licences.open_data_file
      end.should raise_error(Errno::ENOENT)
    end
  end
end