// The M object holds utility methods for mapping and manipulating geographies
var M = {

  // Colors for drawing map layers
  colors: [
    'cornflowerblue',
    'indianred',
    'green',
    'gold'
  ],

  recipes: {},

  // Draw service areas onto the map
  drawMaps: function(layers) {
    layers.forEach(function(layer, i) {
      if(layer != null && layer.length > 0) {
        var poly = L.polygon(layer, {color: M.colors[i]}).addTo(map);
        map.fitBounds(poly.getBounds());
      }
    });
  },

  // Recipe object factory for manipulating recipe model data
  Recipe: function(params) {
    this.container = params.container;
    this._input = this.container.find('.region-input');
    this._results = this.container.find('.region-results');
    this._display = this.container.find('.region-display');
    this._recipe = params.recipeInput;
    this._searchPath = params.searchPath;
    this._ingredientLabelTag = params.ingredientLabelTag;
    this.ingredients = [];
    this._load();
    this.originalIngredients = this.ingredients.slice(); // Set original ingredients to a duplicate of ingredients, once loaded
    this._init();
    this._dump();
  }

}

// Creates a jQuery autocomplete widget for searching GeoIngredients and adding them to the GeoRecipe
M.Recipe.prototype = {
  _init: function() {
    this._display.append("");
    var that = this;
    // Set up autocomplete
    that._input
      .autocomplete({
        source: this._searchPath,
        appendTo: this._results,
        select: $.proxy(this._select, this),
        focus: function(e, ui) {
          this.value = ui.item.label;
          e.preventDefault();
        }
      })
      .autocomplete('instance')._renderItem = $.proxy(this._render, this);
  },
  _select: function(e, ui) {
    this.ingredients.push(ui.item.value);
    this._dump();
    return false;
  },
  _render: function(ul, item) {
    var markup = [
      '<a>' + item.label + '</a>'
    ];
    ul.addClass('dropdown-menu');
    return $('<li>')
      .append(markup.join(''))
      .appendTo(ul);
  },

  // Loads instance variables with value of form
  _load: function() {
    this.ingredients = JSON.parse(this._recipe.val());
  },

  // Dumps instance variables to page form
  _dump: function() {
    var oldRecipe = this._recipe.val();
    var newRecipe = JSON.stringify(this.ingredients);
    this._recipe.val(newRecipe);

    // Trigger change event if recipe has changed
    if(oldRecipe !== newRecipe) {
      this._recipe.trigger('change');
    }

    // Refresh the display with new ingredient label divs
    this._display.empty();
    var that = this;
    this.ingredients.forEach(function(ingredient, i) {
      that._make_label(ingredient, i);
    });
  },

  // Creates a label and delete button for an ingredient
  _make_label: function(ingredient, i) {
    var that = this;

    // Create empty label container
    var labelTag = this._ingredientLabelTag
    this._display.append(labelTag);

    // Add a data-index value to the label container
    var container = this._display.children().last();
    container.addClass(ingredient.model);

    // Insert the ingredient description into the label
    var label = container.find('label');
    var labelText = ingredient.attributes.name;
    if(ingredient.attributes.state) { labelText += (', ' + ingredient.attributes.state) }
    label.text(labelText);

    // Set up delete button for ingredient
    var button = container.find('.btn');
    button.click(function() {
      that.ingredients.splice(i, 1);
      that._dump();
    });
  },

  // Resets recipe form to its original state
  reset: function() {
    this.ingredients = this.originalIngredients.slice();
    this._dump();
  }
};
