if (typeof jQuery =='undefined') {
    var script;
    if (document.createElement && ((script =
                                    document.createElement('script')))) {
        script.type = 'text/javascript';
        script.src = 'http://code.jquery.com/jquery-latest.min.js';
        var heads = document.getElementsByTagName('head');
        if (heads[0]) {
            heads[0].appendChild(script);
        }
    }
}