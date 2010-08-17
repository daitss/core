workspace = #{settings.workspace.to_json}

function update () {
  $.each(workspace, function (index, wip) {

      // update if exists append otherwise
      row = $('table#wips tr:has(td a[href="' + wip.id + '"])')
      if (row.length) {
      cells = row.children('td')
      cells.eq(0).text(wip.task)
      cells.eq(2).text(wip.state)
      } else {
      row = $('<tr/>')
      row.append($('<td>' + wip.task + '</td>').addClass('task'))
      row.append($('<td><a href="' + wip.id + '">' + wip.uri + '</a></td>').addClass('value'))
      row.append($('<td>' + wip.state + '</td>').addClass('state'))
      $('table#wips').append(row)
      }

      })

  // garbage collect
  present_wips = $.map(workspace, function (wip, index) { return wip.uri })
    rows = $('table#wips tr')

    $.each(rows, function (index, row) {
        url = $(row).find('td a').text().trim()

        if ( $.inArray(url, present_wips) == -1 ) {
        $(row).hide('fast', function() {
          $(row).remove()
          })
        }

        })
}

$(document).ready(function () {

    // set button events
    $('#commands button#start').click(function () {
      if ( ! $(this).hasClass('ui-state-disabled') ) {
      $.post('.', {task: 'start'}, function (data, textStatus) {
        workspace = data
        update();
        }, 'json')
      }
      })

    $('#commands button#stop').click(function () {
      if ( ! $(this).hasClass('ui-state-disabled') ) {
      $.post('.', {task: 'stop'}, function (data, textStatus) {
        workspace = data
        update();
        }, 'json')
      }
      })

    $('#commands button#unsnafu').click(function () {
        if ( ! $(this).hasClass('ui-state-disabled') ) {
        $.post('.', {task: 'unsnafu'}, function (data, textStatus) {
          workspace = data
          update();
          }, 'json')
        }
        })

    //update();
    $('#update-form').hide()
      $('#commands button').button()
      $('#commands').show()

      setInterval(function () {
          $.getJSON('.', null, function (data, textStatus) {
            workspace = data
            update();
            })
          }, 3000);

})
