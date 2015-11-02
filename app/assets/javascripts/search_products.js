$(function() {
    var button         = $('button[type="submit"]');
    var keyword        = $('#keyword');
    var negative_match = $('#negative-match');
    var category       = $('#category');
    var is_prime       = $('#is_prime');

    button.on('click', function() {
        var url = '/search_products/products?';
        url = url
            + 'keyword='         + keyword.val()
            + '&negative_match=' + negative_match.val()
            + '&category='       + category.val()
            + '&page='           + 1;
        if ( is_prime.prop('checked') ) {
            url = url + '&is_prime=1';
        } else {
            url = url + '&is_prime=0';
        }
        window.location = url;
    });

});
