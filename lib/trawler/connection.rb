# Copyright 2015 Eluvatar
#
# This file is part of Trawler.
#
# Trawler is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Trawler is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Trawler.  If not, see <http://www.gnu.org/licenses/>.
#

require 'ffi-rzmq'

require 'protobuf'
require 'trawler/trawler.pb'

require 'stringio'

module Trawler

class Connection
  def initialize(host, port, user_agent_str)
    @url = "tcp://#{host}:#{port}"
    @user_agent = user_agent_str
    @req_id = 1
    @zctx = ZMQ::Context.new(1)
    @open = false
  end

  def login
    login_message = Trawler::Login.new( :user_agent => @user_agent )
    @tsock.send_string(login_message.encode)
  end

  def receive
    reply_list = []
    routing_envelope = []
    rc = @tsock.recv_multipart(reply_list, routing_envelope)
    if rc < 0
      puts "errno [#{ZMQ::Util.errno}] description [#{ZMQ::Util.error_string}]"
      invalid
      return
    end
    reply = Trawler::Reply.decode(reply_list[-1].copy_out_string)
    # puts reply.to_json
    case Trawler::Reply::ReplyType.fetch(reply.reply_type)
    when Trawler::Reply::ReplyType::Response
      response(reply)
    when Trawler::Reply::ReplyType::Ack
      ack(reply)
    when Trawler::Reply::ReplyType::Nack
      nack(reply)
    when Trawler::Reply::ReplyType::Logout
      logout(reply)
    else
      invalid
    end
  end

  def ack(reply)
    @ackd = true
  end

  def nack(reply)
    @res = Response.new( reply.result )
    @done = true
  end

  def response(reply)
    raise "invalid req_id" unless @req_id == reply.req_id
    raise "unackd response" unless @ackd
    @res ||= Response.new( reply.result, :headers => reply.headers,
                         :response => reply.response)
    if reply.headers && reply.headers.length > 0
      @res.add_headers(reply.headers)
    elsif reply.response && reply.response.length > 0
      @res.add_body(reply.response)
    end
    unless reply.continued?
      @res.complete
      @done = true
      @ackd = false
    end
  end

  def logout(reply)
    @tsock.close()
    @open = false
    @res = Response.new( reply.result )
    @done = true
  end

  def invalid
    @tsock.close()
    @open = false
    @res = Response.new( 0 )
    @done = true
  end

  def require_open
    unless @open
      @tsock = @zctx.socket(ZMQ::DEALER)
      @tsock.connect(@url)
      login
      @open = true
    end
  end

  def request(method, path, query: nil, session: nil, headers: false)
    require_open
    @res = nil

    method = Trawler::Request::Method.fetch(method.upcase)

    req = Trawler::Request.new( :id => @req_id, :method => method, \
                                :path => path, :query => query, \
                                :session => session, :headers => headers )

    @tsock.send_string(req.encode)

    @done = false
    poller = ZMQ::Poller.new
    poller.register(@tsock, ZMQ::POLLIN)
    begin
      until @done do
        poller.poll(:blocking)
        receive
      end
    ensure
      @req_id += 1
    end
    
    @res
  end
end

class Response
  # A Response from NationStates.net via Trawler
  attr_reader :result, :headers
  # TODO parse headers
  def initialize(result, headers: nil, response: '')
    @result = result
    if headers
      @header_buf = StringIO.new headers
    else
      @header_buf = nil
    end
    @body = StringIO.new response
  end

  def add_headers(headers)
    @header_buf << headers
  end

  def add_body(body)
    if @header_buf
      @header_buf.seek(0)
      s = @header_buf.read
      l = s.split("\r\n")[1..-1]
      if l
        @headers = l.join("\r\n")
      else
        @headers = s
      end
    end
    @body << body
  end

  def seek(pos, from_what: 0)
    @body.seek(pos, from_what)
  end

  def read(size: -1)
    if size > 0
      @body.read(size)
    else
      @body.read
    end
  end

  def complete
    @body.seek(0)
  end

end

end
