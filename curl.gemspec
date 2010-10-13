spec = Gem::Specification.new do |s|
  s.name = "curl"
  s.version = '0.0.1'
  s.summary = "shell CURL ruby wrapper."
  s.description = %{Some simple methods to use shell curl}
  s.files = ['README', 'lib/curl.rb']
  s.require_path = 'lib'
  s.autorequire = 'curl'
  s.has_rdoc = false
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.author = "tg0"
  s.email = "email@tg0.ru"
  s.homepage = "http://github.com/tg0/curl"  
end