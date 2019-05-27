module Rtw
  class AppointmentsController < ApplicationController

    def search
      #hash = ["2019-05-26 10:45:00 -0400","2019-05-26 11:00:00 -0400", "2019-05-27 12:45:00 -0400"]
      hash = params[:appointments].shuffle[0..2]

      render status: 200, json: hash
    end

    protected

    def appointments_params
      params.require(:appointments).permit(
        :appointments
      )
    end

  end
end 