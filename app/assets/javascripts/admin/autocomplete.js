$(document).on("turbolinks:load", () => {
  // Set up a listener to detect when a user tries to delete a tag
  $(".autocomplete-tag-index").on("click", ".autocomplete-tag-delete", onAutocompleteDelete);

  // Implement autocomplete behavior on the desired fields
  $("input.autocomplete-field").each(makeInputAutocomplete);

  // Buttons for adding all tags to field
  $(".autocomplete-add-all").click((e) => {
    const selector = e.target.dataset['selector'];
    const source = window[e.target.dataset['source']]();

    for (let i=0; i<source.length; i++) {
      findOrCreateTag($(`.autocomplete-tag-index${selector}`), source[i]);
    }
  });
});


function makeInputAutocomplete(index, input) {
  input = $(input);

  input.autocomplete({
    source: window[input.data("source")](),
    minLength: 0,
    appendTo: $(input).closest(".autocomplete-tag-new").find(".autocomplete-results"),
    select: autocompleteSelect
  }).focus(function () {
    $(this).autocomplete("search", "");
  });

  $(".autocomplete-results ul").addClass("dropdown-menu");
}

function onAutocompleteDelete(event) {
  const oldTag = $(event.target).parents().closest(".autocomplete-tag-show");
  if (oldTag.data("persisted")) {
    oldTag.find("input[type=hidden][data-type=_destroy]").val(true);
    oldTag.hide();
  } else {
    oldTag.remove();
  }
}

// When the user selects an item from the dropdown, we want to add the selected item to the page.
function autocompleteSelect (event, ui) {
  const self = $(event.target);
  findOrCreateTag(self.parents().closest(".autocomplete-tag-index"), ui.item);

  // Once the tag has been added, we should clear and defocus the input field.
  self.val("");
  self.blur();
  return false;
}

// We should only create a new tag if it doesn't already exist.
function findOrCreateTag (parent, data) {
  const existingTag = parent.find(`.autocomplete-tag-show[data-unique-key=${data["unique-key"]}]`);

  if (existingTag.length === 0) {
    const template = parent.find(".autocomplete-tag-template")
    const newTag = createNewTag(template, data);
    newTag.insertBefore(parent.find(".autocomplete-tag-new"));
  } else {
    existingTag.find("input[type=hidden][data-type=_destroy]").val(false);
    existingTag.insertBefore(parent.find(".autocomplete-tag-new"));
    existingTag.show();
  }
}

// Create a new tag by cloning the elements from a hidden template on the page
function createNewTag (template, tagData) {
  const newTag = template.clone();
  newTag.attr("data-unique-key", tagData["unique-key"]);
  newTag.removeClass("autocomplete-tag-template hidden");
  newTag.addClass("autocomplete-tag-show");

  // Update the new tag's input fields
  for (const property in tagData) {
    if (property === 'label') {
      newTag.find("label").text(tagData.label);
    } else {
      const field = newTag.find(`input[type=hidden][data-type=${property}]`);
      field.val(tagData[property]);
    }
  }

  // Increment the template's index by 1
  template.find('input[type=hidden]').each((index, input) => {
    input = $(input);
    const name = input.attr('name').replace(/\[(\d+)\]/g, (match, p1) => {
      return `[${parseInt(p1) + 1}]`;
    });
    input.attr('name', name);
  });

  return newTag;
}

