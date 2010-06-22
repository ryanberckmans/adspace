if (typeof jQuery === 'undefined') {
    var no_conf_query = function () {
	if (typeof jQuery !== "undefined") {
	    jQuery.noConflict();
	}
    }

    var script;
    if (document.createElement && ((script =
                                    document.createElement('script')))) {
        script.type = 'text/javascript';
        script.src = 'http://code.jquery.com/jquery-latest.min.js';
        var heads = document.getElementsByTagName('head');
        if (heads[0]) {
            heads[0].appendChild(script);
	    var int_id = setInterval(no_conf_query, 100);
	    setTimeout(function() { clearInterval(int_id); }, 1000);
        }
    }
}
