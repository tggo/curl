
require 'cgi'
require "open3"
require 'fileutils' 
include Open3


class CURL
    AGENT_ALIASES = {
      'Windows IE 6' => 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',
      'Windows IE 7' => 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727)',
      'Windows Mozilla' => 'Mozilla/5.0 Windows; U; Windows NT 5.0; en-US; rv:1.4b Gecko/20030516 Mozilla Firebird/0.6',
      'Windows Mozilla 2' => 'Mozilla/5.0 Windows; U; Windows NT 5.0; ru-US; rv:1.4b Gecko/20030516',
      'Windows Mozilla 3' => 'Mozilla/5.0 Windows; U; Windows NT 5.0; en-UK; rv:1.4b Gecko/20060516',
      'Mac Safari' => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/418 (KHTML, like Gecko) Safari/417.9.3',
      'Mac FireFox' => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.8.0.3) Gecko/20060426 Firefox/1.5.0.3',
      'Mac Mozilla' => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.4a) Gecko/20030401',
      'Linux Mozilla' => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.4) Gecko/20030624',
      'Linux Konqueror' => 'Mozilla/5.0 (compatible; Konqueror/3; Linux)',
      'IPhone' => 'Mozilla/5.0 (iPhone; U; CPU like Mac OS X; en) AppleWebKit/420+ (KHTML, like Gecko) Version/3.0 Mobile/1A543a Safari/419.3',
      'IPhone Vkontakt' => 'VKontakte/1.1.8 CFNetwork/342.1 Darwin/9.4.1',
    'Google'=>"Googlebot/2.1 (+http://www.google.com/bot.html)",
    "Yahoo-Slurp"=>"Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp)"

    }
    	
    attr_accessor :user_agent
    
  def initialize(keys={})
    #@debug = true
    @cookies_enable = ( keys[:cookies_disable] ? false : true  )
          @user_agent     = AGENT_ALIASES["Google"]#AGENT_ALIASES[AGENT_ALIASES.keys[rand(6)]]
          FileUtils.makedirs("/tmp/curl/")
    @cookies_file = keys[:cookies] || "/tmp/curl/curl_#{rand}_#{rand}.jar"
		# @cookies_file	= "/home/ruslan/curl.jar"		
		#--header "Accept-Encoding: deflate"
		@setup_params	= ' --header "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" --header "Accept-Language: en-us,en;q=0.5" --header "Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7" '
		@setup_params	= ' --connect-timeout 6 --max-time 8 --retry 1  --location --compressed --silent -k  '
#		@setup_params	= ' --location --silent  '
		yield self if block_given?		
	end

    def user_agent_alias=(al)
      self.user_agent = AGENT_ALIASES[al] || raise("unknown agent alias")
    end	
    
    def cookies
    	@cookies_file    	
    end
    
    def proxy(proxy_uri)
      File.open("/tmp/aaaaaaaa.aaa","w"){|file| file.puts "#{Time.now}---"+proxy_uri}
    	proxy = ( proxy_uri.is_a?(URI) ? proxy_uri : URI.parse("http://#{proxy_uri}") )
    	@setup_params = "#{@setup_params} --proxy \"#{proxy.host}:#{proxy.port}\" "
    	@setup_params = "#{@setup_params} --proxy-user \"#{proxy.user}:#{proxy.password}\" " if proxy.user
    end
    
    def socks(socks_uri)
    	socks = ( socks_uri.is_a?(URI) ? socks_uri : URI.parse("http://#{socks_uri}") )
    	@setup_params = "#{@setup_params} --socks5-hostname \"#{socks.host}:#{socks.port}\" "
    	@setup_params = "#{@setup_params} --proxy-user \"#{socks.user}:#{socks.password}\" " if socks.user
    	@setup_params
    end
    
    def self.check(proxy)
    	out = false
    	catch_errors(5){
    	result = `curl --connect-timeout 6 --max-time 8  --silent --socks5 \"#{proxy}\" \"yahoo.com\" `
    	out = true if result.scan("yahoo").size>0
		}
      out
    end
    
      
    def debug=(debug=false)
    	@debug=debug
    end
    
    def debug?
    	@debug
    end
    
    def get(url,count=3,ref=nil)
    	cmd = "curl #{cookies_store} #{browser_type} #{@setup_params} #{ref}  \"#{url}\"  "
    	if @debug
    		puts cmd.red  
    	end
    	result = open_pipe(cmd)
    		if result.to_s.strip.size == 0 
    			puts "empty result, left #{count} try".yellow  if @debug
    			count -= 1
    			result = self.get(url,count) if count > 0
                end
      result = result.gsub(/\\x../,'')
#      result = Iconv.new("UTF-8", "UTF-8").iconv(result)

    end
    
