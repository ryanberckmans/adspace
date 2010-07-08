// evaluate within a self-evaling anonymous
// function to avoid namespace conflicts
(function() {
    var int_id = 0;
    
    var no_conf_query = function () {
        if (typeof jQuery != "undefined" ) {
            // this puts the version of jQuery we just loaded
            // into its own global variable *and* restores
            // any original value that was set to $ or jQuery
            ADBOTjQuery = jQuery.noConflict(true);

            clearInterval( int_id );
        }
    }

    var script;
    if (document.createElement && ((script =
                                    document.createElement('script')))) {
        script.type = 'text/javascript';
        script.src = 'http://code.jquery.com/jquery-1.4.2.min.js';
        var heads = document.getElementsByTagName('head');
        if (heads[0]) {
            heads[0].appendChild(script);

            // we need to wait for jQuery to load before
            // the noConflict() call, keep trying until its loaded
            int_id = setInterval(no_conf_query, 100);
            setTimeout(function() { clearInterval(int_id); }, 5000);
        }
    }
})();