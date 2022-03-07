// Helper for Rendering Schedule Forms

// Takes JSON of the schedules, a JQuery reference to the containing div, and HTML for a blank schedule
function ScheduleHelper(schedulesJSON, containerDiv, scheduleTemplate, options) {
  this.originalSchedules = JSON.parse(schedulesJSON);
  this.container = containerDiv;
  this.template = scheduleTemplate;
  this.options = options || {};
  this.defaultStartTime = this.options.defaultStartTime || 6 * 3600;
  this.defaultEndTime = this.options.defaultEndTime || 20 * 3600;
  this._init();
}

ScheduleHelper.prototype = {

  // Renders all schedules as divs
  _init: function() {
    var sch = this;
    this.originalSchedules.forEach(function(schedule) {
      sch._render(schedule);
    });
  },

  // Clears all schedules
  _clear: function() {
    this.container.find('.sub-schedule-container').empty();
  },

  // Renders a schedule object in its appropriate container.
  // Returns a JQuery reference to the new schedule.
  _render: function(schedule) {

    // Render the a schedule template into the appropriate day container
    var dayContainer = this._dayContainer(schedule.day);
    dayContainer.append(this.template);

    // Update it with appropriate values
    var scheduleDiv = dayContainer.find('.schedule-body').last();
    scheduleDiv.find('input.day').val(schedule.day);
    scheduleDiv.find('input.id').val(schedule.id);
    scheduleDiv.find('select.start-time').val(schedule.start_time);
    scheduleDiv.find('select.end-time').val(schedule.end_time);
    scheduleDiv.find('select.calendar-date').val(schedule.calendar_date);

    // Set it up with click handlers
    scheduleDiv.find('.delete-schedule').click(this.deleteSchedule);
    scheduleDiv.find('select.start-time').change(this.updateDefaults());
    scheduleDiv.find('select.end-time').change(this.updateDefaults());

    return scheduleDiv;
  },

  // Returns the container for a given schedule day.
  _dayContainer: function(day) {
    if (day !== null) {
      return this.container.find('.sub-schedule-container[data-day=' + day + ']');
    }
    else {
      return this.container.find('.sub-schedule-container');
    }
  },

  // Delete schedule method for click handlers.
  // Hides the div and sets "_destroy" value to true
  deleteSchedule: function() {
    var parent = $(this).parents('.schedule-body');
    parent.find('input.destroy').val(true).trigger('change');
    parent.addClass('hidden');
  },

  // Adds a new schedule to the passed day, and populates it with default values
  addSchedule: function(day) {
    var sch = this;
    return this._render({
      day: day,
      start_time: sch.defaultStartTime,
      end_time: sch.defaultEndTime,
      calendar_date: null
    });
  },

  // Resets the schedule form by clearing out the containers and rebuilding from the original schedules JSON
  reset: function() {
    this._clear();
    this._init();
  },

  // Updates default schedule values
  updateDefaults: function() {
    var sch = this;
    return function() {
      var parent = $(this).parents('.schedule-body');
      sch.defaultStartTime = parent.find('select.start-time').val();
      sch.defaultEndTime = parent.find('select.end-time').val();
    }
  }

}
