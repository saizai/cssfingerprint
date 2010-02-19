<!--
/*

This javascript is used to run the CSS history hack in production.

Original authors: Jeremiah Grossman (license: BSD) and Daniel Bartlett
Revision author: Sai Emrys (license: CC by-sa)

http://jeremiahgrossman.blogspot.com/2006/08/i-know-where-youve-been.html
http://www.gnucitizen.org/projects/javascript-visited-link-scanner

*/

var CSSHistory = {};

// We need to force the links to a known color value to be able to test them
CSSHistory.prep = function() {
	document.write('<style>');
	document.write('a.csshistory {color: #00ff00;}');
	document.write('a.csshistory:visited {color: #ff0000;}');
	document.write('</style>');	
};

CSSHistory.check = function(url) {
	/* create the new anchor tag with the appropriate URL information */
	var link = document.createElement("a");
	link.id = hex_md5(url); // since we are operating on any number of unordered links, this uses a hash to generate the ID
	link.href = 'http://' + url;
	link.innerHTML = url;
	link.className = 'csshistory';
	
	var hex_color = '#ff0000'
	var rgb_color = 'rgb(255, 0, 0)'
	
	/* quickly add and remove the link from the DOM with enough time to save the visible computed color. */
	document.body.appendChild(link);
	// document.defaultView is not supported by IE, nor is getComputedStyle. So for IE we use currentStyle instead.
	// Cf. http://www.quirksmode.org/dom/w3c_html.html http://www.quirksmode.org/dom/w3c_css.html 
	if(document.defaultView) {
		var color = document.defaultView.getComputedStyle(link,null).getPropertyValue("color");
	} else { // IE
		var color = link.currentStyle['color'];
	}
	link.href = 'https://' + url
	if(document.defaultView) {
		var colors = document.defaultView.getComputedStyle(link,null).getPropertyValue("color");
	} else { // IE
		var colors = link.currentStyle['color'];
	}
	link.href = 'http://www.' + url
	if(document.defaultView) {
		var colorw = document.defaultView.getComputedStyle(link,null).getPropertyValue("color");
	} else { // IE
		var colorw = link.currentStyle['color'];
	}
	link.href = 'https://www.' + url
	if(document.defaultView) {
		var colorws = document.defaultView.getComputedStyle(link,null).getPropertyValue("color");
	} else { // IE
		var colorws = link.currentStyle['color'];
	}
	document.body.removeChild(link);
	
	return (color == rgb_color) || (colors == rgb_color) || (colorw == rgb_color) || (colorws == rgb_color) || (color == hex_color) || (colors == hex_color) || (colorw == hex_color) || (colorws == hex_color)
};

// When called, this should probably be wrapped in JSON.stringify() for export back up to AJAX
CSSHistory.check_batch = function(urls) {
	result = {};
	
	for (var i = 0; i < urls.length; i++) {
		result[urls[i]] = CSSHistory.check(urls[i]);
	};
	
	return result;
};

