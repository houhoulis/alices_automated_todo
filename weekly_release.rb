require 'net/http'
require 'open-uri' # to call URI.open (why is this needed, even after requiring net/http?)
require 'json'
require 'twilio-ruby'

GITHUB_TOKEN = ENV['GITHUB_TOKEN'] # Personal access token from https://github.com/settings/tokens
TWILIO_SID = ENV['TWILIO_ACCOUNT_SID'] # Account SID from twilio.com/console
TWILIO_TOKEN = ENV['TWILIO_AUTH_TOKEN'] # Auth Token from twilio.com/console
TWILIO_PHONE = ENV['MY_TWILIO_PHONE'] # Twilio account phone number
MY_PHONE = ENV['MY_PHONE']

HEADERS = {
  'Accept' => 'application/vnd.github.inertia-preview+json',
  'Authorization' => "token #{GITHUB_TOKEN}"
}
# Previously-retrieved column ids for the GitHub Project
DONE    = '10567372'
RELEASE = '10567392'

def log filename, message
  File.write (File.join ENV['TODO_PATH'], 'log', filename), "#{message}\n", mode: 'a'
end

def done_cards
  return @_cards if @_cards
  url = 'https://api.github.com/projects/columns/%s/cards' % DONE
  @_cards = JSON.parse URI.open(url, HEADERS).read
end

# Collect the "Done" cards' notes
def release_summary title = nil
  datestamp_title = title ? Time.now.strftime("(%-m/%d) #{title}:") : Time.now.strftime("%-m/%d:")

  if done_cards.empty?
    datestamp_title + " Nada. 😢"
  else
    ([datestamp_title] + done_cards.map { |card| '- ' + card['note'] }).join "\n"
  end
end

# Create new "Release" card
def create_release_card summary
  # build post object
  url = 'https://api.github.com/projects/columns/%s/cards' % RELEASE
  uri = URI url
  post = Net::HTTP::Post.new uri, HEADERS
  post.body = { 'note' => summary }.to_json

  # create connection and send post
  http = Net::HTTP.new uri.host, uri.port
  http.use_ssl = 'https' == uri.scheme
  response = http.request post
  log 'release.log', "#{response.inspect}: #{response.body}: #{response.uri}" if response.code >= '400'
end

def send_text_with message
  begin
    client = Twilio::REST::Client.new TWILIO_SID, TWILIO_TOKEN
    client.messages.create(
      to: MY_PHONE,
      from: TWILIO_PHONE,
      body: "💪🏼Weekly Release! 🎉\n\n" + message
    )
  rescue StandardError => e
    log 'twilio.log', e.exception.inspect
    raise e
  end
end

# Archive the "Done" cards
def archive_done_cards
  done_cards.each do |card|
    # build patch object
    url = 'https://api.github.com/projects/columns/cards/%s' % card['id']
    uri = URI url
    patch = Net::HTTP::Patch.new uri, HEADERS
    patch.body = { 'archived' => true }.to_json

    # create connection and send patch
    http = Net::HTTP.new uri.host, uri.port
    http.use_ssl = 'https' == uri.scheme
    response = http.request patch
    log 'archive.log', "#{response.inspect}: #{response.body}: #{response.uri}" if response.code >= '400'
  end
end

def release title = nil
  summary = release_summary title
  create_release_card summary
  send_text_with summary
  archive_done_cards
rescue Exception => e
  log 'error.log', e.exception.inspect
  raise e
end


release ARGV[0]
