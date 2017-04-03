console.log("FORM HELPER CALLED");

function FormHandler(form) {
  this.form = form;
  this._addSubmitHandler();
  this._addAJAXHandler();
}

FormHandler.prototype = {
  _addSubmitHandler: function() {
    $('.panel-form-submit').click(function() {
      $(this).closest('.form-container').find('form').submit();
    });
  },
  _addAJAXHandler: function() {
    $('form').on("ajax:success", function(evt, data, status, xhr) {
      console.log("AJAX SUCCESSFUL");
      $(this).closest('.form-container').replaceWith(xhr.responseText);
    });
  }
}

// FormHelper constructor function
function FormHelper() {
  console.log("Initializing FormHelper...");

  // Identify all the forms on the page, and set each one up with click, AJAX handlers, etc.
  this.forms = $('form').map(function(i, f) {
    new FormHandler(f);
  });
  // Set up cancel buttons for each form
}

FormHelper.prototype = {


  //
  // // Handle Form Submit
  // .on("ajax:success", function(evt, data, status, xhr) {
  //   if(thisForm.newService && xhr.status === 200) {
  //     $('#services-menu').replaceWith(xhr.responseText); // Refresh the whole menu on successful create
  //   } else {
  //     $(this).replaceWith(xhr.responseText); // Re-render just this form
  //     thisForm.setReadOnly(xhr.status !== 206); // Set to read-only unless there were errors
  //   }
  // });
}
