csv_header    = %w/ path name code sub-code original-price price sale-price options headline caption abstract explanation additional1 additional2 additional3 /

csv_str = CSV.generate do |csv|
  # header の追加
  csv << csv_header
  # body の追加
  @csv_items.each do |item|
    csv_body = {}

    csv_body['path']        = item['title']
    csv_body['name']        = item['title']
    csv_body['code']        = item['title']
    csv_body['price']       = item['title']
    csv_body['headline']    = item['title']
    csv_body['caption']     = item['title']
    csv_body['explanation'] = item['title']

    csv << csv_body.values_at(*csv_header)
  end
end

# 文字コード変換
NKF::nkf('--sjis -Lw', csv_str)
