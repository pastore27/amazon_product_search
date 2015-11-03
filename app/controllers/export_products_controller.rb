class ExportProductsController < ApplicationController

  def show
    @labels = Label.all
  end

end
