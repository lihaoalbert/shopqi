#encoding: utf-8
class ShopDrop < Liquid::Drop
  extend ActiveSupport::Memoizable

  def initialize(shop, theme = nil)
    @shop = shop
    @theme = theme || shop.theme
  end

  delegate :id, :name, :money_with_currency_format, :money_format, :money_with_currency_in_emails_format, :money_in_emails_format, to: :@shop
  delegate :id, :name, to: :@theme, prefix: :theme # 主题预览脚本使用

  def url
    @shop.primary_domain.url
  end

  def asset_url(asset) # UrlFilter调用
    @theme.asset_url(asset)
  end

  def customer_accounts_enabled # 启用顾客功能
    !@shop.customer_accounts.blank?
  end

  def vendors
    @shop.vendors.map(&:name)
  end
  memoize :vendors

end
