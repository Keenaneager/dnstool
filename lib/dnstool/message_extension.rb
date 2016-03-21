require 'dnsruby'

module Dnsruby
    class Message
        def get_ns_and_glue(only_check_answer = false)
            nses = get_rrs_in_section(self.answer, Dnsruby::Types.NS)
            if nses.length == 0 && only_check_answer == false
                nses = get_rrs_in_section(self.authority, Dnsruby::Types.NS)
            end

            v4hosts = nses.map{|ns| self.additional.rrset(ns.rdata.to_s, Dnsruby::Types.A).sort_canonical.rrs}
            v6hosts = nses.map{|ns| self.additional.rrset(ns.rdata.to_s, Dnsruby::Types.AAAA).sort_canonical.rrs}
            [nses, v4hosts, v6hosts]
        end

        def get_rrs_in_section(section, type)
            section.rrsets.map do |rrset|
                rrset.type == type  ? rrset.sort_canonical.rrs : []
            end.flatten
        end

        def skip_cname_chain(qname = nil, qtype = nil, last_cname = [])
            if qname == nil 
                qname = self.question[0].qname
                qtype = self.question[0].qtype
            end

            rrset = self.answer.rrset(qname, qtype)
            if rrset.length != 0
                return rrset.sort_canonical.rrs
            end

            rrset = self.answer.rrset(qname, Types.CNAME)
            if rrset.length == 1
                skip_cname_chain(rrset[0].rdata, qtype, rrset.rrs)
            else
                last_cname
            end
        end

    end
end
