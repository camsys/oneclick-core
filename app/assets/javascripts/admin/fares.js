// Helper for building zone-based fare structures
function FareZoneHelper(fareZonesJSON, containerDiv, tableDiv, fareZoneTemplate, options) {
  this.originalFareZones = JSON.parse(fareZonesJSON);
  this.codes = Object.keys(this.originalFareZones);
  this.container = containerDiv;
  this.table = tableDiv;
  this.template = fareZoneTemplate;
  this.options = options || {};
  this.searchPath = options.searchPath || '';
  this.ingredientLabelTag = options.ingredientLabelTag || '';
  this.fh = options.formHandler || null;
  this.tableReplacer = options.tableReplacer || null;
  this._init();
}

FareZoneHelper.prototype = {

  // Renders all fare zones as divs
  _init: function() {
    var fzh = this;
    var zones = this.originalFareZones;
    Object.keys(zones).forEach(function(code){
      fzh._render(code, zones[code]);
    });
  },

  // Renders a fare zone object in the appropriate container
  _render: function(code, recipe) {
    var fzh = this;

    // Render a blank fare_zone div into the container
    this.container.append(this.template);
    var fareZoneDiv = this.container.find('.fare-zone-container').last();

    // Add a data-code value
    fareZoneDiv.attr('data-code', code);

    // Update the name attribute of the recipe input
    var recipeInput = fareZoneDiv.find('.recipe-input');
    recipeInput.attr('name', recipeInput.attr('name') + '[' + code + ']');

    // Add an appropriate label
    fareZoneDiv.find('.region-label-container label').text('Zone ' + code.toUpperCase());

    // Set the recipe field value and initialize the recipe field as a new M.Recipe
    recipeInput.val(JSON.stringify(recipe));

    // Add a click handler for delete button
    fareZoneDiv.find('.delete-region').click(this.deleteFareZone(code));

    // Have the formHandler watch the new zone div for changes
    if(this.fh) {
      this.fh.watch(fareZoneDiv);
    }

    var recipe = new M.Recipe({
      container: fareZoneDiv.find('.region-builder-container'),
      recipeInput: recipeInput,
      searchPath: this.searchPath,
      ingredientLabelTag: this.ingredientLabelTag
    });

    return fareZoneDiv;

  },

  // Clears the fare zones
  _clear: function() {
    this.container.empty();
  },

  // Resets the fare zone form by clearing it and then rebuilding
  reset: function() {
    this._clear();
    this._init();
  },

  // Adds a new fare zone
  addFareZone: function() {
    this._render(this._nextCode(), []).trigger('change');
    this.hideTable()();
  },

  // Removes a fare zone
  deleteFareZone: function(code) {
    var codes = this.codes;
    var hideTable = this.hideTable();

    // Return a function to delete the fare zone div
    return function () {
      var fareZoneDiv = $(this).closest('.fare-zone-container');
      fareZoneDiv.trigger('change').remove(); // trigger change for formHelper

      // Remove the code from the list of taken codes
      var codeIndex = codes.indexOf(code);
      if(codeIndex >= 0) {
        codes.splice(codeIndex, 1);
      }

      // Hide the fare zone table
      hideTable();
    }
  },

  // Picks the next free zone code letter
  _nextCode: function() {
    var alphabet = "abcdefghijklmnopqrstuvwxyz".split("");
    var i = 0;
    while(i < alphabet.length) {
      var code = alphabet[i];
      if(this.codes.includes(code)) {
        i++;
      } else {
        this.codes.push(code);
        return code;
      }
    }
    return '';
  },

  // Hides the fare zones table and replaces it with a message
  hideTable: function() {
    var table = this.table;
    var tableReplacer = this.tableReplacer;
    return function() {
      table.addClass('hidden');
      tableReplacer.removeClass('hidden');
    }
  },

  // Shows the table again
  showTable: function() {
    this.table.removeClass('hidden');
    this.tableReplacer.addClass('hidden');
  }
};
