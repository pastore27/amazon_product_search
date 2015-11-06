$(function() {
    var price_option_unit    = $('.price-option-unit');
    var price_option_value   = $('#price-option-value');
    var price_option_preview = $('#price-option-preview');

    // 単位変更もpreviewが更新されるように
    price_option_unit.on('change', function() {
        update_preview();
    });

    // プレビュー
    price_option_value.on('keyup', function() {
        update_preview();
    });

    update_preview = function () {
        var value = price_option_value.val();
        var unit  = $('input[name="price-option-unit"]:checked').val();
        if (unit === 'yen') {
            price_option_preview.text('商品価格 + ' + value + ' 円');
        } else if (unit === 'per') {
            price_option_preview.text('商品価格 ✕ ' + value );
        }
    };

});
