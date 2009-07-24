# redcap -- library for uploading files to Second Life
# Copyright 2009  Paul Morganthall
# 
# redcap is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'rubygems'
require 'builder'
require 'digest/md5'
require 'logger'
require 'net/https'
require 'rexml/document'
require 'RMagick'  # Requires ImageMagick with JPEG2000 (.JPC) installed
require 'tempfile'
require 'xmlrpc/client'
require 'yaml'

# Uploader: support for uploading files to Second Life
# The standard upload fee (L$10) is charged upon successful upload.
# This program was inspired and informed by the work of Katherine Berry, author
# of phpsimcaps, AjaxLife, and other cool stuff:
#    http://blog.katharineberry.co.uk/

module Redcap
  GRIDS = {"main"    => "https://login.agni.lindenlab.com/cgi-bin/login.cgi",
           "preview" => "https://login.aditi.lindenlab.com/cgi-bin/login.cgi"}

  class Uploader
    attr_reader :success, :new_asset_id, :msg, :aspect_ratio
    
    def initialize(first_name, last_name, password, filename, grid="main")
      @debug = false
      @log = Logger.new('redcap.log')
      @log.level = Logger::DEBUG    # DEBUG, WARN, 
      @trace = Array.new            # global trace stored here for now
        # ? seperate from log, so it can be glommed to log in one piece
      @trace << [first_name, last_name, filename, grid, Time.now].join("/")
      
      #1: invoke [begin block has rescue at end]
      begin
        #2: login
        login_data = login(first_name, last_name, password, GRIDS[grid])
        login_data["seed_capability"] or raise "seed_capability not found"
        login_data["inventory-root"] or raise "inventory-root not found"

        #3: request the upload capability
        cap_request = send_request(login_data["seed_capability"],
          %{<llsd><array><string>NewFileAgentInventory</string></array></llsd>})
        cap_request["NewFileAgentInventory"] or raise "no image upload capability found"

        #4: request an upload ticket
        ticket_request = send_request(cap_request["NewFileAgentInventory"],
          encode_ticket(login_data["inventory-root"], filename))
        ticket_request["state"] == "upload" or raise "state not upload"
        ticket_request["uploader"] or raise "no uploader found"

        #5: upload image
        upload_status = send_request(ticket_request["uploader"], make_slimage(filename))
        upload_status["state"] = "complete" or raise "upload failed: #{upload_status["state"]}"

        #7: retrieve the UUID of the newly uploaded image
        @success = true
        @new_asset_id = upload_status["new_asset"]
        # upon success, log the original request and the final result.
        @log.info(@trace[0].to_yaml + @trace[-1].to_yaml)

      rescue
        @success = false
        @msg = "#{$!}"
        @log.fatal @trace.to_yaml     # on failure, log everything
        if @debug
          @msg += "\ntrace: #{@trace[0]}"
        end
      end

    end # initialize

    private
    
    def login(first_name, last_name, password, login_url, method="login_to_simulator")

      login_params = {
        :first     => first_name,
        :last      => last_name,
        :passwd    => "$1$" + Digest::MD5.hexdigest(password),
        :options   => %w{inventory-root},
        :start     => "last",
        :channel   => "redcap.rb",          # w/channel, no need for build id.
        :mac       => "00:D0:4D:28:A1:F1",  # required.
        :read_critical => "true",           # skip...
        :agree_to_tos  => "true",           #   potential...
        :skipoptional  => "true",           #     dialogs...
      }

      login_url or raise "unrecognized grid name"
      @trace << [login_url, method] << login_params
      @log.debug "#{login_url} / #{method} / #{login_params}"
      server = XMLRPC::Client.new2(login_url)
      server.http_header_extra = {"Content-Type" => "text/xml"}
      server.timeout = 120
      result = server.call(method, login_params)
      @trace << result
      @log.debug "raw login response: #{result.to_yaml}"
      # unearth some parameters
      if result.has_key?("inventory-root") then
        result["inventory-root"] = result["inventory-root"][0]["folder_id"]
      end

      # If the login server says "indeterminate", follow the path given.
      if "indeterminate" == result["login"] then
        @log.info "indeterminate login:\n#{result.to_yaml}"
        next_url = result["next_url"]
        next_method = result["next_method"]
        message = result["message"]
        @log.warn "Login redirected:\n#{next_url}, method: #{next_method}, message: #{message}"
        result = login(first_name, last_name, password, next_url, next_method)     
      elsif "false" == result["login"] or "true" != result["login"] then
        raise "error during login: #{result["message"]}"
      end

      result
    end  # login

    # Examine URL and return the base url (server), port number, and parameter path
    def parse_capability(cap)
      match = %r{https://(.+):(\d+)(.+)}.match(cap)
      match or raise "capability format not understood: #{cap}"
      match.captures
    end

    # Convert LLSD ( Linden Lab Structured Data) into a simple hash.
    def decode_llsd(body)
      doc = REXML::Document.new(body)
      pairs = Hash[*doc.elements.to_a("/llsd/map/*")]
      result = Hash.new
      pairs.each { |key,value| result[key.text.strip] = value.text.strip }
      result
    end

    def send_request(capability, data)
      @log.debug "send_request / #{capability} #{data if data[0,1] == '<'}"

      server, port, path = parse_capability(capability)
      site = Net::HTTP.new(server, port)
      # site.set_debug_output($stderr)
      site.use_ssl = true
      site.verify_mode = OpenSSL::SSL::VERIFY_NONE

      response = site.request_post(path, data, {"Content-Type" => "text/xml"})
      result = decode_llsd(response.body)
      @log.debug "response\n#{result.to_yaml}"
      @trace << result
      result
    end

    def encode_ticket(folder, filename)
      request = {
        "asset_type" => "texture",
        "description" => "uploaded by http://adammarker.org/redcap/",
        "folder_id" => folder,
        "inventory_type" => "texture",
        "name" => File.basename(filename)
        }

        xml = Builder::XmlMarkup.new(:indent => 2)
        xml.llsd {
          xml.map {
            request.each do |key, value|
              xml.key(key)
              xml.string(value)
            end
          }
        }
      xml.target!
    end

    # adapted from function by Simon Kröger posted in comp.lang.ruby
    # maximum dimension of an SL image is 1024.
    def nextpow2(n)
      throw 'eeek' if n < 0   # Simon's.  perhaps there is another way?
      return 1 if n < 2
      [1 << (n-1).to_s(2).size, 1024].min
    end

    # Convert image to SL standards:
    # 1. JPEG-2000 Code Stream Syntax (JPC)
    # 2. width and height must be a power of 2
    def make_slimage(filename)      
      image = Magick::Image.read(filename).first
      @aspect_ratio = image.columns.to_f / image.rows.to_f
      new_image = image.resize(nextpow2(image.columns), nextpow2(image.rows))
      slimage = Tempfile.new('redcap').path
      new_image.write("jpc:#{slimage}") or raise "Unable to write JPC image."
      open(slimage, 'rb') { |f| f.read }
    end

  end # class
end # module
