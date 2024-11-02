require "net/http"

class SearchController < ApplicationController
  def index
  end

  def search
    @criteria = params[:criteria]
    @results = nil
    if @criteria
        @results = RecipeApi::Api.new.search_recipes(@criteria)
    end
    render "index"
  end
end
