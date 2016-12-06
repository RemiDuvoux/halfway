$('#new_result').on('submit', function(event) {
  var origin_a = $("#new_result select[name=origin_a]").val();
  var origin_b = $("#new_result select[name=origin_b] ").val();
  var date_there = $('#new_result #date_there').val();
  var date_back = $('#new_result #date_back').val();
  if (date_there != "" && date_back != "" ) {
  var date_input_1 = Date.parse(date_there);
  var date_input_2 = Date.parse(date_back);
  if (origin_a == "" || origin_b == "" || date_there == "" || date_back == "" || date_input_1 > date_input_2 ){
    sweetAlert("Oops, looks like you forgot something ");
    return false;
  } else {
    return true
  } }
  else {
    console.log("false")
    sweetAlert("Oops, looks like you forgot something ");
    return false;
  }
});
