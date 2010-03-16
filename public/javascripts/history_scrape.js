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
	stylesheet = "<style> \
		a.csshistory {color: #00ff00; display: none;} \
		a.csshistory:visited {color: #ff0000; display: inline;} \
		div.csshistory a { display: none;} \
		div.csshistory a:visited { display: inline; } \
	</style>"
	document.write(stylesheet);
};

CSSHistory.test = function(link) {
	// Version 2 - modified from AttackAPI
	if (link.currentStyle) // IE
	    return link.currentStyle['display'] == 'inline';
    else
		return document.defaultView.getComputedStyle(link, null).getPropertyValue('display') == 'inline';
};

CSSHistory.test_color = function(link)	{
	// document.defaultView is not supported by IE, nor is getComputedStyle. So for IE we use currentStyle instead.
	// Cf. http://www.quirksmode.org/dom/w3c_html.html http://www.quirksmode.org/dom/w3c_css.html 
	// Version 1 - modified from the original hack
	if(document.defaultView)
		return document.defaultView.getComputedStyle(link,null).getPropertyValue("color") == CSSHistory.rgb_color;
	else // IE
		return link.currentStyle['color'] == CSSHistory.hex_color;
};

CSSHistory.test_width = function(link)	{
	return link.offsetWidth > 0 // cross-browser compatible, yay
};

// When called, this should probably be wrapped in JSON.stringify() for export back up to AJAX
// Some browsers (versions? OSes? plugins?) return bogus results even with methods that are known working for the browser as a whole.
// I have no idea why, yet.
// However, to correct for this, we make sure the method selftests as nonbogus before using it for the real scrape, falling through to other methods if it doesn't
// If all methods are bogus, then return nothing
CSSHistory.check_batch = function(urls, with_variants) {
	switch(BrowserDetect.browser) {
		case 'Chrome': // ~2MURL/min (!!)
			if (CSSHistory.selftest('reuse_insert'))
				return CSSHistory.check_batch_with(urls, 'reuse_insert', with_variants);
		
		case 'Opera': // ~210kURL/min
		case 'Firefox': // ~210kURL/min
			if (CSSHistory.selftest('mass_insert'))
				return CSSHistory.check_batch_with(urls, 'mass_insert', with_variants);
		
		case 'Mozilla': // ~400kURL/min
			if (CSSHistory.selftest('reuse_noinsert'))
				return CSSHistory.check_batch_with(urls, 'reuse_noinsert', with_variants);
		
		case 'Explorer': // ~200kURL/min 
		case 'Safari': // ~3.4MURL/min (!!!)
		default:
			if (CSSHistory.selftest('jquery'))
				return CSSHistory.check_batch_with(urls, 'jquery', with_variants);
			if (CSSHistory.selftest('mass_insert'))
				return CSSHistory.check_batch_with(urls, 'mass_insert', with_variants);
			if (CSSHistory.selftest('reuse_noinsert'))
				return CSSHistory.check_batch_with(urls, 'reuse_noinsert', with_variants);
			if (CSSHistory.selftest('reuse_insert'))
				return CSSHistory.check_batch_with(urls, 'reuse_insert', with_variants);
			if (CSSHistory.selftest('reuse_reinsert'))
				return CSSHistory.check_batch_with(urls, 'reuse_reinsert', with_variants);
			if (CSSHistory.selftest('full_insert'))
				return CSSHistory.check_batch_with(urls, 'full_insert', with_variants);
			
			// If it ever hits this, then all tests have utterly failed.			
			return {}
	}
};

CSSHistory.selftest = function(method) {
	// check this site (just visited!) and some random garbage that can't possibly be visited
	fake_url = hex_md5(String(Math.random() * 50000).replace(/\D/gi,''))
	result = CSSHistory.check_batch_with(['cssfingerprint.com', ], method)
	return (result['cssfingerprint.com'] && !result[fake_url])
}

CSSHistory.methods = ['jquery_noinsert', 'jquery', 'reuse_noinsert', 'reuse_insert','reuse_reinsert','full_reinsert', 
	'mass_insert', 'mass_noinsert', 'mass_noinsert_width', 'reuse_noinsert_width', 'full_reinsert_width'];

