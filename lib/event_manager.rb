if File.exist?('event_attendees.csv') == true
  lines = File.readlines('event_attendees.csv')
  lines.each_with_index do |line, idx|
    next if idx == 0
    array_row = line.split(",")
    first_name = array_row[2]
    puts first_name
  end
end

