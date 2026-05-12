class HomesController < ApplicationController
  layout "app"

  def show
    @home = Home.new
  end
end
