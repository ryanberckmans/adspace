
var adbot = {
    // requires jQuery

    set_ad_screenshot_info: function( selector ) {
        var info = this.offset_and_size( selector );

        this.ad_screenshot = {}
        this.ad_screenshot.left = info.left;
        this.ad_screenshot.top = info.top;
        this.ad_screenshot.width = info.width;
        this.ad_screenshot.height = info.height;
    },

    offset_and_size: function( selector ) {
        var wrapper = ADBOTjQuery(selector).closest("div");

        if (wrapper.length < 1) {
            wrapper = ADBOTjQuery(selector).parent();
        }

        var offset = wrapper.offset();
        var width  = wrapper.outerWidth();
        var height = wrapper.outerHeight();

        return { "left": offset.left, "top": offset.top, "width": width, "height": height };
    },
    
    ad_class_from_adblock: function() {
        var adTag = document.createElement("AdTagElement");
        adTag.setAttribute("tag", "none");
        document.documentElement.appendChild(adTag);
        
        var e = document.createEvent("Events");
        e.initEvent("AdTagEvent", true, false);
        adTag.dispatchEvent(e);
        
        this.ad_class = adTag.getAttribute("tag");
    },

}; // adbot namespace

adbot.ad_class_from_adblock();