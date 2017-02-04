class LandmarksController < ApplicationController

  def index
    @landmarks = Landmark.all.order(:name)
  end

end