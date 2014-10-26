require 'ri_cal'
require 'csv'
require 'open-uri'
require 'grape'
require 'logger'

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

  class Calendar

    @@logger = Logger.new(STDERR)
    @@logger.level = Logger::ERROR
    @@logger.progname = 'EventCentral::Calendar'

    # Assumes:
    # "Event Name","Start Date","End Date",Country,State,City,Venue,"Region 1","Region 2","Region 3",Contacts,URL,URL2,URL3, Sponsorship,Stakeholders,Type
    #

    def initialize
      @@logger.debug { "Instantiating Calendar class" }

      # Where we'll be getting all our data
      @URL = 'https://redhat.g2planet.com/redhat_ec/confirmed_calendar.php?output=csv'

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
    def load
      @@logger.debug { "Loading from " + @URL }

      # fetch CSV from EventCentral. If that doesn't work, call the whole thing off.
      open(@URL) do |f| 
        @raw_csv = f.read.gsub(/\\"/,'""') 
      end

      @@logger.debug { "raw_csv = " + @raw_csv }

      # turn nil into empties so the date parser doesn't choke
      CSV::Converters[:blank_to_nil] = lambda do |field|
        field && field.empty? ? nil : field
      end

      # load everything up, honor the first row as headers, convert the empties like we told them
      csv = CSV.new(@raw_csv, :headers => true, :header_converters => :symbol, :converters => [:all, :blank_to_nil] )

      @csv_data = csv.to_a.map {|row| row.to_hash }

      @@logger.debug { "csv_data: " + csv.to_a.count.to_s }

    end

    def to_json
      @@logger.debug { "to_json()" }
    end

    def to_ical(cal_name="EventCentral")
      @@logger.debug { "to_ical()" }

      if @csv_data.nil?
        @@logger.debug { "CSV was empty, calling loader." }
        self.load
        @@logger.debug { "csv now holds " + @csv_data.to_a.count.to_s + " items" }
      end

      @calendar = RiCal.Calendar


      @calendar.add_x_property 'X-WR-CALNAME', cal_name

      @csv_data.each do |row|
        @@logger.debug { "row: " + row.values.to_s }

        # if they didn't specify a start date, it's dead to us
        if row[:start_date].nil?
          @@logger.debug { "No start date, skipping." }
          next
        end

        e = RiCal.Event
        @@logger.debug { "New event..." }

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
        @@logger.debug { "Finished " + e.summary }
      end

      @@logger.debug { "Exporting..." }
      @calendar.export.to_s

    end #to_ical

  end #Calendar

  class App

    def self.call(env)
      ec = EventCentral::Calendar.new
      [ '200', {'Content-Type' => 'text/calendar'}, [ec.to_ical] ] 
    end

  end #app

  class API < Grape::API

    version 'v1', using: :path
    format :json
    content_type :txt, "text/plain"
    content_type :ical, "text/calendar"
    default_error_formatter :txt

    formatter :ical, lambda { |object, env| object.to_ical }

    resource :calendar do
      desc "Return an EventCentral resource"
      get '' do
        ec = new EventCentral::Calendar
        ec.to_json
      end
    end

  end #API

end

