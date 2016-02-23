class RiakController < ApplicationController

  # get functions from helpers
  helpers RiakHelpers
  helpers AuthHelpers

  before do
    params[:per_page] ||= 15
    params[:page] ||= 1 
    params[:search_key] ||= 'facts.fqdn'
    params[:search_value] ||= '*'
    params[:index] ||= 'mco_nodes'

    params[:bucket_type] ||= 'puppet'
    params[:bucket] ||= 'nodes'
    params[:key] ||= '*'

    params[:auth] ||= "ldap"

    @results = Hash.new
    @results['per_page'] = params[:per_page]
    @results['page'] = params[:page]
  end

  get '/' do
  end

  get '/search/?' do
    protected!(params[:auth],request,session)
    content_type :json

    # get results
    search_results = search(params[:index],params[:search_key],params[:search_value],params[:page],params[:per_page])

    # display results
    @results['query'] = "#{params[:search_key]}:#{params[:search_value]}"
    @results['results'] = search_results
    @results.to_json
  end

  get '/keys/?' do
    protected!(params[:auth],request,session)
    content_type :json

    search_results = keys(params[:bucket_type],params[:bucket],params[:key])
    
    # display results
    @results['query'] = "#{params[:key]}:#{params[:value]}"
    @results['results'] = search_results
    @results.to_json
  end

end