# 	формат данных для поста
#	data = { "subm"=>"1",
#			"sid"=>cap.split("=").last,
#			"country"=>"1"
#			}    
    def post(url,post_data, ref = nil,count=5, header = " --header \"Content-Type: application/x-www-form-urlencoded\" "  )
    	#header = " --header \"Content-Type: application/x-www-form-urlencoded\" "
    	
			post_q = '--data "'
			post_data.each do |key,val|
				if key
				post_q += "#{key}=#{URI.escape(CGI.escape(val.to_s),'.')}&" unless key == 'IDontAgreeBtn'
				end
			end
			post_q += '"'
			
			post_q.gsub!('&"','"')
		cmd = "curl #{cookies_store} #{browser_type} #{post_q} #{header} #{@setup_params} #{ref}  \"#{url}\"  "		
		puts cmd.red if @debug
		
		result = open_pipe(cmd)
    		if result.to_s.strip.size == 0 
    			puts "empty result, left #{count} try".yellow  if @debug
    			count -= 1
    			result = self.post(url,post_data,nil,count) if count > 0
			end
    	result
    end


# 	формат данных для поста
#	data = { "subm"=>"1",
#			"sid"=>cap.split("=").last,
#			"country"=>"1"
#			}    
    def send(url,post_data, ref = nil,count=5 )
    	
			post_q = '' # "  -F \"method\"=\"post\"  "
			post_data.each do |key,val|
				pre = ""
				if key
						pre = "@" if key.scan("file").size>0 or key.scan("photo").size>0 
					val = val.gsub('"','\"')
					post_q += " -F \"#{key}\"=#{pre}\"#{val}\" " 
				end
			end
			
		cmd = "curl   #{cookies_store} #{browser_type} #{post_q}  #{@setup_params} #{ref}  \"#{url}\" "		
		puts cmd.red if @debug
		
		result = open_pipe(cmd)
    		#if result.to_s.strip.size == 0 
    		#	puts "empty result, left #{count} try".yellow  if @debug
    		#	count -= 1
    		#	result = self.send(url,post_data,nil,count) if count > 0
			#end
    	result
    end
    
    
    
    def get_header(url, location=false)
		cmd = "curl #{cookies_store} #{browser_type} #{@setup_params}  \"#{url}\" -i "
		cmd.gsub!(/\-\-location/,' ') unless location
    	puts cmd.red  if @debug
    	open_pipe(cmd)
    end
    
    def save(url,path="/tmp/curl/curl_#{rand}_#{rand}.jpg")
    FileUtils.mkdir_p(File.dirname(path))
	cmd = "curl #{cookies_store} #{browser_type} #{@setup_params}  \"#{url}\" --output \"#{path}\"  "
	puts cmd.red  if @debug	 
    	system(cmd)
    	path
    end

    def save!(url,path="/tmp/curl/curl_#{rand}_#{rand}.jpg")
    FileUtils.mkdir_p(File.dirname(path))
	cmd = "curl  #{browser_type}   --location --compressed --silent  \"#{url}\" --output \"#{path}\"  "
	puts cmd.red  if @debug	 
    	system(cmd)
    	path
    end


	def clear
		File.delete(@cookies_file) if File.exists?(@cookies_file)
	end
	
	def init_cook(hash,site='')
		file = "# Netscape HTTP Cookie File\n# http://curl.haxx.se/rfc/cookie_spec.html\n# This file was generated by libcurl! Edit at your own risk.\n\n"
		hash.each do |key,val|
			file += "#{site}\tTRUE\t/\tFALSE\t0\t#{key}\t#{val}\n"
		end
		File.open(cookies_store.scan(/\"(.+?)\"/).first.first,"w") {|f| f.puts file+"\n" }
		file+"\n"
	end
	

    private
    def open_pipe_old(cmd,kills=true)
    	result = ''
    	
    	tmp_path="/tmp/curl/curl_#{rand}_#{rand}.html.tmp"
    	#cmd += "  --output \"#{tmp_path}\"  "
		system(cmd)
		stdin, stdout, stderr = popen3(cmd)
		result = stdout

		
		#File.open(tmp_path,"r") { |f| result = f.read } 
		#File.delete(tmp_path)

		result    	
    end

    def open_pipe(cmd,kills=true)
		result, current_process = '', 0		
		IO.popen(cmd,"r+") { |pipe| 
			current_process = pipe.object_id # Saving the PID 
			result = pipe.read
			pipe.close
		}
		while result.to_s.size==0
			sleep 0.5
		end
		#Process.wait
		#Process.kill("KILL", current_process) if kills and current_process.to_i>0
		result    	
    end
    
    def browser_type
    	browser =  " --user-agent \"#{@user_agent}\" "		
    end
    
    def cookies_store
      if @cookies_enable
    	return " --cookie \"#{@cookies_file}\" --cookie-jar \"#{@cookies_file}\" "
      else
        return " "
      end
    end
end
