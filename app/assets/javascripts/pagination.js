$(function() {

    $('ul.pagination > li').each(function() {
        $(this).on('click', function() {
            var url  = window.location.href.replace(/page=\d+/g, 'page=' + $(this).val());
            window.location = url;
        });
    });

});
