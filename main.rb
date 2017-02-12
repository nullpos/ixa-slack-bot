require 'slack-ruby-client'

class MapCoordinate
  def initialize
    @baseurl = 'http://y061.sengokuixa.jp/map.php?'
    @regexp = /([ー－‐―\-]?[０-９\d]+)[,，.．、､]\s?([ー－‐―\-]?[０-９\d]+)/
    @country = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12']
    @country_name = ['織田', '明智', '武田', '相馬', '徳川', '毛利', '柴田', '北条', '長宗我部', '島津', '豊臣', '里見']
    @x, @y, @c = '0', '0', '2'
  end

  def coord_mes?(mes)
    !(mes =~ @regexp).nil?
  end

  def cset_mes?(mes)
    !(mes =~ /^cset/).nil?
  end

  def normalize_coord(mes)
    coord = mes[@regexp, 0]
    coord.gsub(/[ー－‐―\-]/, '-')
         .gsub(/[,，.．、､]/, ',')
         .tr('０-９', '0-9')
         .split(',')
         .map! { |i| i.strip }
  end

  def same_coord?(xy)
    if (xy[0] == @x && xy[1] == @y)
      return true
    end
    @x, @y = xy[0], xy[1]
    false
  end

  def include_url?(mes)
    !mes[/http:/].nil?
  end

  def create_url
    @baseurl + 'x=' + @x + '&y=' + @y + '&c=' + @c
  end

  def set_c(mes)
    set = mes[/^cset (.*)/, 1]
    if set == 'default'
      @c = '2'
      return true
    elsif @country.include?(set)
      @c = set
      return true
    elsif @country_name.include?(set)
      @c = @country[@country_name.index(set)]
      return true
    end
  end
end

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
  raise 'Missing ENV[SLACK_API_TOKEN]!' unless config.token
end

client = Slack::RealTime::Client.new

client.on :hello do
  puts "Successfully connected, welcome '#{client.self.name}' to the '#{client.team.name}' team at https://#{client.team.domain}.slack.com."
end

map_coord = MapCoordinate.new
client.on :message do |data|
  if data.type == 'message' && data.user != client.self.id

    if map_coord.coord_mes?(data.text)
      xy = map_coord.normalize_coord(data.text)
      if !map_coord.same_coord?(xy) && !map_coord.include_url?(data.text)
        client.message channel: data.channel, text: map_coord.create_url
      end
    elsif map_coord.cset_mes?(data.text)
      if map_coord.set_c(data.text)
        client.message channel: data.channel,
                       text: 'successfully set country id'
      else
        client.message channel: data.channel, text: 'unable to set country id'
      end
    end
  end
end

client.on :close do |_data|
  puts 'Client is about to disconnect'
end

client.on :closed do |_data|
  puts 'Client has disconnected successfully!'
end

client.start!
