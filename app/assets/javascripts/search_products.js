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

    var max_item_count      = 10200;
    var item_count_per_page = 60;

    $("#search_by_seller_id").on("click", function() {
        $(this).prop('disabled', true);

        var seller_id = $('#seller_id').val();
        var page = 1;
        var url = 'http://www.amazon.co.jp/s?ie=UTF8&lo=merchants&timestamp=' + $.now() + '&me=' + seller_id + '&page=';

        $.ajax({
            type: 'GET',
            url: url + 1,
            success: function(data) {
                var match = $(data.responseText).find('#s-result-count').text().match(/[\d,]+/);
                console.log(match);
                var item_count = match[0].replace( /,/g , '') > max_item_count ? max_item_count - 1 : match[0].replace( /,/g , '')
                var last_page = Math.floor( item_count / item_count_per_page ) + 1
                console.log(last_page);
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
                        var html = $(arguments[i-1][0].results[0]);

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
