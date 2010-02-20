<!--
/*

This javascript is used to run the CSS history hack in production.

Original authors: Jeremiah Grossman (license: BSD) and Daniel Bartlett
Revision author: Sai Emrys (license: CC by-sa)

http://jeremiahgrossman.blogspot.com/2006/08/i-know-where-youve-been.html
http://www.gnucitizen.org/projects/javascript-visited-link-scanner
http://code.google.com/p/attackapi/source/browse/trunk/lib/dom/scanHistory.js
*/

var CSSHistory = {};

// We need to force the links to a known color value to be able to test them
CSSHistory.prep = function() {
	document.write('<style>');
	document.write('a.csshistory {color: #00ff00; display: inline;}');
	document.write('a.csshistory:visited {color: #ff0000; display: none;}');
	document.write('</style>');	
};

CSSHistory.check = function(url) {
	var found = false;
	var prefixes = ['http://', 'https://', 'http://www.', 'https://www.'];
	var hex_color = '#ff0000'
	var rgb_color = 'rgb(255, 0, 0)'
	
	for (i = 0; !found && (i < prefixes.length); i++){
		// create the new anchor tag with the appropriate URL information
		// NOTE: MSIE has a bug whereby it does NOT update an element's style once created if the href changes.
		// Therefore, we have to do a full setup/teardown each time.
		// The efficiency reduction appears to be approx. 17%. :(
		var link = document.createElement("a");
		// link.id = hex_md5(url); // since we are operating on any number of unordered links, this uses a hash to generate the ID
		// link.innerHTML = url;
		link.className = 'csshistory';
		
		/* quickly add and remove the link from the DOM with enough time to save the visible computed color. */
		document.body.appendChild(link);
		// document.defaultView is not supported by IE, nor is getComputedStyle. So for IE we use currentStyle instead.
		// Cf. http://www.quirksmode.org/dom/w3c_html.html http://www.quirksmode.org/dom/w3c_css.html 
		
		link.href = prefixes[i] + url;
	    
		// Version 2 - modified from AttackAPI
		if (link.currentStyle) {
		    found = found || (link.currentStyle['display'] == 'none');
	    } else {
			found = found || (document.defaultView.getComputedStyle(link, null).getPropertyValue('display') == 'none');
		}
		
		/*
		// Version 1 - modified from the original hack
		if(document.defaultView)
			var color = document.defaultView.getComputedStyle(link,null).getPropertyValue("color");
		else // IE
			var color = link.currentStyle['color'];
		found = found || color == rgb_color) || (color == hex_color);
		*/
		
		document.body.removeChild(link);
	}
	
	return found;
};

// When called, this should probably be wrapped in JSON.stringify() for export back up to AJAX
CSSHistory.check_batch = function(urls) {
	result = {};
	
	for (var i = 0; i < urls.length; i++) {
		result[urls[i]] = CSSHistory.check(urls[i]);
	};
	
	return result;
};

