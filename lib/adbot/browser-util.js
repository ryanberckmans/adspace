
var adbot = {
    // requires jquery

    set_ad_screenshot_info: function( selector ) {
        var info = this.offset_and_size( selector );

        this.ad_screenshot = {}
        this.ad_screenshot.left = info.left;
        this.ad_screenshot.top = info.top;
        this.ad_screenshot.width = info.width;
        this.ad_screenshot.height = info.height;
    },

    offset_and_size: function( selector ) {
        var wrapper = jQuery(selector).closest("div");

        if (wrapper.length < 1) {
            wrapper = jQuery(selector).parent();
        }

        var offset = wrapper.offset();
        var width  = wrapper.outerWidth();
        var height = wrapper.outerHeight();

        return { "left": offset.left, "top": offset.top, "width": width, "height": height };
    },

}; // adbot namespace