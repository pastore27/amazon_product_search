$(function() {

    var button = $('#add-keyword-form');
    var button = $('#add-keyword-form');

    button.on('click', function () {
        button.before('<input name="keyword[]" class="form-control">');
    });

});
