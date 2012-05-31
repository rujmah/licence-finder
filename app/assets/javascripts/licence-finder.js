$(function() {

	var section,
		pluralSection;

	/* Add one thing to another thing, alphabetically */
	function swapList(elem, targetList, state){
		if($(".business-"+section+"-picked ul").length == 0){
            var next_url = $(".business-"+section+"-picked").data("next-url");
            var picked_sectors = '<ul id="picked-business-sectors"></ul><a href="' + next_url + '" class="button medium" id="next-step">Next step</a>';
			$(picked_sectors).insertAfter(".business-"+section+"-picked h3");
			$(".hint").css("display", "none");
            setupEvents();
		}

		var id = $(elem).attr("href").split(pluralSection+"="),
            toAdd = null;
		if(id[1].indexOf("_")){
			id = id[1].split("_");
			id = id[0];
		} else {
			id = id[1];
		}

		if(id.indexOf("&")){
			id = id.split("&");
			id = id[0];
		}

		var plainTextTitle = $(elem).parent().children("span").text();

		if(state == "add"){
			toAdd = "<li data-public-id='" + id + "'><span class='"+section+"-name'>"+plainTextTitle+"</span> <a href='/licence-finder/"+pluralSection+"?"+pluralSection+"="+id+"'>Remove</a></li>";
		}
		else{
			toAdd = "<li><span class='"+section+"-name'>"+plainTextTitle+"</span> <a href='/licence-finder/"+pluralSection+"?"+pluralSection+"="+id+"'>Add</a></li>";
		}

        var added = false;
        var targetListItems = $(targetList+" li");

        $(targetListItems).each(function(){
            if($(this).text() > plainTextTitle){
                $(toAdd).insertBefore($(this));
                added = true;
                return false;
            }
        });

        if(!added) $(toAdd).appendTo(targetList);
        $(elem).parent().remove();
        setupEvents();
	};


	function setupEvents(){
		$(".business-"+section+"-picked a").off("click");
		$(".business-"+section+"-picked a").on("click", function(){
			swapList(this, ".search-picker", "remove");
			return false;
		});
		$(".search-picker a").off("click");
        $(".search-picker a").on("click", function(){
			swapList(this, ".business-"+section+"-picked ul", "add");
			return false;
		});
        $("#next-step,#search-again-button").off("click");
        $("#next-step,#search-again-button").on("click", function(event) {
            event.preventDefault();
            var href = this.href,
                ids  = $.makeArray(
                    $(".business-" + section + "-picked li").map(function(i, item) { return $(item).attr("data-public-id")})
                ).join("_"),
                params = {};
            $(href.substr(href.indexOf("?") + 1).split("&")).each(function() {
                var keyval = this.split("=");
                params[keyval[0]] = keyval[1];
            });
            params[pluralSection] = ids;
            if (href.indexOf("?") != -1) {
                href = href.substring(0, href.indexOf("?"));
            }
            window.location = href + "?" + $.param(params);

        });
        // this handles adding/removing logic:
        // adding the initial elements is handled in the swapList function
        var picked = $(".business-"+section+"-picked");
        if (picked.find('.hint').length == 0) {
            var el = $('<p class="hint">Your chosen sectors will appear here</p>');
            $(".business-"+section+"-picked").append(el);
        }
        picked = picked.find("ul");
        if (picked.length > 0 && picked.find('li').length == 0) {
            $('.hint').removeAttr('style');
            $("#next-step").css('display', 'none');
        }
        else if (picked.length > 0 && picked.find('li').length > 0) {
            $('.hint').css('display', 'none');
            $("#next-step").removeAttr('style');
        }
	};

    function setupSearchForMore() {
        $("#search-again-button").off("click");
        $("#search-again-button").on("click", function() {
            var sectors = $.makeArray(
                $("#picked-business-sectors input").map(function(i, item) {
                    return item.value;
                })
            ).join("_");
            window.location.search = "sectors=" + sectors;

            return false;
        });
    }

	function init(){
		if($(".business-sector-picked").length > 0){
			section = "sector";
			pluralSection = "sectors"
		}
		else{
			section = "activity";
			pluralSection = "activities";
		}


		setupEvents();
        setupSearchForMore();

	};


//	init();
    function extractIds() {
        return $.makeArray(
            $(".picked-items li[data-public-id]").map(function(i, li) { return $(li).data("public-id"); })
        );
    }
    function extractParams() {
        var params = {};
        $(window.location.search.substr(1).split('&')).each(function(i, pair)  {
            pair = pair.split('=');
            params[pair[0]] = pair[1];
        });
        return params;
    }

    function createAddRemoveUrl(id) {
        var ids = extractIds(),
            params = extractParams();
        if (ids.indexOf(id) == -1) {
            ids.push(id);
        } else {
            ids.splice(ids.indexOf(id), 1);
        }
        params[window.location.pathname.split("/").pop()] = ids.join("_");
        return window.location.pathname + "?" + $.param(params);
    }

    function createNextUrl() {
        var ids = extractIds();
        var params = extractParams();
        var url;
        if (window.location.pathname.indexOf("/sectors") > -1) {
            url = window.location.pathname.replace("/sectors", "/activities");
            url += "?sectors=" + ids.join("_");
        } else {
            url = window.location.pathname.replace("/activities", "/location");
            url += "?sectors=" + params["sectors"] + "&activities=" + ids.join("_");
        }

        return url;
    }

    function swapper(event) {
        event.preventDefault();
        var oldli = $(this).parent(),
            publicId = oldli.data("public-id"),
            name = oldli.find("span:first"),
            newli = $('<li data-public-id="' + publicId + '"></li>'),
            source = $(event.delegateTarget),
            target = $(event.data.target),
            targetList = $("ul", target);


        newli.append(name)
             .append(" ")
             .append($('<a href="">' + event.data.linkText + '</a>'));
        targetList.append(newli);
        $('li', targetList).each(function() {
            $('a', this).attr('href', createAddRemoveUrl($(this).data('public-id')));
        });
        oldli.remove();

        if (event.data.sortTarget) {
            var newlis = $('>li', targetList);
            newlis.remove();
            newlis = $.makeArray(newlis);
            newlis.sort(function(a, b) {
                return $("span", a).text().localeCompare($("span", b).text());
            });
            targetList.append(newlis);
        }

        if (event.data.linkText == "Remove") {
            $(".hint", target).removeClass("hint").addClass("hidden");
            if ($("#next-step").length == 0) {
                target.append('<a href="" class="button medium" id="next-step">Next step</a>');
            }
        } else if (source.find("li").length == 0) {
            $(".hidden", source).removeClass("hidden").addClass("hint");
            $("#next-step").remove();
        }
        $("#next-step").attr("href", createNextUrl());

    }

    function init() {
        $(".search-picker").on("click", "li a", {linkText: "Remove", target: ".picked-items", sortTarget: true}, swapper);
        $(".picked-items").on("click", "li a", {linkText: "Add", target: ".search-picker"}, swapper);
    }

    init();

});
