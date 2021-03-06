# encoding: utf-8
require 'spec_helper'
require 'shared_stuff'

describe "Domains", js: true do

  include_context 'login admin'

  let(:shop) { user_admin.shop }

  describe "GET /domains" do

    before(:each) do
      dns = mock('dns')
      dns.stub!(:getresource).and_return("wrong.myshopoqi.com")
      Resolv::DNS.stub(:new).and_return(dns)
      visit domains_path
    end

    it "should be index" do
      within '#domains > .items' do
        within :xpath, './tr[1]' do
          find('a.host').text.should eql "shopqi#{Setting.store_host}"
          find('.dns-check').has_content?('成功').should be_true
          find(:xpath, './td[3]').has_content?('总是重定向顾客到这里?').should be_true
          has_css?('.deletions .del').should be_false
        end
      end
    end

    it "should be destroy" do # 删除
      click_on '新增一个您已经拥有的域名'
      fill_in 'domain[host]', with: 'www.example.com'
      click_on '绑定此域名'
      has_content?('www.example.com').should be_true
      page.execute_script("window.confirm = function(msg) { return true; }")
      within '#domains > .items' do
        click_on '删除'
      end
      page.should have_content('删除成功!')
      within '#domains > .items' do
        page.should have_no_xpath('./tr[2]')
      end
    end

    describe 'add' do

      it "should be validate" do
        click_on '新增一个您已经拥有的域名'
        click_on '绑定此域名'
        find('#errorExplanation').visible?.should be_true
        find('#errorExplanation').has_content?('域名 不能为空').should be_true
      end

      it "should be add" do
        click_on '新增一个您已经拥有的域名'
        fill_in 'domain[host]', with: 'www.example.com'
        click_on '绑定此域名'
        within '#domains > .items' do
          within :xpath, './tr[2]' do
            find('a.host').text.should eql "www.example.com"
            find('.dns-check').should have_content('失败')
            find(:xpath, './td[3]').has_content?('总是重定向顾客到这里?').should be_false
            page.should have_css('.deletions .del')
          end
        end
        visit domains_path # 回显
        within '#domains > .items' do
          within :xpath, './tr[2]' do
            find('a.host').text.should eql "www.example.com"
          end
        end
      end

    end

    describe 'update' do

      it "should be make primary" do # 作为主域名
        click_on '新增一个您已经拥有的域名'
        fill_in 'domain[host]', with: 'www.example.com'
        click_on '绑定此域名'
        click_on '作为主域名'
        within '#domains > .items' do
          find(:xpath, './tr[2]/td[3]').has_content?('总是重定向顾客到这里?').should be_true  # 新的域名记录
          find(:xpath, './tr[1]/td[3]').has_content?('总是重定向顾客到这里?').should be_false # 第一条域名记录
        end
      end

      it "should be force redirect" do # 重定向
        within '#domains > .items' do
          within :xpath, './tr[1]/td[3]' do
            find('#shop_force_domain')['checked'].should be_false
          end
        end
        check '总是重定向顾客到这里?'
        visit domains_path
        within '#domains > .items' do
          within :xpath, './tr[1]/td[3]' do
            find('#shop_force_domain')['checked'].should be_true
          end
        end
      end

    end

  end

end
