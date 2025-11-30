(function($){'use strict';function open_side_panel(){var $woocart_wrapper=$('.tm-floating-woocart-wrapper');var $body=$('body');if(!$woocart_wrapper.length){return}
$body.on('click','.tm-header-search-content-style-side-panel .mini-cart-icon',function(e){e.preventDefault();if(!$woocart_wrapper.hasClass('open')){$woocart_wrapper.addClass('open')}})}
$(document).ready(function(){open_side_panel()})})(jQuery)
;