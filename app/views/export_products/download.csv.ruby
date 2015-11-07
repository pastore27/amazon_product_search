csv_header = %w/ path name code sub-code original-price price sale-price options headline caption abstract explanation additional1 additional2 additional3 /
# テンプレートファイルを開く
caption_erb = Rails.root.join('app/views/template/caption.html.erb').read

csv_str = CSV.generate do |csv|
  # header の追加
  csv << csv_header
  # body の追加
  @csv_items.each do |item|
    csv_body = {}

    csv_body['path']        = @csv_option['path'] if @csv_option['path']
    csv_body['name']        = item['title']
    csv_body['code']        = item['asin']
    csv_body['headline']    = item['headline']
    csv_body['caption']     = ERB.new(caption_erb, nil, '-').result(binding)
    csv_body['explanation'] = @csv_option['explanation'] if @csv_option['explanation']

    # 金額調整
    if (@csv_option['price_option_value'])  then
      if (@csv_option['price_option_unit'] == 'yen') then
        csv_body['price'] = item['price'] + @csv_option['price_option_value']
      elsif (@csv_option['price_option_unit'] == 'per') then
        csv_body['price'] = item['price'] * @csv_option['price_option_value']
      end
    end

    csv << csv_body.values_at(*csv_header)
  end
end

# 文字コード変換
NKF::nkf('--sjis -Lw', csv_str)

