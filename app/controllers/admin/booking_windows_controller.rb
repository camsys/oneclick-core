class Admin::BookingWindowsController < Admin::AdminController
  load_and_authorize_resource

  def index
    @booking_windows = @booking_windows.order(:name)
  end

  def new
    @booking_window.agency = Agency.find(params[:agency_id])
  end

  def create
    @booking_window = BookingWindow.new(booking_window_params)
    @booking_window.agency_id = params[:agency_id]

    if @booking_window.save
      flash[:success] = "New Booking Window successfully created."
  	  redirect_to admin_booking_windows_path 
    else
      flash.now[:danger] = "Booking Window failed to be created."
      render :new
    end
  end

  def edit
  end

  def update
    if @booking_window.update(booking_window_params)
      flash[:success] = "New Booking Window successfully updated."
  	  redirect_to admin_booking_windows_path 
    else
      flash.now[:danger] = "Booking Window failed to be updated."
      render :edit
    end
  end

  def destroy
    if @booking_window.destroy
      flash[:success] = "New Booking Window successfully deleted."
    else
      flash[:danger] = @booking_window.errors.full_messages.join(" ")
    end

    redirect_to admin_booking_windows_path
  end

  private

  def booking_window_params
  	params.require(:booking_window).permit(:name, :description, :minimum_days_notice, :maximum_days_notice, :minimum_notice_cutoff_hour)
  end

end
