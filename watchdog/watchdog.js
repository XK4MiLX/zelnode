var shell = require('shelljs');
var sleep = require('sleep');
sleep.sleep(10);

console.log('Watchdog v1.7 by XK4MiLX Starting...');
console.log('=================================================================');
function zeldaemon_check() {

  date = new Date();
  data_time= new Date(date.getTime() - (date.getTimezoneOffset() * 60000)).toISOString().
  replace(/T/, ' ').
  replace(/\..+/, '');

console.log('Summary Raport / Time: '+data_time );
console.log('=================================================================');
var zelbench_status = shell.exec("zelbench-cli getstatus | jq '.benchmarking'",{ silent: true }).stdout;
var zelback_status = shell.exec("zelbench-cli getstatus | jq '.zelback'",{ silent: true }).stdout;
var zelcash_check = shell.exec("zelcash-cli getinfo | jq '.version'",{ silent: true }).stdout;
var zelcash_node_status = shell.exec("zelcash-cli getzelnodestatus | jq '.status'",{ silent: true }).stdout;
if (zelcash_node_status == ""){
} else{
console.log('Zelnode status = '+zelcash_node_status.trim());
}
if (zelback_status == ""){
console.log('Zelback status = dead');
} else{
console.log('Zelback status = '+zelback_status.trim());
}
if (zelbench_status == ""){
console.log('Zelbench status = dead');
} else{
console.log('Zelbench status = '+zelbench_status.trim());
}
if (zelcash_check !== "" ){
console.log('Zelcash status =  "running"');
}
else {
console.log('Zelcash status =  dead');
shell.exec("sudo fuser -k 16125/tcp",{ silent: true })
shell.exec("sudo systemctl start zelcash",{ silent: true })
console.log('Zelcash restarting...');
}
if ( zelbench_status.trim() == '"toaster"')
{
shell.exec("zelbench-cli restartnodebenchmarks",{ silent: true });
console.log('Zelbench restarting...');
}
console.log('=================================================================');
}
setInterval(zeldaemon_check, 150000);
