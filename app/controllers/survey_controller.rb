class SurveyController < ApplicationController
  before_filter :get_participant, :except => [:index, :start]

  def index
  end

  def start
    @participant = Participant.make("esbi")
    redirect_to @participant.current_path
  end

  def page
    if @participant.completed
      redirect_to @participant.current_path
    else
      @questions = Question.find_for(@participant)
      @answers = Answer.find_for(@participant)
      render :action => "page#{@participant.page}"
    end
  end

  def save
    @participant.update_progress(params[:page])
    if @participant.page == 1 || @participant.page == 2
      @participant.update_attributes(params[:participant])
      error_count = @participant.errors.count
    end
    if !params[:answer].blank?
      @answers, error_count = Answer.save_all(params[:answer])
    end
    if error_count == 0
      @participant.next_page!
      redirect_to @participant.current_path
    else
      @questions = Question.find_for(@participant)
      render :action => "page#{@participant.page}"
    end
  end

  def feedback
  end

  private

  def get_participant
    @participant = nil
    if params[:key].present? && params[:key] =~ /^[0-9a-f]{12}$/i
      @participant = Participant.where(:key => params[:key]).first
    end
    if @participant.nil?
      flash[:error] = "Unknown participant code."
      redirect_to :action => 'index'
    end
  end

end
