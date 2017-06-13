// The M object holds utility methods for mapping and manipulating geographies
var M = {
  
  tileLayerUrls: {
    osm: 'http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    watercolor: 'http://tile.stamen.com/watercolor/{z}/{x}/{y}.jpg',
    toner: 'http://tile.stamen.com/toner/{z}/{x}/{y}.png',
    cartocdn: 'http://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png'
  },

  // Colors for drawing map layers
  colors: [
    'cornflowerblue',
    'indianred',
    'green',
    'gold'
  ],

  recipes: {},
  
  // Sets up a Leaflet.js map with default settings
  setupMap: function(divId, opts={}) {
    var map = L.map(divId);
    var viewCenter = opts.viewCenter || [42.355, -71.066];
    var viewZoom = opts.viewZoom || 10;
    var tileLayer = opts.tileLayer || 'osm';
    
    map.setView(viewCenter, viewZoom);
    
    L.tileLayer(
      M.tileLayerUrls[tileLayer],
      { attribution: 'Map data © OpenStreetMap contributors', maxZoom: 18 }
    ).addTo(map);
    
    map.scrollWheelZoom.disable();
    
    return map;
  },
  
  // Returns a function for building properly scaled point objects
  buildPointScalingFunction: function(valMin, valMax, sizeMin, sizeMax) {
    return function(value) {
      console.log("BUILDING SCALED POINT FOR", value);
      console.log("BASED ON: ", valMin, valMax, sizeMin, sizeMax);
      var size = ( (sizeMax - sizeMin) / (valMax - valMin) ) * (value - valMin) + sizeMin;
      
      return new L.Point(size, size);
    }
  },
  
  // Draws scaled circles on the passed map, based on the dataset provided.
  // Dataset must be an array of objects with a label, value, and point key
  drawScaledCircles: function(mapObj, regions, opts={}) {
    
    // OPTIONS
    var showPopups = ('showPopups' in opts) ? opts.showPopups : false;
    var showLabels = ('showLabels' in opts) ? opts.showLabels : true;
    var minSize = ('scaleRange' in opts) ? opts.scaleRange[0] : 20;
    var maxSize = ('scaleRange' in opts) ? opts.scaleRange[1] : 100;
    
    var regionVals = regions.map(function(r) { return r.value; });
    var minVal = Math.min.apply(Math, regionVals);
    var maxVal = Math.max.apply(Math, regionVals);
    var scalePointForRange = M.buildPointScalingFunction(minVal,maxVal,minSize,maxSize);
    
    regions.forEach(function(region) {
      
      // if (region.geom) {
      //   M.drawPoly(mapObj, region.geom, {color: 'gray', weight: 1, className: 'region-poly'});
      // }
      
      var iconSize = scalePointForRange(region.value);
      
      var marker = L.marker(region.point, {
        icon: L.divIcon({
          className: 'point-icon',
          iconSize: iconSize,
          html: '<div class="point-icon-body"><div class="point-icon-label"><label>' + region.label + ':  </label>' + region.value + '</div></div>'
        })
      }).addTo(mapObj);
      
      if(showPopups) {
        marker.bindPopup(region.label, { offset: new L.Point(0,-10)})
        .on('mouseover', function(e) {
          this.openPopup();
        })
        .on('mouseout', function(e) {
          this.closePopup();
        });
      }
      
    });
    
    // if(showLabels) {
    //   $('.point-icon').mouseenter(function(e) {
    //     $(this).css({ marginTop: '-=5px'});
    //   });
    //   $('.point-icon').mouseout(function(e) {
    //     $(this).css({ marginTop: '+=5px'});
    //   });
    // }
    

  },

  drawPoly: function(mapObj, layer, opts={}) {
    return L.polygon(layer, opts).addTo(mapObj);
  },

  // Draw service area polygons onto the map
  drawMaps: function(mapObj, layers) {
    layers.forEach(function(layer, i) {
      if(layer != null && layer.length > 0) {
        var poly = M.drawPoly(mapObj, layer, { color: M.colors[i]});
        mapObj.fitBounds(poly.getBounds());
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
    this._input.val(''); // Clear the input after selection
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
