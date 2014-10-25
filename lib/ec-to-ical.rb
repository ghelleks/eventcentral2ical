#
## ec-to-ical.rb
#
#
require 'rack'

require 'ri_cal'
require 'csv'
require 'open-uri'

def fetch_csv
  url = 'https://redhat.g2planet.com/redhat_ec/confirmed_calendar.php?output=csv'
  #url = 'calendar.csv'
  csv_text=''
  open(url) do |f| csv_text = f.read.gsub(/\\"/,'""') end
  return csv_text
end

def parse_csv(csv_text)

  # turn nil into empties so the date parser doesn't choke
  CSV::Converters[:blank_to_nil] = lambda do |field|
      field && field.empty? ? nil : field
  end

  csv = CSV.new(csv_text, :headers => true, :header_converters => :symbol, :converters => [:all, :blank_to_nil] )

  return csv.to_a.map

end

def build_cal(event_list)

  RiCal.Calendar do |cal|

    event_list.each do |row|
      row.to_hash

      # if they didn't specify a start date, it's dead to us
      if row[:start_date].nil?
        next
      end

      # if they didn't specify an end date, make it a one-day event
      #if row[:end_date].nil?
      #  row[:end_date] = row[:start_date]
      #end

      cal.event do |e|
        
        # Create a synthetic "Region" field
        row[:region] = [ [ row[:region_1], row[:region_2], row[:region_3] ]- ["", nil] ].join(", ")
        remaining_keys = row.to_hash.keys
        remaining_keys -= [ :region_1, :region_2, :region_3 ]

        # Create a synthetic Location field
        e.location  = [ [ row[:venue], row[:city], row[:state], row[:country] ] - ["", nil] ].join(", ")
        remaining_keys -= [ :venue, :city, :state, :country ]

        e.summary   = row[:event_name]
        remaining_keys -= [ :event_name ]

        e.dtstart   = DateTime.strptime(row[:start_date], '%Y-%m-%d').with_floating_timezone 
        remaining_keys -= [ :start_date ]

        unless row[:end_date].nil?
          e.dtend     = DateTime.strptime(row[:end_date], '%Y-%m-%d').with_floating_timezone 
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

      end
    end
  end

end


# Assumes:
# "Event Name","Start Date","End Date",Country,State,City,Venue,"Region 1","Region 2","Region 3",Contacts,URL,URL2,URL3, Sponsorship,Stakeholders,Type

app = Proc.new do |env|
  csv_text = fetch_csv()
  map = parse_csv(csv_text)
  cal = build_cal(map)

  ['200', {'Content-Type' => 'text/calendar'}, [cal.export] ]

end

Rack::Handler::WEBrick.run app



