require 'rubygems'
require 'bundler/setup'
require 'active_support/core_ext/string/inflections'
require 'restclient'
require 'ostruct'
require 'singleton'
require 'logger'
require File.dirname(__FILE__) + '/smile/session'
require File.dirname(__FILE__) + '/smile/common'
require File.dirname(__FILE__) + '/smile/base'
require File.dirname(__FILE__) + '/smile/smug'
require File.dirname(__FILE__) + '/smile/album'
require File.dirname(__FILE__) + '/smile/photo'
require File.dirname(__FILE__) + '/smile/param_converter'
require File.dirname(__FILE__) + '/smile/exception'
require File.dirname(__FILE__) + '/smile/json'
require 'cgi'
require 'rss'
require 'yajl'

module Smile
  module_function

  # Login to SmugMug using an anonymously account
  # This will allow you to execute many functions, but no user specific functions
  #
  # @return [Smile::SmugMug.new] An Smug object that has been authenticated
  def auth_anonymously
    smug = Smile::Smug.new
    smug.auth_anonymously
    smug
  end

  # Login to SmugMug using a specific user account.
  #
  # @param [String] email The username ( e-mail address ) for the SmugMug account
  # @param [String] password The password for the SmugMug account
  #
  # @return [Smile::SmugMug.new] An Smug object that has been authenticated
  def auth( email, password )
    smug = Smile::Smug.new
    smug.auth( email, password )
    smug
  end


  def base_feed( options={} )
    options.merge!( :format => 'rss' )
    url = "http://api.smugmug.com/hack/feed.mg?"
    url_params =[]
    options.each_pair do |k,value|
      key, value = Smile::ParamConverter.convert( k, value )

      url_params << "#{key.to_s}=#{ CGI.escape( value ) }"
    end

    Session.instance.logger.info url + url_params.join( "&" )
    RestClient.get( url + url_params.join( "&" ) ).body
  end
  private( :base_feed )

  # Search SmugMug for pics.  This search is slower than the others, but returns Smile::Photo objects
  #
  # @param [String] data This is the search term that you want to use
  # @param [optional, Hash] options Hash of options for the search method
  # @option options [optional, String] :keyword override the keyword search
  # @option options [optional, String] :popular Use term all or today
  # @option options [optional, String] :popular_category Use term category ( e.g. cars )
  # @option options [optional, String] :geo_all Geo Stuff
  # @option options [optional, String] :geo_community More Geo Stuff
  # @option options [optional, String] :geo_search Geo Search
  # @option options [optional, String] :open_search_keyword Key word
  # @option options [optional, String] :user_keyword Use term nickname
  # @option options [optional, String] :gallery Use term albumID_albumKey
  # @option options [optional, String] :nickname Use term nickname
  # @option options [optional, String] :nickname_recent Use term nickname
  # @option options [optional, String] :nickname_popular Use term nickname
  # @option options [optional, String] :user_comments Use term nickname
  # @option options [optional, String] :geo_user Use term nickname
  # @option options [optional, String] :geo_album Use term nickname
  #
  # pulling more details from every photo.
  def search( data, options={} )
    auth_anonymously
    search_rss(data,options).items.map do |item|
      image_id, image_key = item.link.split('/').last.split('#').last.split('_')
      Smile::Photo.find( :image_id => image_id, :image_key => image_key )
    end
  end

  # Search SmugMug for pics.  This search is slower than the others, but returns Smile::Photo objects
  #
  # @param [String] data This is the search term that you want to use
  # @param [optional, Hash] options Hash of options for the search method
  # @option options [optional, String] :keyword override the keyword search
  # @option options [optional, String] :popular Use term all or today
  # @option options [optional, String] :popular_category Use term category ( e.g. cars )
  # @option options [optional, String] :geo_all Geo Stuff
  # @option options [optional, String] :geo_community More Geo Stuff
  # @option options [optional, String] :geo_search Geo Search
  # @option options [optional, String] :open_search_keyword Key word
  # @option options [optional, String] :user_keyword Use term nickname
  # @option options [optional, String] :gallery Use term albumID_albumKey
  # @option options [optional, String] :nickname Use term nickname
  # @option options [optional, String] :nickname_recent Use term nickname
  # @option options [optional, String] :nickname_popular Use term nickname
  # @option options [optional, String] :user_comments Use term nickname
  # @option options [optional, String] :geo_user Use term nickname
  # @option options [optional, String] :geo_album Use term nickname
  #
  # @return [Array<Smile::Photo>] RSS feed from the RSS::Parser.parse method
  def search_rss( data, options={} )
    raw = search_raw( data, options )
    RSS::Parser.parse( raw, false ) || OpenStruct.new( :items => [] )
  end

  # Raw feed from the SmugMug data feeds
  #
  # @param [String] data This is the search term that you want to use
  # @param [optional, Hash] options Hash of options for the search method
  # @option options [optional, String] :keyword override the keyword search
  # @option options [optional, String] :popular Use term all or today
  # @option options [optional, String] :popular_category Use term category ( e.g. cars )
  # @option options [optional, String] :geo_all Geo Stuff
  # @option options [optional, String] :geo_community More Geo Stuff
  # @option options [optional, String] :geo_search Geo Search
  # @option options [optional, String] :open_search_keyword Key word
  # @option options [optional, String] :user_keyword Use term nickname
  # @option options [optional, String] :gallery Use term albumID_albumKey
  # @option options [optional, String] :nickname Use term nickname
  # @option options [optional, String] :nickname_recent Use term nickname
  # @option options [optional, String] :nickname_popular Use term nickname
  # @option options [optional, String] :user_comments Use term nickname
  # @option options [optional, String] :geo_user Use term nickname
  # @option options [optional, String] :geo_album Use term nickname
  #
  # @return [RestClientResponse] The response from a RestClient.get request
  def search_raw( data, options={} )
    defaults = { :type => 'keyword', :data => data }
    options = defaults.merge!( options )
    base_feed( options )
  end
end

