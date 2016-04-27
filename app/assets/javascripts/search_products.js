jQuery.ajax = (function(_ajax){
    
    var protocol = location.protocol,
        hostname = location.hostname,
        exRegex = RegExp(protocol + '//' + hostname),
        YQL = 'http' + (/^https/.test(protocol)?'s':'') + '://query.yahooapis.com/v1/public/yql?callback=?',
        query = 'select * from html where url="{URL}" and xpath="*"';
    
    function isExternal(url) {
        return !exRegex.test(url) && /:\/\//.test(url);
    }
    
    return function(o) {
        
        var url = o.url;
        
        if ( /get/i.test(o.type) && !/json/i.test(o.dataType) && isExternal(url) ) {
            
            // Manipulate options so that JSONP-x request is made to YQL
            
            o.url = YQL;
            o.dataType = 'json';
            
            o.data = {
                q: query.replace(
                    '{URL}',
                    url + (o.data ?
                        (/\?/.test(url) ? '&' : '?') + jQuery.param(o.data)
                    : '')
                ),
                format: 'xml'
            };
            
            // Since it's a JSONP request
            // complete === success
            if (!o.success && o.complete) {
                o.success = o.complete;
                delete o.complete;
            }
            
            o.success = (function(_success){
                return function(data) {
                    
                    if (_success) {
                        // Fake XHR callback.
                        _success.call(this, {
                            responseText: (data.results[0] || '')
                                // YQL screws with <script>s
                                // Get rid of them
                                .replace(/<script[^>]+?\/>|<script(.|\s)*?\/script>/gi, '')
                        }, 'success');
                    }
                    
                };
            })(o.success);
            
        }
        
        return _ajax.apply(this, arguments);
        
    };
    
})(jQuery.ajax);

$(function() {

    $("#search_by_seller_id").on("click", function() {
        $(this).prop('disabled', true);

        var seller_id = $('#seller_id').val();
        var min_price = $('input[name=min_price]').val();
        var max_price = $('input[name=max_price]').val();
        var page = 1;
        var url = 'http://www.amazon.co.jp/s?ie=UTF8&lo=merchant-items&timestamp=' + $.now()
            + '&me=' + seller_id + '&low-price=' + min_price + '&high-price=' + max_price + '&page=';
        $.ajax({
            type: 'GET',
            url: url + 1,
            success: function(data) {
                // 商品件数の取得
                var total_item_count;
                // 検索結果xxx件中
                var total_match = $(data.responseText).find('#s-result-count').text().match(/([\d,]+)件中/g);
                console.log($(data.responseText).find('#s-result-count').text());
                if ( $(data.responseText).find('#s-result-count').text().match(/([\d,]+)件中/g) ) {
                    total_item_count = $(data.responseText).find('#s-result-count').text().match(/([\d,]+)件中/g)[0].replace( /件中/g, '').replace( /,/g , '');
                }
                // xx件の結果
                if ( $(data.responseText).find('#s-result-count').text().match(/([\d,]+)件の結果/g) ) {
                    total_item_count = $(data.responseText).find('#s-result-count').text().match(/([\d,]+)件の結果/g)[0].replace( /件の結果/g, '').replace( /,/g , '');
                }

                // 1ページの商品数を取得
                var item_count_per_page = 24;
                if ($(data.responseText).find('#result_59')[0]) {
                    // このまま60件取得する
                    item_count_per_page = 60;
                }
                else if ($(data.responseText).find('#result_23')[0]) {
                    item_count_per_page = 60;
                    url = 'http://www.amazon.co.jp/s?ie=UTF8&lo=merchants&timestamp=' + $.now()
                        + '&me=' + seller_id + '&low-price=' + min_price + '&high-price=' + max_price + '&page=';
                }
                else {
                    // 24件以下と思われる
                }

                console.log("url: " + url);
                console.log("件数: " + total_item_count);
                console.log("1ページあたり: " + item_count_per_page);

                var max_item_count = 170 * item_count_per_page;
                var item_count = total_item_count > max_item_count ? max_item_count - 1 : total_item_count;

                var last_page = Math.floor( item_count / item_count_per_page ) + 1;
                 $("<input>", {
                    type: 'hidden',
                    name: 'seller_name',
                    value: $(data.responseText).find('.nav-search-label').text()
                }).appendTo('#seller_name');

                var request = [];
                for (var i = 1; i <= last_page; i++) {
                    request.push($.ajax({
                        type: 'GET',
                        url: url + i
                    }));
                }

                $.when.apply($, request).done(function() {
                    for (var i = 1; i <= last_page; i++) {
                        console.log(i);
                        var html = (last_page == 1) ?  $(arguments[i-1].results[0]) : $(arguments[i-1][0].results[0]);

                        for (var j = 0; j < item_count_per_page; j++) {
                            var index = item_count_per_page * (i-1) + j;
                            var asin = html.find('#result_' + index).data('asin');
                            if (asin) {
                                $("<input>", {
                                    type: 'hidden',
                                    name: 'asins[]',
                                    value: asin,
                                }).appendTo('#asins');
                            }
                        }
                    }
　                   $('#submit-button').click();
                });
            }
        });
    });

});
