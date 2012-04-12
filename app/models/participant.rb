class Participant < ActiveRecord::Base
  has_many :answers
  serialize :c_money, Array

  @@audit_values = {
    5 => {"Never or almost never" => 0, "Less than once a month" => 1, "Once a month" => 1, "Once every two weeks" => 2, "Once a week" => 2, "Two or three times a week" => 3, "Four or five times a week" => 4, "Six or seven times a week" => 4},
    6 => {"1" => 0, "2" => 0, "3" => 1, "4" => 1, "5" => 2, "6" => 2, "7" => 3, "8" => 3, "9" => 3, "10" => 4, "11" => 4, "12" => 4, "13" => 4, "14" => 4, "15" => 4, "16" => 4, "17" => 4, "18" => 4, "19" => 4, "20" => 4, "21" => 4, "22" => 4, "23" => 4, "24" => 4, "25-29" => 4, "30-34" => 4, "35-39" => 4, "40-49" => 4, "50 or more" => 4},
    7 => {"Never" => 0, "Once or twice a year" => 1, "Less than monthly" => 1, "Monthly" => 2, "Weekly" => 3, "Daily or almost daily" => 4},
    8 => {"Never" => 0, "Less than monthly" => 1, "Monthly" => 2, "Weekly" => 3, "Daily or almost daily" => 4},
    9 => {"Never" => 0, "Less than monthly" => 1, "Monthly" => 2, "Weekly" => 3, "Daily or almost daily" => 4},
    10 => {"Never" => 0, "Less than monthly" => 1, "Monthly" => 2, "Weekly" => 3, "Daily or almost daily" => 4},
    11 => {"Never" => 0, "Less than monthly" => 1, "Monthly" => 2, "Weekly" => 3, "Daily or almost daily" => 4},
    12 => {"Never" => 0, "Less than monthly" => 1, "Monthly" => 2, "Weekly" => 3, "Daily or almost daily" => 4},
    13 => {"No" => 0, "Yes, but not in the last year" => 2, "Yes, during the last year" => 4},
    14 => {"No" => 0, "Yes, but not in the last year" => 2, "Yes, during the last year" => 4}
  }

  @@avg_dpo = {
    "Male" => {"18-19" => 5.5, "20-24" => 3.5, "25-29" => 3.5, "30-34" => 3.5, "35-39" => 3.5, "40-44" => 3.5, "45-49" => 3.5, "50-54" => 3.5, "55-59" => 1.5, "60-64" => 1.5, "65-69" => 1.5, "70-74" => 1.5, "75-79" => 1.5, "80-84" => 1.5, "85+" => 1.5},
    "Female" => {"18-19" => 3.5, "20-24" => 3.5, "25-29" => 1.5, "30-34" => 1.5, "35-39" => 1.5, "40-44" => 1.5, "45-49" => 1.5, "50-54" => 1.5, "55-59" => 1.5, "60-64" => 1.5, "65-69" => 1.5, "70-74" => 1.5, "75-79" => 1.5, "80-84" => 1.5, "85+" => 1.5}
  }

  @@avg_dpw = {
    "Male" => {"18-19" => 5.25, "20-24" => 5.25, "25-29" => 5.25, "30-34" => 5.25, "35-39" => 5.25, "40-44" => 5.25, "45-49" => 5.25, "50-54" => 5.25, "55-59" => 5.25, "60-64" => 5.25, "65-69" => 5.25, "70-74" => 5.25, "75-79" => 5.25, "80-84" => 2.25, "85+" => 2.25},
    "Female" => {"18-19" => 2.25, "20-24" => 2.25, "25-29" => 1.75, "30-34" => 1.75, "35-39" => 1.75, "40-44" => 2.25, "45-49" => 2.25, "50-54" => 0.875, "55-59" => 0.75, "60-64" => 0.875, "65-69" => 0.375, "70-74" => 0.375, "75-79" => 0.375, "80-84" => 0, "85+" => 0}
  }

  @@themes = {
    :two => {:colors=>["#339933", "red"], :marker_color=>"black", :font_color=>"black", :background_colors=>["#d1edf5", "white"]},
    :three => {:colors=>["#339933", "#336699", "red"], :marker_color=>"black", :font_color=>"black", :background_colors=>["#d1edf5", "white"]}
  }

  def audit_score(question, answer)
    @@audit_values[question][answer]
  end

  def self.make
    begin
      key = Digest::SHA1.hexdigest("#{rand} - #{Time.now.to_f}")[0..11]
      participant = self.create(:key => key)
    rescue
      retry
    end
    Answer.make_all(participant)
    return participant
  end

  # Sets the current page to that of the page the participant
  # just submitted. Checks to prevent skipping ahead and to
  # ensure a valid page.
  def update_progress(page)
    unless page.nil?
      p = page.to_i
      if p > 0 && p <= self.page
        self.page = p
        self.save
      end
    end
  end

  # Increment the current page, and save.
  # If the end is reached, automatically sets completed to true.
  def next_page!
    if self.page > Question.count(:page, :distinct => true)
      self.completed = true
    end
    if self.page != 99
      self.page += 1
    end
    # Skip pages when answering no to Question on page 3 or 5
    if self.page == 4
      answer = Answer.where(:participant_id => self.id, :page => 3).order("id ASC").select(:value).first
      if answer.value =~ /no/i
        self.page = 99
      end
    elsif self.page == 6
      answer = Answer.where(:participant_id => self.id, :page => 5).order("id ASC").select(:value).first
      if answer.value =~ /no/i
        self.page = 8
      end
    end
    self.save
  end

  # The AUDIT score (page 4)
  def audit
    if self.c_audit.nil?
      answers = Answer.where(:participant_id => self.id, :page => 4).order("id ASC")
      self.c_audit = answers.reduce(0) do |sum, a|
        sum + audit_score(a.question_id, a.value)
      end
      self.save
    end
    self.c_audit
  end

  # The Leeds Dependence Questionnaire score (page 7)
  def ldq
    if self.c_ldq.nil?
      answers = Answer.where(:participant_id => self.id, :page => 7).order("id ASC")
      self.c_ldq = answers.reduce(0) do |sum, a|
        sum + a.value.to_i
      end
      self.save
    end
    self.c_ldq
  end

  def typical_drinks
    Answer.where(:participant_id => self.id, :question_id => 6).select(:value).first.value
  end

  def dpw
    if self.c_dpw.nil?
      drinks = typical_drinks.to_i
      frequency = Answer.where(:participant_id => self.id, :question_id => 5).select(:value).first.value
      case frequency
      when /^Never/
        mult = 0
      when /^(Less)|(Once a month)/
        mult = 0.25
      when /two weeks$/
        mult = 0.5
      when /Once a week/
        mult = 1
      when /^Two/
        mult = 2.5
      when /^Four/
        mult = 4.5
      when /^Six/
        mult = 6.5
      end
      self.c_dpw = drinks * mult
    end
    self.c_dpw
  end

  def money
    if self.c_money.empty?
      dpy = self.dpw * 52
      self.c_money = [dpy * 1.5, dpy * 6.0]
      self.save
    end
    self.c_money
  end

  def bac
    if self.c_bac.nil?
      # Get the values of the Answers needed for the calculation
      reqd_answers = Answer.where(:participant_id => self.id, :page => 6).order("id ASC").pluck(:value)
      reqd_answers += Answer.where(:participant_id => self.id, :page => 2).order("id ASC").pluck(:value)
      # Number of Standard Drinks
      sd = reqd_answers[0].to_i
      # Body Water constant
      bw = 0.58 # Males
      if reqd_answers[4] == "Female"
        bw = 0.49
      end
      # Weight
      wt = reqd_answers[3].to_f
      # Metabolism Rate
      if self.audit <= 7
        mr = 0.017
      else
        mr = 0.02
      end
      # Drinking Period
      dp = reqd_answers[1].to_i
      self.c_bac = ((0.806 * sd) / ((bw * wt) - (mr * dp))).round(2)
      self.save
    end
    self.c_bac.to_f
  end

  def display_dpo?
    a = Answer.where(:participant_id => self.id, :page => 2).order("id ASC").limit(2).pluck(:value)
    a += Answer.where(:participant_id => self.id, :page => 4).order("id ASC").limit(2).pluck(:value)
    return a[3].to_i > 4
  end

  def display_dpw?
    a = Answer.where(:participant_id => self.id, :page => 2).order("id ASC").limit(2).pluck(:value)
    return self.dpw > 14
  end

  def dpo_graph
    a = Answer.where(:participant_id => self.id, :page => 2).order("id ASC").limit(2).pluck(:value)
    a += Answer.where(:participant_id => self.id, :page => 4).order("id ASC").limit(2).pluck(:value)
    g = Gruff::Bar.new(400)
    if (a[3].to_i >= @@avg_dpo[a[0]][a[1]])
      g.theme = @@themes[:three]
    else
      g.theme = @@themes[:two]
    end
    g.bar_spacing = 0.6
    g.title = "Average Number of Standard Drinks"
    g.data("Australian Medical Guidelines", 4)
    if (a[3].to_i >= @@avg_dpo[a[0]][a[1]])
      g.data(self.peergroup, @@avg_dpo[a[0]][a[1]])
    end
    g.data("YOU", a[3].to_i)
    g.sort = false
    g.minimum_value = 0
    return g.to_blob
  end

  def dpw_graph
    a = Answer.where(:participant_id => self.id, :page => 2).order("id ASC").limit(2).pluck(:value)
    g = Gruff::Bar.new(400)
    if (self.dpw >= @@avg_dpw[a[0]][a[1]])
      g.theme = @@themes[:three]
    else
      g.theme = @@themes[:two]
    end
    g.bar_spacing = 0.6
    g.title = "Standard Drinks Per Week"
    g.data("Australian Medical Guidelines", 14)
    if (self.dpw >= @@avg_dpw[a[0]][a[1]])
      g.data(self.peergroup, @@avg_dpw[a[0]][a[1]])
    end
    g.data("YOU", self.dpw)
    g.sort = false
    g.minimum_value = 0
    return g.to_blob
  end

  def audit_only?
    a = Answer.where(:participant_id => self.id, :page => 5).pluck(:value)
    return a[0] == "No"
  end

  def peergroup
    if self[:peergroup].blank?
      a = Answer.where(:participant_id => self.id, :page => 2).order("id ASC").limit(2).pluck(:value)
      self[:peergroup] = "#{a[1]} year old "
      if a[0] =~ /female/i
        self[:peergroup] += "women"
      else
        self[:peergroup] += "men"
      end
      self[:peergroup] += " in Australia"
      self.save
    end
    return self[:peergroup]
  end
end
