require 'spec_helper'
require 'capybara'

# Make sure Capybara doesn't automatically refresh the page
Capybara.automatic_reload = false

describe "Sector browse page", :js => true do
  before(:each) do
    @s1 = FactoryGirl.create(:sector, layer: 1, name: 'First top level')
    @s2 = FactoryGirl.create(:sector, layer: 2, name: 'First child', parents: [@s1])
    @s3 = FactoryGirl.create(:sector, layer: 3, name: 'First grand child', parents: [@s2])
    @s4 = FactoryGirl.create(:sector, layer: 2, name: 'Second child', parents: [@s1])
    @s5 = FactoryGirl.create(:sector, layer: 3, name: 'Second grand child', parents: [@s4])
    @s6 = FactoryGirl.create(:sector, layer: 1, name: 'Second top level')
  end

  specify "when browsing the main sectors page" do
    visit "/#{APP_SLUG}/browse-sectors"

    within "#sector-navigation" do
      page.should have_css("li>a")
      page.should have_content(@s1.name)
      page.should have_content(@s6.name)
      page.should_not have_content(@s3.name)
    end
  end

  specify "clicking on sectors fetches children" do
    visit "/#{APP_SLUG}/browse-sectors"

    page.should have_content @s1.name
    page.should_not have_content @s2.name

    within "#sector-navigation" do
      click_on @s1.name
    end

    page.should have_content @s2.name
    page.should_not have_content @s3.name

    within "#sector-navigation" do
      click_on @s2.name
    end

    page.should have_content @s3.name
  end

  specify "clicking on sibling sectors collapses other sectors" do
    visit "/#{APP_SLUG}/browse-sectors"

    click_on @s1.name
    click_on @s2.name
    click_on @s4.name
    page.should_not have_content @s3.name
  end

end
