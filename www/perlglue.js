  document.addEventListener("deviceready", onDeviceReady, false);
  
  var deviceId;
  var deviceType;
var page = 0; 
  
  function onDeviceReady() {
    
    var pushNotification = window.plugins.pushNotification;
                                     
    deviceId = device.uuid;
    deviceType = device.platform;
          
    prepMySchedulePage();
    getMySchedule();
  }

  $('#my_schedule_page').live('pageinit', function(event) { getMySchedule(); });
  $('#schedule_page').live('pageinit', function(event) { prepSchedulePage(); });
  $('#talk_page').live('pagebeforeshow', function(event) { getTalk(); });
  $('#comment_page').live('pagebeforeshow', function(event) { prepCommentForm(); });
  $('#rating_page').live('pagebeforeshow', function(event) { prepRatingForm(); });
  $('#settings_page').live('pagebeforeshow', function(event) { prepSettingsPage(); });


function prepMySchedulePage() {

  $("#my_schedule_date_sel").bind("change", function() {
                                  getMySchedule();
                                  });
}
  
  function getMySchedule() {
    $("#my_schedule_list").html("");
    var epoch = $("#my_schedule_date_sel option:selected").attr('value');
    $.getJSON("http://perlglue.m0nkey.us/talks/myschedule/", { device_id: deviceId, device_type: deviceType, epoch: epoch }, 
        function(json) {
              console.log( json );
          popScheduleList( json.results, $("#my_schedule_list") );
        }
    );
  }
  
function prepSchedulePage() {
  $("#schedule_date_sel").bind("change", function() {
                                  getSchedule();
                                  });
  getSchedule();
}
  
  function getSchedule() {
    $("#schedule_list").html("");
    var epoch = $("#schedule_date_sel option:selected").attr('value');
    $.getJSON("http://perlglue.m0nkey.us/talks/schedule/", { device_id: deviceId, device_type: deviceType, epoch: epoch }, function(json) { popScheduleList( json.results, $("#schedule_list") ); });
  }
  
  function popScheduleList( talks, element ) {
    $.each( talks, function(i, talk) {
           var url = "talk.html?talk_id=" + talk.id;
           element.append("<li data-role='list-divider'><a href='" + url + "'><b>" + talk.time + " for " + talk.duration + " minutes </b><br>" + talk.title + "<br>" + talk.author + "<br><b>Room: " + talk.location + "</b></a></li>");       
           });
    element.listview('refresh');
  }

  
  function getTalk() {
    page = 0;
    var id = getUrlVars()["talk_id"];
    $.getJSON("http://perlglue.m0nkey.us/talks/" + id + "/info/", { device_id: deviceId, device_type: deviceType }, function(json) {
              $("#talk_title").html( json.title );
              $("#talk_title_bold").html( json.title );
              $("#talk_date").html( json.date );
              $("#talk_location").html( "Room: " + json.location );
              $("#talk_overview").html( json.overview );
              $("#talk_author").html( json.author );
              var rating = json.rating;
              if( rating != "N/A") {
                rating = rating + "/10";
              }
              $("#talk_rating").html( rating );
              $("#add_talk_btn").bind('click',function() { addTalkToSchedule( id ); });
              $("#remove_talk_btn").bind('click',function() { removeTalkFromSchedule( id ); });
              $("#comment_btn").attr('href','comment.html?talk_id=' + id);
              $("#rate_btn").attr('href','rate.html?talk_id=' + id);
              var comments = json.comments;
              popComments( comments );
              $("#load_more_btn").bind('click', function() { loadMoreComments( id ); });
    });
  }

function loadMoreComments( id ) {
  console.log("Loading more comments");
  page = page + 1;
  console.log("Page: " + page);
  $.getJSON("http://perlglue.m0nkey.us/talks/" + id + "/info/", { device_id: deviceId, device_type: deviceType, page: page }, function(json) {
            console.log( json );
            var comments = json.comments;
            popComments( comments );
  });
  
}

function popComments( comments ) {
  $.each( comments, function(i, comment) {
         $("#comment_list").append("<li>" + comment.body + "<br>" + comment.date + "</li>");       
         });
  $("#comment_list").listview('refresh');
}
  
  function addTalkToSchedule( talkId ) {
    $.getJSON("http://perlglue.m0nkey.us/talks/" + talkId + "/add/", { device_id: deviceId, device_type: deviceType, talk_id: talkId }, function(json) {
              alert("Talk added to your schedule");
              window.location.href = "index.html";
              });
  }
  
  function removeTalkFromSchedule( talkId ) {
    $.getJSON("http://perlglue.m0nkey.us/talks/" + talkId + "/remove/", { device_id: deviceId, device_type: deviceType, talk_id: talkId }, function(json) {
              alert( "Talk removed from your schedule" );
              window.location.href = "index.html";
              });
  }
  
  function prepCommentForm() {
    var talkId = getUrlVars()["talk_id"];
    $("#comment_submit_btn").bind("click", function() {
      var message = $("#comment_mesage_input").attr('value');
      $.getJSON("http://perlglue.m0nkey.us/talks/" + talkId + "/comment/", { device_id: deviceId, device_type: deviceType, talk_id: talkId, message: message }, function(json) {
              alert( json.message );
              $('.ui-dialog').dialog('close')            
          });
      });
  }
  
  function prepRatingForm() {
    var talkId = getUrlVars()["talk_id"];
    $("#rating_submit_btn").bind("click", function() {
                                  var rating = $("#rating_input").attr('value');
                                  $.getJSON("http://perlglue.m0nkey.us/talks/" + talkId + "/rate/", { device_id: deviceId, device_type: deviceType, talk_id: talkId, rating: rating }, function(json) {
                                            alert( json.message );
                                            $('.ui-dialog').dialog('close')            
                                            });
                                  });
  }
  
  function prepSettingsPage() {

    $("#enable_alerts_btn").bind("click", function() {
                                 console.log("Enabling alerts");
      window.plugins.pushNotification.registerDevice({alert:true, badge:true, sound:true}, function(status) {
                                                               
          $.getJSON("http://perlglue.m0nkey.us/alerts/enable/", { device_id: deviceId, device_type: deviceType, token: status.deviceToken }, function(json) { alert( json.message ); });
      });
                                  });
    $("#disable_alerts_btn").bind("click", function() {
                                  console.log("disabling alerts");
                                  window.plugins.pushNotification.registerDevice({alert:false, badge:false, sound:false}, function(status) { });
                                 $.getJSON("http://perlglue.m0nkey.us/alerts/disable/", { device_id: deviceId, device_type: deviceType }, function(json) {
                                           alert( json.message );           
                                           });
                                 });
  }
  
  function getUrlVars() {
    var vars = [], hash;
    var hashes = window.location.href.slice(window.location.href.lastIndexOf('?') + 1).split('&');
    for(var i = 0; i < hashes.length; i++)
    {
      hash = hashes[i].split('=');
      vars.push(hash[0]);
      vars[hash[0]] = hash[1];
    }
    return vars;
  }
