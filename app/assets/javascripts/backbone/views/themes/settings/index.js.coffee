App.Views.Theme.Settings.Index = Backbone.View.extend
  el: '#main'

  events:
    "submit form": 'save'
    "change #settings_panel :input": 'customize' # 修改配置项左边选项切换至'定制'
    "change #save-current-setting": 'select' # 点击复选框显示新增命名
    "change #theme_save_preset_existing": 'select_existing'
    "click .closure-lightbox": 'show' # 显示图片

  initialize: ->
    self = this
    this.render()

  render: ->
    self = this
    template = Handlebars.compile $('#section-header-item').html()
    $('fieldset').each ->
      title = $('legend', this).text()
      $(this).hide().before template title: title
    $('.section-header').addClass('collapsed').click ->
      $(this).toggleClass 'collapsed'
      $(this).next().toggle()
    $('.section-header:first').click()
    $('.color').miniColors()
    $('.miniColors').live 'mousedown', (e) -> self.customize(e) # fixed: 修改颜色要修改预设选项
    @presets_view = new App.Views.Theme.Settings.Preset.Index
    $(".file").each -> # 上传图片
      new qq.FileUploader
        multiple: false
        element: $(this)[0],
        action: "/admin/themes/#{theme_id}/assets/0/upload"
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif']
        sizeLimit: 1048576 # 1M
        messages:
          typeError: "{file} 文件格式不正确. 只能上传 {extensions} 格式的图片.",
        onSubmit: (id, file_name) ->
          name = $(@element).attr('name')
          max_width = $(@element).attr('data-max-width')
          max_height = $(@element).attr('data-max-height')
          text = "正在上传..."
          text = "#{text} 限制宽高为#{max_width}x#{max_height}" if max_width and max_height
          msg text
          $('#indicator').show()
          $(document).mousemove window.moveIndicator
          csrf_token = $('meta[name=csrf-token]').attr('content')
          csrf_param = $('meta[name=csrf-param]').attr('content')
          this.params = key: "assets/#{name}", name: name, max_width: max_width, max_height: max_height
          this.params[csrf_param] = csrf_token
        onComplete: (id, file_name, responseJSON)->
          msg '上传成功!'
          $('#indicator').hide()
          $(document).unbind 'mousemove'
    $('.qq-upload-list').hide() # 不显示上传文件列表
    $(".qq-upload-button").each ->
      $(this).css('padding', '2px 0').width(70).contents().first().replaceWith("选择文件")

  save: ->
    self = this
    attrs = _.reduce $('form :input'), (result, obj) ->
      obj = $(obj)
      value = switch obj.attr('type')
        when 'checkbox'
          obj.attr('checked') is 'checked'
        else
          obj.val()
      name = obj.attr('name')
      result[name] = value unless name is 'file'
      result
    , {_method: 'put'}
    $.post "/admin/themes/#{theme_id}/settings", attrs, (data) ->
      msg '保存成功!'
      collection = self.presets_view.collection
      new_preset_name = $('#theme_save_preset_new').val()
      exist_preset_name = $('#theme_save_preset_existing').val()
      if $('#save-current-setting').attr('checked') is 'checked' # 名称要先保存到变量，此操作会清空名称
        $('#save-current-setting').attr('checked', false).change()
      if new_preset_name
        collection.add name: new_preset_name, value: data
        $('#theme_load_preset').val new_preset_name
      else if exist_preset_name
        preset = collection.detect (model) -> model.get('name') is exist_preset_name
        preset.set value: data
        $('#theme_load_preset').val exist_preset_name

  customize: (e) -> # 修改配置项，切换至定制预设
    if e.target.type not in ['submit', 'file']
      $('#theme_load_preset').val ''
      $('#delete_theme_preset_link').hide()

  select: -> # 显示新增命名输入项
    checked = $('#save-current-setting').attr 'checked'
    $('#save-preset').toggle(checked)
    $('#theme_save_preset_existing').val('').change()

  select_existing: -> # 显示或隐藏名称输入项
    existing =  $('#theme_save_preset_existing').val() is ''
    $('#theme_save_preset_new_container').toggle(existing)
    $('#theme_save_preset_new').val ''

  show: (e) ->
    template = Handlebars.compile $('#asset-image-item').html()
    url = $(e.target).closest('a').attr('href') # /s/files/2/theme/assets/bg-logo.png
    title = url.substr(url.lastIndexOf('/')+1) #bg-logo.png
    $.blockUI message: template(title: title, url: url)
    false
