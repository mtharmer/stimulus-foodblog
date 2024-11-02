require "net/http"

module RecipeApi
    class Api
        BASE_URL = "https://platform.fatsecret.com/rest/"

        def initialize
            @client = Rails.configuration.x.recipe_api.client_id
            @secret = Rails.configuration.x.recipe_api.secret
            @@token = nil
            @@ttl = 0
        end

        def refresh_token
            uri = URI("https://oauth.fatsecret.com/connect/token")
            req = Net::HTTP::Post.new(uri)
            req.basic_auth @client, @secret
            req.content_type = "application/x-www-form-urlencoded"

            req.set_form_data({
                "grant_type" => "client_credentials",
                "scope" => "basic"
            })

            req_options = {
                use_ssl: uri.scheme == "https"
            }
            res = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
                http.request(req)
            end
            body = JSON.parse(res.body)
            @@token = body["access_token"]
            @@ttl = body["expires_in"]
        end

        def get(uri)
            auth = "Bearer #{@@token}"
            req = Net::HTTP::Get.new(uri)
            req["Authorization"] = auth
            res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
                http.request(req)
            end
            JSON.parse(res.body)
        end

        def get_recipe(id)
            refresh_token if needs_token?
            uri = URI(BASE_URL + "recipe/v2?recipe_id=#{id}&format=json")
            get(uri)
        end

        def search_recipes(keyword)
            refresh_token if needs_token?

            uri = URI(BASE_URL + "recipes/search/v3?search_expression=#{keyword}&format=json")
            get(uri)
        end

        def needs_token?
            @@token.nil? || @@ttl.zero?
        end
    end
end
