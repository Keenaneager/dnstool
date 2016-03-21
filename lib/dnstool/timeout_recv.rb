require 'dnsruby'
require 'timeout'

module DnsTool
    def self.recv_with_timeout(socket, len, seconds)
        timeout(seconds) {socket.recvfrom(len)} rescue [nil, nil]
    end
end
