csv_str = CSV.generate do |csv|
  # header の追加
  csv << ['title', 'price', 'headline']
  # body の追加
  @csv_items.each do |item|
    csv_body = []
    csv_body.push(item['title'])
    csv_body.push(item['price'])
    csv_body.push(item['headline'])
    csv << csv_body
  end
end

# 文字コード変換
NKF::nkf('--sjis -Lw', csv_str)
