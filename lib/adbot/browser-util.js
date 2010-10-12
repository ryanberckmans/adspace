
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
    
    collect_frames: function() {
        var frames = ADBOTjQuery("." + adbot.ad_class).filter("iframe");
        frames.filter(function(i) {
            var frame = ADBOTjQuery(this);
            if ( frame.width() < 2 || frame.height() < 2 ) {
                return false; // tiny frames are for tracking purposes and are not ads. strip them out.
            }
            return true;
        });
        
        var i = 0;
        var frame_names = "";
        while ( i < frames.length ) {
            var frame_name = frames.eq(i).attr("id");
            if ( ! frame_name || frame_name.length < 1 ) {
                frame_name = adbot.ad_class + i;
                frames.eq(i).attr("id", frame_name);
            }
            frame_names += frame_name;
            i++;
            if ( i >= frames.length ) {
                break;
            }
            frame_names += ",";
        }
        
        adbot.frames = frames;
        adbot.frame_names = frame_names;
    },
    
    collect_ad_elements: function () {
        var ad_elements = ADBOTjQuery();
        ADBOTjQuery("." + adbot.ad_class).each(function(i) { ad_elements = ad_elements.add( ADBOTjQuery(this).closest("object,embed,div,img,li,iframe") ); } );
        ad_elements = ad_elements.filter(function() {
            var actually_an_ad = true;
            var current_ad = this;

            if ( ADBOTjQuery(current_ad).is("iframe") ) {
                return false; // reject iframes, they will be sub-scanned
            }
            
            ad_elements.each(function() {
                if ( ADBOTjQuery.contains( current_ad, this ) ) {
                    actually_an_ad = false; // each element is only a true advertisement if it does not contain another true advertisement
                }
            });
            
            return actually_an_ad;
        });
        adbot.ad_elements = ad_elements;
    },
    
    ad_link_url: function( ad_element ) {
        var link_url = "";  
        ad_element = ADBOTjQuery(ad_element);        

        if ( ad_element.is("a") ) {
            link_url = ad_element[0].href;
        } else if ( ad_element.parents("a").length > 0 ) {
            link_url = ad_element.parents("a")[0].href;
        } else if ( ad_element.find("a").length > 0 ) {
            link_url = ad_element.find("a")[0].href;
        } else if ( ad_element.is("object,embed") ) {
            ad_element.wrap('<div />');
            link_url = "SCRAPEME " + ad_element.parent().html();
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
            
            var element_for_screenshot = ad_element;
            while ( true ) {
                var screenshot = adbot.ad_screenshot( element_for_screenshot );
                ad.screenshot_left = screenshot.left;
                ad.screenshot_top = screenshot.top;
                ad.screenshot_width = screenshot.width;
                ad.screenshot_height = screenshot.height;
                if ( !isNaN( ad.screenshot_width) && !isNaN( ad.screenshot_height) ) {
                    break;
                }
                if ( ! ADBOTjQuery(element_for_screenshot).parent().is("div") ) {
                    ADBOTjQuery(element_for_screenshot).wrap('<div />');
                }
                element_for_screenshot = ADBOTjQuery(element_for_screenshot).parent()[0]
            }
            
            if ( ad.screenshot_width < 2 || ad.screenshot_height < 2 ) {
                return; // tiny elements are for tracking purposes and are not ads. strip them out even though they are present in adbot.ad_elements
            }
            
            adbot.ads.push(ad);
        });

        adbot.page_width  = ADBOTjQuery(document).width();        
        adbot.page_height = ADBOTjQuery(document).height();
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
    
}; // adbot namespace

adbot.ad_class_from_adblock();
document.adbot = adbot;