// with_variants controls whether http/https x bare/www variants are tested; must pass explicit false to disable
CSSHistory.check_batch_with = function(urls, method, with_variants) {
	if (urls.constructor == Array) {
		// backwards compatibility. Convert a simple array to a return-value hash.
		new_urls = new Object();
		for (var i = 0; i < urls.size(); i++) {
			new_urls[urls[i]] = urls[i];
		}
		urls = new_urls;
	}
	
	switch(method) {
		case 'jquery_noinsert':
			return CSSHistory.check_batch_jquery_noinsert(urls, with_variants);
		case 'jquery':
			return CSSHistory.check_batch_jquery(urls, with_variants);
		case 'mass_insert_width':
			return CSSHistory.check_batch_mass_insert_width(urls, with_variants);
		case 'mass_insert':
			return CSSHistory.check_batch_mass_insert(urls, with_variants);
		case 'mass_noinsert':
			return CSSHistory.check_batch_mass_noinsert(urls, with_variants);
		case 'reuse_noinsert_width': // NOTE: reuse_noinsert appears to crash IE in at least some cases. No idea why yet.
			return CSSHistory.check_batch_reuse_noinsert_width(urls, with_variants);
		case 'reuse_noinsert': // NOTE: reuse_noinsert appears to crash IE in at least some cases. No idea why yet.
			return CSSHistory.check_batch_reuse_noinsert(urls, with_variants);
		case 'reuse_insert':
			return CSSHistory.check_batch_reuse_insert(urls, with_variants);
		case 'reuse_reinsert':
			return CSSHistory.check_batch_reuse_reinsert(urls, with_variants);
		case 'full_reinsert_width':
			return CSSHistory.check_batch_full_reinsert_width(urls, with_variants);
		case 'full_reinsert':
			return CSSHistory.check_batch_full_reinsert(urls, with_variants);
	} 
};

// Query URLs in bulk thanks to jQuery's visible selector - http://api.jquery.com/visible-selector/
// requires jQuery. Assumes that  var $j = jQuery.noConflict();
// requires CSS:
// <style>
//  div.csshistory a { display: none;}
//  div.csshistory a:visited { display: inline; }
// </style>
CSSHistory.check_batch_jquery = function(urls, with_variants) {
	result = {};
	string_to_insert = '';
	var div = document.createElement('div');
	div.className = 'csshistory';
	var id = hex_md5(String(Math.random() * 50000).replace(/\D/gi,''));
	div.id = id;
	for(i in urls ){
		result[escape(urls[i])] = false;
		string_to_insert = string_to_insert + '<a href="http://' + i + '">' + urls[i] + '</a>' ;
		if (with_variants !== false) { // false !== but == undefined
			string_to_insert = string_to_insert + '<a href="https://' + i + '">' + urls[i] + '</a>';
			string_to_insert = string_to_insert + '<a href="http://www.' + i + '">' + urls[i] + '</a>';
			string_to_insert = string_to_insert + '<a href="https://www.' + i + '">' + urls[i] + '</a>';
		}
	}
	// ~20 ms per 500 in Firefox
	div.innerHTML = string_to_insert;
	// ~300 ms 
	document.body.appendChild(div);
	// ~60 ms
	$j("#" + id + " :visible").each(function() { // w00t visible selector
	   result[escape($j(this).text())] = true;
	});
	// 13 ms
	document.body.removeChild(div);
	
	return result
}

CSSHistory.check_batch_jquery_noinsert = function(urls, with_variants) {
	result = {};
	string_to_insert = '';
	var div = document.createElement('div');
	div.className = 'csshistory';
	var id = hex_md5(String(Math.random() * 50000).replace(/\D/gi,''));
	div.id = id;
	for(i in urls ){
		result[escape(urls[i])] = false;
		string_to_insert = string_to_insert + '<a href="http://' + i + '">' + urls[i] + '</a>' ;
		if (with_variants !== false) { // false !== but == undefined
			string_to_insert = string_to_insert + '<a href="https://' + i + '">' + urls[i] + '</a>';
			string_to_insert = string_to_insert + '<a href="http://www.' + i + '">' + urls[i] + '</a>';
			string_to_insert = string_to_insert + '<a href="https://www.' + i + '">' + urls[i] + '</a>';
		}
	}
	div.innerHTML = string_to_insert;
	$j("#" + id + " :visible").each(function() { // w00t visible selector
	   result[escape($j(this).text())] = true;
	});
	return result
}

