// When the user adds a POI we need to create hidden inputs for it
// and add it to the form so that the data will be submitted.
function createPoi (data) {
  let prefix = "landmark_set[landmark_set_landmarks_attributes]"
  let container = document.createElement("div");
  container.classList.add(getPoiClass(data));

  if (data.id) {
    container.append(createHiddenField(`${prefix}[${data.landmarkId}][id]`, data.id));
    container.append(createHiddenField(`${prefix}[${data.landmarkId}][_destroy]`, true));
  }
  container.append(createHiddenField(`${prefix}[${data.landmarkId}][landmark_id]`, data.landmarkId));
  return container;
}

// Use the Landmark ID to generate a css class for the POI
function getPoiClass(data) {
  return `poi-${data.landmarkId}`;
}

// Helper method that creates a hidden input and sets its values
function createHiddenField (key, value) {
  let input = document.createElement("input");
  input.setAttribute("type", "hidden");
  input.setAttribute("name", key);
  input.value = value;
  return input;
}

// Navigating to a different search results page triggers the
// search form to be submitted again. This time with the page
// number added to the query params
function poiPageHandler (e) {
  let self = $(e.target);
  let form = self.closest(".form-container").find("form");
  let formURL = form.attr("action").split("?");
  let linkURL = self.attr("href").split("?");
  
  form.attr("action", formURL[0]+"?"+linkURL[1]);
  form.submit();

  return false;
}

// ---- System POIs ----

// On page load this callback should be passed to the form handler so
// that the form handler can attach the right event listeners after an
// AJAX request
function addSystemPoiHandlers (fh) {
  fh.formContainer.find("#add-all").on("click", systemPoiAddAllHandler)
  fh.formContainer.find(".toggle-poi i.btn").on("click", systemPoiAddHandler);
  fh.formContainer.find("li.page-item a").on("click", poiPageHandler);
  fh.form.submit(systemPoiSearchHandler);

  fh.formContainer.find("#add-all-pois span").each((index, poi) => {
    let data = poi.dataset;
    $("#poi-data #added-pois").append(createPoi(data));
  });
}

// Handler for when the user clicks to add, or un-add, a system POI
function systemPoiAddHandler (e) {
  let self = $(e.target).closest("tr");
  let data = self[0].dataset;

  if (data.isAdded == "true") {
    $("#poi-data #added-pois").find("." + getPoiClass(data)).remove();
    data.isAdded = false;
  } else {
    $("#poi-data #added-pois").append(createPoi(data));
    data.isAdded = true;
  }
}

// When the searching through the system POIs, we need to also
// send which POIs have been added, but not yet saved, so that
// the server can render them correctly
function systemPoiSearchHandler (e) {
  let self = $(e.target);
  let addedPois = $("#added-pois").clone();
  self.append(addedPois);
};

// Tells the controller to add all pois that match the current query
function systemPoiAddAllHandler (e) {
  let self = $(e.target);
  let input = self.find("input[name='add_all']");
  input.val("true");

  poiPageHandler({target: self.closest(".form-container").find("li.page-item.active a")});
}

// ---- Selected POIs ----

// On page load this callback should be passed to the form handler so
// that the form handler can attach the right event listeners after an
// AJAX request
function addSelectedPoiHandlers (fh) {
  fh.formContainer.find("#remove-all").on("click", selectedPoiRemoveAllHandler)
  fh.formContainer.find(".toggle-poi i.btn").on("click", selectedPoiRemoveHandler);
  fh.formContainer.find("li.page-item a").on("click", poiPageHandler);
  fh.form.submit(selectedPoiSearchHandler);

  fh.formContainer.find("#remove-all-pois span").each((index, poi) => {
    let data = poi.dataset;
    $("#poi-data #removed-pois").append(createPoi(data));
  });
}

// Handler for when the user clicks to add, or un-add, a system POI
function selectedPoiRemoveHandler (e) {
  let self = $(e.target).closest("tr");
  let data = self[0].dataset;

  if (data.isRemoved == "true") {
    $("#poi-data #removed-pois").find("." + getPoiClass(data)).remove();
    data.isRemoved = false;
  } else {
    $("#poi-data #removed-pois").append(createPoi(data));
    data.isRemoved = true;
  }
}

// When the searching through the system POIs, we need to also
// send which POIs have been removed, but not yet saved, so that
// the server can render them correctly
function selectedPoiSearchHandler (e) {
  let self = $(e.target);
  let removedPois = $("#removed-pois").clone();
  self.append(removedPois);
};

// Tells the controller to remove all pois that match the current query
function selectedPoiRemoveAllHandler (e) {
  let self = $(e.target);
  let input = self.find("input[name='remove_all']");
  input.val("true");

  poiPageHandler({target: self.closest(".form-container").find("li.page-item.active a")});
}
