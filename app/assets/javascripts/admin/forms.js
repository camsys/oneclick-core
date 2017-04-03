console.log("FORM HELPER CALLED");

function FormHandler(form) {
  console.log("NEW FORM HANDLER");
  this.form = $(form);
  this._container = this.form.closest('.form-container');
  this._submitButton = this._container.find('.panel-form-submit');
  this._cancelButton = this._container.find('.panel-form-cancel');
  this._addSubmitHandler();
  this._addAJAXHandler();
  this._addCancelHandler();
}

FormHandler.prototype = {
  _addSubmitHandler: function() {
    var fh = this;
    this._submitButton.click(function() {
      fh.form.submit();
    });
  },
  _addAJAXHandler: function() {
    var fh = this;
    console.log("adding AJAX handler to ", fh.form);
    this.form.on("ajax:complete", function(xhr, status) {
      console.log("AJAX SUCCESSFUL", xhr);
      // fh._container.replaceWith(xhr.responseText);
    });
    // this.form.on("ajax:remotipartComplete", function(e, data){
    //   console.log("REMOTIPART COMPLETE", data);
    // });
  },
  _addCancelHandler: function() {
    var fh = this;
    this._cancelButton.click(function() {
      console.log("CANCEL BUTTON CLICKED");
    });
  }
}

// FormHelper constructor function
function FormHelper() {
  console.log("Initializing FormHelper...");
  console.log("IDENTIFYING FORMS", $('form'));

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
