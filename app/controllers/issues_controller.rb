class IssuesController < ApplicationController
  filter_access_to [:edit, :update, :destroy], attribute_check: true
  
  def index
    @issues = Issue.order("created_at DESC").limit(10)
    @start_location = index_start_location
    @popular_issues = Issue.plusminus_tally(start_at: 2.weeks.ago) # only count recent votes
  end

  def show
    issue = Issue.find(params[:id])
    @issue = IssueDecorator.decorate(issue)
    @threads = @issue.threads
  end

  def new
    @issue = Issue.new
    @start_location = current_user.start_location
  end

  def create
    @issue = current_user.issues.new(params[:issue])

    if @issue.save
      redirect_to @issue
    else
      @start_location = index_start_location
      render :new
    end
  end

  def edit
    @issue = Issue.find(params[:id])
    @start_location = @issue.location
  end

  def update
    @issue = Issue.find(params[:id])

    if @issue.update_attributes(params[:issue])
      set_flash_message(:success)
      redirect_to action: :show
    else
      render :edit
    end
  end

  def destroy
    @issue = Issue.find(params[:id])

    if @issue.destroy
      set_flash_message(:success)
      redirect_to issues_path
    else
      set_flash_message(:failure)
      redirect_to @issue
    end
  end

  def geometry
    @issue = Issue.find(params[:id])
    respond_to do |format|
      format.json { render json: RGeo::GeoJSON.encode(@issue.location) }
    end
  end

  def all_geometries
    if params[:bbox]
      bbox = bbox_from_string(params[:bbox], Issue.rgeo_factory)
      issues = Issue.intersects(bbox.to_geometry).order("created_at DESC").limit(50)
    else
      issues = Issue.order("created_at DESC").limit(50)
    end
    factory = RGeo::GeoJSON::EntityFactory.new
    collection = factory.feature_collection(issues.map { | issue | factory.feature(issue.location)})
    respond_to do |format|
      format.json { render json: RGeo::GeoJSON.encode(collection)}
    end
  end

  def search
    @query = params[:q]
    @results = Issue.find_with_index(params[:q])
  end

  def vote_up
    @issue = Issue.find(params[:id])
    if current_user.voted_for?(@issue)
      set_flash_message(:already)
    else
      current_user.vote_exclusively_for(@issue)
      set_flash_message(:success)
    end
    redirect_to @issue
  end

  def vote_down
    @issue = Issue.find(params[:id])
    if current_user.voted_against?(@issue)
      set_flash_message(:already)
    else
      current_user.vote_exclusively_against(@issue)
      set_flash_message(:success)
    end
    redirect_to @issue
  end

  protected

  def index_start_location
    return current_user.start_location if current_user && current_user.start_location != Geo::NOWHERE_IN_PARTICULAR
    # TODO return subdomain.group.location if subdomain
    return @issues.first.location unless @issues.empty?
    return Geo::NOWHERE_IN_PARTICULAR
  end
end
