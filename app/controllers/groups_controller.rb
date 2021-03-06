class GroupsController < ApplicationController
  def show
    if params[:id]
      @group = Group.find(params[:id])
    elsif current_group
      @group = current_group
    end

    if @group
      @group = GroupDecorator.decorate(@group)
      if @group.has_member?(current_user)
        recent_threads = ThreadList.recent_from_groups(@group, 10).includes(:issue, :group)
      else
        recent_threads = ThreadList.recent_public_from_groups(@group, 10).includes(:issue, :group)
      end
      @recent_threads = ThreadListDecorator.decorate(recent_threads)
      @recent_issues = IssueDecorator.decorate(@group.recent_issues.limit(10).includes(:created_by))
    else
      redirect_to root_url(subdomain: 'www')
    end
  end
end
