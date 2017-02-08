require 'slack-ruby-client'

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
  fail 'Missing ENV[SLACK_API_TOKEN]!' unless config.token
end

client = Slack::RealTime::Client.new

client.on :hello do
  puts "Successfully connected, welcome '#{client.self.name}' to the '#{client.team.name}' team at https://#{client.team.domain}.slack.com."
end

x = "0"
y = "0"
c = "2"
client.on :message do |data|
  if data.type == "message" && data.user != client.self.id then
    baseurl = "http://y061.sengokuixa.jp/map.php?"
    regexp = /([ー－‐―\-]?[０-９\d]+)[,，.．、､]\s?([ー－‐―\-]?[０-９\d]+)/

    case data.text
    when regexp then
      xy = conv_xy(data.text[regexp, 0]).split(",")
      if x != xy[0] || y != xy[1] then
        if data.text[/http:/] == nil then
          url = baseurl + "x=" + xy[0] + "&y=" + xy[1] + "&c=" + c
          x = xy[0]
          y = xy[1]
          client.message channel: data.channel, text: url
        end
      end
    when /^cset/
      set = data.text[/^cset (.*)/, 1]
      if set == "default" then
        c = 2
      else
        c = set
      end
      client.message channel: data.channel, text: "set to " + set
    end
  end
end

client.on :close do |_data|
  puts "Client is about to disconnect"
end

client.on :closed do |_data|
  puts "Client has disconnected successfully!"
end

def conv_xy(xy)
  return xy.gsub(/[ー－‐―\-]/, "-").gsub(/[,，.．、､]/, ",").tr("０-９", "0-9")
end

client.start!
