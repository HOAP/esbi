class SurveyController < ApplicationController
  before_filter :get_participant, :except => [:index, :start]

  def index
  end

  def start
    if params[:code].present?
      if Participant.exists?(:code => params[:code])
        @participant = Participant.where(:code => params[:code]).first
      else
        @participant = Participant.make(params[:code])
      end
      unless @participant.nil? || @participant.completed
        redirect_to page_url(@participant.key)
        return
      end
      flash[:error] = "Non existent code."
    else
      flash[:error] = "Please enter a participant code."
    end
    redirect_to :action => 'index'
  end

  def page
    if @participant.completed
      if @participant.exit_code == 0
        redirect_to report_url(@participant)
      else
        render "exit#{@participant.exit_code}"
      end
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
      if @participant.completed
        redirect_to report_url(@participant.key)
      else
        redirect_to page_url(:key => @participant.key)
      end
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
