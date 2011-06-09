# -*- encoding: UTF-8 -*-

require 'mechanize'
require 'kconv'
require 'nkf'

class DartsLive
  LOGIN_URL   = "http://www.dartslive.jp/t/login.jsp"
  STATS_URL   = "http://www.dartslive.jp/t/usr/index.jsp"
  IMADOKO_URL = "http://www.dartslive.jp/t/group/allima2.jsp"
  SHOP_URL    = "http://www.dartslive.jp/kt/search/shop.jsp" 
  SEARCH_URL  = "http://www.dartslive.jp/kt/search/search.jsp"
  RESULT_URL  = "http://www.dartslive.jp/t/day/index.jsp"
  GEOCODE_URL = "http://maps.google.com/maps/api/geocode/json"
  @agent = nil

  def initialize(cardno, passwd)# {{{
    @agent = Mechanize.new
    @agent.post(LOGIN_URL, {'i' => cardno, 'p' => passwd})
    check()
  end# }}}

  def check# {{{
    file = File.open("body.html",'w')
      file.puts @agent.page.body
    file.close
    if @agent.page.at('font[color=red]')
      raise AuthError, 'login error' if @agent.page.at('font[color=red]').inner_text.match('ERROR')
    end 
    raise AuthError, "charge error"  if @agent.page.at('div[id=error]')
  end# }}}

  def getCardname# {{{
    raise InternalError, "get cardname failed" unless cardname = @agent.page.at('a[class="fs16"]')
    cardname.inner_text
  end# }}}

  def getRating# {{{
    raise InternalError, "get rating failed" unless rating = @agent.page.at('span[class="fs16 bold red"]')
    rating.inner_text
  end# }}}

  def getHomeshop# {{{
    raise InternalError, "get homeshop failed" unless homeshop = @agent.page.at('li.shop>a')
    homeshop.inner_text
  end# }}}

  def getCardInfo# {{{
    return {:cardno => getCardname,
            :rating => getRating,
            :homeshop => getHomeshop}
  end# }}}

  def getStats# {{{
    @agent.get(STATS_URL)
    @agent.page.encoding = 'CP932'
    html = NKF::nkf('-Ss', @agent.page.body).toutf8
    result = {}

    raise InternalError, "get 01 ave faild" unless /(\d{2,3}\.\d{2}) pts/ =~ html 
    result[:zero1_ave] = $1

    raise InternalError, "get 01 res faild" unless /([-\+]\d{1,3}\.\d{2}) pts/ =~ html 
    result[:zero1_res] = $1 

    raise InternalError, "get Cri ave faild" unless /(\d{1}\.\d{2}) マーク/u =~ html 
    result[:cri_ave] = $1 

    raise INternalError, "get Cri res failed" unless /([-\+]\d{1}\.\d{2}) マーク/u =~ html 
    result[:cri_res] = $1 

    return result
  end# }}}

  def getAward# {{{
    @agent.get(RESULT_URL)
    @agent.page.encoding = 'CP932'
    raise NotFoundError, "今日のアワードが見つかりませんでした" unless link = @agent.page.link_with(:text => '今日')
    link.click
    @agent.page.encoding = 'CP932'
    result = {"3 - BLACK" => 0,
              "TON 80" => 0,
              "WHITE HRS" => 0,
              "3IN A BED" => 0,
              "HIGH TON" => 0,
              "HAT TRICK" => 0,
              "LOW TON" => 0}

    @agent.page.links_with(:href => /dgame.jsp\?d=\d+&g=(1001|1002|1003|1004|1005|1006|2001|3001)/).each do |link|
      link.click
      @agent.page.body.each_line do |line|
        line.chomp!
        if /(#{award.keys.join("|")}).*:(\d+)/ =~ line
          result[$1] += $2.to_i
        end 
      end
    end
    return result
  end# }}}

  def getCountup# {{{
    @agent.get(RESULT_URL)
    @agent.page.encoding = 'CP932'
    raise NotFoundError, "今日のカウントアップは見つかりませんでした" unless link = @agent.page.link_with(:text => '今日')
    link.click
    @agent.page.encoding = 'CP932'

    @agent.page.link_with(:href => /dgame.jsp\?d=\d+&g=3001/).click
    result[:max] = 0
    result[:ave] = 0
    return result
  end# }}}


end

class AuthError < Exception; end
class NotFoundError < Exception; end
class InternalError < Exception; end
