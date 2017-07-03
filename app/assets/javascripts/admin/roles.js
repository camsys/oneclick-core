// Helper for Rendering User Role Forms

// Takes JSON of the roles, a JQuery reference to the containing div, and HTML for a blank role
function RoleHelper(rolesJSON, containerDiv, roleTemplate, options) {
  this.originalRoles = JSON.parse(rolesJSON);
  this.container = containerDiv;
  this.template = roleTemplate;
  this.options = options || {};
  this.defaultRole = this.options.defaultRole || {
    resource_type: "Agency"
  };
  this._init();
}

RoleHelper.prototype = {

  // Renders all roles as divs
  _init: function() {
    var rh = this;
    this.originalRoles.forEach(function(role) {
      rh._render(role);
    });
  },
  
  // Clears all roles
  _clear: function() {
    this.container.empty();
  },
  
  // Renders a role object in its appropriate container.
  // Returns a JQuery reference to the new role.
  _render: function(role) {
  
    // Render the a role template into the roles container
    this.container.append(this.template);
  
    // Update it with appropriate values
    var roleDiv = this.container.find('.role-body').last();
        
    roleDiv.find('select.name').val(role.name);
    roleDiv.find('select.resource-id').val(role.resource_id);
    roleDiv.find('input.resource-type').val(role.resource_type);
    roleDiv.find('input.id').val(role.id);
  
    // Set it up with click handlers
    roleDiv.find('.delete-role').click(this.deleteRole);
    roleDiv.find('.role-input.name').change(this.updateResourceSelectCallback());
    this.updateResourceSelect(roleDiv);
    
    return roleDiv;
  },
  

  // Delete role method for click handlers.
  // Hides the div and sets "_destroy" value to true
  deleteRole: function() {
    var parent = $(this).parents('.role-body');
    parent.find('input.destroy').val(true).trigger('change');
    parent.addClass('hidden');
  },
  
  // Adds a new schedule to the passed day, and populates it with default values
  addRole: function() {
    var rh = this;
    return this._render(rh.defaultRole);
  },
  
  // Resets the roles form by clearing out the containers and rebuilding from the original roles JSON
  reset: function() {
    this._clear();
    this._init();
  },

  // Updates appropriate Resource (i.e. agency) selection field based on the role  
  updateResourceSelect: function(parentDiv) {
    // Identify the new role name
    var role = parentDiv.find(':input.name').val();
          
    // Hide and disable all selectors
    parentDiv.find('.role-fields').addClass('hidden')
    parentDiv.find(':input.resource-id').prop('disabled', true);

    // Show and enable the appropriate one
    parentDiv.find(".role-fields[data-role='" + role + "']").removeClass('hidden')
          .find(":input.resource-id").prop('disabled', false);
          
    return parentDiv;
  },
  
  // Returns a callback function to update the resource selection field
  updateResourceSelectCallback: function() {
    var rh = this;
    return function() {
      rh.updateResourceSelect($(this).parents('.role-body'));
    }
  }

}
