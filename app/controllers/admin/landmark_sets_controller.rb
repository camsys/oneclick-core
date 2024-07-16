class Admin::LandmarkSetsController < Admin::AdminController
  include Pagy::Backend
  include RemoteFormResponder

  load_and_authorize_resource
  before_action :load_agency_from_params_or_user, only: [:new, :create]
  before_action :load_agency, only: [:new, :create]
  before_action :load_queries, only: [:new, :edit]
  before_action :load_pois, only: [:new, :edit]

  def index
    @landmark_sets = @landmark_sets.for_user(current_user).order(:name)
  end

  def new
    respond_with_partial_or(partial_layout: false) do
      respond_to do |format|
        format.html
      end
    end
  end

  def create
    if database_transaction
      flash[:success] = "New Landmark Set successfully created."
      path = params[:button] == "Save" ? admin_landmark_sets_path : edit_admin_landmark_set_path(@landmark_set)
      redirect_to path
    else
      load_queries
      load_pois

      flash.now[:danger] = "Landmark Set failed to be created."
      render :new
    end
  end

  def edit
    respond_with_partial_or(partial_layout: false) do
      respond_to do |format|
        format.html
      end
    end
  end

  def update
    @landmark_set.assign_attributes(landmark_set_params)
    if database_transaction
      flash[:success] = "New Landmark Set successfully updated."
      path = params[:button] == "Save" ? admin_landmark_sets_path : edit_admin_landmark_set_path(@landmark_set)
      redirect_to path
    else
      load_queries
      load_pois

      flash.now[:danger] = "Landmark Set failed to be updated."
      render :edit
    end
  end

  def destroy
    if @landmark_set.destroy
      flash[:success] = "Set of Ecolane POIs Deleted Successfully"
    else
      flash[:warning] = "Set of Ecolane POIs could not be Deleted"
    end
    redirect_to admin_landmark_sets_path
  end

  private
  def landmark_set_params
    params.require(:landmark_set).permit(
      :name,
      :description,
      landmark_set_landmarks_attributes: [:id, :landmark_id, :_destroy]
    )
  end

  def load_agency
    @landmark_set.agency ||= @agency
  end

  def load_queries
    @selected_query = params.fetch(:selected_query, '')
    @system_query = params.fetch(:system_query, '')
  end

  def load_pois
    if (params[:landmark_set] && params[:landmark_set][:landmark_set_landmarks_attributes])
      changed_pois = params[:landmark_set][:landmark_set_landmarks_attributes].values
    else
      changed_pois = []
    end
  
    unless @partial_path == "/admin/landmark_sets/_system_pois"
      @selected_pagy, @selected_pois = pagy(
        find_selected_pois(@selected_query),
        items: (params[:selected_per_page] || 10).to_i,
        params: { partial_path: "/admin/landmark_sets/_selected_pois" },
        page_param: :selected_page,
        size: [1, 1, 2, 1]
      )
  
      @selected_poi_count = @landmark_set.landmark_set_landmarks.count
      @removed_pois = LandmarkSetLandmark.where(
        id: changed_pois.reject { |poi| poi[:id].blank? && !poi[:_destroy] }
                        .map { |poi| poi[:id] }
      )
  
      if params[:remove_all] == "true"
        @remove_all_pois = find_selected_pois(@selected_query).where.not(id: @removed_pois.map(&:id))
        @removed_pois += @remove_all_pois
      end
    end
  
    unless @partial_path == "/admin/landmark_sets/_selected_pois"
      @system_pagy, @system_pois = pagy(
        find_system_pois(@system_query),
        items: (params[:system_per_page] || 10).to_i,
        params: ->(params) { 
          params.select { |key, value| ["agency_id", "system_page"].include?(key) }
                .merge!(partial_path: "/admin/landmark_sets/_system_pois")
        },
        page_param: :system_page,
        size: [1, 1, 2, 1]
      )
  
      @system_poi_count = Landmark.where(agency: @landmark_set.agency).count
      @added_pois = changed_pois.select { |poi| poi[:id].blank? && !poi[:_destroy] }
                                .map { |poi| LandmarkSetLandmark.new(poi) }
      
      if params[:add_all] == "true"
        @add_all_pois = find_system_pois(@system_query).merge(
          Landmark.where.not(id: @added_pois.map(&:landmark_id) + @landmark_set.landmark_set_landmarks.pluck(:landmark_id))
        ).distinct.on(:name, :agency_id)
        @added_pois += @add_all_pois
      end
    end
  end
  

  def find_selected_pois(query)
    @landmark_set.landmark_set_landmarks
                  .joins(:landmark)
                  .eager_load(:landmark)
                  .merge(
                    Landmark.where("CONCAT(name, ' ', street_number, ' ', route, ' ', city) ILIKE :query", query: "%#{query}%")
                            .order(:name)
                  )
  end

  def find_system_pois(query)
    LandmarkSetLandmark.select('"landmark_set_landmarks".*, "landmarks"."id" AS landmark_id')
                        .preload(:landmark)
                        .from(@landmark_set.landmark_set_landmarks, :landmark_set_landmarks)
                        .joins('RIGHT OUTER JOIN "landmarks" ON "landmark_set_landmarks"."landmark_id" = "landmarks"."id"')
                        .merge(
                          Landmark.where(agency: @landmark_set.agency)
                                  .where('CONCAT("name", \' \', "street_number", \' \', route, \' \', "city") ILIKE :query', query: "%#{query}%")
                                  .order(:name)
                        ).distinct_on(:name, :lat, :lng)
  end
  
  def database_transaction
    success = false
    LandmarkSet.transaction do
      if @landmark_set.save()
        @landmark_set.update_associated_regions
        success = true
      else
        raise ActiveRecord::Rollback
      end
    end

    return success
  end
end