// Insert a batch, but check each link individually
CSSHistory.check_batch_mass_insert = function(urls, with_variants){
	result = {};
	string_to_insert = '';
	var div = document.createElement('div');
	div.className = 'csshistory';
	var id = hex_md5(String(Math.random() * 50000).replace(/\D/gi, ''));
	div.id = id;
	ids_to_check = [];
	for (i in urls) {
		result[escape(urls[i])] = false;
		string_to_insert = string_to_insert + '<a id="' + 'ip' + urls[i] + '" href="http://' + i + '">' + urls[i] + '</a>';
		ids_to_check.push('ip' + urls[i]);
		if (with_variants !== false) { // false !== but == undefined
			string_to_insert = string_to_insert + '<a id="' + 'sp' + urls[i] + '" href="https://' + i + '">' + urls[i] + '</a>';
			string_to_insert = string_to_insert + '<a id="' + 'iw' + urls[i] + '" href="http://www.' + i + '">' + urls[i] + '</a>';
			string_to_insert = string_to_insert + '<a id="' + 'sw' + urls[i] + '" href="https://www.' + i + '">' + urls[i] + '</a>';
			ids_to_check.push('sp' + urls[i]);
			ids_to_check.push('iw' + urls[i]);
			ids_to_check.push('sw' + urls[i]);
		}
	}
	div.innerHTML = string_to_insert;
	document.body.appendChild(div);
	
	for (i = 0; i < ids_to_check.size(); i++) {
		link = $(ids_to_check[i]);
		if (CSSHistory.test(link)) {
			result[escape(ids_to_check[i].substring(2))] =  true ;
		}
	}
	document.body.removeChild(div);
	
	return result
}

// Insert a batch, but check each link individually, using width to test
CSSHistory.check_batch_mass_insert_width = function(urls, with_variants){
	result = {};
	string_to_insert = '';
	var div = document.createElement('div');
	div.className = 'csshistory';
	var id = hex_md5(String(Math.random() * 50000).replace(/\D/gi, ''));
	div.id = id;
	ids_to_check = [];
	for (i in urls) {
		result[escape(urls[i])] = false;
		string_to_insert = string_to_insert + '<a id="' + 'ip' + urls[i] + '" href="http://' + i + '">' + urls[i] + '</a>';
		ids_to_check.push('ip' + urls[i]);
		if (with_variants !== false) { // false !== but == undefined
			string_to_insert = string_to_insert + '<a id="' + 'sp' + urls[i] + '" href="https://' + i + '">' + urls[i] + '</a>';
			string_to_insert = string_to_insert + '<a id="' + 'iw' + urls[i] + '" href="http://www.' + i + '">' + urls[i] + '</a>';
			string_to_insert = string_to_insert + '<a id="' + 'sw' + urls[i] + '" href="https://www.' + i + '">' + urls[i] + '</a>';
			ids_to_check.push('sp' + urls[i]);
			ids_to_check.push('iw' + urls[i]);
			ids_to_check.push('sw' + urls[i]);
		}
	}
	div.innerHTML = string_to_insert;
	document.body.appendChild(div);
	
	for (i = 0; i < ids_to_check.size(); i++) {
		link = $(ids_to_check[i]);
		if (CSSHistory.test_width(link)) {
			result[escape(ids_to_check[i].substring(2))] =  true ;
		}
	}
	document.body.removeChild(div);
	
	return result
}

// Insert a batch, but check each link individually
CSSHistory.check_batch_mass_noinsert = function(urls, with_variants){
	result = {};
	string_to_insert = '';
	var div = document.createElement('div');
	div.className = 'csshistory';
	var id = hex_md5(String(Math.random() * 50000).replace(/\D/gi, ''));
	div.id = id;
	ids_to_check = [];
	for (i in urls) {
		result[escape(urls[i])] = false;
		string_to_insert = string_to_insert + '<a id="' + 'ip' + urls[i] + '" href="http://' + i + '">' + urls[i] + '</a>';
		ids_to_check.push('ip' + urls[i]);
		if (with_variants !== false) { // false !== but == undefined
			string_to_insert = string_to_insert + '<a id="' + 'sp' + urls[i] + '" href="https://' + i + '">' + urls[i] + '</a>';
			string_to_insert = string_to_insert + '<a id="' + 'iw' + urls[i] + '" href="http://www.' + i + '">' + urls[i] + '</a>';
			string_to_insert = string_to_insert + '<a id="' + 'sw' + urls[i] + '" href="https://www.' + i + '">' + urls[i] + '</a>';
			ids_to_check.push('sp' + urls[i]);
			ids_to_check.push('iw' + urls[i]);
			ids_to_check.push('sw' + urls[i]);
		}
	}
	div.innerHTML = string_to_insert;
	document.body.appendChild(div);
	
	for (i = 0; i < ids_to_check.size(); i++) {
		link = $(ids_to_check[i]);
		try {
			if (CSSHistory.test(link)) {
				result[escape(ids_to_check[i].substring(2))] = true;
			}
		} 
		catch (err) {;} // if this failed, then the method is bogus
	}
	document.body.removeChild(div);
	
	return result
}

