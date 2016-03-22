require 'dnsruby'
require 'thread'

module DnsTool
    DEFAULT_PACKATE_SIZE = 4096
    DEFAULT_RECV_TIMEOUT = 5 # 5 seconds
    ROOT_SERVER_NAMES = %w{b.root-servers.net.h.root-servers.net.}
    ROOT_SERVER_IPS = %w{192.228.79.201 198.97.190.53}

    def self.query(server, qname, qtype)
        puts "---> query #{server} with #{qname} #{qtype}"
        msg = Dnsruby::Message.new(qname, qtype)
        msg.header.rd = true
        msg.add_additional(Dnsruby::RR::OPT.new(DEFAULT_PACKATE_SIZE))

        s = UDPSocket.new
        s.send(msg.encode, 0, server, 53)
        msg, _ = DnsTool.recv_with_timeout(s, DEFAULT_PACKATE_SIZE, DEFAULT_RECV_TIMEOUT)
        msg == nil ? nil : Dnsruby::Message.decode(msg) 
    end

    def self.query_any_server(servers, qname, qtype) 
        queue = Queue.new
        threads = servers.map do |s|
            server = s.dup
            Thread.new do 
                msg = self.query(server, qname, qtype)
                queue << msg if msg != nil
            end
        end
        msg = queue.pop
        threads.each{|t| Thread.kill(t)}
        msg
    end

    def self.query_all_servers(servers, qname, qtype) 
        results = []
        index = 0
        servers.inject([]) do |threads, server|
            threads << Thread.new(server.dup, index) do |server_, i|
                msg = self.query(server_, qname, qtype)
                results[i] = msg
            end
            index += 1
            threads
        end.each(&:join)
        results
    end

    def self.get_ns_and_glue(qname)
        servers = ROOT_SERVER_IPS
        qname = Dnsruby::Name.create(qname) if qname.kind_of?(String)
        nses = []
        v4_hosts = []
        v6_hosts = []
        answer = nil
        loop do
            break if servers.empty? || qname.length == 0 
            answer = self.query_any_server(servers, qname, Dnsruby::Types.NS)
            break if answer.nil?

            if answer.header.aa && (answer.header.ancount == 0 || answer.answer.rrset(qname, Dnsruby::Types.NS).rrs.empty?)
                qname = qname.strip_label 
                next
            end

            break if answer.header.aa
            nses, v4_hosts_, _ = answer.get_ns_and_glue
            servers = v4_hosts_.flatten.map{|rr| rr.rdata.to_s}
        end

        if answer && answer.header.aa
            nses, v4_hosts, v6_hosts = answer.get_ns_and_glue(true)
        end

        if !nses.empty? && v4_hosts.flatten.empty?
            nses.each_index do |i|
                ns_, v4_hosts_, _ = self.get_ns_and_glue(nses[i].rdata.to_s)
                if !v4_hosts_.empty?
                    answer =  self.query_any_server(v4_hosts_.flatten.map{|rr| rr.rdata.to_s}, nses[i].rdata.to_s, Dnsruby::Types.A)
                    if answer != nil
                        v4_hosts[i] = answer.get_rrs_in_section(answer.answer, Dnsruby::Types.A)
                    end
                end
            end
        end

        [nses, v4_hosts, v6_hosts]
    end
end
