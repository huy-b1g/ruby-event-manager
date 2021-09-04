# frozen_string_literal: true

require 'erb'
require 'csv'
require 'google/apis/civicinfo_v2'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_homephone(homephone)
  only_number_homephone = homephone.delete('^0-9')
  case true
  when only_number_homephone.length < 10
    'Bad number'
  when only_number_homephone.length == 10
    only_number_homephone
  when only_number_homephone.length == 11 && only_number_homephone[0] == '1'
    only_number_homephone[1..-1]
  when only_number_homephone.length == 11 && only_number_homephone[0] != '1'
    'Bad number'
  when only_number_homephone.length > 11
    'Bad number'
  end
end

def clean_regdate_to_time(regdate)
  regdate = reformat_regdate(regdate)
  DateTime.strptime(regdate, '%m/%d/%Y %k:%M').hour
end

def clean_regdate_to_wday(regdate)
  reformat_regdate(regdate)
  wday = DateTime.strptime(regdate, '%m/%d/%Y').wday
  wday_arr = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
  wday_arr[wday]
end

def reformat_regdate(regdate)
  regdate.insert(0, '0').insert(3, '0') if regdate[6] == ' '
  regdate.insert(6, '20') if regdate[6] != '2'
end

def find_peak_regdate(regdate)
  freq = regdate.each_with_object(Hash.new(0)) { |v, h| h[v] += 1; }
  arr = freq.sort_by { |_k, v| v }.reverse
  arr.each { |k, v| puts "#{k}: #{v}" }
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)
reg_hours = []
reg_wdays = []
# Test Clean Phone Numbers
contents.each do |row|
  # homephone = clean_homephone(row[:homephone])
  # puts homephone
  reg_hours << clean_regdate_to_time(row[:regdate])
  reg_wdays << clean_regdate_to_wday(row[:regdate])
end
puts 'Time Targeting:'
find_peak_regdate(reg_hours)

puts 'Day of the Week Targeting:'
find_peak_regdate(reg_wdays)
# template_letter = File.read('form_letter.erb')
# erb_template = ERB.new template_letter
# contents.each do |row|
#   id = row[0]
#   name = row[:first_name]
#   zipcode = clean_zipcode(row[:zipcode])
#   legislators = legislators_by_zipcode(zipcode)
#   form_letter = erb_template.result(binding)
#   save_thank_you_letter(id, form_letter)
# end
