# (see Billingly::RedemptionsControllerBase)
class Billingly::RedemptionsController < Billingly::RedemptionsControllerBase
  
  def on_redemption_by_non_customer
    redirect_to subscriptions_path
  end
end
