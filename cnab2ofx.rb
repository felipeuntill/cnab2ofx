#!/usr/bin/env ruby

require 'yaml'
require 'pp'
require 'date'
require 'erb'

CONFIG_DIR = 'config'
VIEW_DIR = 'view' 

class CNAB240

  attr_reader :cnab240, :dtserver, :org, :fid
  
  def initialize(filename)
    @filename = filename
    @cnab240 = parse
    @dtserver = get_dtserver
    @org = @fid = get_org
    @transactions = [{},{}]
  end
  
  def to_ofx
    ERB.new(File.read(File.join(VIEW_DIR, "extrato.ofx.erb"))).run(binding)
  end
			
  private
  
  def str_decode_with_headers(str, headers)
		raise ArgumentError, "str.size should be 240 for CNAB240 but it's #{str.size}" if str.size != 240
		str = str.dup
		headers.each_with_object({}) do |(k,v), hsh| 
			hsh[k.to_sym] = str.slice!(0,v) 
		end
	end
	
	def parse
    
    f = File.open(@filename)
    
    lines = {}

		lines[:header_de_arquivo],
		lines[:header_de_lote],
		*lines[:detalhe_segmento_e],
		lines[:trailer_de_lote],
		lines[:trailer_de_arquivo] = f.readlines
		
		lines.each_with_index.with_object({}) do |((k,v), i), hsh| #|(k,v), i, hsh|
			file_index = "%03d" % i
			fields_headers = YAML.load_file (File.join(CONFIG_DIR, "#{file_index}_registro_#{k}.yaml"))
			case v
			when String
				hsh[k] = str_decode_with_headers(v.chomp, fields_headers)
			when Array
				hsh[k] = v.map {|line| str_decode_with_headers(line.chomp, fields_headers) }
			else
				raise ArgumentError, "v (line) should be Array or String but it is #{v.class} "
			end
		end
	end
	
	def get_dtserver
		cnab_date_string = @cnab240[:header_de_arquivo][:data_arquivo]+@cnab240[:header_de_arquivo][:hora_arquivo]
		cnab_dtserver = DateTime.strptime(cnab_date_string,"%d%m%Y%H%M%S") # Import CNAB DateTime format
		@dtserver = cnab_dtserver.strftime("%Y%m%d%H%M%S") # Export OFX DateTime format
	end
	
	def get_org
	  @org = @fid = @cnab240[:header_de_arquivo][:nome_banco].strip
	end
	
	alias get_fid get_org
	
end



filename = ARGV[0] || "UnicredLucas.2013.03.3aVersao.txt"

cnab240 = CNAB240.new(filename)

pp cnab240.cnab240
pp cnab240.dtserver
pp cnab240.fid
pp cnab240.org
pp cnab240.to_ofx



exit


pp decoded





@transactions = Array.new(5) { Hash.new }

e = ERB.new(File.read("extrato.ofx.erb")).run

puts e

pp date_string
pp cnab_dtserver

pp @dtserver



=begin
@dtserver 20130420152834[-3:GMT]

@org e @fid SANTANDER

=end