# encoding: utf-8
class Product < ActiveRecord::Base
  include Models::Handle
  belongs_to :shop
  has_many :photos             , dependent: :destroy           , order: 'position asc'
  has_many :variants           , dependent: :destroy           , class_name: 'ProductVariant'
  has_many :options            , dependent: :destroy           , class_name: 'ProductOption'          , order: 'position asc'
  has_many :collection_products, dependent: :destroy           , class_name: 'CustomCollectionProduct'
  has_many :collections        , class_name: 'CustomCollection', through: :collection_products        , source: :custom_collection
  has_and_belongs_to_many :tags
  # 标签
  attr_accessor :tags_text,:images
  scope :published, where(published: true)

  accepts_nested_attributes_for :photos  , allow_destroy: true
  accepts_nested_attributes_for :variants, allow_destroy: true
  accepts_nested_attributes_for :options, allow_destroy: true

  validates_presence_of :title, :product_type, :vendor

  #商品列表中显示的产品图片
  def index_photo
    photo('thumb')
  end

  def photo(version = :icon)
    unless photos.empty?
      photos.first.send(version)
    else
      "/assets/admin/no-image-#{version}.gif"
    end
  end

  searchable do
    integer :shop_id, references: Shop
    text :title, :body_html, :product_type, :vendor
    text :variants_text do
      variants.map do |variant|
        [variant.option1, variant.option2, variant.option3, variant.sku]
      end
    end
  end

  before_create do
    if self.variants.empty?
      self.variants.build price: 0.0, weight: 0.0
    end
    if self.options.empty?
      option_name = KeyValues::Product::Option.first.name
      self.options.build name: option_name
      self.variants.first.option1 = "默认#{option_name}"
    end
  end

  before_save do
    self.make_valid(shop.products)
    # 新增的选项默认值要设置到所有款式中
    self.options.reject{|option| option.marked_for_destruction?}.each_with_index do |option, index|
      next if option.value.blank?
      self.variants.each do |variant|
        variant.send "option#{index+1}=", option.value
      end
    end
  end

  def tags_text
    @tags_text ||= tags.map(&:name).join(', ')
  end

  after_save do
    product_tags = self.tags.map(&:name)
    # 删除tag
    (product_tags - Tag.split(tags_text)).each do |tag_text|
      tag = shop.tags.where(name: tag_text,category: 1).first
      tags.delete(tag)
    end
    # 新增tag
    (Tag.split(tags_text) - product_tags).each do |tag_text|
      tag = shop.tags.where(name: tag_text, category: 1).first
      if tag
        # 更新时间，用于显示最近使用过的标签
        tag.touch
      else
        tag = shop.tags.create(name: tag_text, category: 1) unless tag
      end
      self.tags << tag
    end
  end

  def available
    self.published
  end

  begin 'shop' # 只供商店调用

    def shop_as_json(options = nil) # 不能以as_json，会与后台管理的to_json冲突(options同名)
      {
        id: self.id,
        handle: self.handle,
        title: self.title,
        available: self.available,
        options: self.options.map(&:name),
        variants: self.variants.map(&:shop_as_json),
      }
    end

  end

end

#商品款式
class ProductVariant < ActiveRecord::Base
  belongs_to :shop #冗余字段，前台商店下订单时使用
  belongs_to :product
  validates_with SkuValidator

  before_create do
    self.shop_id = self.product.shop_id
  end

  before_save do
    self.price ||= 0.0 # 价格、重量一定要有默认值
    self.weight ||= 0.0
  end

  after_save do
    min_price = self.product.variants.map(&:price).min || self.price
    self.product.update_attributes price: min_price # 商品冗余最小价格，方便集合排序
  end

  after_destroy do
    min_price = self.product.variants.map(&:price).min
    self.product.update_attributes price: min_price
  end

  def options
    [option1, option2, option3].compact
  end

  def inventory_policy_name
    KeyValues::Product::Inventory::Policy.find_by_code(inventory_policy).name
  end

  def title
    self.options.join(' / ')
  end

  def available
    true
  end


  begin 'shop' # 只供商店调用的json

    def shop_as_json(options = nil)
      {
        id: self.id,
        option1: self.option1,
        option2: self.option2,
        option3: self.option3,
        available: self.available,
        title: self.title,
        price: self.price,
        compare_at_price: self.compare_at_price,
        weight: self.weight,
        sku: self.sku,
      }
    end

  end
end

#商品选项
class ProductOption < ActiveRecord::Base
  belongs_to :product
  acts_as_list scope: :product
  #辅助值，用于保存至商品款式中
  attr_accessor :value

  # 更新商品所有款式
  before_destroy do
    options_size = product.options.size
    product.variants.each do |variant|
      (position...options_size).each do |i|
        variant.send("option#{i}=", variant.send("option#{i+1}"))
      end
      variant.save
    end
  end
end

class Photo < ActiveRecord::Base
  belongs_to :product
  default_scope order: 'position asc'

  image_accessor :product_image do
    storage_path{ |image|
      "#{self.product.shop.id}/products/#{self.product.id}/#{image.basename}_#{rand(1000)}.#{image.format}" # data/shops/1/products/1/foo_45.jpg
    }
  end

  validates_size_of :product_image, maximum: 8000.kilobytes

  validates_property :mime_type, of: :product_image, in: %w(image/jpeg image/jpg image/png image/gif), message:  "格式不正确"

  #定义图片显示大小种类
  def self.versions(opt={})
    opt.each_pair do |k,v|
      define_method k do
        if product_image
          product_image.thumb(v).url
        end
      end
    end
  end

  #显示在产品列表的缩略图(icon)
  #后台管理商品详情(small)
  versions pico: '16x16', icon: '32x32', thumb: '50x50', small:'100x100', compact: '160x160', medium: '240x240', large: '480x480', grande: '600x600', original: '1024x1024'

end

CustomCollection

