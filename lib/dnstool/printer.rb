require 'dnsruby'
require 'terminal-table'
require 'dnstool'
require 'thread'

module DnsTool
    def self.print_ns(ns_and_glue)
        concat_rrs = ->(rrs) {rrs.map{|rr| rr.rdata.to_s}.join("  ")}
        ns_and_glue.transpose.map do |ns, v4_hosts, v6_hosts|
            sprintf("%-30s [%-15s] [%s]", ns.rdata.to_s, concat_rrs.(v4_hosts), concat_rrs.(v6_hosts))
        end.join("\n")
    end

    def self.print_rrs(rrs)
        rrs.map{|rr| "#{rr.type} #{rr.rdata}"}.join("\n")
    end

    def self.table_with_rows(title, headers, rows)
        Terminal::Table.new(:headings => headers).tap do |t|
            t.title = title
            rows.each_index do |i|
                t.add_row rows[i]
                t.add_separator if i != rows.length - 1
            end 
        end
    end
end

