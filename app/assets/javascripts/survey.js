// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

function missedAlert(form, validator) {
  var errors = validator.numberOfInvalids();
  if (errors) {
    $("input:blank").first().focus();
    var message = errors == 1
      ? 'You missed 1 question. It has been highlighted.'
      : 'You missed ' + errors + ' questions. They have been highlighted.<br/>';
    $("#dialog-confirm").html(message);
    $("#dialog-confirm").dialog("open");
    // Make sure dialog in centred after scrolling up to focus on first missed question.
    setTimeout("$('#dialog-confirm').dialog('widget').position({my: 'center', at: 'center', of: window});", 20);
  }
}

function configureCheck() {
  jQuery.validator.messages.required = ""

  $(function() {
    $("#dialog-confirm").dialog({
      autoOpen: false,
      resizable: false,
      width: 500,
      modal: true,
      buttons: {
        "Go back to missed questions": function() {
          $( this ).dialog( "close" );
        }
      }
    });
  });

  $(document).ready(function(){
    $("form").validate({
      highlight: function(element, errorClass, validClass) {
        $(element).parents("p,tr").addClass("errorCell");
      },
      unhighlight: function(element, errorClass, validClass) {
        $(element).parents("p,tr").removeClass("errorCell");
      },
      invalidHandler: missedAlert
    });
  });
}

function configurePage2() {
  jQuery.validator.messages.equalTo = "Please enter the same address again.";
  $("input:radio").on("click", function() {
    if ($("input[name=have_email]:checked").val() == "y") {
      $("#email").show();
      $("#participant_email").addClass("email");
      $("#email_confirmation").rules("add", { equalTo: "#participant_email" });
    } else {
      $("#email").hide();
      $("#participant_email").removeClass("email");
    }
  });
  $("#email").hide();
}
