class Admin::FeedbacksController < Admin::AdminController

  def index
    @feedbacks = Feedback.pending
  end
  
  def acknowledged
    @feedbacks = Feedback.acknowledged
  end
  
  def show
    @feedback = Feedback.find(params[:id])
  end

end
