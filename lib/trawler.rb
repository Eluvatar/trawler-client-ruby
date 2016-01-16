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

# 
# This module defines a ruby interface toward being a Trawler client.
# Trawler is a system for sharing rate-limited access to NationStates.net
# among multiple (prioritized) programs with minimal sharing of state.
#
# The interface this module defines is not thread-safe: the module itself
# provides wrappers around a singleton Connection, and any Connection may
# only be used from one thread of execution. To use this module from multiple
# threads, use multiple Connection objects.
#
# This interface provides request methods which return Response objects.
#
# Response objects behave like files, but also have a 'result' method
# which returns the HTTP status code 
#

require 'trawler/connection'

module Trawler

  # The default instance. A +Trawler::Connection+ which requires
  # +TRAWLER_USER_AGENT+ to be set. Is called against by +Trawler.request+
  INSTANCE = Connection.new 'localhost', 5557, TRAWLER_USER_AGENT

  # Sends a request for sending to nationstates.net to the trawler daemon
  # Params:
  # +method+ required string such as 'GET', 'HEAD', or 'POST'
  # +path+ required string such as '/cgi-bin/api.cgi'
  # +query+ optional string containing query parameters or form data
  # +session+ optional string containing cookies to send
  # +headers+ optional boolean specifying whether you want the headers
  def self.request( method, path, query: nil, session: nil, headers: false)
    INSTANCE.request( method, path, query: query, session: session, headers: headers )
  end

  def self.version
    'v0.1.1'
  end
end
