# encoding: utf-8
require 'spec_helper'

describe Shop::ProductsController do

  let(:theme) { Factory :theme_woodland_dark }

  let(:shop) do
    model = Factory(:user_admin).shop
    model.themes.install theme
    model.update_attributes password_enabled: false
    model
  end

  let(:frontpage_collection) { shop.custom_collections.where(handle: 'frontpage').first }

  let(:iphone4) { Factory :iphone4, shop: shop, collections: [frontpage_collection] }

  before :each do
    request.host = "#{shop.primary_domain.host}"
  end

  context 'show' do

    it 'should be success' do
      get 'show', handle: iphone4.handle
      response.should be_success
      response.body.should have_content('iphone')
    end

    context 'within collection' do

      it 'should be get' do
        path = shop.theme.template_path('product')
        File.open(path, 'w') {|f| f.write('{{collection.title}}分类') }
        get 'show', handle: iphone4.handle, collection_handle: frontpage_collection.handle
        response.body.should have_content('首页商品分类')
      end

    end

  end

  context 'js' do

    it 'should be get', focus: true do # 获取product json
      get 'show', handle: iphone4.handle, format: :js
      response.should be_success
      json = JSON(response.body)
      json.should_not be_empty
      %w(id handle title available).each do |attr|
        json[attr].should eql iphone4.send(attr)
      end
      json['options'].should eql ['标题']
      json['variants'].should_not be_empty
    end

  end

  it "should not create new product" do

  end

  describe 'error' do

    it "should handle not found" do
      get 'show', handle: 'no-exists-handle'
      response.status.should eql 404
    end

  end

end
