class LabelsController < ApplicationController

  def show
    @labels = Label.all
  end

  def create_form

  end

  def create
    label = Label.new(
      :name => params['name']
    )
    label.save

    redirect_to :action => 'show'
  end

  def update_form
    @label = Label.find_by(id: params[:id])
  end

  def update
    label = Label.find_by(id: params[:id])
    label.name = params['name']
    label.save

    redirect_to :action => 'show'
  end

  def delete
    label = Label.find_by(id: params[:id])
    label.destroy

    redirect_to :action => 'show'
  end

end
