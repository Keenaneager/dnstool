Gem::Specification.new do |s|
    s.homepage = "http://www.zdns.cn"
    s.license = 'ZDNS'
    s.name = "dnstool"
    s.version = "0.0.1"
    s.date = "2016-03-20"
    s.authors = ["Knet DNS"]
    s.email = "td_ddi@knet.cn"
    s.summary = "tools for dns"
    s.description = "several tools to inspect dns server"
    s.files = Dir["lib/dnstool/*.rb"]
    s.files += Dir["lib/dnstool.rb"]
    s.files += Dir["bin/*"]
    s.require_paths << 'lib'

    s.bindir = "bin"
    Dir["bin/*"].each do |script|
        s.executables << File.basename(script)
    end
end
