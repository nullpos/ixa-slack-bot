require 'slack-ruby-client'

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
  fail 'Missing ENV[SLACK_API_TOKEN]!' unless config.token
end

client = Slack::RealTime::Client.new

client.on :hello do
  puts "Successfully connected, welcome '#{client.self.name}' to the '#{client.team.name}' team at https://#{client.team.domain}.slack.com."
end

client.on :message do |data|
  if data.type == "message" && data.user != client.self.id then
    map_coord = MapCoordinate.new

    case data.text
    when map_coord.coord_mes?(data.text) then
      xy = map_coord.normalize_coord(data.text)
      if not map_coord.same_coord?(xy) then
        if not map_coord.include_url(data.text) then
          client.message channel: data.channel, text: map_coord.create_url
        end
      end
    when map_coord.cset_mes?(data.text) then
      if map_coord.set_c(data.text) then
        client.message channel: data.channel, text: "successfully set country id to " + set
      else
        client.message channel: data.channel, text: "unable to set country id"
      end
    end
  end
end

client.on :close do |_data|
  puts "Client is about to disconnect"
end

client.on :closed do |_data|
  puts "Client has disconnected successfully!"
end

client.start!


class MapCoordinate
  def initialize
    @baseurl = "http://y061.sengokuixa.jp/map.php?"
    @regexp = /([ー－‐―\-]?[０-９\d]+)[,，.．、､]\s?([ー－‐―\-]?[０-９\d]+)/
    @country = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"]
    @x = "0", @y = "0", @c = "2"
  end

  def coord_mes?(mes)
    if (mes =~ @regexp) != nil then
      return true
    else
      return false
    end
  end

  def cset_mes?(mes)
    if (mes =~ /^cset/) != nil then
      return true
    else
      return false
    end
  end

  def normalize_coord(mes)
    coord = mes[regexp, 0]
    return coord.gsub(/[ー－‐―\-]/, "-").gsub(/[,，.．、､]/, ",").tr("０-９", "0-9").split(",")
  end

  def same_coord?(xy)
    if xy[0] == @x && xy[1] == @y then
      return true
    end
    @x = xy[0], @y = xy[1]
    return false
  end

  def include_url?(mes)
    if mes[/http:/] == nil then
      return false
    end
    return true
  end

  def create_url
    return @baseurl + "x=" + @x + "&y=" + @y + "&c=" + @c
  end

  def set_c(mes)
    set = mes[/^cset (.*)/, 1]
    if set == "default" then
      @c = "2"
      return true
    else if @country.include?(set)
      @c = set
      return true
    else
      return false
    end
  end
end
