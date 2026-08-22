class ThreadAccountsController < ApplicationController
  def index
    @accounts = ThreadAccount.order(created_at: :desc)
  end

  def new
    @account = ThreadAccount.new
  end

  def create
    @account = ThreadAccount.new(account_params)
    if @account.save
      redirect_to thread_accounts_path, notice: "Account added"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @account = ThreadAccount.find(params[:id])
    @account.destroy
    redirect_to thread_accounts_path, notice: "Account removed"
  end

  private

  def account_params
    params.require(:thread_account).permit(:threads_user_id, :username, :access_token, :token_expires_at)
  end
end
