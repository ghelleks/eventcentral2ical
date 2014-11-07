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

  describe "#fetch_cached_file" do
    it "returns content of the specified cache file" do
      filename = 'sample-cache.txt'
      @e.cache_content('this is a test', filename)
      expect(@e.fetch_cached_file(filename).length).to be > 0
      File.delete(filename)
    end
  end

  describe "#fetch_and_cache" do
    it "fetches a url and caches it for later" do
    end
  end

end

describe "EventCentral::CSVFile" do

  before :all do
    @url = 'spec/sample.csv'
    @csv = EventCentral::CSVFile.new('spec/sample.csv')
  end

  describe "#new" do
    it "populates based on the given string" do
      expect(@csv.contents.length).to be > 0
    end
  end

  describe "#fetch" do

    it "caches the data from a URL" do
      @csv.fetch(@url)
      expect(@csv.contents.length).to be > 0
    end

  end

  describe "#url" do
    it "is a string" do
      expect(@csv.url).to be_a(String)
    end

    it "can be set" do
      @csv.url = "something"
      expect(@csv.url).to eq("something")
    end
  end

  describe "#contents" do

    it "is an array" do
      expect(@csv.contents).to be_an(Array)
    end

    it "can be set" do
      @csv.contents = [ "foo", "bar", "baz" ]
      expect(@csv.contents.length).to be == 3
    end
    
  end

end


describe "EventCentral::Calendar" do

  before :all do
    @e = EventCentral::Calendar.new 'spec/sample.csv'
  end

  it "is a EventCentral::CSVFile" do
    expect(@e).to be_an(EventCentral::CSVFile)
  end

  describe "#new" do
    it "sets the logging progname to EventCentral::Calendar" do
      expect(@e.logger.progname).to eq("EventCentral::Calendar")
    end
    it "accepts a URL as the source file" do
      expect(@e.contents.length).to be > 0
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
