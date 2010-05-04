wip = #{@wip.to_json}

// update the page with json wip object
function update() {

  if ( wip.task_complete ) {
    $('#commands button#start').button('disable')
      $('#commands button#stop').button('disable')
  } else {

    if ( wip.running == false ) {
      $('#commands button#start').button('enable')
        $('#commands button#stop').button('disable')
    } else {
      $('#commands button#stop').button('enable')
        $('#commands button#start').button('disable')
    }

  }

  if (  wip.running || wip.task_complete ) {
    $('#commands button#stash').button('disable')
      $('#commands input#stash-path').attr('disabled', true)
  } else {
    $('#commands button#stash').button('enable')
      $('#commands input#stash-path').removeAttr('disabled')
  }

  if ( wip.pid ) {
    $('#process-status-pid').text(wip.pid)
      $('#process-status-pid-time').text(wip.pidTime)
  } else {
    $('#process-status-pid').text('inactive')
      $('#process-status-pid-time').text('')
  }

  $('#task-status').text(wip.state)

    if ( wip.snafu ) {

      if ( !$('#snafu').is(':visible') ) {
        $('#snafu').show('fast');
        $('#commands button#unsnafu').button('enable')
          $('#snafu pre').text(wip.snafu)
      }

    } else {

      if ( $('#snafu').is(':visible') ) {
        $('#commands button#unsnafu').button('disable')
          $('#snafu').hide('fast');
        $('#snafu pre').text(wip.snafu)
      }
    }

  if ( wip.reject ) {
    $('#reject pre').text(wip.reject)
      $('#reject').show('fast');
  } else {
    $('#reject').hide('slow');
  }

}

// when the doc is loaded setup the cool stuff
$(document).ready(function () {
    $('#update-form').hide()
    $('#commands button').button()

    // set button events
    $('#commands button#start').click(function () {
      if ( ! $(this).hasClass('ui-state-disabled') ) {
      $.post(wip.id, {task: 'start'}, function (data, textStatus) {
        wip = data
        update();
        }, 'json')
      }
      })

    $('#commands button#stop').click(function () {
      if ( ! $(this).hasClass('ui-state-disabled') ) {
      $.post(wip.id, {task: 'stop'}, function (data, textStatus) {
        wip = data
        update();
        }, 'json')
      }
      })

    $('#commands button#unsnafu').click(function () {
        if ( ! $(this).hasClass('ui-state-disabled') ) {
        $.post(wip.id, {task: 'unsnafu'}, function (data, textStatus) {
          wip = data
          update();
          }, 'json')
        }
        })

    $('#commands button#stash').click(function () {
        if ( ! $(this).hasClass('ui-state-disabled') ) {
        $.post(wip.id, {task: 'stash', path: $('#stash-path').attr('value') }, function (data, textStatus) {

          // notify the stash
          d = $(document.createElement("div"))
          d.append('<p>stashed at <code>' + $('#stash-path').attr('value') + '/' + wip.id + '</code></p>')
          d.append('return to <a href="/">workspace<a/>')
          d.dialog({
title: 'stashed',
bgiframe: true,
draggable: false,
modal: true,
width: 500,
closeOnEscape: true,
close: function() { window.location = '/' },
})

          }, 'json')
        }
        })

if ( ! wip.snafu ) {
  $('#snafu').hide()
    $('#commands button#unsnafu').button('disable')
}
if ( ! wip.reject ) { $('#reject').hide() }

// update from the json
update();
$('#commands').show()

// update periodically
setInterval(function () {
    $.getJSON(wip.id, null, function (data, textStatus) {
      wip = data
      update();
      })
    }, 3000);

})
