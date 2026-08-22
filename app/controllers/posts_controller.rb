class PostsController < ApplicationController
  def index
    @posts = Post.includes(:thread_account).order(created_at: :desc)
    @draft_posts = @posts.select(&:draft?)
    @queued_posts = @posts.select(&:queued?)
    @published_posts = @posts.select(&:published?)
    @failed_posts = @posts.select(&:failed?)
  end

  def new
    @post = Post.new
    @accounts = ThreadAccount.all
  end

  def create
    @post = Post.new(post_params.merge(status: :draft))
    if @post.save
      redirect_to posts_path, notice: "Draft created"
    else
      @accounts = ThreadAccount.all
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @post = Post.find(params[:id])
  end

  def approve
    @post = Post.find(params[:id])
    if @post.draft?
      @post.update!(status: :queued, scheduled_at: params[:scheduled_at] || Time.current)
      redirect_to posts_path, notice: "Post queued for publishing"
    else
      redirect_to posts_path, alert: "Only draft posts can be approved"
    end
  end

  private

  def post_params
    params.require(:post).permit(:thread_account_id, :content, :media_url)
  end
end