// Just make & reuse the link. Don't even insert into DOM.
CSSHistory.check_batch_reuse_noinsert = function(urls, with_variants){
	result = {};
	var link = document.createElement("a");
	link.className = 'csshistory';
	for (i in urls) { // i is the URL, urls[i] is the return value (i.e. site id)
		var found = false;
		
		var j = 0
		do { // if with_variants === false, only run this once
			link.href = CSSHistory.prefixes[j] + i;
		    found = found || CSSHistory.test(link);
			j++;
		} while (!found && (j < CSSHistory.prefixes.length) && (with_variants !== false))
		
		result[escape(urls[i])] = found;
	};
	return result;
};

CSSHistory.check_batch_reuse_noinsert_width = function(urls, with_variants){
	result = {};
	var link = document.createElement("a");
	link.className = 'csshistory';
	for (i in urls) { // i is the URL, urls[i] is the return value (i.e. site id)
		var found = false;
		
		var j = 0
		do { // if with_variants === false, only run this once
			link.href = CSSHistory.prefixes[j] + i;
		    found = found || CSSHistory.test_width(link);
			j++;
		} while (!found && (j < CSSHistory.prefixes.length) && (with_variants !== false))
		
		result[escape(urls[i])] = found;
	};
	return result;
};

// Insert it into DOM, but reuse the same thing over again.
CSSHistory.check_batch_reuse_insert = function(urls, with_variants){
	result = {};
	var link = document.createElement("a");
	link.className = 'csshistory';
	document.body.appendChild(link);
	for (i in urls) {
		var found = false;
		
		var j = 0
		do {
			link.href = CSSHistory.prefixes[j] + i;
		    found = found || CSSHistory.test(link);
			j++;
		} while (!found && (j < CSSHistory.prefixes.length) && (with_variants !== false))
		
		result[escape(urls[i])] = found;

	};
	document.body.removeChild(link);
	return result;
};

// Reuse the same link, but reinsert it into DOM each time
CSSHistory.check_batch_reuse_reinsert = function(urls, with_variants){
	result = {};
	var link = document.createElement("a");
	link.className = 'csshistory';
	for (i in urls) {
		var found = false;
		
		var j = 0
		do {
			document.body.appendChild(link);
			link.href = CSSHistory.prefixes[j] + i;
		    found = found || CSSHistory.test(link);
			document.body.removeChild(link);
			j++;
		} while (!found && (j < CSSHistory.prefixes.length) && (with_variants !== false))
		
		result[escape(urls[i])] = found;
	};
	return result;
};

// Completely redo the link each time.
CSSHistory.check_batch_full_reinsert = function(urls, with_variants) {
	result = {};
	for (i in urls) {
		var found = false;
		
		var j = 0
		do {
			var link = document.createElement("a");
			link.className = 'csshistory';
			link.href = CSSHistory.prefixes[j] + i;
			document.body.appendChild(link);
		    found = found || CSSHistory.test(link);
			document.body.removeChild(link);
			j++;
		} while (!found && (j < CSSHistory.prefixes.length) && (with_variants !== false))
		
		result[escape(urls[i])] = found;
	};		
	return result;
};

// Completely redo the link each time.
CSSHistory.check_batch_full_reinsert_width = function(urls, with_variants) {
	result = {};
	for (i in urls) {
		var found = false;
		
		var j = 0
		do {
			var link = document.createElement("a");
			link.className = 'csshistory';
			link.href = CSSHistory.prefixes[j] + i;
			document.body.appendChild(link);
		    found = found || CSSHistory.test_width(link);
			document.body.removeChild(link);
			j++;
		} while (!found && (j < CSSHistory.prefixes.length) && (with_variants !== false))
		
		result[escape(urls[i])] = found;
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
