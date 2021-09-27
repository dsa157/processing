const { exec } = require("child_process");

var myArgs = process.argv.slice(2);
var myOutFile = myArgs[0];
var myHash = myArgs[1];
//console.log('outFile: ', myArgs[0]);
//console.log('hash: ', myArgs[1]);


var cmd = `processing-java --sketch=/Users/dsa157/Documents/Processing/projects/CreateNFTs --output=/Users/dsa157/Documents/Processing/projects/out1 --force --run -DimageList=http://www.dsa157.com/NFT/hiRez.txt DoutputFileName=${myOutFile} -Dhash=${myHash} `;

exec(cmd, (error, stdout, stderr) => {
    if (error) {
        console.log(`error: ${error.message}`);
        return;
    }
    if (stderr) {
        console.log(`stderr: ${stderr}`);
        return;
    }
    console.log(`stdout: ${stdout}`);
});
