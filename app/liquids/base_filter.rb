module BaseFilter #扩展标准filter http://j.mp/v8XGFK

  def json(object)
    object.to_json
  end

  def pluralize(input, singular, plural) # input为奇数返回singular, 否则plural
    input == 1 ? singular : plural
  end

  def money(object) # ¥19.00
    shop = @context['shop'] #ShopDrop
    format = shop.money_format
    text = format.gsub '{{amount}}', object.to_s
    text.gsub '{{amount_no_decimals}}', object.round.to_s
  end

  def money_with_currency(object) # ¥19.00 元
    shop = @context['shop'] #ShopDrop
    format = shop.money_with_currency_format
    text = format.gsub '{{amount}}', object.to_s
    text.gsub '{{amount_no_decimals}}', object.round.to_s
  end

  def money_without_currency(object) # 19.00，currency指"¥"前缀和"元"后缀
    object
  end

  def handleize(input) # 转化可用于url的字符串(英文转为中文，并去掉%@*$)
    input.gsub! /[%@*$]/, ''
    Pinyin.t input, '-'
  end
  alias :handle :handleize

  def camelize(input)
    input && input.gsub(/\s+/, '_').camelize
  end

end
