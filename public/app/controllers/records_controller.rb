class RecordsController < ApplicationController

  def resource
    @resource = JSONModel(:resource).find(params[:id], :repo_id => params[:repo_id], "resolve[]" => ["subjects", "container_locations", "digital_object", "linked_agents"])
    raise RecordNotFound.new if not @resource.publish

    @repository = @repositories.select{|repo| JSONModel(:repository).id_for(repo.uri).to_s === params[:repo_id]}.first

    @tree_view = Search.tree_view(@resource.uri)

    @breadcrumbs = [
      [@repository['repo_code'], url_for(:controller => :search, :action => :repository, :id => @repository.id), "repository"],
      [@resource.finding_aid_status === 'completed' ? @resource.finding_aid_title : @resource.title, "#", "resource"]
    ]
  end

  def archival_object
    @archival_object = JSONModel(:archival_object).find(params[:id], :repo_id => params[:repo_id], "resolve[]" => ["subjects", "container_locations", "digital_object", "linked_agents"])
    raise RecordNotFound.new if not @archival_object.publish

    @repository = @repositories.select{|repo| JSONModel(:repository).id_for(repo.uri).to_s === params[:repo_id]}.first

    @tree_view = Search.tree_view(@archival_object.uri)

    @breadcrumbs = [
      [@repository['repo_code'], url_for(:controller => :search, :action => :repository, :id => @repository.id), "repository"]
    ]

    @tree_view["path_to_root"].each do |record|
      raise RecordNotFound.new if not record["publish"] == false

      if record["node_type"] === "resource"
        @breadcrumbs.push([record["finding_aid_status"] === 'completed' ? record["finding_aid_title"] : record["title"], url_for(:controller => :records, :action => :resource, :id => record["id"], :repo_id => @repository.id), "resource"])
      else
        @breadcrumbs.push([record["title"], url_for(:controller => :records, :action => :archival_object, :id => record["id"], :repo_id => @repository.id), "archival_object"])
      end
    end

    @breadcrumbs.push([@archival_object.title, "#", "archival_object"])
  end

  def digital_object
    @digital_object = JSONModel(:digital_object).find(params[:id], :repo_id => params[:repo_id], "resolve[]" => ["subjects", "linked_instances", "linked_agents"])

    raise RecordNotFound.new if not @digital_object.publish

    @repository = @repositories.select{|repo| JSONModel(:repository).id_for(repo.uri).to_s === params[:repo_id]}.first
    tree = JSONModel(:digital_object_tree).find(nil, :digital_object_id => @digital_object.id, :repo_id => params[:repo_id])
    @children = tree['children'].select{|doc| doc['publish']}

    @breadcrumbs = [
      [@repository['repo_code'], url_for(:controller => :search, :action => :repository, :id => @repository.id), "repository"],
      [@digital_object.title, "#", "digital_object"]
    ]
  end

  def digital_object_component
    @digital_object_component = JSONModel(:digital_object_component).find(params[:id], :repo_id => params[:repo_id], "resolve[]" => ["subjects", "linked_agents"])
    raise RecordNotFound.new if not @digital_object_component.publish

    @digital_object = JSONModel(:digital_object).find_by_uri(@digital_object_component['digital_object']['ref'], :repo_id => params[:repo_id])
    raise RecordNotFound.new if not @digital_object.publish

    @repository = @repositories.select{|repo| JSONModel(:repository).id_for(repo.uri).to_s === params[:repo_id]}.first
    @children = JSONModel::HTTP::get_json("/repositories/#{params[:repo_id]}/digital_object_components/#{@digital_object_component.id}/children").select{|doc| doc['publish']}

    @breadcrumbs = [
      [@repository['repo_code'], url_for(:controller => :search, :action => :repository, :id => @repository.id), "repository"],
      [@digital_object.title, url_for(:controller => :records, :action => :digital_object, :id => @digital_object.id, :repo_id => @repository.id), "digital_object"],
    ]

    doc = @digital_object_component
    while doc['parent'] do
      doc = JSONModel(:digital_object_component).find(JSONModel(:digital_object_component).id_for(doc['parent']['ref']), :repo_id => @repository.id)

      raise RecordNotFound.new if not doc.publish

      @breadcrumbs.push([doc.title, url_for(:controller => :records, :action => :digital_object_component, :id => doc.id, :repo_id => @repository.id), "digital_object_component"])
    end

    @breadcrumbs.push([@digital_object_component.title, "#", "digital_object_component"])
  end

end
