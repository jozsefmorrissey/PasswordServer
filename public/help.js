
const cmds = {
	'edit': 'edit COLLECTION_IDENTIFIER',
	'view': 'view COLLECTION_IDENTIFIER',

	'value': 'value COLLECTION_IDENTIFIER PASSWORD_IDENTIFIER',
	'update': 'update COLLECTION_IDENTIFIER PASSWORD_IDENTIFIER NEW_VALUE',

	'replace': 'replace COLLECTION_IDENTIFIER PASSWORD_IDENTIFIER FILE_LOC',
	'remove': 'remove COLLECTION_IDENTIFIER PASSWORD_IDENTIFIER FILE_LOC',

	'log': 'log ',
	'help': 'help',

	'setup-server': 'setup-server COLLECTION_IDENTIFIER PASSWORD_IDENTIFIER NEW_VALUE',
	'stop-server': 'stop-server PORT',
	'start-server': 'start-server PORT',
}

const urlInfo = {
  '/password/get': {},
}


const app = angular.module("passApp", []);
app.controller("passCtrl", function($scope, $http, domAop, $compile) {
    $scope.cmds = cmds;
    $scope.urls = Object.keys(urlInfo);
    $scope.domain = window.location.href.replace(/(.*\/\/.*)\/.*/, "$1");
    $scope.currPort = window.location.href.replace(/.*:([0-9]*).*/, "$1");

		function longestFirst(a, b) {
		    return b.length - a.length;
		}

    let keywords = [];
    function setKeywords(resp) {
      keywords = resp.data.sort(longestFirst);

      function onHover(elem) {
				let jqElem = $(elem);
				if (!jqElem.attr('scanned')) {
	        for(let index = 0; index < keywords.length; index += 1) {
	          surroundWord(jqElem, keywords[index], '<hover-resource></hover-resource>');
	        }
					jqElem.attr('scanned', true);
	        $compile(elem)($scope);
				}
      }
      domAop.hover('b,p,li', onHover);
    }
    $http.get('/keywords').then(setKeywords);

		function setDockerCommand(resp) {
			$scope.dockerCommand = `${resp.data}`;
		}
		$http.get('/dockerCommand').then(setDockerCommand);

		function setToken(resp) {
			$scope.token = `${resp.data}`;
		}
		$http.get('/token').then(setToken);

    function surroundWord(jqObj, word, htmlStr) {
			if (word == 'dockerCommand') {
				console.log('dcmd');
			}
      let html = '>> ' + jqObj.html() + ' <<';
      html = html.replace(/\n/g, ' ');
      const wordReg = '(>[^>^<]{1,})' + word + '([^>^<]{1,}<)'
      while (html.match(wordReg)) {
        const jqSurrounded = $(htmlStr).text(word);
        html = html.replace(new RegExp(wordReg, "g"), "$1" + jqSurrounded[0].outerHTML + "$2");
        jqObj.html(html.substr(2, html.length - 4));
      }
    }
});

