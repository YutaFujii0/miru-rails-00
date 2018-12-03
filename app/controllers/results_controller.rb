class ResultsController < ApplicationController
  def index
    # TODO: return all results with image paths
    # set the instances
    # search images for each food

    @results = Result.where(menu_id: params[:menu_id])
    search_image_for_each_food(@results)
    @fav = Favourite.where(user_id: current_user)
    @menu = Menu.find(params[:menu_id]) #footer favourite number
    @all = @results.to_json
    @sort_name = @results.includes(:food).order("foods.name")
    @sort_popularity = @results.includes(:food).order("foods.popularity")

  end

  def order
    @orders = Result.where("results.order > ?", 0).where(menu_id: params[:menu_id].to_i)
    @menu = Menu.find(params[:menu_id])
    if @orders.first.nil? # If no orders made
      @food_title = ""
      @food_summary = ""
    else
      @food_title = @orders.first.food.name
      @food_summary = @orders.first.food.en
    end
    @fav = Favourite.where(user_id: current_user) #footer favourite number
  end

  # for the order page/ + and - icon
  def update
    @result = Result.find(params[:id])
    if params[:button] == "increase"
      @result.order += 1
    elsif params[:button] == "decrease"
      @result.order -= 1
    end
    @result.save!
    @order_total = Result.where("results.order > ?", 0).where(menu_id: @result.menu.id).sum("order")
    respond_to do |format|
      format.js
    end
  end

  # for the result#index page/ check icon
  def toggle
    @result = Result.find(params[:id])
    @result.order = @result.order.zero? ? 1 : 0
    @result.save!
    @order_total = Result.where("results.order > ?", 0).where(menu_id: @result.menu.id).sum("order")
    respond_to do |format|
      format.js
    end
  end

  private

  def search_image_for_each_food(results)
    # boost threads to increase performance
    # pool = Concurrent::FixedThreadPool.new(10)
    # completed = []

    translation_of_meal = Language.find_by(code: results.first.lang)&.meal_is # -> REFERENCE 1 (refer to the bottom)
    results.each do |result|
      # pool.post do
        # ==========================================
        # if result.food.images.nil?
        #   result.food.images = [Food::SAMPLE_IMAGES.sample]
        #   result.food.save!
        # end
        # ------------------------------------------
        if result.food.en.nil?
          result.food.en = Translate.call(result.food.name)
          result.food.save!
        end
        if result.food.images.nil?
          keyword = "#{result.food.name}+#{translation_of_meal}"
          attributes = SearchImagesAndPopularity.call(keyword)
          result.food.popularity = [999999999, attributes[:popularity]].min
          result.food.images = attributes[:image_paths]
          result.food.save!
        end
        # ==========================================
        # completed << 1
      # end
    end
    # temporary measure: wait_for_termination does not work well
    # sleep(0.1) unless completed.count == results.count
    # pool.shutdown
    # pool.wait_for_termination
  end
end

# REFERENCES
# 1. Here, we get the string of 'meal' translated to the language of the menu.
#     This variable is used for creating keyword which we pass to the API.
#     The reason for this is to improve the relevance of the result images.
#     For example, Japanese menu has lot of fishes which really is 'sashimi',
#     but if you put those words API returns the fish itself not the meal.
#     There are other possibilities as an additional keyword to search with:
#       - food(english)
#       - meal(english)
#       - 'food'(translated to that lang)
#     However we feel 'meal'(translated) is the best performer.
