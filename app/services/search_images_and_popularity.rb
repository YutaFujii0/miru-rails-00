class SearchImagesAndPopularity
  base_url = "https://www.googleapis.com/customsearch/v1?&"
  parameters = {
    cx: ENV["SEARCH_ENGINE_ID"],
    key: ENV["GOOGLE_CUSTOM_SEARCH_KEY"],
    num: 9,
    searchType: "image",
    imgColorType: "color",
    safe: "active",
    fields: "searchInformation(searchTime,totalResults),items/link"
  }
  @url = base_url + parameters.map { |k, v| "#{k}=#{v}" }.join("&")
  # -> REFERENCE 1 (refer to the bottom)

  def self.call(keyword)
    doc = JSON.parse(open(URI.encode(@url + "&q=#{keyword}")).read) # -> REFERENCE 2 (refer to the bottom)
    {
      popularity: doc["searchInformation"]["totalResults"].to_i,
      image_paths: doc["items"]&.map { |item| item["link"] } || [Food::DEFAULT_IMAGE]
    }
  rescue OpenURI::HTTPError => e # -> REFERENCE 3 (refer to the bottom)
    puts "============================================================"
    puts e.message
    puts "Please check if Google Custom Search API exceeds daily query limit."
    puts "============================================================"
    return { popularity: 0, image_paths: [Food::DEFAULT_IMAGE] }
  end
end

# TODO: return 2 things: number of results / an array containing image paths
# 1. create the url
# 2. open url (GET request) and convert it into json file
# 3. for each item, pick up elements needed
# 4. return a hash
# 5. use begin/rescue method for the case the url returns no images



# REFERENCES
# 1. We set some variables out of "call" method to improve the runtime performance.
#     All these variables are to create endpoint URL.
#     <NOTE>
#     In parameters[:fields], you can manipulate the returned hash content
#     To improve runtime performance, we narrow results to necessary things.

# 2. It's important to use "URI.encode" method for the keyword to
#     convert NON-english language into ascii code.
#     Without this you'll see the error from GoogleCustomSearch API

# 3. Even if the request returns 403 error, the "call" method returns a "dummy" hash.
#     Otherwise you'll see 'undefined method error: *** for NilClass' in the views.