app.service("hoverSrvc", function ($http, $location) {
  const obj = {};
  const loadedContent = {};

  function setLoadedContent(url, contentGroupId, urlContentId) {
    if (loadedContent[url] === undefined) {
      loadedContent[url] = $http.get(url);
    }
    return loadedContent[url];
  }

  function getContent($element, id, contentId) {
    switch(contentId) {
      case 'keyword':
        let keyword = $($element).text().replace(/\//g, "$");
        const absUrl = $location.$$absUrl;
        const host = $location.$$host;
        const firstPathSlash = absUrl.indexOf('/', absUrl.indexOf(host));
        let domain = absUrl.substr(0, firstPathSlash + 1);
        let keywordUrl = `${domain}keywords/${keyword}.html`;
        // keywordUrl = 'http://localhost:9001/keywords/COLLECTION_IDENTIFIER.html';
        return setLoadedContent(keywordUrl);
      default:
        return $($element).html();
    }
  }

  function getContainer(contents, id, name) {
    switch(name) {
      default:
        return $(`<div class="hover-outer" id='${id}' ng-click='$event.stopPropagation()'>
										<button class='hover-close-btn' ng-click='close("${id}")'>X</button>
                    <div class='hover-inner'>
                      ${contents}
                    </div>
                  </div>`);
    }
  }

  obj.getContainer = getContainer;
  obj.getContent = getContent;
  return obj;
});

let hoverCount = 0;
app.directive("hoverResource", function (hoverSrvc, domAop) {
  // $('hover-resource').on('mouseenter', function () {$scope.hoverOn();});//,
  domAop.hover('hover-resource', function(elem) {
    $(elem).addClass('link');
  });

  domAop.hoverOff('hover-resource', function(elem) {
    $(elem).removeClass('link');
  });

  function ctrl($scope, $element, $compile) {
      $scope.show = false;
      let beenOn = false;
      let id = hoverCount++;
      const switchId = "hover-switch-" + id;
      const hoverId = "hover-resource-" + id;
      $($element).attr('id', switchId);
      let content;
      hoverSrvc.getContent($element, hoverId, 'keyword').then(function (resp) {
        content = hoverSrvc.getContainer(resp.data, hoverId);//$("<p id='" + hoverId + "'><b>Hello World!</b></p>");
        $('body').append(content);
        $('#' + hoverId).hide();
        $compile($('#' + hoverId))($scope);
      });

			$scope.close = close;

			function close(id) {
				$('#' + id).hide();
			}

      $(document).click(function () {
				close(hoverId);
      });

      function positionText() {
        const offset = $(`#${switchId}`).offset();
        const height = $(`#${switchId}`).height();
        const screenWidth =  $(window).width();
        const top = offset.top + height + "px";
        const left = (offset.left + 10 < screenWidth / 2 ? offset.left + 10 : screenWidth / 2) + "px";

        const width = ((screenWidth - left - 10)) + "px"
        content.css( {
          cursor: 'pointer',
          position: 'absolute',
          left: left,
          width: width,
          top: top
        })
      }

      $scope.hoverOn = function () {
        $(`#${switchId}`).toggleClass('link');
      }
      $scope.hoverOff = function () {
        $(`#${switchId}`).toggleClass('link');
      }

      $(`#${switchId}`).click(function ($event) {
        if($('#' + hoverId).is(":visible")) {
          $('#' + hoverId).hide();
        } else {
          positionText();
          $('#' + hoverId).show();
        }
        $event.stopPropagation();
      });

      $(`#${switchId}`).css("cursor", "pointer");
    }

  return {
    controller: ctrl,
  }});

app.service('domAop', function () {
  const AFTER = 'blur';
  const CHANGE = 'change';
  const RIGHT_CLICK = 'click';
  const DBL_CLICK = 'dblclick';
  const BEFORE = 'focus';
  const ON_HOVER = 'mouseover';
  const AFTER_HOVER = 'mouseout';
  const LEFT_CLICK = 'mouseup';

  const SURROUND = [BEFORE, AFTER];
  const HOVER = [ON_HOVER, AFTER_HOVER];
  const CLICK = [LEFT_CLICK, RIGHT_CLICK];

  let obj = {};
  let cutPoints = {};

  function exicuteFunc(event, func) {
    function exicute(e) {
      for (let index = 0; index < cutPoints[event].length; index++) {
        if ($(e.target).is(cutPoints[event][index].cutPoint)) {
          cutPoints[event][index].func(e.target);
        }
      }
    }
    return exicute;
  }

  function addCutPoint(event, cutPoint, func) {
    if (cutPoints[event] === undefined) {
      cutPoints[event] = [];
    }

    cutPoints[event].push({cutPoint, func});
    document.addEventListener(event, exicuteFunc(event, func));
  }

  function before(cutPoint, func) {
    addCutPoint(BEFORE, cutPoint, func);
  }

  function allClick(cutPoint, func) {
    addCutPoint(LEFT_CLICK, cutPoint, func);
  }

  function after(cutPoint, func) {
    addCutPoint(AFTER, cutPoint, func);
  }

  function change(cutPoint, func) {
    addCutPoint(CHANGE, cutPoint, func);
  }

  function click(cutPoint, func) {
    addCutPoint(RIGHT_CLICK, cutPoint, func);
  }

  function dblClick(cutPoint, func) {
    addCutPoint(DBL_CLICK, cutPoint, func);
  }

  function before(cutPoint, func) {
    addCutPoint(BEFORE, cutPoint, func);
  }

  function hover(cutPoint, func) {
    addCutPoint(ON_HOVER, cutPoint, func);
  }

  function hoverOff(cutPoint, func) {
    addCutPoint(AFTER_HOVER, cutPoint, func);
  }

  function surround(cutPoint, func) {
    obj.before(cutPoint, func);
    obj.after(cutPoint, func);
  }

  function surroundHover(cutPoint, func) {
    obj.hover(cutPoint, func);
    obj.hoverOff(cutPoint, func);
  }

  obj.surroundHover = surroundHover;
  obj.surround =surround;
  obj.click = click;
  obj.before = before;
  obj.after = after;
  obj.dblClick = dblClick;
  obj.hover = hover;
  obj.hoverOff = hoverOff;
  obj.change = change;
  obj.allClick = allClick;

  return obj;
});
