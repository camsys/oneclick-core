module Admin::LandmarkSetsHelper
  include Pagy::Frontend

  def search_url(mode, params)
    return new_admin_landmark_set_path(params) if mode == "new" || mode == "create"
    return edit_admin_landmark_set_path(@landmark_set, params) if mode == "edit" || mode == "update"
    root_path
  end

  #### All POIs ####
  def poi_display_name(poi)
    "#{content_tag(:strong, poi.landmark.name)}, #{content_tag(:em, poi.landmark.auto_name)}".html_safe
  end

  def collective_action_button(type)
    if type == "system"
      add_all_button
    elsif type == "selected"
      remove_all_button
    end
  end

  def poi_toggle
    content_tag(:i, nil, class: ["glyphicon", "glyphicon-poi-toggle", "btn", "btn--no-bg"])
  end

  #### System POIs ####
  def system_poi_table_row(poi, added_pois)
    if poi.id
      system_poi_exists_row(poi)
    else
      system_poi_new_row(poi, added_pois)
    end
  end

  def system_poi_exists_row(poi)
    content_tag(:tr, nil, data: { id: poi.id, landmark_id: poi.landmark_id }) do
      [
        content_tag(:td, poi_display_name(poi)),
        content_tag(:td, "Selected")
      ].join("\n").html_safe
    end
  end

  def system_poi_new_row(poi, added_pois)
    is_added = added_pois.find { |added_poi| added_poi.landmark_id == poi.landmark_id } != nil
    content_tag(:tr, nil, data: { landmark_id: poi.landmark_id, is_added: is_added }) do
      [
        content_tag(:td, poi_display_name(poi)),
        content_tag(:td, poi_toggle, class: ["toggle-poi"])
      ].join("\n").html_safe
    end
  end

  def add_all_button
    content_tag(:div, nil, id: "add-all", class: ["btn", "btn-primary"]) do
      [
        "Add All",
        content_tag(:input, nil, type: "hidden", name: "add_all", value: false)
      ].join("\n").html_safe
    end
  end

  #### Selected POIs ####
  def selected_poi_table_row(poi, removed_pois)
    is_removed = removed_pois.find { |removed_poi| removed_poi.landmark_id == poi.landmark_id } != nil
    content_tag(:tr, nil, data: { id: poi.id, landmark_id: poi.landmark_id, is_removed: is_removed }) do
      [
        content_tag(:td, poi_display_name(poi)),
        content_tag(:td, poi_toggle, class: ["toggle-poi"])
      ].join("\n").html_safe
    end
  end

  def remove_all_button
    content_tag(:div, nil, id: "remove-all", class: ["btn", "btn-danger"]) do
      [
        "Remove All",
        content_tag(:input, nil, type: "hidden", name: "remove_all", value: false)
      ].join("\n").html_safe
    end
  end
end
