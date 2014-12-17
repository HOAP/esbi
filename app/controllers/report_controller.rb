class ReportController < ApplicationController
  before_filter :get_participant

  def index
  end

  def facts
  end

  def support
  end

  def tips
  end

  def referral
  end

  def finish
    if !params[:page].blank?
      @participant.increment_time(params[:page], params[:page_timer])
    end
  end

  def save
    @participant.update_attributes(params[:participant])
    if !params[:page].blank?
      @participant.increment_time(params[:page], params[:page_timer])
    end
    if @participant.audit_c >= 10 && @participant.appointment == 0
      redirect_to referral_url(:key => @participant.key)
    else
      redirect_to facts_url(:key => @participant.key)
    end
  end

  def time
    @participant.increment_time(params[:page], params[:timer])
    render :text => "1"
  end

  def dpo_graph
    send_data(@participant.dpo_graph, :type => 'image/png', :disposition => 'inline', :filename => 'std_drinks_graph.png')
  end

  def dpw_graph
    send_data(@participant.dpw_graph, :type => 'image/png', :disposition => 'inline', :filename => 'dpw_graph.png')
  end

  private

  def get_participant
    @participant = nil
    if params[:key].present? && params[:key] =~ /^[0-9a-f]{12}$/i
      @participant = Participant.where(:key => params[:key]).first
    elsif params[:key].present?
      @participant = Participant.where(:code => params[:key]).first
    end
    if @participant.nil?
      flash[:error] = "Unknown participant code."
      redirect_to root_url
    end
  end
end
