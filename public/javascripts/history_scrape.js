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

CSSHistory.prefixes = ['http://', 'https://', 'http://www.', 'https://www.'];
CSSHistory.hex_color = '#ff0000'
CSSHistory.rgb_color = 'rgb(255, 0, 0)'

// We need to force the links to a known color value to be able to test them
CSSHistory.prep = function() {
	document.write('<style>');
	document.write('a.csshistory {color: #00ff00; display: inline;}');
	document.write('a.csshistory:visited {color: #ff0000; display: none;}');
	document.write('</style>');	
};

CSSHistory.test = function(link) {
	// document.defaultView is not supported by IE, nor is getComputedStyle. So for IE we use currentStyle instead.
	// Cf. http://www.quirksmode.org/dom/w3c_html.html http://www.quirksmode.org/dom/w3c_css.html 
	
	// Version 2 - modified from AttackAPI
	if (link.currentStyle) { // IE
	    return (link.currentStyle['display'] == 'none');
    } else {
		return (document.defaultView.getComputedStyle(link, null).getPropertyValue('display') == 'none');
	}
	
	/*
	// Version 1 - modified from the original hack
	if(document.defaultView)
		var color = document.defaultView.getComputedStyle(link,null).getPropertyValue("color");
	else // IE
		var color = link.currentStyle['color'];
	return (color == CSSHistory.rgb_color) || (color == CSSHistory.hex_color);
	*/
};

// When called, this should probably be wrapped in JSON.stringify() for export back up to AJAX
CSSHistory.check_batch = function(urls) {
	switch(BrowserDetect.browser) {
		case 'Mozilla': // random mozilla/gecko (e.g. namoroka) appears to be faster w/ reuse_noinsert
		case 'Firefox':
			return CSSHistory.check_batch_with(urls, 'reuse_noinsert'); // Firefox is ~28% faster w/ reuse_noisert vs jquery
		
		case 'Chrome':
		case 'Safari': 
		default:
			return CSSHistory.check_batch_with(urls, 'jquery'); // Safari is ~4x faster using jquery vs reuse_reinsert; reuse_noinsert fails on safari
	}
};

CSSHistory.methods = ['jquery_noinsert', 'jquery', 'reuse_noinsert', 'reuse_insert','reuse_reinsert','full_reinsert'];

CSSHistory.check_batch_with = function(urls, method) {
	switch(method) {
		case 'jquery_noinsert':
			return CSSHistory.check_batch_jquery_noinsert(urls);
		case 'jquery':
			return CSSHistory.check_batch_jquery(urls);
		case 'reuse_noinsert':
			return CSSHistory.check_batch_reuse_noinsert(urls);
		case 'reuse_insert':
			return CSSHistory.check_batch_reuse_insert(urls);
		case 'reuse_reinsert':
			return CSSHistory.check_batch_reuse_reinsert(urls);
		case 'full_reinsert':
			return CSSHistory.check_batch_full_reinsert(urls);
	} 
};

// Query URLs in bulk thanks to jQuery's visible selector - http://api.jquery.com/visible-selector/
// requires jQuery. Assumes that  var $j = jQuery.noConflict();
// requires CSS:
// <style>
//  div.csshistory a { display: none;}
//  div.csshistory a:visited { display: inline; }
// </style>
CSSHistory.check_batch_jquery = function(urls) {
	result = {};
	string_to_insert = '';
	var div = document.createElement('div');
	div.className = 'csshistory';
	var id = hex_md5(String(Math.random() * 50000).replace(/\D/gi,''));
	div.id = id
	for(var i =0; i < urls.size(); i++ ){
		result[urls[i]] = false;
		string_to_insert = string_to_insert + '<a href="http://' + urls[i] + '">' + urls[i] + '</a>' ;
		string_to_insert = string_to_insert + '<a href="https://' + urls[i] + '">' + urls[i] + '</a>' ;
		string_to_insert = string_to_insert + '<a href="http://www.' + urls[i] + '">' + urls[i] + '</a>' ;
		string_to_insert = string_to_insert + '<a href="https://www.' + urls[i] + '">' + urls[i] + '</a>' ;
	}
	// ~20 ms per 500 in Firefox
	div.innerHTML = string_to_insert;
	// ~300 ms 
	document.body.appendChild(div);
	// ~60 ms
	$j("#" + id + " :visible").each(function() { // w00t visible selector
	   result[$j(this).text()] = true;
	});
	// 13 ms
	document.body.removeChild(div);
	
	return result
}

CSSHistory.check_batch_jquery_noinsert = function(urls) {
	result = {};
	string_to_insert = '';
	var div = document.createElement('div');
	div.className = 'csshistory';
	var id = hex_md5(String(Math.random() * 50000).replace(/\D/gi,''));
	div.id = id
	for(var i =0; i < urls.size(); i++ ){
		result[urls[i]] = false;
		string_to_insert = string_to_insert + '<a href="http://' + urls[i] + '">' + urls[i] + '</a>' ;
		string_to_insert = string_to_insert + '<a href="https://' + urls[i] + '">' + urls[i] + '</a>' ;
		string_to_insert = string_to_insert + '<a href="http://www.' + urls[i] + '">' + urls[i] + '</a>' ;
		string_to_insert = string_to_insert + '<a href="https://www.' + urls[i] + '">' + urls[i] + '</a>' ;
	}
	div.innerHTML = string_to_insert;
	$j("#" + id + " :visible").each(function() { // w00t visible selector
	   result[$j(this).text()] = true;
	});
	return result
}

