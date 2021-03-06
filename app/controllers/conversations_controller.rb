class ConversationsController < ApplicationController
  before_filter :load_conversation, :except => [:index, :new, :create]
  before_filter :set_page_title

  def new
    authorize! :converse, @current_project
    @conversation = @current_project.conversations.new
  end

  def create
    authorize! :converse, @current_project
    @conversation = @current_project.conversations.new_by_user(current_user, params[:conversation])

    if @conversation.save
      respond_to do |f|
        f.html {
          if request.xhr? or iframe?
            render :partial => 'activities/thread', :locals => {:thread => @conversation}
          else
            redirect_to current_conversation
          end
        }
        handle_api_success(f, @conversation, true)
      end
    else
      respond_to do |f|
        f.html {
          if request.xhr? or iframe?
            output_errors_json(@conversation)
          else
            # TODO: display inline instead of flash
            flash.now[:error] = @conversation.errors.to_a.first[1]
            render :action => :new
          end
        }
        handle_api_error(f, @conversation)
      end
    end
  end

  def index
    @conversations = @current_project.conversations.not_simple

    respond_to do |f|
      f.html
      f.rss   { render :layout => false }
      f.xml   { render :xml     => @conversations.to_xml }
      f.json  { render :as_json => @conversations.to_xml }
      f.yaml  { render :as_yaml => @conversations.to_xml }
    end
  end

  def show
    @conversations = @current_project.conversations.not_simple

    respond_to do |f|
      f.html
      f.xml   { render :xml     => @conversation.to_xml(:include => :comments) }
      f.json  { render :as_json => @conversation.to_xml(:include => :comments) }
      f.yaml  { render :as_yaml => @conversation.to_xml(:include => :comments) }
    end
  end

  def update
    authorize! :update, @conversation
    success = @conversation.update_attributes(params[:conversation])
    
    respond_to do |f|
      f.js   { head :ok }
      f.html { redirect_to current_conversation }
      
      if success
        handle_api_success(f, @conversation)
      else
        handle_api_error(f, @conversation)
      end
    end
  end

  def destroy
    authorize! :destroy, @conversation
    @conversation.destroy
    
    respond_to do |f|
      f.html do
        flash[:success] = t('deleted.conversation', :name => @conversation.to_s)
        redirect_to project_conversations_path(@current_project)
      end
      f.js { head :ok }
      handle_api_success(f, @conversation)
    end
  end

  def watch
    @conversation.add_watcher(current_user)
    
    respond_to do |f|
      f.js
      f.html { redirect_to current_conversation }
    end
  end

  def unwatch
    @conversation.remove_watcher(current_user)
    
    respond_to do |f|
      f.js
      f.html { redirect_to current_conversation }
    end
  end

  protected
  
    def load_conversation
      @conversation = @current_project.conversations.find params[:id]
    end
    
    def current_conversation
      [@current_project, @conversation]
    end
end