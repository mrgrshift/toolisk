/////// simple-monitor

//Define a port you want to listen to
const PORT=9100;

var http = require('http');
var fs = require("fs");
var monitor = "";
var global_data = "";
var css = "";  //you can add you own css style
css = css + "<style>";
css = css + "table { border-collapse: collapse; }";
css = css + "th, td { padding: 8px; text-align: left; border-bottom: 1px solid #ddd;}";
css = css + "tr:hover{background-color:#f5f5f5}";
css = css + "</style>";

//Function check database every 27 seconds
setInterval(function() {
	fs.readFile("logs/forging_manager.log", "UTF8", function(err, data) {
	    if (err) { throw err };
	    global_data = data;
	});
	monitor = "<!DOCTYPE html><html><head>" + css + "</head><body><h1>Monitor<br><input type='button' value='Refresh' onclick='javascript:location.reload();'><br>"+ global_data;
}, 10000);


function handleRequest(request, response){
    response.end(monitor);
}

//Create a server
var server = http.createServer(handleRequest);


//Start our server
server.listen(PORT, function(){
    console.log("Server listening on: http://localhost:%s", PORT);
});