// Just make & reuse the link. Don't even insert into DOM.
CSSHistory.check_batch_reuse_noinsert = function(urls){
	result = {};
	var link = document.createElement("a");
	link.className = 'csshistory';
	for (var i = 0; i < urls.length; i++) {
		var found = false;
		
		for (var j = 0; !found && (j < CSSHistory.prefixes.length); j++) {
			link.href = CSSHistory.prefixes[j] + urls[i];
		    found = found || CSSHistory.test(link)
		}
		
		result[urls[i]] = found;
	};
	return result;
};

// Insert it into DOM, but reuse the same thing over again.
CSSHistory.check_batch_reuse_insert = function(urls){
	result = {};
	var link = document.createElement("a");
	link.className = 'csshistory';
	document.body.appendChild(link);
	for (var i = 0; i < urls.length; i++) {
		var found = false;
		
		for (var j = 0; !found && (j < CSSHistory.prefixes.length); j++) {
			link.href = CSSHistory.prefixes[j] + urls[i];
		    found = found || CSSHistory.test(link)
		}
		
		result[urls[i]] = found;
	};
	document.body.removeChild(link);
	return result;
};

// Reuse the same link, but reinsert it into DOM each time
CSSHistory.check_batch_reuse_reinsert = function(urls){
	result = {};
	var link = document.createElement("a");
	link.className = 'csshistory';
	for (var i = 0; i < urls.length; i++) {
		var found = false;
		
		for (var j = 0; !found && (j < CSSHistory.prefixes.length); j++) {
			document.body.appendChild(link);
			link.href = CSSHistory.prefixes[j] + urls[i];
		    found = found || CSSHistory.test(link)
			document.body.removeChild(link);
		}
		
		result[urls[i]] = found;
	};
	return result;
};

// Completely redo the link each time.
CSSHistory.check_batch_full_reinsert = function(urls) {
	result = {};
	for (var i = 0; i < urls.length; i++) {
		var found = false;
		
		for (var j = 0; !found && (j < CSSHistory.prefixes.length); j++) {
			var link = document.createElement("a");
			link.className = 'csshistory';
			link.href = CSSHistory.prefixes[j] + urls[i];
			document.body.appendChild(link);
		    found = found || CSSHistory.test(link);
			document.body.removeChild(link);
		}
		
		result[urls[i]] = found;
	};		
	return result;
};


// timing utility 
 var timeDiff  =  {
    setStartTime:function (){
        d = new Date();
        time  = d.getTime();
    },

    getDiff:function (){
        d = new Date();
        return (d.getTime()-time);
    }
};

// Taken from http://www.quirksmode.org/js/detect.html
var BrowserDetect = {
	init: function () {
		this.browser = this.searchString(this.dataBrowser) || "An unknown browser";
		this.version = this.searchVersion(navigator.userAgent)
			|| this.searchVersion(navigator.appVersion)
			|| "an unknown version";
		this.OS = this.searchString(this.dataOS) || "an unknown OS";
	},
	searchString: function (data) {
		for (var i=0;i<data.length;i++)	{
			var dataString = data[i].string;
			var dataProp = data[i].prop;
			this.versionSearchString = data[i].versionSearch || data[i].identity;
			if (dataString) {
				if (dataString.indexOf(data[i].subString) != -1)
					return data[i].identity;
			}
			else if (dataProp)
				return data[i].identity;
		}
	},
	searchVersion: function (dataString) {
		var index = dataString.indexOf(this.versionSearchString);
		if (index == -1) return;
		return parseFloat(dataString.substring(index+this.versionSearchString.length+1));
	},
	dataBrowser: [
		{
			string: navigator.userAgent,
			subString: "Chrome",
			identity: "Chrome"
		},
		{ 	string: navigator.userAgent,
			subString: "OmniWeb",
			versionSearch: "OmniWeb/",
			identity: "OmniWeb"
		},
		{
			string: navigator.vendor,
			subString: "Apple",
			identity: "Safari",
			versionSearch: "Version"
		},
		{
			prop: window.opera,
			identity: "Opera"
		},
		{
			string: navigator.vendor,
			subString: "iCab",
			identity: "iCab"
		},
		{
			string: navigator.vendor,
			subString: "KDE",
			identity: "Konqueror"
		},
		{
			string: navigator.userAgent,
			subString: "Firefox",
			identity: "Firefox"
		},
		{
			string: navigator.vendor,
			subString: "Camino",
			identity: "Camino"
		},
		{		// for newer Netscapes (6+)
			string: navigator.userAgent,
			subString: "Netscape",
			identity: "Netscape"
		},
		{
			string: navigator.userAgent,
			subString: "MSIE",
			identity: "Explorer",
			versionSearch: "MSIE"
		},
		{
			string: navigator.userAgent,
			subString: "Gecko",
			identity: "Mozilla",
			versionSearch: "rv"
		},
		{ 		// for older Netscapes (4-)
			string: navigator.userAgent,
			subString: "Mozilla",
			identity: "Netscape",
			versionSearch: "Mozilla"
		}
	],
	dataOS : [
		{
			string: navigator.platform,
			subString: "Win",
			identity: "Windows"
		},
		{
			string: navigator.platform,
			subString: "Mac",
			identity: "Mac"
		},
		{
			   string: navigator.userAgent,
			   subString: "iPhone",
			   identity: "iPhone/iPod"
	    },
		{
			string: navigator.platform,
			subString: "Linux",
			identity: "Linux"
		}
	]

};
BrowserDetect.init();
