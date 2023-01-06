// FormHandler handles setup and re-rendering of remote forms
function FormHandler(form) {

  // Element References
  this.form = $(form); // JQuery object for Form
  this.formEl = this.form.get(0); // Reference to form's DOM element
  this.formContainer = this.form.closest('.form-container');
  this.submitButton = this.formContainer.find('.form-submit');
  this.cancelButton = this.formContainer.find('.form-reset');
  this.inputs = this.form.find(':input');

  // Callbacks
  this.onResetCallback = false;
  this.onAjaxSuccessCallbacks = [];

  // Set up form on initialization
  this.clean(); // Form has not yet been altered from its original state
  this.addHandlers();
}

FormHandler.prototype = {
  addHandlers: function() {
    let fh = this;
    let onAjaxSuccessCallbacks = this.onAjaxSuccessCallbacks;
    
    // On submit button click, submit form.
    this.submitButton.click(function(e) {
      fh.form.submit();
    });

    // On cancel button click, reset form to original state and set to clean
    this.cancelButton.click(function() {
      fh.formEl.reset();
      if(fh.onResetCallback) {
        fh.onResetCallback();
      }
      fh.clean();
    });

    // On any change to form inputs, set form to dirty
    this.watch(this.inputs);

    // On Successful Form Submit, Replace form with response HTML.
    this.form.on("ajax:success", function(evt, data, status, xhr) {
      fh.formContainer.replaceWith(xhr.responseText);
      let newfh = new FormHandler($(fh.form.selector)); // Reset form with new handlers
      newfh.now(...onAjaxSuccessCallbacks);
    });
  },

  // Watch for change on passed elements
  watch: function(elements) {
    let fh = this;

    elements.on("change keypress", function() {
      fh.dirty();
    });

    return elements;
  },

  // Form has been changed; may be different from model in database
  dirty: function() {
    this.isDirty = true;
    this.enableButtons();
  },

  // Form has not been changed; matches model in database
  clean: function() {
    this.isDirty = false;
    this.disableButtons();
  },

  // Disables submit and cancel buttons
  disableButtons: function() {
    this.submitButton.addClass('disabled');
    this.cancelButton.addClass('disabled');
  },

  // Enables submit and cancel buttons
  enableButtons: function() {
    this.submitButton.removeClass('disabled');
    this.cancelButton.removeClass('disabled');
  },

  // Set onReset Callback
  onReset: function(callback) {
    this.onResetCallback = callback;
  },

  // Add callbacks for Ajax Success
  onAjaxSuccess: function (...callbacks) {
    this.onAjaxSuccessCallbacks.push(...callbacks);
  },

  // Calls functions immediately and adds again on Ajax Success
  now: function(...callbacks) {
    let fh = this;
    callbacks.forEach(callback => callback(fh));
    fh.onAjaxSuccess(...callbacks);
  }
}
