require 'dotenv'
require 'ri_cal'
require 'csv'
require 'open-uri'
require 'grape'
require 'logger'
require 'json'

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

    def initialize
      @logger = Logger.new($stderr).tap do |log|
        log.progname = 'EventCentral::Base'
        log.level = Logger.const_get ENV['eventcentral.log_level']
      end
    end

    def logger
      @logger
    end

    def logger=(logger)
      @logger = logger
    end

  end

  class Calendar < Base

    # Assumes:
    # "Event Name","Start Date","End Date",Country,State,City,Venue,"Region 1","Region 2","Region 3",Contacts,URL,URL2,URL3, Sponsorship,Stakeholders,Type
    #

    def initialize
      super()
      logger.progname = 'EventCentral::Calendar'
      logger.debug { "Instantiating Calendar class" }

      # Contains the CSV text from EventCentral's website
      @raw_csv = nil

      # Contains the parsed CSV object
      @csv = nil

      # the hash we work with
      @csv_data = nil

      # Calendar object, used for to_ical converstion
      @calendar = nil

    end

    # Load raw CSV from EventCentral into a formal CSV object
    def load_csv
      logger.debug { "Loading from " + ENV['eventcentral.url'] }

      unless @csv_data.nil?
        logger.debug { "csv already holds " + @csv_data.to_a.count.to_s + " items, returning" }
        return @csv_data
      end

      # fetch CSV from EventCentral. If that doesn't work, call the whole thing off.
      open(ENV['eventcentral.url']) do |f| 
        @raw_csv = f.read.gsub(/\\"/,'""') 
      end

      #logger.debug { "raw_csv = " + @raw_csv }

      # turn nil into empties so the date parser doesn't choke
      CSV::Converters[:blank_to_nil] = lambda do |field|
        field && field.empty? ? nil : field
      end

      # load everything up, honor the first row as headers, convert the empties like we told them
      csv = CSV.new(@raw_csv, :headers => true, :header_converters => :symbol, :converters => [:all, :blank_to_nil] )

      @csv_data = csv.to_a.map {|row| row.to_hash }

      logger.debug { "csv_data now holds " + @csv_data.to_a.count.to_s + " records"}

    end

    # removes events from the list, based on the contents of the param argument
    def filter(params)
      logger.debug { "filter(" + params.inspect + ")" }

      load_csv

      unless params[:stakeholder].nil?
        filter_stakeholders(params[:stakeholder])
      end

      unless params[:region].nil?
        filter_region(params[:region])
      end

      unless params[:country].nil?
        filter_country(params[:country])
      end

      @cvs_data

    end

    def filter_stakeholders(stakeholder)
        logger.debug { "stakeholder filter set: " + stakeholder } 
        logger.debug { "    @csv_data contains " + @csv_data.to_a.count.to_s + ")" }
        new_csv_data = @csv_data.select {|e|
          logger.debug { e.to_s }
          unless e[:stakeholders].nil?
            e[:stakeholders].match(stakeholder)
          end
        }
        @csv_data = new_csv_data
        logger.debug { "    @csv_data now contains " + @csv_data.to_a.count.to_s + ")" }
    end

    def filter_region(region)
      logger.debug { "region filter set: " + region } 
      logger.debug { "    @csv_data contains " + @csv_data.to_a.count.to_s + ")" }
      new_csv_data = @csv_data.select {|e|
        logger.debug { e.to_s }
        unless e[:region_1].nil?
          e[:region_1].match(region)
        end
      }
      @csv_data = new_csv_data
      logger.debug { "    @csv_data now contains " + @csv_data.to_a.count.to_s + ")" }
    end

    def filter_country(country)
      logger.debug { "country filter set: " + country } 
      logger.debug { "    @csv_data contains " + @csv_data.to_a.count.to_s + ")" }
      new_csv_data = @csv_data.select {|e|
        logger.debug { e.to_s }
        unless e[:country].nil?
          e[:country].match(country)
        end
      }
      @csv_data = new_csv_data
      logger.debug { "    @csv_data now contains " + @csv_data.to_a.count.to_s + ")" }
    end

    def to_json
      logger.debug { "to_json()" }
      load_csv
      JSON.dump @csv_data
    end

    def to_txt
      logger.debug { "to_txt()" }
      load_csv
      @csv_raw
    end

    def to_ical(cal_name="EventCentral")
      logger.debug { "to_ical()" }

      load_csv

      @calendar = RiCal.Calendar

      @calendar.add_x_property 'X-WR-CALNAME', cal_name

      @csv_data.each do |row|
        #logger.debug { "row: " + row.values.to_s }

        # if they didn't specify a start date, it's dead to us
        if row[:start_date].nil?
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
      ec = EventCentral::Calendar.new
      [ '200', {'Content-Type' => 'text/calendar'}, [ec.to_ical] ] 
    end

  end #app

  class API < Grape::API

    version 'v1', using: :path

    format :json
    default_error_formatter :txt

    content_type :ical, "text/calendar"
    formatter :ical, lambda { |object, env| object.to_ical }

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
      ec = EventCentral::Calendar.new
      ec.filter(params)
      ec
    end

  end #API

end

