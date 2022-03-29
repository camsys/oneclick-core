class ChangeServiceScheduleBelongsToAgency < ActiveRecord::Migration[5.0]
  def up
    add_belongs_to :service_schedules, :agency

    ServiceSchedule.all.each do |s|
      s.update(agency_id: Service.find(s.service_id)&.agency_id)
    end

    remove_reference :service_schedules, :service
  end

  def down
    add_belongs_to :service_schedules, :service

    remove_reference :service_schedules, :agency
  end
end
