// Helper for building zone-based fare structures
function FareZoneHelper(fareZonesJSON, containerDiv, fareZoneTemplate, options) {
  this.originalFareZones = JSON.parse(fareZonesJSON);
  this.container = containerDiv;
  this.template = fareZoneTemplate;
  this.options = options || {};
  console.log("FARE ZONE HELPER", this);
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
  _render: function(code, zone) {
    // Render a blank fare_zone div into the container
    this.container.append(this.template);

    // Update it with appropriate values
    var fareZoneDiv = this.container.find('.fare-zone-container').last();
    fareZoneDiv.data('code', code);
    console.log("FARE ZONE DIV", fareZoneDiv.data("code"));
  }
};
