require 'dotenv'
require 'ri_cal'
require 'csv'
require 'open-uri'
require 'grape'
require 'grape-swagger'
require 'logger'
require 'json'
require 'digest'

Dotenv.load

# Until https://github.com/rubyredrick/ri_cal/pull/5 is resolved, we're monkeypatching
class RiCal::Component::Calendar
  def export_x_properties_to(export_stream) #:nodoc:
    x_properties.each do |name, props|
      props.each do | prop |
        export_stream.puts("#{name}#{prop}")
      end
    end
  end
end

module EventCentral


  class Base
  
    @@DEFAULT_MAX_AGE = 600

    attr_accessor :cache_dir
    attr_accessor :logger

    def initialize

      @logger = Logger.new($stderr).tap do |log|
        log.progname = 'EventCentral::Base'
        log.level = Logger.const_get ENV['eventcentral.log_level']
      end

      @cache_dir = ENV['OPENSHIFT_TMP_DIR'] || ENV['eventcentral.cache_dir'] || '/tmp'

    end

    def get_cache_filename(url)
      file = "eventcentral-" + Digest::MD5.hexdigest(url)
      file_path = File.join("", cache_dir, file)
      return file_path
    end

    def fetch(url, max_age=@@DEFAULT_MAX_AGE)
      logger.debug { "fetch(" + url + ", " + max_age.to_s + ")" }
      logger.debug { "cache_dir = " + cache_dir }

      file_path = get_cache_filename(url)

      cached_results = fetch_cached_file(file_path, max_age)

      # if the file does not exist (or if the data is not fresh), we
      #  grab a fresh copy and save it
      if cached_results.nil?
        cached_results = fetch_and_cache(url, file_path)
      end

      return cached_results

    end #fetch()

    def fetch_cached_file(filename, max_age=@@DEFAULT_MAX_AGE)
      # we check if the file -- an MD5 hexdigest of the URL -- exists
      #  in the dir. If it does and the data is fresh, we just read
      #  data from the file and return
      if File.exists? filename
        if Time.now-File.mtime(filename) < max_age
          logger.debug { "using cached = " + filename }
          cached_results = File.new(filename).read 
        end
      end

      return cached_results

    end

    def cache_content(content, file_path)
      File.open(file_path, "w") do |f|
        logger.debug { "using new = " + file_path }
        f << content
      end
    end

    def fetch_contents(url)
      contents = nil
      open(url) do |f| 
        contents = f.read
      end
      return contents
    end

    def fetch_and_cache(url, file_path)

      contents = fetch_contents(url)
      cache_content(contents, file_path)

      return contents

    end

  end #Base

  class CSVFile < Base
    
    attr_accessor :contents
    attr_accessor :url

    def initialize
      super()
      logger.progname = 'EventCentral::CSVFile'
      logger.debug { "Instantiating CSVFile class" }
    end

    def initialize(csv_file_url)
      super()
      logger.progname = 'EventCentral::CSVFile'
      logger.debug { 'Instantiating CSVFile class('+csv_file_url+')' }
      self.url = csv_file_url
      fetch(self.url)
    end

    # overload the parent's fetch to do caching
    def fetch(url, max_age=@@DEFAULT_MAX_AGE)

      if @contents.nil?

        # let EventCentral::Base actually get the contents
        results = super(url, max_age).gsub(/\\"/,'""') 

        # turn nil into empties so the date parser doesn't choke
        CSV::Converters[:blank_to_nil] = lambda do |field|
          field && field.empty? ? nil : field
        end

        # load everything up, 
        # honor the first row as headers, 
        # convert the empties per above
        csv = CSV.new(results, :headers => true, :header_converters => :symbol, :converters => [:all, :blank_to_nil] )

        @contents = csv.to_a.map {|row| row.to_hash }

      end

      logger.debug { "contents now holds " + @contents.to_a.count.to_s + " records"}

      return @contents

    end

  end

  class Calendar < CSVFile

    # Assumes:
    # "Event Name","Start Date","End Date",Country,State,City,Venue,"Region 1","Region 2","Region 3",Contacts,URL,URL2,URL3, Sponsorship,Stakeholders,Type
    #

    attr_accessor :contents

    def initialize(eventcentral_url)
      super(eventcentral_url)
      logger.progname = 'EventCentral::Calendar'
      logger.debug { "Instantiating Calendar class" }
    end

    # removes events from the list, based on the contents of the param argument
    def filter(params)
      logger.debug { "filter(" + params.inspect + ")" }

      unless params[:stakeholder].nil?
        filter_stakeholders(params[:stakeholder])
      end

      unless params[:region].nil?
        filter_region(params[:region])
      end

      unless params[:country].nil?
        filter_country(params[:country])
      end

      return @contents

    end

    def filter_stakeholders(stakeholder)
        logger.debug { "stakeholder filter set: " + stakeholder } 
        logger.debug { "    @contents contains " + @contents.to_a.count.to_s + ")" }
        new_contents = @contents.select {|e|
          #logger.debug { e.to_s }
          unless e[:stakeholders].nil?
            e[:stakeholders].match(stakeholder)
          end
        }
        @contents = new_contents
        logger.debug { "    @contents now contains " + @contents.to_a.count.to_s + ")" }
    end

    def filter_region(region)
      logger.debug { "region filter set: " + region } 
      logger.debug { "    @contents contains " + @contents.to_a.count.to_s + ")" }
      new_contents = @contents.select {|e|
        logger.debug { e.to_s }
        unless e[:region_1].nil?
          e[:region_1].match(region)
        end
      }
      @contents = new_contents
      logger.debug { "    @contents now contains " + @contents.to_a.count.to_s + ")" }
    end

    def filter_country(country)
      logger.debug { "country filter set: " + country } 
      logger.debug { "    @contents contains " + @contents.to_a.count.to_s + ")" }
      new_contents = @contents.select {|e|
        logger.debug { e.to_s }
        unless e[:country].nil?
          e[:country].match(country)
        end
      }
      @contents = new_contents
      logger.debug { "    @contents now contains " + @contents.to_a.count.to_s + ")" }
    end

    def to_json
      logger.debug { "to_json()" }
      JSON.dump @contents
    end

    def to_txt
      logger.debug { "to_txt()" }
      @contents.join("\n")
    end

    def to_ical(cal_name="EventCentral")
      logger.debug { "to_ical()" }

      @calendar = RiCal.Calendar

      @calendar.add_x_property 'X-WR-CALNAME', cal_name

      @contents.each do |row|
        logger.debug { "row: " + row.values.to_s }

        # if they didn't specify a start date, it's dead to us
        unless row[:start_date] =~ /\d\d\d\d-\d\d?-\d\d?/ 
          logger.debug { "No start date, skipping." }
          next
        end

        e = RiCal.Event

        # Create a synthetic "Region" field
        row[:region] = [ [ row[:region_1], row[:region_2], row[:region_3] ]- ["", nil] ].join(", ")
        remaining_keys = row.to_hash.keys
        remaining_keys -= [ :region_1, :region_2, :region_3 ]

        # Create a synthetic Location field
        e.location  = [ [ row[:venue], row[:city], row[:state], row[:country] ] - ["", nil] ].join(", ")
        remaining_keys -= [ :venue, :city, :state, :country ]

        e.summary   = row[:event_name]
        remaining_keys -= [ :event_name ]

        e.dtstart   = Date.strptime(row[:start_date], '%Y-%m-%d')
        remaining_keys -= [ :start_date ]

        unless row[:end_date].nil?
          e.dtend     = Date.strptime(row[:end_date], '%Y-%m-%d')
        end
        remaining_keys -= [ :end_date ]

        unless row[:url].nil?
          e.url       = row[:url]
        end
        remaining_keys -= [ :url ]

        # now dump all fields into the description
        new_description = ""
        remaining_keys.sort.each do |key|
          unless row[key].nil?
            new_description += "#{key.capitalize}: #{row[key]}\n"
          end
        end
        e.description = new_description

        @calendar.add_subcomponent(e)
        #logger.debug { "Added " + e.summary }
      end

      logger.debug { "Exporting..." }
      @calendar.export.to_s

    end #to_ical

  end #Calendar

  class App < Base

    def initialize
      super()
      logger.progname = 'EventCentral::App'
    end

    def self.call(env)
      ec = EventCentral::Calendar.new(ENV['eventcentral.url'])
      [ '200', {'Content-Type' => 'text/calendar'}, [ec.to_ical] ] 
    end

  end #app

  class API < Grape::API

    version 'v1', using: :path

    format :json
    default_error_formatter :txt

    content_type :ical, "text/calendar"
    formatter :ical, lambda { |object, env| object.to_ical }

    # Set access controls to enable documentation
    before do
      header['Access-Control-Allow-Origin'] = '*'
      header['Access-Control-Request-Method'] = '*'
    end

    desc "Returns the version we're working with"
    get :version do
      { :version => version }
    end

    desc "Returns a representation of the EventCentral calendar"
    get :calendar do
      params do
        optional :stakeholder, type: String
        optional :region, type: String
        optional :country, type: String
      end
      ec = EventCentral::Calendar.new(ENV['eventcentral.url'])
      ec.filter(params)
      ec
    end

    add_swagger_documentation

  end #API

end

