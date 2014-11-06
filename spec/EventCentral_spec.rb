require 'spec_helper.rb'

describe 'EventCentral::Base' do

  before :all do
    @e = EventCentral::Base.new
  end
 
  before :each do
    # TK
  end

  describe '#new()' do

    it "has a cache directory" do
      expect(@e.cache_dir).to_not be_nil
    end

    it "has a logging facility" do
      expect(@e.logger).to_not be_nil
    end

  end

  describe '#get_cache_filename' do
    it "returns the location of a url's cache results" do
      # TK
    end
  end

  describe '#fetch_contents' do
    it "returns the content of a URL" do
      expect(@e.fetch_contents('spec/sample.csv').length).to be > 0
    end
  end

  describe '#cache_content' do
    it "saves content to the specified cache file" do
      filename = 'sample-cache.txt'
      @e.cache_content('this is a test', filename)
      expect(File.size(filename)).to be > 0
      File.delete(filename)
    end
  end

  describe "#fetch_and_cache" do
    it "fetches a url and caches it for later" do
    end
  end

end

describe "EventCentral::Calendar" do

  before :all do
    @e = EventCentral::Calendar.new
  end

  describe "#new" do
    it "sets the logging progname to EventCentral::Calendar" do
      expect(@e.logger.progname).to eq("EventCentral::Calendar")
    end
  end

  describe "#load_csv" do
    it "draws the CSV data into memory" do
    end
  end

  describe "#filter" do
    it "runs the proper filters based on the provided options" do
    end
  end

  describe "#filter_stakeholders" do
    it "filters the results by the contents of the stakeholders field" do
    end
  end

  describe "#filter_region" do
    it "filters the results by the region_1 field" do
    end
  end

  describe "#filter_country" do
    it "filters the results by the country field" do
    end
  end

  describe "#to_json" do
    it "formats the results in JSON" do
    end
  end

  describe "#to_txt" do
    it "formats the results in plain text" do
    end
  end

  describe "#to_ical" do
    it "formats the results in ICalendar" do
    end
  end

end

