$(function() {
    function pageName() {
        return window.location.pathname.split("/").pop();
    }

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
        params[pageName()] = ids.join("_");

        return window.location.pathname + "?" + $.param(params);
    }

    function createNextUrl() {
        var ids = extractIds();
        var params = extractParams();
        var url;
        if (pageName() == "sectors") {
            url = window.location.pathname.replace("/sectors", "/activities");
            url += "?sectors=" + ids.join("_");
        } else {
            url = window.location.pathname.replace("/activities", "/location");
            url += "?sectors=" + params["sectors"] + "&activities=" + ids.join("_");
        }

        return url;
    }

    // Move a list item from one list to another.
    function swapper(event) {
        event.preventDefault();
        var oldli = $(this).parent(), // the list item that is being moved
            newli = $('<li data-public-id="' + oldli.data("public-id") + '"></li>'), // the target list element
            source = $(event.delegateTarget), // container for list that element is coming from
            target = $(event.data.target), // container for list that element is going to
            targetList = $("ul", target);

        newli.append(oldli.find("span:first"))
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
        if (pageName() == "sectors") {
            $("#search-again-button").attr("href", window.location.pathname + "?sectors=" + extractIds().join("_"));
            $("#hidden-sectors").attr("value", extractIds().join("_"));
        }
    }

    function init() {
        // event handler to add a list item to the picked list.
        $(".search-picker").on("click", "li a", {linkText: "Remove", target: ".picked-items", sortTarget: true}, swapper);
        // event handler to remove a list item from the picked list.
        $(".picked-items").on("click", "li a", {linkText: "Add", target: ".search-picker"}, swapper);
    }

    init();

});