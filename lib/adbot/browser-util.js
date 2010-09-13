
var adbot = {
    // requires jQuery

    ad_screenshot: function( element ) {
        element = ADBOTjQuery(element);

        var offset = element.offset();
        var width  = element.outerWidth();
        var height = element.outerHeight();

        if( typeof(element.attr("width")) != "undefined" && typeof(element.attr("height")) != "undefined" ) {
            width = parseInt(element.attr("width"));
            height = parseInt(element.attr("height"));
        }

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
    
    collect_ad_elements: function () {
        ad_elements = ADBOTjQuery();
        ADBOTjQuery("." + adbot.ad_class).each(function(i) { ad_elements = ad_elements.add( ADBOTjQuery(this).closest("object,embed,div,img,li,iframe") ); } );
        ad_elements = ad_elements.filter(function(i) {
            var actually_an_ad = true;
            var current_ad = this;
            
            if ( ADBOTjQuery(current_ad).is("iframe,object,embed") ) {
                return true; // as a highest priority, each iframe,object,embed is considered an advertisement
            }
            
            ad_elements.each(function(i) {
                if ( ADBOTjQuery.contains( current_ad, this ) ) {
                    actually_an_ad = false; // each element is only a true advertisement if it does not contain another true advertisement
                }
            });
            
            if ( ADBOTjQuery(current_ad).parents("a").length + ADBOTjQuery(current_ad).find("a").length < 1 ) { 
                actually_an_ad = false; // each non-iframe,object,embed element is only a true advertisement if it contains/is-contained-by a link
            }

            return actually_an_ad;
        });
        adbot.ad_elements = ad_elements;
    },
    
    ad_link_url: function( ad_element ) {
        var link_url = "";  
        ad_element = ADBOTjQuery(ad_element);        

        if ( ad_element.parents("a").length > 0 ) {
            link_url = ad_element.parents("a")[0].href;
        } else if ( ad_element.find("a").length > 0 ) {
            link_url = ad_element.find("a")[0].href;
        } else if ( ad_element.is("object,embed") ) {
            link_url = adbot.scrape_object_link_url( ad_element[0] );
        } else {
            link_url = "link-url-not-supported-for-this-element:" + ad_element[0].tagName;
        }
        
        return link_url;
    },
    
    process_ads: function() {
        adbot.collect_ad_elements();
        adbot.ads = [];
        adbot.ad_elements.each( function() {
            var ad_element = this;
            var ad = {};
            
            ad.element = ad_element;
            ad.link_url = adbot.ad_link_url( ad_element );            
            ad.type = ad_element.tagName;
            
            var screenshot = adbot.ad_screenshot( ad_element );
            ad.screenshot_left = screenshot.left;
            ad.screenshot_top = screenshot.top;
            ad.screenshot_width = screenshot.width;
            ad.screenshot_height = screenshot.height;
            
            adbot.ads.push(ad);
        });

        adbot.page_width  = ADBOTjQuery(document).width();        
        adbot.page_height = ADBOTjQuery(document).height();
        adbot.date = (new Date()).getTime();
    },
    
    ad_iterator: function() {
        adbot.current_ad_index = -1; // adbot.next_ad() increments this to zero to access the first ad
    },
    
    next_ad: function() {
        // next_ad() behaviour undefined if adbot.ad_iterator() has not been called
        adbot.current_ad_index += 1;
        
        if( adbot.current_ad_index < adbot.ads.length ) {
            adbot.is_next_ad = true;
            adbot.current_ad = adbot.ads[adbot.current_ad_index];
        } else { 
            adbot.is_next_ad = false; 
        }
    },
    
    array_as_csv: function( arrayName ) {
        var str = arrayName + "-is-undefined";
        array = eval( arrayName );
        if (typeof(array) == "undefined") {
            return str;
        }
        str = "";
        for ( i in array ) {
            str += array[i] + ",";
        }
        return str;
    },
    
    click_on: function( element ) {
        var evt = document.createEvent("Events"); 
        evt.initEvent("ClickOnElement", true, false); 
        element.dispatchEvent(evt);
    },
    
    attr_string: function( element ) {
        var str = "";
        
        for( i = 0; i < element.attributes.length ; i++ ) {
            str += element.attributes[i].value + "\"";
        }
        return str;
    },
    
    highlight_ads: function() {
        adbot.ad_elements.css("border", "3px solid red");
    },
    
    scrape_object_link_url: function( object ) {
        var link_url = "link-url-scrape-failed";
        
        var attrs = adbot.attr_string( object );
        var temp = attrs.split(/(http.*?)"/gi);
        while ( temp.length > 0 && temp[temp.length-1].length < 1 ) temp.pop();
        if ( temp.length > 0 ) {
            temp = temp.pop(); 
            var link_url = temp.slice(temp.lastIndexOf("http"));
        }
                               
        return link_url;
    },

}; // adbot namespace

adbot.ad_class_from_adblock();
ADBOTjQuery( adbot.process_ads );
document.adbot = adbot;
