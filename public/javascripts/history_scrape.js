<!--
/*

This javascript is used to run the CSS history hack in production.

Original author: Jeremiah Grossman (license: BSD)
Revision author: Sai Emrys (license: CC by-sa)

*/

var CSSHistory = {};

// We need to force the links to a known color value to be able to test them
CSSHistory.prep = function() {
	document.write('<style>');
	document.write('a.csshistory {color: #00FF00;}');
	document.write('a.csshistory:visited {color: #FF0000;}');
	document.write('</style>');	
};

CSSHistory.check = function(url) {
	/* create the new anchor tag with the appropriate URL information */
	var link = document.createElement("a");
	link.id = hex_md5(url); // since we are operating on any number of unordered links, this uses a hash to generate the ID
	link.href = 'http://' + url;
	link.innerHTML = url;
	link.className = 'csshistory';
	
	/* quickly add and remove the link from the DOM with enough time to save the visible computed color. */
	document.body.appendChild(link);
	var color = document.defaultView.getComputedStyle(link,null).getPropertyValue("color");
	link.href = 'https://' + url
	var colors = document.defaultView.getComputedStyle(link,null).getPropertyValue("color");
	link.href = 'http://www.' + url
	var colorw = document.defaultView.getComputedStyle(link,null).getPropertyValue("color");
	link.href = 'https://www.' + url
	var colorws = document.defaultView.getComputedStyle(link,null).getPropertyValue("color");
	document.body.removeChild(link);
	
	return (color == "rgb(255, 0, 0)") || (colors == "rgb(255, 0, 0)") || (colorw == "rgb(255, 0, 0)") || (colorws == "rgb(255, 0, 0)")
};

// When called, this should probably be wrapped in JSON.stringify() for export back up to AJAX
CSSHistory.check_batch = function(urls) {
	result = {};
	
	for (var i = 0; i < urls.length; i++) {
		result[urls[i]] = CSSHistory.check(urls[i]);
	};
	
	return result;
};

