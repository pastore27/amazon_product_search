# coding: utf-8
class BulksController < ApplicationController

  # ユーザがログインしていないとにアクセスできないように
  before_action :authenticate_user!
  before_action :correct_user

  def index
    @is_job_running = false
    DelayedJob.all.each do |job|
      job_data = YAML::load(job.handler).job_data
      if (job_data['arguments'][0].instance_of?(Hash))
        @is_job_running = true if job_data['arguments'][0]['user']['id'] == current_user.id
      end
    end
  end

  def add_search_conditions
    keyword = params[:keyword]
    keywords = keyword.rstrip.split(/\r?\n/).map {|line| line.chomp }
    keywords = keywords.reject(&:blank?)
    count = 1
    # 1ラベルあたり20検索条件
    keywords.each_slice(20).to_a.each do |ele|
      # ラベルの登録
      label = Label.new(
        :user_id => current_user.id,
        :name    => "#{params['label']}_#{count}"
      )
      label.save
      ele.each do |keyword|
        search_condition = SearchCondition.new(
          :label_id        => label.id,
          :keyword         => keyword,
          :negative_match  => params['negative_match'],
          :category        => params['category'],
          :is_prime        => params['is_prime'] || "0",
          :min_offer_count => params['min_offer_count'] || "0",
        )
        search_condition.save
      end
      count += 1
    end

    redirect_to :action => 'index'
  end

  def add_items
    ItemJob.perform_later({user: to_user_hash(current_user)})
    redirect_to :action => 'index'
  end

  def check_items
    labels = Label.where(user_id: current_user.id)
    min_offer_count = params[:min_offer_count] ? params[:min_offer_count] : 0
    invalid_item_codes = []
    labels.each do |label|
      invalid_item_codes.concat(
        extract_invalid_item_codes(
          req_lookup_api(
            to_user_hash(current_user), fetch_asins_by_label(label.id), label.id
          ),
          ProhibitedWord.where(user_id: current_user.id),
          min_offer_count
        )
      )
    end

    tmp_zip = generate_tmp_zip_file_name()
    Zip::Archive.open(tmp_zip, Zip::CREATE) do |ar|
      # csvファイルの追加
      ar.add_buffer(
        NKF::nkf('--sjis -Lw', "不正商品(全ラベル).csv"),
        NKF::nkf('--sjis -Lw', create_invalid_items_csv_str(invalid_item_codes))
      )
    end

    send_zip_file(tmp_zip, "不正商品(全ラベル).zip")
  end

  def delete_items
    if params[:csv_file]
      path = params[:csv_file].tempfile.path
      open(path, 'r:cp932:utf-8', undef: :replace) do |f|
        csv = CSV.new(f, :headers => :first_row)
        csv.each do |row|
          next if row.header_row?
          code = row.fields
          item = Item.find_by(user_id: current_user.id, code: code)
          item.destroy if item.present?
        end
      end
    end

    redirect_to :action => 'index'
  end

end
