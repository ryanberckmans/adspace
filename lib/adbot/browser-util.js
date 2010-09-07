
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
        
        adbot.ad_class = adTag.getAttribute("tag");
    },
    
    collect_ads: function() {
        ads = ADBOTjQuery();
        ADBOTjQuery("." + adbot.ad_class).each(function(i) { ads = ads.add( ADBOTjQuery(this).closest("object,embed,div,img,li,iframe") ); } );
        ads = ads.filter(function(i) {
            var actually_an_ad = true;
            var parent_ad = this;
            ads.each(function(i) {
                if ( ADBOTjQuery.contains( parent_ad, this ) ) {
                    actually_an_ad = false;
                }
            });
            
            if ( ADBOTjQuery(parent_ad).parents("a,object,embed").length + ADBOTjQuery(parent_ad).children("a,object,embed").length < 1 ) { 
                // the element isn't an advertisement unless it contains/has a link, or it contains/has a flash object
                actually_an_ad = false;
            }

            return actually_an_ad;
        });
        adbot.ads = ads;

        adbot.ad_links = [];
        adbot.ads.children("a").add( adbot.ads.parents("a") ).each( function(i) { adbot.ad_links.push( this.href ); } );
        
        adbot.click = ADBOTjQuery(adbot.ads).filter("img")[0];
    },
    
    highlight_ads: function() {
        adbot.ads.css("border", "3px solid red");
    },

}; // adbot namespace

adbot.ad_class_from_adblock();
ADBOTjQuery( adbot.collect_ads );
document.adbot = adbot;
